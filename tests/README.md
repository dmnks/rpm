# Tests

To run these tests, you need one of the following:

1. [Podman](https://github.com/containers/podman/)
2. [Docker](https://github.com/docker/)

Then run the command

    make check

> [!IMPORTANT]
> Whether the native build of RPM will be tested or a separate, fresh build
> (including CMake configuration) will be done for the purposes of the
> test-suite depends on the host OS and the availability of Podman.  Currently,
> native build integration is only supported on Fedora Linux with Podman, any
> other combination will trigger a custom build against a Fedora based image.

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
included binaries) within a shared Podman or Docker container and then compare
the standard (error) output with the one expected, producing a failure if they
don't match.

### Container image (WIP)

1. **Native** - Exercises the local build of RPM against a minimal image of the
   Linux distribution running on the host.  Currently, only Fedora Linux is
   supported.  This mode is optimized for local RPM development and requires
   Podman.

1. **Standalone** - Exercises a custom, fresh build of RPM (including cmake
   configuration) against a Fedora-based image.  This mode is optimized for
   portability (CI environment) and works with both Podman and Docker.

The mode is selected automatically during cmake configuration based on the host
distribution and the container engine installed, with native mode being
preferred whenever possible, and is reported in the cmake output as follows:

    -- Using mktree backend: oci (native: <yes|no>)

### Test isolation

There are two categories of tests:

1. **Immutable** - These tests typically perform a read-only operation that
   doesn't involve writing to the root filesystem (with the exception of the
   `$PWD`, `/build` and `/tmp` directories), such as `rpm --eval`, and thus can
   be executed "natively" within the Podman/Docker container without any kind
   of additional isolation to prevent them from interfering with each other.
   To ensure no accidental writes occur, the container's filesystem is mounted
   as read-only.

2. **Mutable** - These tests perform an action that alters the root filesystem,
   such as installing or removing packages.  To ensure they always run against
   the original, pristine filesystem and to allow for parallel execution, each
   of these tests gets a writable, throwaway snapshot of the root filesystem
   and runs in a nested, lightweight container on top of that.  This container
   is built using a combination of Bubblewrap and OverlayFS so that the
   overhead of a full-blown OCI container is avoided, making the whole
   test-suite comprising of several hundreds of tests run significantly faster.




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
