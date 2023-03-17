FROM registry.fedoraproject.org/fedora:37
MAINTAINER rpm-maint@lists.rpm.org

RUN dnf -y --disablerepo=\* --enablerepo=fedora,updates install \
    binutils \
    bubblewrap \
    cpio \
    debugedit \
    diffutils \
    dwz \
    file

ENTRYPOINT ["./rpmtests"]
