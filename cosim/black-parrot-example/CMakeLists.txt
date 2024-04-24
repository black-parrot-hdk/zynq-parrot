cmake_minimum_required(VERSION 3.20 FATAL_ERROR)
project(ExampleProject)

# Set this to the path where Surelog's CMake config file is located
set(Surelog_DIR "/home/mysanoop/.local")

find_package(Surelog REQUIRED)

add_executable(example instrumentation/walker.cpp)
target_link_libraries(example surelog)
