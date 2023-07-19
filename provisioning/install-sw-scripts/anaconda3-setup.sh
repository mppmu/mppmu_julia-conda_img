# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2016: Oliver Schulz.


pkg_installed_check() {
    test -f "${INSTALL_PREFIX}/bin/conda"
}


install_disable_conda() {
# Function "remove_from_path" is a variation of a solution by Mark Booth,
# see https://unix.stackexchange.com/a/291611:

cat > "${1}/bin/disable-conda.sh" <<-EOF
function remove_from_path {
    # Delete path by parts so we can never accidentally remove sub paths
    export PATH=\${PATH//":\$1:"/":"} # delete any instances in the middle
    export PATH=\${PATH/#"\$1:"/} # delete any instance at the beginning
    export PATH=\${PATH/%":\$1"/} # delete any instance in the at the end
}

(command -v conda > /dev/null) && remove_from_path "${1}/bin" && remove_from_path "${1}/condabin"
EOF
}


pkg_install() {
    DOWNLOAD_URL="https://repo.continuum.io/archive/Anaconda3-${PACKAGE_VERSION}-Linux-x86_64.sh"
    echo "INFO: Download URL: \"${DOWNLOAD_URL}\"." >&2

    download "${DOWNLOAD_URL}" > anaconda-installer.sh
    bash ./anaconda-installer.sh -b -p "${INSTALL_PREFIX}"

    conda clean -y --tarballs

    mkdir "${INSTALL_PREFIX}/devbin"
    mv "${INSTALL_PREFIX}/bin"/*-config "${INSTALL_PREFIX}/devbin"

    # Install mamba via micromamba since conda solver takes ages or fails to do it:
    wget -qO- https://anaconda.org/conda-forge/micromamba/1.4.9/download/linux-64/micromamba-1.4.9-0.tar.bz2 | tar -xvj bin/micromamba
    bin/micromamba -r "${INSTALL_PREFIX}" install -y mamba -n base -c conda-forge

    install_disable_conda "${INSTALL_PREFIX}"
}


pkg_env_vars() {
cat <<-EOF
PATH="${INSTALL_PREFIX}/bin:\$PATH"
MANPATH="${INSTALL_PREFIX}/share/man:\$MANPATH"
EOF
}
