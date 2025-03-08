#!/bin/bash

# Build and install RPM and the test-suite data into a directory

export DESTDIR=$1
ld_conf_dir=$DESTDIR/@CMAKE_INSTALL_SYSCONFDIR@/ld.so.conf.d
script_dir=/usr/share/mktree

@CMAKE_MAKE_PROGRAM@ -C @CMAKE_BINARY_DIR@ install
mkdir -p $ld_conf_dir
echo @CMAKE_INSTALL_FULL_LIBDIR@ > $ld_conf_dir/rpm.conf
ldconfig -r $DESTDIR @CMAKE_INSTALL_FULL_LIBDIR@

cp -r @CMAKE_CURRENT_SOURCE_DIR@/data $DESTDIR/
cp -r @CMAKE_CURRENT_SOURCE_DIR@/pinned $DESTDIR/

mkdir -p $DESTDIR/usr/bin
cp @TESTPROG_NAMES@ $DESTDIR/usr/bin/
ln -s $script_dir/rpmtests.sh $DESTDIR/usr/bin/rpmtests

mkdir -p $DESTDIR/$script_dir
cp rpmtests atlocal $DESTDIR/$script_dir/
cp @CMAKE_CURRENT_SOURCE_DIR@/rpmtests.sh $DESTDIR/$script_dir/

touch $DESTDIR/.rpmtestsuite
