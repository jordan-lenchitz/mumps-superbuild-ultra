# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/root/mumps-superbuild-ultra/build/mumps_upstream-src"
  "/root/mumps-superbuild-ultra/build/mumps_upstream-build"
  "/root/mumps-superbuild-ultra/build/mumps_upstream-subbuild/mumps_upstream-populate-prefix"
  "/root/mumps-superbuild-ultra/build/mumps_upstream-subbuild/mumps_upstream-populate-prefix/tmp"
  "/root/mumps-superbuild-ultra/build/mumps_upstream-subbuild/mumps_upstream-populate-prefix/src/mumps_upstream-populate-stamp"
  "/root/mumps-superbuild-ultra/build/mumps_upstream-subbuild/mumps_upstream-populate-prefix/src"
  "/root/mumps-superbuild-ultra/build/mumps_upstream-subbuild/mumps_upstream-populate-prefix/src/mumps_upstream-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/root/mumps-superbuild-ultra/build/mumps_upstream-subbuild/mumps_upstream-populate-prefix/src/mumps_upstream-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/root/mumps-superbuild-ultra/build/mumps_upstream-subbuild/mumps_upstream-populate-prefix/src/mumps_upstream-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
