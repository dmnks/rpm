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
    /usr/bin/gdb-add-index \
    audit-libs-devel \
    autoconf \
    btrfs-progs \
    bzip2-devel \
    cmake \
    dbus-devel \
    debugedit \
    doxygen \
    dwz \
    elfutils binutils \
    elfutils-devel \
    elfutils-libelf-devel \
    fakechroot which \
    file-devel \
    findutils sed grep gawk diffutils file patch \
    fsverity-utils fsverity-utils-devel \
    gcc \
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
    lua-devel readline-devel \
    make \
    openssl-devel \
    pkgconfig \
    popt-devel \
    python3-devel \
    rpm-sequoia-devel \
    sqlite-devel \
    tar unzip gzip bzip2 cpio xz \
    xz-devel \
    zlib-devel \
    pandoc

CMD cmake -DENABLE_PLUGINS=off .. && make rpmtests
