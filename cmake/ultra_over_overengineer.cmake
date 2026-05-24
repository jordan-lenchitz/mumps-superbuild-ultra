# ultra_over_overengineer.cmake
# We heard you like overengineering, so we overengineered your overengineering.

macro(ultra_over_overengineer_init)
    message(STATUS "  [ULTRA] initiating hyper-dimensional overengineering sequence...")

    # 23. The 1000-Target Dependency Chain
    # Creates a chain of 1000 custom targets, each depending on the previous one.
    message(STATUS "  [ULTRA] forging the Chain of a Thousand Targets...")
    set(_prev_target "ultra_chain_0")
    add_custom_target(${_prev_target} COMMAND ${CMAKE_COMMAND} -E echo "Chain start")
    foreach(i RANGE 1 1000)
        set(_curr_target "ultra_chain_${i}")
        add_custom_target(${_curr_target} COMMAND ${CMAKE_COMMAND} -E true)
        add_dependencies(${_curr_target} ${_prev_target})
        set(_prev_target ${_curr_target})
    endforeach()
    # Tie the end of the chain to something real so it might actually build
    add_custom_target(ultra_chain_end ALL DEPENDS ${_prev_target})

    # 24. Procedural CMake Generation
    # Generates a CMake file that generates a CMake file that generates a header.
    message(STATUS "  [ULTRA] initiating procedural meta-generation...")
    set(_meta_dir "${CMAKE_BINARY_DIR}/ultra_meta")
    file(MAKE_DIRECTORY "${_meta_dir}")
    
    set(_gen_1 "${_meta_dir}/gen_1.cmake")
    set(_gen_2 "${_meta_dir}/gen_2.cmake")
    set(_out_hdr "${_meta_dir}/ultra_procedural.h")

    file(WRITE "${_gen_1}" "file(WRITE \"${_gen_2}\" \"file(WRITE \\\"${_out_hdr}\\\" \\\"#define ULTRA_PROCEDURAL 1\\\\n\\\")\\n\")\n")
    execute_process(COMMAND ${CMAKE_COMMAND} -P "${_gen_1}")
    execute_process(COMMAND ${CMAKE_COMMAND} -P "${_gen_2}")

    # 25. The "Enterprise" Variable Namespace
    # Prefixing variables with 'ENTERPRISE_SYNERGY_' to maximize business value.
    message(STATUS "  [ULTRA] aligning synergies with core competencies...")
    set(ENTERPRISE_SYNERGY_MAX_RETRIES 3)
    set(ENTERPRISE_SYNERGY_LEVERAGE_RATIO 1.5)
    set(ENTERPRISE_SYNERGY_PARADIGM_SHIFT "PENDING")

    # 26. Useless Mathematical Computations at Configure Time
    # Calculating an approximation of Pi using a slow method just to waste time.
    message(STATUS "  [ULTRA] computing Pi the hard way...")
    set(_pi_approx 3)
    set(_sign 1)
    # CMake math is integer only, so we simulate decimals poorly or just do something else dumb.
    # Let's calculate the sum of the first 1000 integers instead.
    set(_sum 0)
    foreach(i RANGE 1 1000)
        math(EXPR _sum "${_sum} + ${i}")
    endforeach()
    message(STATUS "  [ULTRA] sum of 1 to 1000 is ${_sum}. useful.")

    # 27. The Build Directory Labyrinth
    # Creates a deep, pointless directory structure.
    message(STATUS "  [ULTRA] constructing the labyrinth...")
    set(_lab_dir "${CMAKE_BINARY_DIR}/labyrinth")
    set(_current_path "${_lab_dir}")
    foreach(i RANGE 1 50)
        set(_current_path "${_current_path}/level_${i}")
    endforeach()
    file(MAKE_DIRECTORY "${_current_path}")
    file(WRITE "${_current_path}/minotaur.txt" "moo.")

    message(STATUS "  [ULTRA] hyper-dimensional sequence complete. god speed.")
endmacro()
