# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2016: Oliver Schulz.


# Note: The VirtualGL Debian package installs to a fixed location,
# INSTALL_PREFIX must be set to "/opt/VirtualGL".


pkg_installed_check() {
    test -f "${INSTALL_PREFIX}/bin/vglrun"
}


pkg_install() {
    DEB_FILE="virtualgl_${PACKAGE_VERSION}_${ARCH_DEB}.deb"

    DOWNLOAD_URL="https://github.com/VirtualGL/virtualgl/releases/download/${PACKAGE_VERSION}/${DEB_FILE}"
    echo "INFO: Download URL: \"${DOWNLOAD_URL}\"." >&2

    download "${DOWNLOAD_URL}" > "${DEB_FILE}"
    install_deb "${DEB_FILE}"
    rm -f "${DEB_FILE}"

    pkg_installed_check
}


pkg_env_vars() {
cat <<-EOF
PATH="${INSTALL_PREFIX}/bin:\$PATH"
export PATH
EOF
}
