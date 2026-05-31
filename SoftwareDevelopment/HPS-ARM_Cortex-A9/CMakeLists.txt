cmake_minimum_required(VERSION 3.10)

project(hps-music-player VERSION 1.0.0 LANGUAGES C)

set(HPS_COMMON_SOURCES
    src/fpga_mem.c
    src/hps_fpga_comm.c
    src/hps_audio_streamer.c
    src/wav_reader.c
)

set(HPS_INCLUDE_DIRS
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/../common/include
)

add_executable(hps_music_player
    src/main.c
    ${HPS_COMMON_SOURCES}
)

target_include_directories(hps_music_player PRIVATE ${HPS_INCLUDE_DIRS})
target_link_libraries(hps_music_player m)

add_executable(hps_music_player_test
    src/main_test.c
    ${HPS_COMMON_SOURCES}
)

target_include_directories(hps_music_player_test PRIVATE ${HPS_INCLUDE_DIRS})
target_compile_definitions(hps_music_player_test PRIVATE
    USE_FAKE_SHARED_MEM
)
target_link_libraries(hps_music_player_test m)

install(TARGETS hps_music_player DESTINATION bin)
