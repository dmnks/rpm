# Tests

This test-suite bootstraps a minimal, self-contained OS filesystem tree with an
installation of RPM (done with `make install`) and runs a series of small shell
scripts, each operating on a container based on this tree.  The main, top-level
script (called `rpmtests` when compiled) is written in [GNU
Autotest](https://www.gnu.org/software/autoconf/manual/autoconf-2.68/html_node/Using-Autotest.html#Using-Autotest).

Each test covers a specific piece of functionality by running an RPM command
(or a program/script using the API) in the container and verifying the changes
made in the container's filesystem as well as the standard/error output and/or
exit code.

Currently, the following methods (*mktree backends*) are available for
bootstrapping the tree:

1. **OCI** - Pulls a prebuilt [OCI](https://opencontainers.org/) image matching
   the host OS and layers RPM on top to produce the final image.  This backend
   is suitable for native development of RPM, requires
   [Podman](https://github.com/containers/podman/) and is selected by default.

2. **Rootfs** - Installs RPM into the root filesystem.  This backend is
   suitable for use within a development container that has the runtime
   dependencies installed and can be selected with the CMake option
   `-DMKTREE_BACKEND=rootfs`.

> [!IMPORTANT]
> Currently, local build integration (*native* mode) in the OCI backend is only
> supported on **Fedora Linux** hosts, on other hosts a fresh build will be
> done and tested in a Fedora container (*non-native mode*).

> [!NOTE]
> When the OCI backend operates in non-native mode,
> [Docker](https://github.com/docker/) is also supported and will be used if
> Podman isn't available.

The backend in use is reported during CMake configuration in the following
message:

    -- Using mktree backend: <name>

For the OCI backend, native mode (`yes` or `no`) is also reported.

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

## Understanding the tests

### Optimizations

The test-suite is meant to be run repeatedly during local development and is
therefore optimized for speed.  Each test gets a *snapshot* of the shared tree
using [OverlayFS](https://docs.kernel.org/filesystems/overlayfs.html) and runs
lightweight [Bubblewrap](https://github.com/containers/bubblewrap/) containers
with that snapshot mounted as the root directory.

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

Furthermore, mutable snapshots ensure that:

1. Each test operates on a pristine filesystem
2. Individual tests can run in parallel without affecting each other
3. Test logic isn't affected by the (side) effects of a test (e.g. the removal
   of a system utility that's later used to verify the results)

Lastly, the OCI backend runs the test-suite script itself in a read-only Podman
container and uses its root filesystem as the immutable snapshot.  This has the
following benefits:

1. Simplifies the backend (it already uses Podman to build the image)
2. Fully isolates the test-suite from the host (to prevent a misbehaving test
   from affecting it)

This Podman container runs in `--privileged` mode so that mutable snapshots and
Bubblewrap containers (i.e. nested namespaces) can still be created.

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
