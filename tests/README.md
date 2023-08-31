# Test suite

The test suite is written using GNU Autotest and, once built, is a standalone
bash script named `rpmtests` which must be run as root and exercises the RPM
installation in the root filesystem.  The tests that need to modify the root
filesystem get a writable, disposable snapshot of it.

When hacking on RPM, installing the build artifacts natively is typically not
desired so, by default, `make check` runs this script in a container on top of
a minimal OS image that mirrors the host OS and includes an installation of RPM
in the configured prefix.

## Running tests

To run these tests, you need [autom4te](https://www.gnu.org/software/autoconf/)
and one of the following container tools:

1. [Bubblewrap](https://github.com/containers/bubblewrap/)
1. [Podman](https://github.com/containers/podman/)
1. [Docker](https://github.com/docker/)

These tools are required for test suite isolation and are looked for in that
order.  If none is available, the test suite will be disabled.

Bubblewrap provides the best experience as it's lightweight and runs the test
suite against your local build directory, using the native package manager such
as DNF or Zypper to setup the OS image.

Podman and Docker will perform a separate build in a container on every run,
which is more portable and thus suitable for the CI environment but not as
optimal for local development.

> [!IMPORTANT]
> Currently, the Bubblewrap method is only supported on Fedora Linux hosts,
> other distros will need Podman or Docker installed.

Then run the command:

    make check

The number of tests performed depends on features enabled at configure time, at
least `--enable-`/`--disable-python`.  See also the [INSTALL](../INSTALL) file
for more information.

To run *single tests*, you can run the command:

    make check TESTOPTS="$NNN $MMM"

where _NNN_ and _MMM_ are the numbers of the tests to be run.

You can also select *tests by keywords* used in their description by using the
command:

     make check TESTOPTS="-k $KEYWORD"

Use multiple `-k` parameters to have tests with different keywords run.  Use
`-k $KEYWORD1,$KEYWORD2` to execute tests matching both _KEYWORD1_ and
_KEYWORD2_.

For all available options, see the output of the command:

	./rpmtests --help

By default, tests are executed in parallel using all available cores, pass a
specific `-jN` value to limit, for example:

    make check TESTOPTS="-j4"

## Interactive testing

To manually test your RPM build in a shell, run:

    make shell

This spawns a container on top of the same OS image as the one used by the test
suite, with a shell as the process and the `tests` directory mounted at `/srv`
for easy sharing of files with the host.

When re-entering this shell, the image is rebuilt for any RPM source changes to
take effect, the OS layer is reused and any user changes to the filesystem are
retained.

> [!IMPORTANT]
> If using Podman or Docker, user changes are dropped too.

To factory-reset the container (drop any user changes), run:

    make reset

## Test-like environment

This is like `make shell` on steroids, invoke it with:

    make env

This shell runs natively on the host, sources the `atlocal` file with the usual
test commands such as `runroot`, and mounts a writable snapshot of the OS image
at the path stored in `$RPMTEST`.

> [!WARNING]
> Unlike a real test, this shell runs **without** filesystem isolation from the
> host so be mindful when using destructive commands.

The advantage over `make shell` is that you can use your native tooling to view
or modify the contents of the filesystem in `$RPMTEST`.  It can also be handy
when debugging a newly written test.

> [!NOTE]
> See the `motd(5)`-like output printed upon entering the shell for the
> instructions on how to use it.

Effectively, `make shell` is just a shorthand for

    make env
    runroot_other $SHELL

> [!NOTE]
> The snapshot used by `make shell` is the same as the one mounted at
> `$RPMTEST` in `make env`.

## Advanced features

### Common OS layer

If you use multiple build directories during development, you may want them to
reuse the same OS layer, to save time and disk space.  To enable that, simply
run:

    cd /path/to/source/dir/
    mkdir mktree.output

This directory will then be used by the build system to store the OS layer,
instead of the build directory.

Note that if you're using `git-worktree(1)`, the `mktree.output` directory will
only be looked for in the original (full) checkout.

### Rebuilding the OS layer

Sometimes, you may need to recreate this layer, e.g. if some RPM dependencies
change and/or to update the software installed in it.  Do it simply by running:

    make clean

If you're using a [common OS layer](#common-os-layer), you have to delete it
manually:

    cd /path/to/source/dir/
    rm -rf mktree.output/

Next time the image is needed, the OS layer will be rebuilt.

### Reusing a build container

If you already have a throwaway container or VM for building and running RPM,
you can instruct the test suite to run "natively" in the same root filesystem,
rather than building a separate image for it, by configuring your build with:

    cmake -DMKTREE_BACKEND=rootfs /path/to/source/dir

If you're brave enough, you can also do this on your host and then use `sudo
make check` but that's not recommended.

### Running CI locally

If you wish to verify that your changes pass in our CI before opening a PR, the
following will run the same CI setup locally (needs Podman or Docker):

    make ci

This is equivalent to doing:

    cmake -DMKTREE_BACKEND=podman /path/to/source/dir
    make check

## Known Issues

CONTINUE HERE
