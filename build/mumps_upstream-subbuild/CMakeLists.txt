# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.28.3)

# Reject any attempt to use a toolchain file. We must not use one because
# we could be downloading it here. If the CMAKE_TOOLCHAIN_FILE environment
# variable is set, the cache variable will have been initialized from it.
unset(CMAKE_TOOLCHAIN_FILE CACHE)
unset(ENV{CMAKE_TOOLCHAIN_FILE})

# We name the project and the target for the ExternalProject_Add() call
# to something that will highlight to the user what we are working on if
# something goes wrong and an error message is produced.

project(mumps_upstream-populate NONE)



include(ExternalProject)
ExternalProject_Add(mumps_upstream-populate
                     "URL" "https://mumps-solver.org/MUMPS_5.8.2.tar.gz" "URL_HASH" "SHA256=eb515aa688e6dbab414bb6e889ff4c8b23f1691a843c68da5230a33ac4db7039"
                    SOURCE_DIR          "/root/mumps-superbuild-ultra/build/mumps_upstream-src"
                    BINARY_DIR          "/root/mumps-superbuild-ultra/build/mumps_upstream-build"
                    CONFIGURE_COMMAND   ""
                    BUILD_COMMAND       ""
                    INSTALL_COMMAND     ""
                    TEST_COMMAND        ""
                    USES_TERMINAL_DOWNLOAD  YES
                    USES_TERMINAL_UPDATE    YES
                    USES_TERMINAL_PATCH     YES
)


