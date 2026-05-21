# ==============================================================
# CMakeLists.txt  (root)
# ==============================================================
#cmake_minimum_required(VERSION 3.10)
#project(librobot VERSION 6.0.1 LANGUAGES C)

# ── Hardware: low-level utilities ─────────────────────────────
#add_subdirectory(lib/hardware/sysfs)
#add_subdirectory(lib/hardware/gpio)
#add_subdirectory(lib/hardware/i2c)
#add_subdirectory(lib/hardware/process)
#add_subdirectory(lib/hardware/pwm)

# ── Hardware: component drivers ───────────────────────────────
#add_subdirectory(lib/hardware/ventilator)
#add_subdirectory(lib/hardware/led)
#add_subdirectory(lib/hardware/ultrasonic)
#add_subdirectory(lib/hardware/motor)
#add_subdirectory(lib/hardware/mpu6050)
#add_subdirectory(lib/hardware/audio)

# ── Applications ──────────────────────────────────────────────
#add_subdirectory(src/test)
#add_subdirectory(src/app)

# ── Static web assets → /usr/share/robot/www ─────────────────
#install(DIRECTORY www/ DESTINATION share/robot/www)

# ── Packaging ────────────────────────────────────────────────
#set(CPACK_SOURCE_GENERATOR "TGZ")
#set(CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${PROJECT_VERSION}")
#set(CPACK_SOURCE_IGNORE_FILES "/build/;${CPACK_SOURCE_IGNORE_FILES}")
#include(CPack)
