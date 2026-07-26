FROM nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04

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
# Note: Nsight Eclipse Edition (cuda-nsight) is only available for x86_64.

RUN set -eux && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y cuda-nsight-systems-13-0 \
    && if [ "`dpkg --print-architecture`" = "amd64" ] ; then \
        apt-get install -y cuda-nsight-13-0 ; \
    fi \
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


# Install Java:

# JavaCall.jl needs JAVA_HOME to locate libjvm.so. OpenJDK installs into an
# architecture-dependent directory, so provide an arch-independent symlink:
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk"

RUN true \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:openjdk-r/ppa \
    && apt-get update \
    && apt-get install -y openjdk-11-jdk \
    && ln -s "java-11-openjdk-`dpkg --print-architecture`" "${JAVA_HOME}" \
    && test -f "${JAVA_HOME}/lib/server/libjvm.so" \
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


# Install VirtualGL and TurboVNC:

COPY provisioning/install-sw-scripts/virtualgl-* provisioning/install-sw-scripts/turbovnc-* provisioning/install-sw-scripts/

RUN apt-get update && apt-get install -y \
        libglu1-mesa libegl-mesa0 dbus-x11 \
    && provisioning/install-sw.sh virtualgl-bindist 3.1.4 /opt/VirtualGL \
    && provisioning/install-sw.sh turbovnc-bindist 3.3 /opt/TurboVNC \
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
