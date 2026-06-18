FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

# Select bash as default shell to prevent errors in "/.singularity.d/actions/shell":
RUN true \
    && echo "dash dash/sh boolean false" | debconf-set-selections \
    && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash


# User and workdir settings:

USER root
WORKDIR /root


# Install system packages:

RUN set -eux && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y unminimize \
    && sed -i 's/apt-get upgrade$/apt-get upgrade -y/' `which unminimize` \
    && (echo y | unminimize) \
	&& apt-get install -y --no-install-recommends ca-certificates \
    && apt-get install -y locales && locale-gen en_US.UTF-8 \
    && apt-get install -y \
        less \
        rsync \
        wget curl \
        nano vim \
        bzip2 \
        aptitude \
        \
        perl \
        zsh \
        \
        screen tmux parallel mc tree ncdu \
        util-linux numactl \
        \
        git \
        build-essential autoconf cmake pkg-config gfortran \
        libedit-dev libncurses-dev openssl libssl-dev symlinks \
        debhelper dh-autoreconf help2man libarchive-dev \
        squashfs-tools \
        \
    && apt-get install -y --no-install-recommends gnuplot \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Install Nvidia visual profilers:

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        cuda-nsight-systems-12-8 cuda-nsight-12-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Copy provisioning script(s):

COPY provisioning/install-sw.sh /root/provisioning/


# Install LaTeX (for Juypter PDF export and direct use):

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y \
        texlive texlive-latex-extra texlive-extra-utils texlive-science \
        texlive-fonts-extra texlive-bibtex-extra texlive-pstricks latexmk \
        biber feynmf latexdiff dvipng texlive-xetex pdf2svg cm-super \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Install Julia:

COPY provisioning/install-sw-scripts/julia-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/julia/bin:/opt/julia-1.13/bin:/opt/julia-1.12/bin:/opt/julia-1.10/bin:$PATH" \
    MANPATH="/opt/julia/share/man:$MANPATH"

RUN true\
    && mkdir /opt/julia-local \
    && provisioning/install-sw.sh julia-bindist 1.10.11 /opt/julia-1.10 \
    && (cd /opt/julia-1.10 && ln -s ../julia-local local) \
    && (cd /opt/julia-1.10/bin && ln -s julia julia-1.10) \
    && provisioning/install-sw.sh julia-bindist 1.12.6 /opt/julia-1.12 \
    && (cd /opt/julia-1.12 && ln -s ../julia-local local) \
    && (cd /opt/julia-1.12/bin && ln -s julia julia-1.12) \
    && provisioning/install-sw.sh julia-bindist 1.13.0-rc1 /opt/julia-1.13 \
    && (cd /opt/julia-1.13 && ln -s ../julia-local local) \
    && (cd /opt/julia-1.13/bin && ln -s julia julia-1.13) \
    && (cd /opt && ln -s julia-1.12 julia)


# Install Pixi:

COPY provisioning/install-sw-scripts/pixi-* provisioning/install-sw-scripts/

RUN provisioning/install-sw.sh pixi current /opt/pixi

ENV \
    PIXI_HOME="/opt/pixi" \
    PIXI_GLOBALPRJ="/opt/pixi/global" \
    PIXI_GLOBALBIN="/opt/pixi/global/.pixi/envs/default/bin" \
    PATH="/opt/pixi/bin:/opt/pixi/global/.pixi/envs/default/bin:$PATH" \
    MANPATH="/opt/pixi/global/.pixi/envs/default/man:$MANPATH" \
    PYTHON="python3" \
    JUPYTER="jupyter"

# Install Python, Jupyter, etc.:

RUN cd "$PIXI_GLOBALPRJ" \
    && pixi add \
        python=3.12 \
        pip \
        matplotlib numpy numba \
        jupyterlab notebook nbformat nbconvert \
        jupyterlab_rise jupyter_contrib_nbextensions bash_kernel \
        jsonschema-with-format-nongpl webcolors \
        jupytext \
        click docopt pykwalify ruamel.yaml \
        mpi4py \
        pyjuliacall pyjuliapkg \
        voila ipympl \
    && pixi add --pypi \
        RISE \
        webio_jupyter_extension


# Install Node.js:

COPY provisioning/install-sw-scripts/nodejs-* provisioning/install-sw-scripts/

ENV \
    PATH="/opt/nodejs/bin:$PATH" \
    MANPATH="/opt/nodejs/share/man:$MANPATH"

RUN provisioning/install-sw.sh nodejs-bindist 24.16.0 /opt/nodejs


# Install Rust:

ENV \
    PATH="/opt/rust/toolchains/stable-x86_64-unknown-linux-gnu/bin:$PATH" \
    MANPATH="/opt/rust/toolchains/stable-x86_64-unknown-linux-gnu/share/man:$MANPATH"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    RUSTUP_HOME="/opt/rust" CARGO_HOME="/opt/rust" \
    sh -s -- -y --no-modify-path --profile default --default-toolchain stable


# Install Java:

# JavaCall.jl needs JAVA_HOME to locate libjvm.so:
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

RUN true \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:openjdk-r/ppa \
    && apt-get update \
    && apt-get install -y openjdk-11-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Install support for GUI applications:

RUN apt-get update && apt-get install -y \
        x11-xserver-utils mesa-utils \
        libglu1-mesa libegl-mesa0 \
        xdg-utils \
        xvfb \
        libxss-dev libxtst-dev libxkbfile-dev \
        fonts-inconsolata fonts-dejavu \
        zenity \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Install VirtualGL:

RUN apt-get update && apt-get install -y \
        libglu1-mesa libegl-mesa0 dbus-x11 \
    && wget \
        https://github.com/VirtualGL/virtualgl/releases/download/3.1.4/virtualgl_3.1.4_amd64.deb \
        https://github.com/TurboVNC/turbovnc/releases/download/3.3/turbovnc_3.3_amd64.deb \
    && dpkg -i virtualgl_3.1.4_amd64.deb turbovnc_3.3_amd64.deb \
    && rm virtualgl_3.1.4_amd64.deb turbovnc_3.3_amd64.deb \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Default profile environment settings:

ENV \
    LESSOPEN="||/usr/bin/lesspipe.sh %s"\
    LESSCLOSE=""


# Install additional packages:

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        htop nmon \
        nano vim \
        git-gui gitk \
        ncat netcat-openbsd \
        ncurses-term \
        parallel \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Final steps

CMD /bin/bash
