# ultra_chaos_moar.cmake
# the abyss stares back.

macro(ultra_chaos_moar_init)
    message(STATUS "  [ULTRA] expanding chaos horizon...")

    # 13. System Load Emulation
    message(STATUS "  [ULTRA] emulating heavy system load...")
    execute_process(
        COMMAND python3 -c "import time; [time.sleep(0.01) for _ in range(100)]"
    )

    # 14. Phase of the Moon Subsystem
    # Because why shouldn't the build depend on lunar cycles?
    message(STATUS "  [ULTRA] calculating lunar phase offset...")
    string(TIMESTAMP _lunar_seed "%d")
    math(EXPR _lunar_phase "(${_lunar_seed} * 11) % 8")
    set(_moon_phases "NEW;WAXING_CRESCENT;FIRST_QUARTER;WAXING_GIBBOUS;FULL;WANING_GIBBOUS;LAST_QUARTER;WANING_CRESCENT")
    list(GET _moon_phases ${_lunar_phase} _current_moon_phase)
    message(STATUS "  [ULTRA] lunar phase detected: ${_current_moon_phase}")
    add_compile_definitions(ULTRA_LUNAR_PHASE_${_current_moon_phase})

    # 15. The 100-File Dummy Library
    message(STATUS "  [ULTRA] generating 100-file dummy library to increase inode usage...")
    set(_dummy_dir "${CMAKE_BINARY_DIR}/ultra_dummy_lib")
    file(MAKE_DIRECTORY "${_dummy_dir}")
    set(_dummy_sources "")
    foreach(i RANGE 1 100)
        set(_src "${_dummy_dir}/dummy_${i}.c")
        file(WRITE "${_src}" "int dummy_func_${i}() { return ${i}; }\n")
        list(APPEND _dummy_sources "${_src}")
    endforeach()
    add_library(ultra_dummy STATIC ${_dummy_sources})
    set_target_properties(ultra_dummy PROPERTIES EXCLUDE_FROM_ALL TRUE)

    # 16. Fibonacci Delay Sequence
    # Every time this is configured, we delay by the next Fibonacci number of milliseconds.
    if(NOT DEFINED ULTRA_FIB_A)
        set(ULTRA_FIB_A 0 CACHE INTERNAL "fib a")
        set(ULTRA_FIB_B 1 CACHE INTERNAL "fib b")
    else()
        math(EXPR ULTRA_FIB_NEXT "${ULTRA_FIB_A} + ${ULTRA_FIB_B}")
        set(ULTRA_FIB_A ${ULTRA_FIB_B} CACHE INTERNAL "fib a")
        set(ULTRA_FIB_B ${ULTRA_FIB_NEXT} CACHE INTERNAL "fib b")
        message(STATUS "  [ULTRA] Fibonacci delay sequence: sleeping for ${ULTRA_FIB_NEXT} milliseconds...")
        execute_process(COMMAND python3 -c "import time; time.sleep(${ULTRA_FIB_NEXT} / 1000.0)")
    endif()

    # 17. Extreme Environment Variable Verification
    # Asserting dominance over the PATH
    message(STATUS "  [ULTRA] asserting dominance over PATH...")
    set(ENV{ULTRA_PATH_DOMINANCE} "TRUE")

    # 18. Compile-time Shakespeare Injection
    message(STATUS "  [ULTRA] injecting compile-time Shakespeare...")
    set(_shake_path "${CMAKE_BINARY_DIR}/shakespeare.h")
    file(WRITE "${_shake_path}" "#define HAMLET \"To be, or not to be, that is the question:\"\n")
    include_directories("${CMAKE_BINARY_DIR}")

    # 19. The "Ghost of Fortran 77" Compile Flag
    # Add a flag that doesn't do anything but sounds spooky
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-form-but-spiritually-fixed")

    # 20. Overengineered Random String Generator Macro
    macro(generate_random_string _out_var _length)
        set(_chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        string(LENGTH "${_chars}" _num_chars)
        set(${_out_var} "")
        foreach(i RANGE 1 ${_length})
            string(TIMESTAMP _seed "%S")
            math(EXPR _idx "(${_seed} * ${i}) % ${_num_chars}")
            string(SUBSTRING "${_chars}" ${_idx} 1 _char)
            string(APPEND ${_out_var} "${_char}")
        endforeach()
    endmacro()

    generate_random_string(_my_random_string 16)
    message(STATUS "  [ULTRA] random compile-time token generated: ${_my_random_string}")

    # 21. Recursive CMake Inclusion Test (Safeguarded)
    # This just includes a file that does nothing, to inflate configure time
    set(_recursive_test "${CMAKE_BINARY_DIR}/ultra_recursive.cmake")
    file(WRITE "${_recursive_test}" "message(DEBUG \"  [ULTRA] recursive include OK\")\n")
    include("${_recursive_test}")

    # 22. Excessive Logging
    foreach(i RANGE 1 50)
        message(DEBUG "  [ULTRA] excessive log line ${i} / 50")
    endforeach()

    message(STATUS "  [ULTRA] chaos horizon successfully expanded.")
endmacro()
