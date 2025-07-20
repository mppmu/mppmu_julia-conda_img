# This software is licensed under the MIT "Expat" License.
#
# Copyright (c) 2016: Oliver Schulz.


pkg_installed_check() {
    test -f "${INSTALL_PREFIX}/bin/pixi"
}


install_disable_pixi() {
# Function "remove_from_path" is a variation of a solution by Mark Booth,
# see https://unix.stackexchange.com/a/291611:

cat > "${1}/bin/disable-pixi.sh" <<-EOF
function remove_from_path {
    # Delete path by parts so we can never accidentally remove sub paths
    export PATH=\${PATH//":\$1:"/":"} # delete any instances in the middle
    export PATH=\${PATH/#"\$1:"/} # delete any instance at the beginning
    export PATH=\${PATH/%":\$1"/} # delete any instance in the at the end
}

(command -v pixi > /dev/null) && remove_from_path "${1}/bin" && remove_from_path "${1}/global/.pixi/envs/default/bin"
EOF
}


pkg_install() {
    export PIXI_HOME="${INSTALL_PREFIX}"
    export PIXI_NO_PATH_UPDATE="yes"

    curl -fsSL https://pixi.sh/install.sh | bash -s -- --yes
    cd "$PIXI_HOME"
    "${PIXI_HOME}/bin/pixi" config set default-channels '["conda-forge"]' --global
    mkdir "global" && cd global
    "${PIXI_HOME}/bin/pixi" init --channel conda-forge --channel bioconda .

    install_disable_pixi "${INSTALL_PREFIX}"
}


pkg_env_vars() {
cat <<-EOF
PATH="${INSTALL_PREFIX}/bin:\$PATH"
MANPATH="${INSTALL_PREFIX}/share/man:\$MANPATH"
EOF
}
