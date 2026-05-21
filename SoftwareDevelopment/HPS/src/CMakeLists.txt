# ==============================================================
# src/app/CMakeLists.txt
# ==============================================================
#include_directories(${CMAKE_SOURCE_DIR}/include)
#find_package(Threads REQUIRED)

# libmicrohttpd ships its own pkg-config; find it if available,
# otherwise fall back to linking by name.
#find_package(PkgConfig QUIET)
#if (PkgConfig_FOUND)
#    pkg_check_modules(MHD libmicrohttpd)
#endif()

#add_executable(robot_main
    # core
    main.c
    core/app_state.c
    core/thread_helpers.c
    # threads
    threads/sensor_thread.c
    threads/navigation_thread.c
    threads/map_thread.c
    # web: lifecycle + glue
    web/web_thread.c
    web/http_server.c
    web/router.c
    web/tls_bootstrap.c
    web/cookies.c
    web/form_parser.c
    # web: auth
    web/auth/auth_module.c
    web/auth/password_hash.c
    web/auth/user_store.c
    web/auth/session_store.c
    web/auth/sha256.c
    # web: handlers
    web/handlers/handler_static.c
    web/handlers/handler_auth.c
    web/handlers/handler_control.c
    web/handlers/handler_telemetry.c
    # audio
    threads/audio_thread.c
    web/handlers/handler_audio.c
    # config
    core/config.c
#)

#if (MHD_FOUND)
#    target_include_directories(robot_main PRIVATE ${MHD_INCLUDE_DIRS})
#    target_link_libraries    (robot_main ${MHD_LIBRARIES})
#else()
#    target_link_libraries    (robot_main microhttpd)
#endif()

#target_link_libraries(robot_main
#    ventilator led ultrasonic motor mpu6050 audio
#    gpio pwm sysfs i2c process
#    Threads::Threads m)

#install(TARGETS robot_main DESTINATION bin)