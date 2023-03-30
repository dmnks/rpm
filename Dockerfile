FROM registry.fedoraproject.org/fedora:37
MAINTAINER rpm-maint@lists.rpm.org

RUN echo -e "\
deltarpm=0\n\
install_weak_deps=0\n\
tsflags=nodocs" >> /etc/dnf/dnf.conf
RUN sed -i -e "s:^enabled=.$:enabled=0:g" /etc/yum.repos.d/*openh264.repo
RUN rpm -e fedora-repos-modular

RUN dnf -y install \
    audit \
    audit-libs-devel \
    autoconf \
    binutils \
    bubblewrap \
    bzip2 \
    bzip2-devel \
    cmake \
    cpio \
    dbus-devel \
    debugedit \
    diffutils \
    doxygen \
    dwz \
    elfutils-devel \
    elfutils-libelf-devel \
    file \
    file-devel \
    fsverity-utils \
    fsverity-utils-devel \
    gcc \
    gdb-headless \
    gdb-minimal \
    gettext-devel \
    git-core \
    glibc-gconv-extra \
    ima-evm-utils-devel \
    libacl-devel \
    libarchive-devel \
    libcap-devel \
    libgcrypt-devel \
    libselinux-devel \
    libzstd-devel \
    lua-devel \
    make \
    openssl-devel \
    pandoc \
    patch \
    pkgconf-pkg-config \
    pkgconfig \
    popt-devel \
    python3-devel \
    readline-devel \
    redhat-lsb-core \
    rpm-sequoia \
    rpm-sequoia-devel \
    sqlite-devel \
    unzip \
    which \
    xz \
    xz-devel \
    zlib-devel \
    zstd
