# Tests

This test-suite exercises the local build of RPM against an OS filesystem tree
with compatible runtime dependencies using rootless containers.  Currently, the
following methods (*mktree backends*) of initializing the filesystem tree are
supported:

1. **OCI** - Uses an OCI image based on the running Linux distro.  This backend
   is suitable for native development on a Linux workstation and is selected by
   default (requires Podman).

2. **Rootfs** - Uses the root filesystem itself and thus requires the runtime
   dependencies of RPM and root privileges.  This backend is suitable for use
   within a development container and can be selected with the CMake option
   `-DMKTREE_BACKEND=rootfs`.

> [!IMPORTANT]
> Currently, the OCI backend only supports local build integration (*native*
> mode) on **Fedora Linux** hosts, on other hosts a fresh build of RPM will be
> done from the local sources as part of a Fedora based image (*non-native*
> mode).

> [!NOTE]
> When the OCI backend operates in non-native mode, Docker is also supported
> and will be used if Podman isn't available.

The backend in use is reported during CMake configuration in the following
message:

    -- Using mktree backend: <name>

For the `oci` backend, native mode (`yes` or `no`) is also reported.

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

Sometimes, if the test-suite is configured in native mode, you may want to try
it in standalone mode before submitting a pull request since that's how our CI
is set up.  You can do that with:

    make ci

This target accepts the same `TESTOPTS` variable as `make check`.

### Interactive testing

To drop into an Autotest-like shell, run:

    make atshell

This is like a singular, empty `RPMTEST_CHECK()` with a shell running in it and
a writable tree available at the path stored in `$RPMTEST`.  From this shell,
you can run the same commands as a normal test would, such as `runroot rpm`.
This can be used to quickly prototype (or debug) a test.

You can also drop straight into the `$RPMTEST` container like so:

    make shell

This is just a shorthand for `make atshell` followed by `runroot_other bash`.

To factory-reset the `$RPMTEST` container, run:

    make reset

## Architecture

The test-suite consists of a number of small shell scripts (*tests*) written in
GNU Autotest that perform some kind of operation using `rpm(8)` (or one of the
included binaries) in a container and then compare the output and error code
with the expected values.

### Optimizations

Since the test-suite consists of hundreds of tests and is meant to be executed
repeatedly during development, it's optimized for speed.  Each test runs in a
lightweight Bubblewrap container on top of an OverlayFS snapshot created from
the shared OS filesystem tree.

There are two kinds of snapshots:

1. **Immutable** - This is a read-only snapshot created (and destroyed) once
   per test-suite run and is shared among all the tests that don't need write
   access to the root filesystem (e.g. those testing `rpm --eval`).

2. **Mutable** - This is writable a snapshot created (and destroyed) once per
   each test that needs write access to the root filesystem (e.g. those testing
   `rpm --install` or `rpm --erase`).

Snapshots allow the tests to run in parallel and ensure that each one operates
on a pristine filesystem, without the risk of interfering with any other test.

As a further optimization, the test-suite process assumes its root directory is
set to the immutable snapshot, which serves two purposes:

1. Only one container is needed for all the read-only tests

2. No misbehaving test can accidentally write to the host filesystem

This is why the OCI backend wraps the test-suite script itself in a container.

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







### Structure of rpmtests.at

This file contains a list `m4_include()` macros, one for each sub test-suite,
and is used to produce the standalone test-suite executable.  It is built using
`autom4te(1)` and the `local.at` file.

An individual test consist of a set of m4 macros as described in Autotest's
[user guide](https://www.gnu.org/savannah-checkouts/gnu/autoconf/manual/autoconf-2.71/html_node/Writing-Testsuites.html)
and can
