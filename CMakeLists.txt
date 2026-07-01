cmake_minimum_required(VERSION 3.30.5)

project(Vane CXX)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED On)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(VANE_VULKAN_VERSION 1.3.296.0)
set(OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../bin/${CMAKE_BUILD_TYPE}/${CMAKE_SYSTEM_NAME}/${CMAKE_ARCHITECTURE}/")

option(VANE_BUILD_EXAMPLES "Build examples" ON)
option(VANE_PROFILING "Enable profiler" ON) 
option(VANE_FORCE_PROFILING "Force the use of the profiler regardless of build type" OFF)
option(VANE_BUILD_DISTRIBUTABLE "Build Vane as a distributable" OFF)
option(VANE_BUILD_VULKAN "Build with Vulkan support" OFF)

add_subdirectory(platform)
add_subdirectory(src)
add_subdirectory(lib)

target_link_libraries(Vane-Platform INTERFACE Vane-Vendor)
target_link_libraries(Vane-Source PUBLIC Vane-Platform)

if(MSVC)
  target_compile_options(Vane-Source PRIVATE /W4 /Wall /sdl /external:anglebrackets /external:W2 /fsanitizer=address)
else()
  target_compile_options(Vane-Source PRIVATE -Wall -Wextra -Wpedantic )
endif()

if(VANE_BUILD_EXAMPLES)
    add_subdirectory(test)
endif()
