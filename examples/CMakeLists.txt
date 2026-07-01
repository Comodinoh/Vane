cmake_minimum_required(VERSION 3.30.4)

project(Vane-Example)

file(GLOB_RECURSE SRC src/*.cpp)
add_executable(${PROJECT_NAME} ${SRC})

#target_include_directories(${PROJECT_NAME} PRIVATE ../src)
target_link_libraries(${PROJECT_NAME} Vane-Source)
