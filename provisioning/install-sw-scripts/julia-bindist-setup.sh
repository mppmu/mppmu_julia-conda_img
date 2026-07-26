# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2016: Oliver Schulz.


pkg_installed_check() {
    test -f "${INSTALL_PREFIX}/bin/julia"
}


pkg_install() {
    PACKAGE_VERSION_MAJOR=`echo "${PACKAGE_VERSION}" | cut -f 1,2 -d . | grep -o '[0-9.]*'`

    case "${ARCH}" in
        x86_64)  JULIA_ARCH="x64"     ;;
        aarch64) JULIA_ARCH="aarch64" ;;
        *)
            echo "ERROR: No Julia binary distribution for architecture \"${ARCH}\"." >&2
            exit 1
            ;;
    esac

    DOWNLOAD_URL="https://julialang-s3.julialang.org/bin/linux/${JULIA_ARCH}/${PACKAGE_VERSION_MAJOR}/julia-${PACKAGE_VERSION}-linux-${ARCH}.tar.gz"
    echo "INFO: Download URL: \"${DOWNLOAD_URL}\"." >&2

    mkdir -p "${INSTALL_PREFIX}"
    download "${DOWNLOAD_URL}" \
        | tar --strip-components=1 -x -z -f - -C "${INSTALL_PREFIX}"

    #JLVER=`"${INSTALL_PREFIX}/bin/julia" -e 'println("$(VERSION.major).$(VERSION.minor)")'`
    #mkdir -p "/buildworker/worker/package_linux64/build/usr/share/julia/stdlib"
    #ln -s "${INSTALL_PREFIX}/share/julia/stdlib/v${JLVER}" "/buildworker/worker/package_linux64/build/usr/share/julia/stdlib/v${JLVER}"
}


pkg_env_vars() {
cat <<-EOF
PATH="${INSTALL_PREFIX}/bin:\$PATH"
MANPATH="${INSTALL_PREFIX}/share/man:\$MANPATH"
export PATH MANPATH
EOF
}
