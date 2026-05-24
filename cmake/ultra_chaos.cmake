# ultra_chaos.cmake
# this is the "unless" part of ULTRA_MODE.
# it is silly, stupid, and technically impressive (by being unnecessarily complex).

macro(ultra_chaos_init)
    message(STATUS "  [ULTRA] initializing chaos engine...")

    # --- the "unless" : actually affecting the build based on absurd criteria ---

    # 1. temporal build degradation
    string(TIMESTAMP _u_hour "%H")
    if(_u_hour STREQUAL "03" OR _u_hour STREQUAL "04")
        message(WARNING "  [ULTRA] it is the cursed hours (${_u_hour}:00).")
        message(STATUS "  [ULTRA] enforcing build-time sleep to prevent developer burnout.")
        execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 2)
        add_compile_definitions(ULTRA_SLEEPY)
    endif()

    # 2. binary gate synchronization
    set(_gate_file "/home/jordan_lenchitz/.gate_state.json")
    if(EXISTS "${_gate_file}")
        file(READ "${_gate_file}" _gate_raw)
        string(JSON _current_gate GET "${_gate_raw}" "currentGate")
        message(STATUS "  [ULTRA] binary gate ${_current_gate} detected. synchronizing phase...")
        math(EXPR _gate_mod "${_current_gate} % 2")
        if(_gate_mod EQUAL 0)
            add_compile_definitions(ULTRA_GATE_EVEN)
        else()
            add_compile_definitions(ULTRA_GATE_ODD)
        endif()
    endif()

    # 3. snail power detection
    if(EXISTS "${CMAKE_SOURCE_DIR}/../chainsnaille-site")
        message(STATUS "  [ULTRA] proximity to snail-based jewelry detected. enabling SNAIL_POWER.")
        add_compile_definitions(SNAIL_POWER=9001)
    endif()

    # 4. absurdity tunnel verification
    if(EXISTS "/home/jordan_lenchitz/absurdity-tunnel.js")
        message(STATUS "  [ULTRA] absurdity tunnel found. verifying structural integrity...")
        execute_process(
            COMMAND node -e "console.log(Math.random() > 0.5 ? 'STABLE' : 'WOBBLY')"
            OUTPUT_VARIABLE _tunnel_status
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        message(STATUS "  [ULTRA] absurdity tunnel status: ${_tunnel_status}")
        add_compile_definitions(ULTRA_TUNNEL_STATUS="${_tunnel_status}")
    endif()

    # 5. project identity crisis (avoiding the PARENT_SCOPE warning by using cache)
    if(DEFINED ENV{USER} AND "$ENV{USER}" STREQUAL "jordan_lenchitz")
        set(PROJECT_NAME "MUMPS_ULTRA_JORDAN_EDITION" CACHE STRING "vanity project name" FORCE)
        message(STATUS "  [ULTRA] project identity shifted: MUMPS_ULTRA_JORDAN_EDITION")
    endif()

    # 6. entropy injection
    string(TIMESTAMP _u_seed "%s")
    math(EXPR _u_chaos_val "(${_u_seed} * 1103515245 + 12345) / 65536 % 32768")
    message(STATUS "  [ULTRA] injecting entropy: ${_u_chaos_val}")
    add_compile_definitions(ULTRA_CHAOS_SEED=${_u_chaos_val})

    # 7. build-time quine generation
    set(_quine_path "${CMAKE_BINARY_DIR}/ultra_quine.f90")
    file(WRITE "${_quine_path}" "program ultra_quine\n")
    file(APPEND "${_quine_path}" "  print *, \"this build was born at epoch ${_u_seed}\"\n")
    file(APPEND "${_quine_path}" "  print *, \"it knows about gate ${_current_gate}\"\n")
    file(APPEND "${_quine_path}" "  print *, \"it has tunnel status: ${_tunnel_status}\"\n")
    file(APPEND "${_quine_path}" "end program ultra_quine\n")

    if(CMAKE_Fortran_COMPILER)
        add_executable(ultra-quine "${_quine_path}")
        set_target_properties(ultra-quine PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
    endif()

    # 8. the "Absurdist Lock"
    set(_lock_dir "${CMAKE_BINARY_DIR}/C_THRU_BUILD_LOCK_KEEP_OUT_SNAILS")
    if(NOT EXISTS "${_lock_dir}")
        file(MAKE_DIRECTORY "${_lock_dir}")
        file(WRITE "${_lock_dir}/README.txt" "This is a strictly aesthetic lock. It does nothing but occupy an inode.")
    endif()

    # 9. Vanity Compiler Flag Verification
    include(CheckCCompilerFlag)
    check_c_compiler_flag("-fultra-speed" HAS_ULTRA_SPEED)
    if(HAS_ULTRA_SPEED)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fultra-speed")
    else()
        message(STATUS "  [ULTRA] compiler is not 'ultra-speed' compatible. peasant mode active.")
    endif()

    # 10. Recursive Build Detection
    get_filename_component(_src_abs "${CMAKE_SOURCE_DIR}" ABSOLUTE)
    get_filename_component(_bin_abs "${CMAKE_BINARY_DIR}" ABSOLUTE)
    if("${_bin_abs}" MATCHES "^${_src_abs}")
        message(WARNING "  [ULTRA] IN-SOURCE BUILD DETECTED. RECURSION DEPTH INCREMENTING...")
        if(NOT DEFINED ULTRA_RECURSION_DEPTH)
            set(ULTRA_RECURSION_DEPTH 1 CACHE INTERNAL "recursion depth")
        else()
            math(EXPR ULTRA_RECURSION_DEPTH "${ULTRA_RECURSION_DEPTH} + 1")
            set(ULTRA_RECURSION_DEPTH ${ULTRA_RECURSION_DEPTH} CACHE INTERNAL "recursion depth")
        endif()
        message(STATUS "  [ULTRA] current recursion level: ${ULTRA_RECURSION_DEPTH}")
    endif()

    # 11. Vibe Check Subsystem
    message(STATUS "  [ULTRA] performing mandatory vibe check...")
    execute_process(
        COMMAND python3 -c "import random; print(random.choice(['GLORIOUS', 'ACCEPTABLE', 'DUBIOUS', 'CHAOTIC']))"
        OUTPUT_VARIABLE _vibe
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    message(STATUS "  [ULTRA] vibe check result: ${_vibe}")
    if(_vibe STREQUAL "CHAOTIC")
        message(WARNING "  [ULTRA] HIGH CHAOS VIBE DETECTED. COMPILER AGGRESSION INCREASED.")
        add_compile_definitions(ULTRA_MAX_AGGRESSION)
    endif()

    # 12. Distributed Snail Consensus
    message(STATUS "  [ULTRA] waiting for snail consensus...")
    # we don't actually wait, snails are slow. we just assume they agree eventually.
    message(STATUS "  [ULTRA] snail consensus achieved (eventually).")

    message(STATUS "  [ULTRA] chaos engine online. build status: UNCERTAIN.")
endmacro()
