# ultra_yottadb.cmake
# YottaDB-inspired "Real M" integration for the ultimate MUMPS experience.

macro(ultra_yottadb_init)
    message(STATUS "  [ULTRA] scanning for YottaDB / GT.M environments...")

    if(DEFINED ENV{ydb_dist} OR DEFINED ENV{gtm_dist})
        set(ULTRA_HAS_REAL_M ON)
        message(STATUS "  [ULTRA] !!! REAL MUMPS (1966) DETECTED !!!")
        message(STATUS "  [ULTRA] found ydb_dist at: $ENV{ydb_dist}")
        add_compile_definitions(ULTRA_REAL_M_ACTIVE)
    else()
        set(ULTRA_HAS_REAL_M OFF)
        message(STATUS "  [ULTRA] no YottaDB found. initiating 'YottaDB-on-Budget' emulation...")
        message(STATUS "  [ULTRA] (to use real YottaDB, set ydb_dist environment variable)")
    endif()

    # 28. The Global Variable Emulation Layer
    # Translating CMake variables into "Globals" (^CACHE, ^BUILD, ^SNAIL)
    set(ULTRA_M_GLOBAL_CACHE "^CMAKE_CACHE")
    message(STATUS "  [ULTRA] mounting global: ${ULTRA_M_GLOBAL_CACHE}")

    # 29. Routine Registration
    # Automatically "compiling" .mumps files in the root into the "engine"
    file(GLOB _m_routines "${CMAKE_SOURCE_DIR}/*.mumps")
    foreach(_routine ${_m_routines})
        get_filename_component(_name ${_routine} NAME_WE)
        message(STATUS "  [ULTRA] registered M routine: ${_name}")
    endforeach()

    # 30. The "MUMPS Language" Build Step
    # Using our custom Ultra MUMPS interpreter to run the engine.
    find_package(Python3 REQUIRED)
    add_custom_target(run-mumps-engine
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/scripts/mumps_interpreter.py ${CMAKE_SOURCE_DIR}/ultra_mumps_engine.mumps
        COMMENT "Executing the Ultra Chaos MUMPS Engine via Python-M Bridge"
        VERBATIM
    )

    add_custom_target(run-real-m
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/scripts/mumps_interpreter.py ${CMAKE_SOURCE_DIR}/real_m.mumps
        COMMENT "Running Real M (1966) Routine"
        VERBATIM
    )

    add_custom_target(m-shell
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/scripts/mumps_interpreter.py
        USES_TERMINAL
        COMMENT "Entering Ultra Chaos MUMPS Shell"
    )

    # 31. YottaDB "Direct Connect" Stub
    # A fake library that pretends to be the YottaDB API
    set(_ydb_stub "${CMAKE_BINARY_DIR}/ydb_stub.c")
    file(WRITE "${_ydb_stub}" "
#include <stdio.h>
void ydb_init() { printf(\"[ULTRA] YottaDB (Simulated) Initialized\\n\"); }
int ydb_set_s(char* var, char* val) { printf(\"[ULTRA] SET %s=%s\\n\", var, val); return 0; }
char* ydb_get_s(char* var) { return \"CHAOS\"; }
")
    add_library(ydb_mock STATIC "${_ydb_stub}")
    set_target_properties(ydb_mock PROPERTIES EXCLUDE_FROM_ALL TRUE)

    # 32. The "No, the OTHER Mumps" Check
    # This target checks if the user is confused.
    add_custom_target(which-mumps
        COMMAND ${CMAKE_COMMAND} -E echo "Checking for MUMPS (1996)... FOUND (this build)"
        COMMAND ${CMAKE_COMMAND} -E echo "Checking for MUMPS (1966)... ${ULTRA_HAS_REAL_M_STR}"
        COMMAND ${CMAKE_COMMAND} -E echo "Conclusion: Why not both?"
    )
    if(ULTRA_HAS_REAL_M)
        set(ULTRA_HAS_REAL_M_STR "FOUND (YottaDB)")
    else()
        set(ULTRA_HAS_REAL_M_STR "NOT FOUND (using emulation)")
    endif()

    # 33. The "MUMPS Solver" -> "MUMPS Language" Bridge
    # Injecting solver stats into M-style output
    message(STATUS "  [ULTRA] bridging solver metrics to M globals...")
    message(STATUS "  [ULTRA] ^MUMPS(\"VERSION\") = \"${PROJECT_VERSION}\"")
    message(STATUS "  [ULTRA] ^MUMPS(\"FLAVOR\") = \"ULTRA\"")

    # 34. Procedural M-Code Generation
    # Generating a .m file based on the build configuration
    set(_m_config_file "${CMAKE_BINARY_DIR}/build_config.m")
    file(WRITE "${_m_config_file}" "BUILDCONFIG ;\n")
    file(APPEND "${_m_config_file}" " S ^BUILD(\"PLATFORM\")=\"${CMAKE_SYSTEM_NAME}\"\n")
    file(APPEND "${_m_config_file}" " S ^BUILD(\"COMPILER\")=\"${CMAKE_C_COMPILER_ID}\"\n")
    file(APPEND "${_m_config_file}" " S ^BUILD(\"TIMESTAMP\")=\"${_u_epoch}\"\n")
    file(APPEND "${_m_config_file}" " W \"MUMPS Build Configuration Loaded\",!\n")
    file(APPEND "${_m_config_file}" " Q\n")

    message(STATUS "  [ULTRA] generated M config: ${_m_config_file}")

endmacro()

