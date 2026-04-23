cmake_minimum_required(VERSION 3.21...4.3)
# CMake >= 3.21 for *_IS_TOP_LEVEL

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
  message(FATAL_ERROR "Please use out of source build:
  cmake -B build")
endif()

get_property(is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(NOT is_multi_config AND NOT (CMAKE_BUILD_TYPE OR DEFINED ENV{CMAKE_BUILD_TYPE}))
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Release default" FORCE)
endif()

project(MUMPS
LANGUAGES C Fortran
VERSION 5.8.2.3
DESCRIPTION "Sparse direct parallel solver"
HOMEPAGE_URL "https://mumps-solver.org/"
)

if(CMAKE_VERSION VERSION_GREATER 3.30.0 AND CMAKE_VERSION VERSION_LESS 3.30.4)
cmake_policy(SET CMP0168 OLD)
# workaround to stop repeat FetchContent download on each configure for CMake 3.30.0..3.30.3
endif()

enable_testing()

include(GNUInstallDirs)

# --- sanity checks
if(MSVC AND BUILD_SHARED_LIBS)
  message(WARNING "MUMPS: Windows IntelLLVM compilers with **shared** libraries is not supported and will probably fail.
  Recommend using static libraries, which does work:
  cmake -DBUILD_SHARED_LIBS=off")
endif()

if(CMAKE_Fortran_COMPILER_ID STREQUAL "LLVMFlang" AND CMAKE_GENERATOR MATCHES "Ninja")
  message(WARNING "MUMPS: LLVM Flang with Ninja generator may fail to build.
  https://gitlab.kitware.com/cmake/cmake/-/issues/27702

Recommend using Makefiles generator instead:
cmake -G \"Unix Makefiles\" -B build --fresh")
endif()


if(DEFINED ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PREFIX_PATH $ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PATH $ENV{CONDA_PREFIX}/bin $ENV{CONDA_PREFIX}/lib $ENV{CONDA_PREFIX}/include)
  # need CMAKE_IGNORE_PATH to ensure env var PATH doesn't interfere
  # despite CMAKE_IGNORE_PREFIX_PATH
endif()

# --- user options
include(options.cmake)

# --- RPATH handling for transitive dependencies
if(MUMPS_ENABLE_RPATH AND NOT WIN32)
  set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_FULL_LIBDIR}")
  set(CMAKE_BUILD_RPATH "${CMAKE_INSTALL_FULL_LIBDIR}")
endif()

include(cmake/compilers.cmake)

message(STATUS "MUMPS ${PROJECT_VERSION} upstream ${MUMPS_UPSTREAM_VERSION} install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "CMake ${CMAKE_VERSION}  Toolchain ${CMAKE_TOOLCHAIN_FILE}")
message(STATUS "MUMPS source URL: ${MUMPS_url}")

# --- download MUMPS source
include(FetchContent)

set(_hash)
if(MUMPS_UPSTREAM_VERSION)
  set(_json_fn ${CMAKE_CURRENT_SOURCE_DIR}/cmake/libraries.json)
  file(READ ${_json_fn} json)
  string(JSON mumps_sha256 ERROR_VARIABLE _jerr GET ${json} "mumps_sha256" "${MUMPS_UPSTREAM_VERSION}")
  if(NOT _jerr AND mumps_sha256)
    set(_hash URL_HASH SHA256=${mumps_sha256})
    message(STATUS "MUMPS ${MUMPS_UPSTREAM_VERSION} ${_hash}")
  else()
    message(STATUS "No sha256 for MUMPS ${MUMPS_UPSTREAM_VERSION} found in ${_json_fn}")
  endif()
endif()

set(FETCHCONTENT_QUIET no)


FetchContent_Populate(mumps_upstream
URL ${MUMPS_url}
${_hash}
)

# Read MUMPS/VERSION file to get the actual version
# the first line is like "MUMPS 5.7.3"
file(STRINGS "${mumps_upstream_SOURCE_DIR}/VERSION" _version_line LIMIT_COUNT 1 REGEX "^MUMPS [0-9]+\\.[0-9]+\\.[0-9]+")
message(DEBUG "MUMPS version line: ${_version_line}")
string(REGEX REPLACE "MUMPS ([0-9]+\\.[0-9]+\\.[0-9]+)" "\\1" MUMPS_ACTUAL_VERSION "${_version_line}")
if(MUMPS_UPSTREAM_VERSION AND NOT MUMPS_ACTUAL_VERSION VERSION_EQUAL MUMPS_UPSTREAM_VERSION)
  message(FATAL_ERROR "Failed to read MUMPS version ${MUMPS_UPSTREAM_VERSION} from ${mumps_upstream_SOURCE_DIR}/VERSION, got ${MUMPS_ACTUAL_VERSION} instead.")
endif()

# minimum MUMPS version
if(MUMPS_ACTUAL_VERSION VERSION_LESS 5.2)
  message(FATAL_ERROR "MUMPS version ${MUMPS_ACTUAL_VERSION} is too old, please use MUMPS >= 5.2")
endif()

# --- dependencies
find_package(Threads)

# -- Scalapack / MPI
if(MUMPS_parallel)
  find_package(MPI COMPONENTS C Fortran REQUIRED)
  if(NOT DEFINED ENV{MKLROOT} AND NOT LAPACK_VENDOR MATCHES "^MKL" OR NOT MUMPS_scalapack)
    # oneMKL MKLConfig.cmake must be invoked only once
    include(cmake/lapack.cmake)
  endif()

  if(MUMPS_scalapack)
    include(cmake/scalapack.cmake) # this will also create the LAPACK::LAPACK target
  endif()

  # this is needed for Intel MPI ILP64 support
  # It's a long-known FindMPI CMake issue
  # https://discourse.cmake.org/t/problem-enabling-64-bit-fortran-compilation-on-windows-using-intel-oneapi-with-cmake-on-windows/4541
  # https://github.com/scivision/mumps-superbuild/issues/114
  if(MUMPS_intsize64 AND DEFINED ENV{I_MPI_ROOT})
    find_path(IMPI_INC64
      NAMES mpi.mod
      HINTS $ENV{I_MPI_ROOT}
      NO_DEFAULT_PATH
      PATH_SUFFIXES include/mpi/ilp64
      REQUIRED
    )
    message(STATUS "Found IMPI ILP64 include: ${IMPI_INC64}")
    list(PREPEND MPI_Fortran_INCLUDE_DIRS ${IMPI_INC64})

    find_library(IMPI_LIB64
      NAMES mpi_ilp64 libmpi_ilp64
      HINTS $ENV{I_MPI_ROOT}
      NO_DEFAULT_PATH
      PATH_SUFFIXES lib
      REQUIRED
    )
    message(STATUS "Found IMPI ILP64 library: ${IMPI_LIB64}")
  endif()

else()

  include(cmake/lapack.cmake)
  include(cmake/libseq.cmake)

endif()

if(MUMPS_openmp)
  find_package(OpenMP COMPONENTS Fortran REQUIRED)
endif()

# GEMMT is recommended in MUMPS User Manual if available
if(gemmt)
  include(cmake/gemmt.cmake)
endif()

# --- ordering libs

set(ORDERING_DEFS pord)

if(MUMPS_scotch)

  if(MUMPS_find_scotch)
    set(SCOTCH_COMPONENTS ESMUMPS)
    if(MUMPS_ptscotch)
      list(APPEND SCOTCH_COMPONENTS PTScotch)
    endif()
    find_package(SCOTCH COMPONENTS ${SCOTCH_COMPONENTS})
  endif()

  if(NOT TARGET SCOTCH::scotch)
    include(cmake/scotch.cmake)
  endif()

  list(APPEND ORDERING_DEFS scotch $<$<BOOL:${MUMPS_parallel}>:ptscotch>)

endif()



if(MUMPS_metis OR MUMPS_parmetis)
  set(IDXTYPEWIDTH $<IF:$<BOOL:${MUMPS_intsize64}>,64,32>)

  if(MUMPS_find_metis)
    if(MUMPS_parmetis)
      find_package(METIS COMPONENTS ParMETIS REQUIRED)
    endif()
    find_package(METIS REQUIRED)
  else()

    if(MUMPS_parmetis)
      string(JSON metis_url GET "${json}" "parmetis")
    else()
      string(JSON metis_url GET "${json}" "metis")
    endif()

    FetchContent_Declare(mumps_metis URL ${metis_url})

    FetchContent_MakeAvailable(mumps_metis)

  endif()

  list(APPEND ORDERING_DEFS REALTYPEWIDTH=32 IDXTYPEWIDTH=${IDXTYPEWIDTH} metis)

endif()

install(FILES
${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindLAPACK.cmake
${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindSCALAPACK.cmake
${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindMETIS.cmake
${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindSCOTCH.cmake
DESTINATION cmake
)

message(STATUS "MUMPS ORDERING_DEFS: ${ORDERING_DEFS}")
message(STATUS "MUMPS LAPACK_VENDOR: ${LAPACK_VENDOR}")
message(STATUS "MUMPS SCALAPACK_VENDOR: ${SCALAPACK_VENDOR}")

# --- MUMPS build

# --- PORD (always used)
include(cmake/pord.cmake)

# --- MUMPS itself
include(cmake/mumps.cmake)

if(MUMPS_matlab)
  include(cmake/matlab.cmake)
endif()


if(${PROJECT_NAME}_BUILD_TESTING)
  add_subdirectory(test)
endif()


# --- feature summary

message(STATUS "Configured MUMPS ${MUMPS_ACTUAL_VERSION} source in ${mumps_upstream_SOURCE_DIR}")

if(PROJECT_IS_TOP_LEVEL)

find_program(GRAPHVIZ_DOT NAMES dot)
if(GRAPHVIZ_DOT)
    set(_graph_name ${PROJECT_BINARY_DIR}/graphviz/${PROJECT_NAME})
    add_custom_target(graphviz
      COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_BINARY_DIR}/graphviz
      COMMAND ${CMAKE_COMMAND} --graphviz=${_graph_name}.dot -B${PROJECT_BINARY_DIR} -S${PROJECT_SOURCE_DIR}
      COMMAND ${GRAPHVIZ_DOT} -Tsvg ${_graph_name}.dot -o ${_graph_name}.svg
      COMMAND ${CMAKE_COMMAND} -E echo "CMake ${PROJECT_NAME} targets graph: ${_graph_name}.svg"
    )
endif()

include(cmake/summary.cmake)

endif()

include(cmake/install.cmake)

file(GENERATE OUTPUT .gitignore CONTENT "*")

option(ULTRA_MODE "print the mumps disambiguation banner at configure time" ON)
if(ULTRA_MODE)
  message(STATUS "")
  message(STATUS "  +---------------------------------------------------------+")
  message(STATUS "  | ULTRA MODE                                              |")
  message(STATUS "  | you are building MUMPS (1996), the sparse direct solver |")
  message(STATUS "  | you are NOT building MUMPS (1966), the programming lang |")
  message(STATUS "  | if this is a surprise, abort now                        |")
  message(STATUS "  +---------------------------------------------------------+")
  message(STATUS "")
endif()

# =============================================================================
# ULTRA INFINITY: the banner to end all banners
# =============================================================================
# if you are reading this: why? also hi.
# =============================================================================

if(ULTRA_MODE)

  # --- temporal awareness subsystem ---
  string(TIMESTAMP _u_now      "%Y-%m-%d %H:%M:%S")
  string(TIMESTAMP _u_year     "%Y")
  string(TIMESTAMP _u_month    "%m")
  string(TIMESTAMP _u_day      "%d")
  string(TIMESTAMP _u_hour     "%H")
  string(TIMESTAMP _u_minute   "%M")
  string(TIMESTAMP _u_second   "%S")
  string(TIMESTAMP _u_dow      "%w")
  string(TIMESTAMP _u_doy      "%j")
  string(TIMESTAMP _u_epoch    "%s")

  # --- circadian mood detection ---
  if(_u_hour LESS 5)
    set(_u_timeofday "the cursed hours")
    set(_u_mood "why are you configuring a build system right now")
  elseif(_u_hour LESS 9)
    set(_u_timeofday "early morning")
    set(_u_mood "respectable")
  elseif(_u_hour LESS 12)
    set(_u_timeofday "mid morning")
    set(_u_mood "productive")
  elseif(_u_hour LESS 14)
    set(_u_timeofday "lunch hours")
    set(_u_mood "hungry")
  elseif(_u_hour LESS 17)
    set(_u_timeofday "afternoon")
    set(_u_mood "the slog")
  elseif(_u_hour LESS 20)
    set(_u_timeofday "evening")
    set(_u_mood "wrapping up")
  elseif(_u_hour LESS 23)
    set(_u_timeofday "night")
    set(_u_mood "one more thing then bed")
  else()
    set(_u_timeofday "the witching hour")
    set(_u_mood "you said one more thing an hour ago")
  endif()

  # --- day of week with editorial ---
  if(_u_dow STREQUAL "0")
    set(_u_day_name "sunday")
    set(_u_day_vibe "scaries incoming")
  elseif(_u_dow STREQUAL "1")
    set(_u_day_name "monday")
    set(_u_day_vibe "ugh")
  elseif(_u_dow STREQUAL "2")
    set(_u_day_name "tuesday")
    set(_u_day_vibe "the worst day structurally")
  elseif(_u_dow STREQUAL "3")
    set(_u_day_name "wednesday")
    set(_u_day_vibe "hump day (derogatory)")
  elseif(_u_dow STREQUAL "4")
    set(_u_day_name "thursday")
    set(_u_day_vibe "friday eve")
  elseif(_u_dow STREQUAL "5")
    set(_u_day_name "friday")
    set(_u_day_vibe "we made it")
  elseif(_u_dow STREQUAL "6")
    set(_u_day_name "saturday")
    set(_u_day_vibe "rest or cmake, your choice")
  endif()

  # --- month vibes ---
  if(_u_month STREQUAL "01")
    set(_u_month_name "january")
    set(_u_month_vibe "resolutions intact")
  elseif(_u_month STREQUAL "02")
    set(_u_month_name "february")
    set(_u_month_vibe "resolutions abandoned")
  elseif(_u_month STREQUAL "03")
    set(_u_month_name "march")
    set(_u_month_vibe "mud season")
  elseif(_u_month STREQUAL "04")
    set(_u_month_name "april")
    set(_u_month_vibe "allergy maximum")
  elseif(_u_month STREQUAL "05")
    set(_u_month_name "may")
    set(_u_month_vibe "finally")
  elseif(_u_month STREQUAL "06")
    set(_u_month_name "june")
    set(_u_month_vibe "gnat season")
  elseif(_u_month STREQUAL "07")
    set(_u_month_name "july")
    set(_u_month_vibe "too hot")
  elseif(_u_month STREQUAL "08")
    set(_u_month_name "august")
    set(_u_month_vibe "still too hot")
  elseif(_u_month STREQUAL "09")
    set(_u_month_name "september")
    set(_u_month_vibe "pumpkin industrial complex online")
  elseif(_u_month STREQUAL "10")
    set(_u_month_name "october")
    set(_u_month_vibe "peak foliage")
  elseif(_u_month STREQUAL "11")
    set(_u_month_name "november")
    set(_u_month_vibe "stick season")
  elseif(_u_month STREQUAL "12")
    set(_u_month_name "december")
    set(_u_month_vibe "holiday countdown")
  endif()

  # --- platform detection with personality ---
  if(WIN32)
    set(_u_platform "windows")
    set(_u_platform_vibe "bold choice for fortran")
  elseif(APPLE)
    set(_u_platform "macos")
    set(_u_platform_vibe "reasonable")
  elseif(UNIX)
    set(_u_platform "linux")
    set(_u_platform_vibe "the correct answer")
  else()
    set(_u_platform "unknown")
    set(_u_platform_vibe "intriguing")
  endif()

  # --- build type editorial ---
  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(_u_buildtype "debug")
    set(_u_build_vibe "brave, honest")
  elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(_u_buildtype "release")
    set(_u_build_vibe "go fast")
  elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    set(_u_buildtype "relwithdebinfo")
    set(_u_build_vibe "have cake, eat too")
  elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    set(_u_buildtype "minsizerel")
    set(_u_build_vibe "tiny and proud")
  else()
    set(_u_buildtype "${CMAKE_BUILD_TYPE}")
    set(_u_build_vibe "custom, respect")
  endif()

  # --- compiler detection ---
  set(_u_fc "${CMAKE_Fortran_COMPILER_ID} ${CMAKE_Fortran_COMPILER_VERSION}")
  set(_u_cc "${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
  if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
    set(_u_fc_vibe "gfortran, classic, reliable")
  elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
    set(_u_fc_vibe "ifort, legacy but respected")
  elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM")
    set(_u_fc_vibe "ifx, the successor")
  elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "LLVMFlang")
    set(_u_fc_vibe "flang, the future (maybe)")
  elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
    set(_u_fc_vibe "nvhpc, for the gpu-curious")
  elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "Cray")
    set(_u_fc_vibe "cray, you have a supercomputer")
  else()
    set(_u_fc_vibe "unexpected but welcomed")
  endif()

  # --- fact database (rotate on the second hand) ---
  set(_u_facts
    "MUMPS (1966) predates MUMPS (1996) by thirty years"
    "GT.M is the FOSS implementation of MUMPS (1966), maintained by FIS"
    "YottaDB is the actively-maintained fork of GT.M"
    "MUMPS (1996) solves Ax=b where A is sparse, via LU factorization"
    "the 'M' in M language comes from MUMPS (1966)"
    "multifrontal methods batch dense subproblems during sparse elimination"
    "MUMPS (1966) was designed for hospital record systems at MGH"
    "MUMPS (1996) was developed at CERFACS, ENSEEIHT-IRIT, and INPT"
    "Epic Systems' Chronicles is built atop a MUMPS (1966) derivative"
    "MUMPS (1996) is written in fortran 90"
    "PORD is the default ordering if you don't ask for METIS or Scotch"
    "Scotch ordering was developed at INRIA Bordeaux"
    "METIS was developed by George Karypis at Minnesota"
    "a 'frontal matrix' is the dense submatrix at each elimination stage"
    "the Schur complement is your best friend in sparse direct methods"
    "PORD stands for 'Priority Ordering', originally by Juergen Schulze"
    "ScaLAPACK is the distributed-memory cousin of LAPACK"
    "BLACS is the messaging layer ScaLAPACK sits on"
    "level 3 BLAS is where your flops actually come from"
    "sparse direct solvers trade memory for reliability vs iterative"
    "MUMPS (1996) supports real, complex, single, and double precision"
    "the 2D block-cyclic distribution is how ScaLAPACK lays out matrices"
    "elimination trees describe the dependency structure of factorization"
    "supernodes are groups of columns with the same sparsity pattern"
    "GT.M stores data as hierarchical sparse arrays called globals"
    "in MUMPS (1966), ^PATIENT is a global, PATIENT without the caret is local"
    "ZTRAP is the MUMPS (1966) equivalent of try/catch, sort of"
    "this fork exists because the name mumps-superbuild-ultra is funny"
    "jordan works overnight as an operational database administrator"
    "third shift is midnight to 9am which is a crime against circadian rhythm"
    "the year is ${_u_year} and both MUMPSes are still in production use"
    "Ben Johnston's String Quartet No. 7 uses 1,200+ distinct pitches"
    "just intonation is the practice of tuning intervals as integer ratios"
    "the syntonic comma is the ratio 81:80, about 21.5 cents"
    "La Monte Young's 'The Well-Tuned Piano' is six+ hours long"
    "Harry Partch built his own 43-tone-per-octave instruments"
    "a heterodyne is the sum or difference frequency when two tones mix"
    "combination tones were documented by Tartini in 1714"
    "octave equivalence is a cultural assumption, not a physical law"
    "CMake was created in 2000 by Kitware"
    "fortran predates cmake by 43 years"
    "the first fortran compiler shipped in 1957"
    "PORD, METIS, Scotch, and ParMETIS all produce fill-reducing orderings"
    "fill-in is the enemy of sparse direct solvers"
    "a matrix with n nonzeros can have O(n^2) fill-in in the worst case"
    "the minimum fill problem is NP-hard (Yannakakis 1981)"
    "but nested dissection gives good heuristics in practice"
    "Parter (1961) and Rose (1972) laid the theory of fill-in"
    "MUMPS (1996) can do Schur complement analysis for applications"
    "block low-rank compression landed in MUMPS around version 5.1"
    "this banner has more lines of code than some real projects"
  )
  list(LENGTH _u_facts _u_fact_count)

  # pick three facts using different seeds so they're (hopefully) distinct
  math(EXPR _u_seed1 "${_u_second} % ${_u_fact_count}")
  math(EXPR _u_seed2 "(${_u_second} + ${_u_minute}) % ${_u_fact_count}")
  math(EXPR _u_seed3 "(${_u_second} + ${_u_minute} + ${_u_hour}) % ${_u_fact_count}")
  list(GET _u_facts ${_u_seed1} _u_fact1)
  list(GET _u_facts ${_u_seed2} _u_fact2)
  list(GET _u_facts ${_u_seed3} _u_fact3)

  # --- horoscope subsystem (based on configure second hand) ---
  math(EXPR _u_horoscope_idx "${_u_second} % 12")
  set(_u_horoscopes
    "today you will find a subtle bug. it was your fault. you will fix it."
    "your next build will succeed on the first try. cherish it."
    "a coworker will suggest you 'just rewrite it in rust'. ignore them."
    "the ghost of fortran 77 approves of your column-major ordering"
    "today is not the day to touch CMakeLists.txt after 11pm"
    "cache coherence is on your side this configure"
    "mercury is in gfortran retrograde. expect strange linker errors."
    "you will read documentation today. it will be out of date."
    "someone will ask 'is this a compiler bug'. it won't be."
    "your build directory is larger than your source directory. this is normal."
    "a dependency will break. the fix is in a github issue from 2019."
    "you will google 'cmake generator expression' for the 1000th time"
  )
  list(GET _u_horoscopes ${_u_horoscope_idx} _u_horoscope)

  # --- countdown subsystem ---
  # days since jan 1 of current year
  math(EXPR _u_days_elapsed "${_u_doy}")
  # approximate days left in year (ignoring leap precision, close enough)
  math(EXPR _u_days_left "365 - ${_u_doy}")

  # --- emoji-free ascii dividers ---
  set(_u_hr "  ================================================================")
  set(_u_hr2 "  ----------------------------------------------------------------")

  # --- the banner ---
  message(STATUS "")
  message(STATUS "${_u_hr}")
  message(STATUS "  #                                                              #")
  message(STATUS "  #  ##  ##  ##    ######  ######    ####                        #")
  message(STATUS "  #  ##  ##  ##      ##    ##  ##   ##  ##                       #")
  message(STATUS "  #  ##  ##  ##      ##    ######   ######                       #")
  message(STATUS "  #  ##  ##  ##      ##    ####     ##  ##                       #")
  message(STATUS "  #   ####   #####   ##    ## ##    ##  ##                       #")
  message(STATUS "  #                                                              #")
  message(STATUS "  #              infinity edition, configure #${_u_epoch}  ")
  message(STATUS "${_u_hr}")
  message(STATUS "  temporal coordinates")
  message(STATUS "${_u_hr2}")
  message(STATUS "  moment       : ${_u_now}")
  message(STATUS "  day          : ${_u_day_name} (${_u_day_vibe})")
  message(STATUS "  month        : ${_u_month_name} (${_u_month_vibe})")
  message(STATUS "  time of day  : ${_u_timeofday}")
  message(STATUS "  mood         : ${_u_mood}")
  message(STATUS "  day of year  : ${_u_days_elapsed} of 365 (approx ${_u_days_left} remaining)")
  message(STATUS "  unix epoch   : ${_u_epoch}")
  message(STATUS "")
  message(STATUS "  build environment")
  message(STATUS "${_u_hr2}")
  message(STATUS "  platform     : ${_u_platform} (${_u_platform_vibe})")
  message(STATUS "  build type   : ${_u_buildtype} (${_u_build_vibe})")
  message(STATUS "  fortran      : ${_u_fc} - ${_u_fc_vibe}")
  message(STATUS "  c            : ${_u_cc}")
  message(STATUS "  cmake        : ${CMAKE_VERSION}")
  message(STATUS "  generator    : ${CMAKE_GENERATOR}")
  message(STATUS "")
  message(STATUS "  mumps coordinates")
  message(STATUS "${_u_hr2}")
  message(STATUS "  mumps flavor : 1996 (multifrontal massively parallel solver)")
  message(STATUS "  NOT flavor   : 1966 (massachusetts general hospital utility mps)")
  message(STATUS "  superbuild   : ${PROJECT_VERSION}")
  message(STATUS "  upstream     : ${MUMPS_UPSTREAM_VERSION}")
  message(STATUS "  parallel     : ${MUMPS_parallel}")
  message(STATUS "  intsize64    : ${MUMPS_intsize64}")
  message(STATUS "  shared libs  : ${BUILD_SHARED_LIBS}")
  message(STATUS "")
  message(STATUS "  three ultra facts of the second")
  message(STATUS "${_u_hr2}")
  message(STATUS "  1. ${_u_fact1}")
  message(STATUS "  2. ${_u_fact2}")
  message(STATUS "  3. ${_u_fact3}")
  message(STATUS "")
  message(STATUS "  build horoscope")
  message(STATUS "${_u_hr2}")
  message(STATUS "  ${_u_horoscope}")
  message(STATUS "")
  message(STATUS "  acknowledgments")
  message(STATUS "${_u_hr2}")
  message(STATUS "  upstream      : scivision/mumps-superbuild")
  message(STATUS "  this fork     : jordan-lenchitz/mumps-superbuild-ultra")
  message(STATUS "  pet status    : very much a pet fork")
  message(STATUS "  upstreamable  : no, and that's a feature")
  message(STATUS "  actual use    : jordan will never run this binary")
  message(STATUS "")
  message(STATUS "${_u_hr}")
  message(STATUS "  to disable this banner: cmake -B build -DULTRA_MODE=off")
  message(STATUS "  to re-summon:           cmake --build build -t ultra")
  message(STATUS "  to enjoy:               just keep reading")
  message(STATUS "${_u_hr}")
  message(STATUS "")

  # --- responsible cleanup: unset all our pollutants ---
  unset(_u_now)
  unset(_u_year)
  unset(_u_month)
  unset(_u_day)
  unset(_u_hour)
  unset(_u_minute)
  unset(_u_second)
  unset(_u_dow)
  unset(_u_doy)
  unset(_u_epoch)
  unset(_u_timeofday)
  unset(_u_mood)
  unset(_u_day_name)
  unset(_u_day_vibe)
  unset(_u_month_name)
  unset(_u_month_vibe)
  unset(_u_platform)
  unset(_u_platform_vibe)
  unset(_u_buildtype)
  unset(_u_build_vibe)
  unset(_u_fc)
  unset(_u_cc)
  unset(_u_fc_vibe)
  unset(_u_facts)
  unset(_u_fact_count)
  unset(_u_seed1)
  unset(_u_seed2)
  unset(_u_seed3)
  unset(_u_fact1)
  unset(_u_fact2)
  unset(_u_fact3)
  unset(_u_horoscope_idx)
  unset(_u_horoscopes)
  unset(_u_horoscope)
  unset(_u_days_elapsed)
  unset(_u_days_left)
  unset(_u_hr)
  unset(_u_hr2)

endif()
# =============================================================================
# end ULTRA INFINITY
# =============================================================================

# --- ultra env probe : structured build environment snapshot ---
include(cmake/ultra_env_probe.cmake)
ultra_env_probe_write("${CMAKE_BINARY_DIR}/ultra_env.json")

add_custom_target(ultra-env
  COMMAND ${CMAKE_COMMAND} -E cat "${CMAKE_BINARY_DIR}/ultra_env.json"
  COMMENT "dumping ultra env probe"
  VERBATIM
)
