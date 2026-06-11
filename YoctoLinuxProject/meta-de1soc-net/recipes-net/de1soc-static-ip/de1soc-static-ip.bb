SUMMARY = "DE1-SoC static IP on end0 (systemd-networkd)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://20-wired-static.network"
S = "${WORKDIR}"

do_configure[noexec] = "1"
do_compile[noexec]   = "1"

do_install() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/20-wired-static.network \
        ${D}${sysconfdir}/systemd/network/20-wired-static.network
}

FILES:${PN} = "${sysconfdir}/systemd/network/20-wired-static.network"