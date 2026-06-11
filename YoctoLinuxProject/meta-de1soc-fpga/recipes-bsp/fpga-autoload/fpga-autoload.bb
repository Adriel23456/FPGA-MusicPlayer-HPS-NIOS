SUMMARY = "Auto-load FPGA fabric (Nios program embedded) at boot via DT overlay"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://soc_system.rbf \
    file://fpga-load.dtbo \
    file://fpga-load.service \
"
S = "${WORKDIR}"

# Prebuilt artifacts -> nothing to compile.
do_configure[noexec] = "1"
do_compile[noexec]   = "1"

inherit systemd
SYSTEMD_SERVICE:${PN} = "fpga-load.service"
SYSTEMD_AUTO_ENABLE   = "enable"

do_install() {
    # FPGA bitstream + overlay -> /lib/firmware
    install -d ${D}${nonarch_base_libdir}/firmware
    install -m 0644 ${WORKDIR}/soc_system.rbf  ${D}${nonarch_base_libdir}/firmware/soc_system.rbf
    install -m 0644 ${WORKDIR}/fpga-load.dtbo  ${D}${nonarch_base_libdir}/firmware/fpga-load.dtbo

    # systemd unit
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/fpga-load.service \
        ${D}${systemd_system_unitdir}/fpga-load.service
}

FILES:${PN} += " \
    ${nonarch_base_libdir}/firmware/soc_system.rbf \
    ${nonarch_base_libdir}/firmware/fpga-load.dtbo \
    ${systemd_system_unitdir}/fpga-load.service \
"

# Prebuilt binary bitstream: skip QA that doesn't apply.
INSANE_SKIP:${PN} += "arch already-stripped"
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_SYSROOT_STRIP = "1"