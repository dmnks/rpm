# Tests

## Overview

This test-suite exercises RPM by installing it natively with `make install` (or
emulating such a system using containers) and running a series of simple shell
scripts, each representing a single use case that calls one of the RPM binaries
(or a program using the API) and verifies the results.

In order to prevent individual tests from interfering with each other or with
the test logic itself, those that need to *write* to the root filesystem (such
as to install packages) do so through a container with a copy-on-write snapshot
mounted as the root directory.

### Backends

Currently, there are two ways (*mktree backends*) in which the OS filesystem
tree (image) is constructed and tested: OCI and Rootfs.

The backend in use is reported during CMake configuration in the following
message:

    -- Using mktree backend: <name>

#### OCI

This backend pulls an [OCI](https://opencontainers.org/) image matching the
host OS and layers RPM on top to produce the final image.  Its purpose is to
allow for testing the native build of RPM on a developer's workstation with a
simple `make check`, without having to manage containers or images by hand.

This backend is selected automatically and requires
[Podman](https://github.com/containers/podman/).

> [!IMPORTANT]
> Native build integration is currently only supported on **Fedora Linux**
> hosts, on other hosts a fresh build is done and tested in a Fedora container
> ("non-native" mode).

> [!NOTE]
> In non-native mode, [Docker](https://github.com/docker/) is also supported
> and will be used if Podman isn't available.

During CMake configuration, native mode (`yes` or `no`) is also reported.

#### Rootfs

This backend installs RPM natively and uses the root filesystem for testing.
Its suitable for use within development containers that already have RPM's
runtime dependencies preinstalled.

To select this backend, use the CMake option `-DMKTREE_BACKEND=rootfs`.

> [!WARNING]
> It is *not* recommended to use this backend on a production system since it
> requires root privileges and may delete files in case of a broken test.

## Running tests

To run the test-suite, issue this command:

    make check

The number of tests performed depends on features enabled at configure time,
at least `--with-`/`--without-lua` and `--enable-`/`--disable-python`.
See also the [INSTALL](../INSTALL) file for more information.

To run *single tests*, you can run the commands:

    make check TESTOPTS="$NNN $MMM"

where _NNN_ and _MMM_ are the numbers of the tests to be run.

You can also select *tests by keywords* used in their description by using the command:

     make check TESTOPTS="-k $KEYWORD"

Use multiple `-k` parameters to have tests with different keywords run.
Use `-k $KEYWORD1,$KEYWORD2` to execute tests matching both _KEYWORD1_ and _KEYWORD2_.

For all available options, see the output of the command:

	./rpmtests --help

By default, tests are executed in parallel using all available cores, pass
a specific -jN value to limit.

Lastly, if the OCI backend is configured in native mode, you may want to try it
in standalone mode before submitting a pull request since that's how our CI is
set up.  You can do that with:

    make ci

This target accepts the same `TESTOPTS` variable as `make check`.

### Interactive testing

To drop into a GNU Autotest like shell, run:

    make atshell

This is like a singular, empty `RPMTEST_CHECK()` with a shell running in it and
a writable tree available at the path stored in `$RPMTEST`.  From this shell,
you can run the same commands as a normal test would, such as `runroot rpm`.
This can be used to quickly prototype (or debug) a test.  See TODO for details
on how the tests are structured.

You can also drop straight into the `$RPMTEST` container like so:

    make shell

This is just a shorthand for `make atshell` followed by `runroot_other bash`.

To factory-reset the `$RPMTEST` container, run:

    make reset

## Understanding the tests

The goals of the test-suite are:

1. Install the RPM build natively, or emulate such a system using containers
2. Separate the test logic from *that* system so that the latter can be broken
   (intentionally or not) without affecting the test results



### Optimizations

The test-suite is meant to be run repeatedly during local development and is
therefore optimized for speed.  Each test gets a *snapshot* of the shared tree
using [OverlayFS](https://docs.kernel.org/filesystems/overlayfs.html) and runs
RPM in lightweight [Bubblewrap](https://github.com/containers/bubblewrap/)
containers with that snapshot mounted as the root directory.

There are two kinds of snapshots:

1. **Immutable** - A read-only snapshot created at the beginning of the
   test-suite and destroyed afterwards.  Used by those tests that don't need
   write access to the root filesystem (e.g. those testing `rpm --eval`).

2. **Mutable** - A read/write snapshot created on demand, typically at the
   beginning of a single test or test group and destroyed afterwards.  Used by
   those tests that alter the root filesystem (e.g. `rpm --install` or `rpm
   --erase`).  This snapshot gets a freshly initialized (empty) rpmdb.

This separation reduces the number of snapshots that need to be created and
destroyed per test-suite run since a large portion of the tests only requires
the former (immutable) one.

Furthermore, snapshots ensure that:

1. Each test operates *in* a pristine filesystem (the test logic isn't affected
2. Each test operates *on* a pristine filesystem
3. Individual tests can run in parallel without affecting each other

Lastly, depending on the mktree backend, the test-suite script itself may be
wrapped in a container with the immutable snapshot as its root directory, which
has the following benefits:

1. Only this one container is needed for all immutable tests, with RPM executed
   directly in it
2. Full isolation of the test-suite from the host (to prevent a misbehaving
   test from affecting it)

> [!NOTE]
> The OCI backend does this by running the test-suite in a privileged,
> read-only Podman container.  This also simplifies the backend as Podman is
> already used to build the image.

### Layout

The test-suite is written in
[GNU Autotest](https://www.gnu.org/savannah-checkouts/gnu/autoconf/manual/autoconf-2.71/html_node/Using-Autotest.html)
and comprises of the following files:

```
├── atlocal.in          shell environment setup (variables and functions)
├── data/               resource files (SPECS, PGP keys, etc.)
├── Dockerfile          ──┐
├── Dockerfile.fedora   ──┴── OS-specific images for mktree.oci
├── local.at            m4 macro definitions
├── mktree.common       ──┐
├── mktree.oci            ├── mktree backends
├── mktree.rootfs       ──┘
├── rpmbuild.at         ──┐
├── rpmbuildid.at         │
├── rpmconfig2.at         ├── sub test-suites (per functionality area)
├── ...                 ──┘
├── rpmtests.at         main test-suite (compiled into rpmtests script)
├── rpmtests.sh         wrapper around rpmtests script with extra CLI switches
```

## Writing tests (TBD)
