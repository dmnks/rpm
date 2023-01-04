FROM registry.fedoraproject.org/fedora:37
MAINTAINER rpm-maint@lists.rpm.org

RUN echo -e "\
deltarpm=0\n\
install_weak_deps=0\n\
tsflags=nodocs" >> /etc/dnf/dnf.conf
RUN sed -i -e "s:^enabled=.$:enabled=0:g" /etc/yum.repos.d/*openh264.repo
RUN rpm -e fedora-repos-modular
RUN dnf -y update
RUN dnf -y install \
    autoconf \
    cmake \
    gettext-devel \
    debugedit \
    doxygen \
    make \
    gcc \
    git-core \
    glibc-gconv-extra \
    zlib-devel \
    bzip2-devel \
    xz-devel \
    libzstd-devel \
    elfutils-libelf-devel \
    elfutils-devel \
    openssl-devel \
    libgcrypt-devel \
    rpm-sequoia-devel \
    file-devel \
    popt-devel \
    libarchive-devel \
    sqlite-devel \
    libselinux-devel \
    ima-evm-utils-devel \
    libcap-devel \
    libacl-devel \
    audit-libs-devel \
    lua-devel readline-devel \
    python3-devel \
    dbus-devel \
    fakechroot which \
    elfutils binutils \
    findutils sed grep gawk diffutils file patch \
    tar unzip gzip bzip2 cpio xz \
    pkgconfig \
    /usr/bin/gdb-add-index \
    dwz \
    fsverity-utils fsverity-utils-devel \
    pandoc
RUN dnf -y install --releasever=37 --installroot=/runtime \
    audit \
    bash \
    binutils \
    bzip2 \
    coreutils \
    cpio \
    curl \
    debugedit \
    diffutils \
    elfutils-libelf \
    elfutils-libs \
    file \
    file-libs \
    findutils \
    gawk \
    gcc \
    gdb-headless \
    gdb-minimal \
    glibc \
    gpg \
    grep \
    gzip \
    ima-evm-utils \
    libacl \
    libarchive \
    libcap \
    libfsverity \
    libgcc \
    libgomp \
    libzstd \
    lua-libs \
    make \
    openssl-libs \
    patch \
    pkgconf-pkg-config \
    python3 \
    rpm-sequoia \
    sed \
    sqlite-libs \
    tar \
    unzip \
    xz \
    xz-libs \
    zlib \
    zstd \
    && dnf clean all

WORKDIR /source
