# CMakeLists.txt (root)
cmake_minimum_required(VERSION 3.10)
project(hps-music-player VERSION 1.0.0 LANGUAGES C)

# Project headers + the shared contract header (same file the Nios includes).
# Adjust the common path if your tree differs.
include_directories(
    ${CMAKE_SOURCE_DIR}/include
)

add_executable(hps_music_player
    src/main.c
    src/fpga_mem.c
    src/hps_fpga_comm.c
    src/hps_audio_streamer.c
    src/wav_reader.c
)

# _DEFAULT_SOURCE for usleep/dirent; warnings on.
target_compile_definitions(hps_music_player PRIVATE _DEFAULT_SOURCE)
target_compile_options(hps_music_player PRIVATE -O2 -Wall)

install(TARGETS hps_music_player DESTINATION bin)