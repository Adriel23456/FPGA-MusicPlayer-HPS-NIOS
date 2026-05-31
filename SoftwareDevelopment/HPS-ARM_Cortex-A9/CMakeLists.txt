cmake_minimum_required(VERSION 3.10)

project(fpga-mem-test VERSION 1.0.0 LANGUAGES C)

add_executable(fpga_mem_test
    src/main.c
    src/fpga_mem.c
    src/hps_fpga_comm.c
    src/hps_audio_streamer.c
    src/wav_reader.c
)

target_include_directories(fpga_mem_test PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/../common/include
)

# target_compile_definitions(fpga_mem_test PRIVATE
#     USE_FAKE_SHARED_MEM
# )

target_compile_definitions(fpga_mem_test PRIVATE
    USE_FAKE_SHARED_MEM
)

target_link_libraries(fpga_mem_test m)

install(TARGETS fpga_mem_test DESTINATION bin)