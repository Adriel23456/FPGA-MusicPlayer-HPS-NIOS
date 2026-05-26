# CMakeLists.txt (root)
cmake_minimum_required(VERSION 3.10)
project(fpga-mem-test VERSION 1.0.0 LANGUAGES C)

include_directories(${CMAKE_SOURCE_DIR}/include)

add_executable(fpga_mem_test src/main.c)

target_link_libraries(fpga_mem_test m)

install(TARGETS fpga_mem_test DESTINATION bin)