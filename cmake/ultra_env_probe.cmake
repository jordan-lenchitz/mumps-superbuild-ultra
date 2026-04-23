# ultra_env_probe.cmake
# writes a json snapshot of the configure-time environment to a file.
# useful for bug reports: "it works on my machine" -> "attach your ultra_env.json"
#
# usage from top-level CMakeLists.txt:
#   include(cmake/ultra_env_probe.cmake)
#   ultra_env_probe_write("${CMAKE_BINARY_DIR}/ultra_env.json")

function(ultra_env_probe_write _out_path)

  string(TIMESTAMP _t_iso "%Y-%m-%dT%H:%M:%SZ" UTC)
  string(TIMESTAMP _t_epoch "%s")

  # detect hostname portably
  cmake_host_system_information(RESULT _hostname QUERY HOSTNAME)
  cmake_host_system_information(RESULT _fqdn QUERY FQDN)
  cmake_host_system_information(RESULT _os_name QUERY OS_NAME)
  cmake_host_system_information(RESULT _os_release QUERY OS_RELEASE)
  cmake_host_system_information(RESULT _os_version QUERY OS_VERSION)
  cmake_host_system_information(RESULT _os_platform QUERY OS_PLATFORM)
  cmake_host_system_information(RESULT _proc_name QUERY PROCESSOR_NAME)
  cmake_host_system_information(RESULT _proc_desc QUERY PROCESSOR_DESCRIPTION)
  cmake_host_system_information(RESULT _n_logical QUERY NUMBER_OF_LOGICAL_CORES)
  cmake_host_system_information(RESULT _n_physical QUERY NUMBER_OF_PHYSICAL_CORES)
  cmake_host_system_information(RESULT _mem_total QUERY TOTAL_PHYSICAL_MEMORY)
  cmake_host_system_information(RESULT _mem_avail QUERY AVAILABLE_PHYSICAL_MEMORY)

  # collect relevant env vars (list, and null string if unset)
  set(_env_vars
    PATH CC CXX FC F77
    CMAKE_PREFIX_PATH CMAKE_BUILD_TYPE
    MKLROOT I_MPI_ROOT CONDA_PREFIX VIRTUAL_ENV
    LD_LIBRARY_PATH DYLD_LIBRARY_PATH
    FFLAGS CFLAGS LDFLAGS
  )
  set(_env_json "{}")
  foreach(_v IN LISTS _env_vars)
    if(DEFINED ENV{${_v}})
      string(REPLACE "\\" "\\\\" _val "$ENV{${_v}}")
      string(REPLACE "\"" "\\\"" _val "${_val}")
      string(JSON _env_json SET "${_env_json}" "${_v}" "\"${_val}\"")
    else()
      string(JSON _env_json SET "${_env_json}" "${_v}" "null")
    endif()
  endforeach()

  # mumps-specific option snapshot
  set(_mumps_json "{}")
  string(JSON _mumps_json SET "${_mumps_json}" "superbuild_version" "\"${PROJECT_VERSION}\"")
  string(JSON _mumps_json SET "${_mumps_json}" "upstream_version" "\"${MUMPS_UPSTREAM_VERSION}\"")
  string(JSON _mumps_json SET "${_mumps_json}" "parallel" "\"${MUMPS_parallel}\"")
  string(JSON _mumps_json SET "${_mumps_json}" "intsize64" "\"${MUMPS_intsize64}\"")
  string(JSON _mumps_json SET "${_mumps_json}" "scalapack" "\"${MUMPS_scalapack}\"")
  string(JSON _mumps_json SET "${_mumps_json}" "shared_libs" "\"${BUILD_SHARED_LIBS}\"")

  # compiler snapshot
  set(_comp_json "{}")
  string(JSON _comp_json SET "${_comp_json}" "fortran_id" "\"${CMAKE_Fortran_COMPILER_ID}\"")
  string(JSON _comp_json SET "${_comp_json}" "fortran_version" "\"${CMAKE_Fortran_COMPILER_VERSION}\"")
  string(JSON _comp_json SET "${_comp_json}" "fortran_path" "\"${CMAKE_Fortran_COMPILER}\"")
  string(JSON _comp_json SET "${_comp_json}" "c_id" "\"${CMAKE_C_COMPILER_ID}\"")
  string(JSON _comp_json SET "${_comp_json}" "c_version" "\"${CMAKE_C_COMPILER_VERSION}\"")
  string(JSON _comp_json SET "${_comp_json}" "c_path" "\"${CMAKE_C_COMPILER}\"")

  # host snapshot
  set(_host_json "{}")
  string(JSON _host_json SET "${_host_json}" "hostname" "\"${_hostname}\"")
  string(JSON _host_json SET "${_host_json}" "fqdn" "\"${_fqdn}\"")
  string(JSON _host_json SET "${_host_json}" "os_name" "\"${_os_name}\"")
  string(JSON _host_json SET "${_host_json}" "os_release" "\"${_os_release}\"")
  string(JSON _host_json SET "${_host_json}" "os_version" "\"${_os_version}\"")
  string(JSON _host_json SET "${_host_json}" "os_platform" "\"${_os_platform}\"")
  string(JSON _host_json SET "${_host_json}" "processor_name" "\"${_proc_name}\"")
  string(JSON _host_json SET "${_host_json}" "processor_desc" "\"${_proc_desc}\"")
  string(JSON _host_json SET "${_host_json}" "cores_logical" "${_n_logical}")
  string(JSON _host_json SET "${_host_json}" "cores_physical" "${_n_physical}")
  string(JSON _host_json SET "${_host_json}" "memory_total_mb" "${_mem_total}")
  string(JSON _host_json SET "${_host_json}" "memory_available_mb" "${_mem_avail}")

  # cmake snapshot
  set(_cmake_json "{}")
  string(JSON _cmake_json SET "${_cmake_json}" "version" "\"${CMAKE_VERSION}\"")
  string(JSON _cmake_json SET "${_cmake_json}" "generator" "\"${CMAKE_GENERATOR}\"")
  string(JSON _cmake_json SET "${_cmake_json}" "source_dir" "\"${CMAKE_SOURCE_DIR}\"")
  string(JSON _cmake_json SET "${_cmake_json}" "binary_dir" "\"${CMAKE_BINARY_DIR}\"")
  string(JSON _cmake_json SET "${_cmake_json}" "install_prefix" "\"${CMAKE_INSTALL_PREFIX}\"")
  string(JSON _cmake_json SET "${_cmake_json}" "build_type" "\"${CMAKE_BUILD_TYPE}\"")
  string(JSON _cmake_json SET "${_cmake_json}" "toolchain" "\"${CMAKE_TOOLCHAIN_FILE}\"")

  # assemble the top-level object
  set(_root "{}")
  string(JSON _root SET "${_root}" "schema_version" "1")
  string(JSON _root SET "${_root}" "timestamp_iso" "\"${_t_iso}\"")
  string(JSON _root SET "${_root}" "timestamp_epoch" "${_t_epoch}")
  string(JSON _root SET "${_root}" "fork" "\"jordan-lenchitz/mumps-superbuild-ultra\"")
  string(JSON _root SET "${_root}" "host" "${_host_json}")
  string(JSON _root SET "${_root}" "cmake" "${_cmake_json}")
  string(JSON _root SET "${_root}" "compilers" "${_comp_json}")
  string(JSON _root SET "${_root}" "mumps" "${_mumps_json}")
  string(JSON _root SET "${_root}" "environment" "${_env_json}")

  file(WRITE "${_out_path}" "${_root}\n")
  message(STATUS "ultra env probe written to ${_out_path}")

endfunction()
