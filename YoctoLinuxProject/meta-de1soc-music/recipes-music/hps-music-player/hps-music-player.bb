SUMMARY = "HPS music player daemon + bundled music"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://hps_music_player \
    file://hps_music_player.service \
    file://music \
"
S = "${WORKDIR}"

# Prebuilt binary (built with the Yocto SDK) -> nothing to compile here.
do_configure[noexec] = "1"
do_compile[noexec]   = "1"

inherit systemd
SYSTEMD_SERVICE:${PN} = "hps_music_player.service"
SYSTEMD_AUTO_ENABLE   = "enable"

do_install() {
    # Binary -> /usr/bin
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/hps_music_player ${D}${bindir}/hps_music_player

    # Music -> /mnt/music (created here). Copy every file from the music/
    # source dir; new songs are picked up automatically (no per-file edits).
    install -d ${D}/mnt/music
    install -m 0644 ${WORKDIR}/music/*.wav ${D}/mnt/music/

    # systemd unit
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/hps_music_player.service \
        ${D}${systemd_system_unitdir}/hps_music_player.service
}

FILES:${PN} += " \
    ${bindir}/hps_music_player \
    /mnt/music \
    ${systemd_system_unitdir}/hps_music_player.service \
"

# Prebuilt artifact: skip QA that doesn't apply (mirrors your RoboVac recipe).
INSANE_SKIP:${PN} += "already-stripped ldflags"
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_SYSROOT_STRIP = "1"