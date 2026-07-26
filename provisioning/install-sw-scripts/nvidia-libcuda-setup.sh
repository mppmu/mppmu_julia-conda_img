# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2016: Oliver Schulz.


pkg_install() {
    # NVIDIA uses "uname -m" architecture naming (x86_64, aarch64):
    RUN_FILE="NVIDIA-Linux-${ARCH}-${PACKAGE_VERSION}.run"

    DOWNLOAD_URL="https://download.nvidia.com/XFree86/Linux-${ARCH}/${PACKAGE_VERSION}/${RUN_FILE}"
    echo "INFO: Download URL: \"${DOWNLOAD_URL}\"." >&2

    download "${DOWNLOAD_URL}" > "${RUN_FILE}"
    bash "${RUN_FILE}" --extract-only
    CURRDIR=`pwd`
    mkdir -p "${INSTALL_PREFIX}"
    cd "NVIDIA-Linux-${ARCH}-${PACKAGE_VERSION}"
    cp -a "libcuda.so.${PACKAGE_VERSION}" "${INSTALL_PREFIX}/"
    (cd "${INSTALL_PREFIX}" && ln -s "libcuda.so.${PACKAGE_VERSION}" "libcuda.so.1")
    (cd "${INSTALL_PREFIX}" && ln -s "libcuda.so.${PACKAGE_VERSION}" "libcuda.so")
}


pkg_env_vars() {
	true
}
