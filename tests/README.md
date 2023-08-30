# Testing

To run these tests, you need at least these dependencies on the host:

1.    [bwrap](https://github.com/containers/bubblewrap/)

If your host is *not* running Fedora Linux, you will also need either of:

1.    [podman](https://github.com/containers/podman/)
1.    [docker](https://github.com/docker/)

Then run the command

    make check

The number of tests performed depends on features enabled at configure time,
at least `--with-`/`--without-lua` and `--enable-`/`--disable-python`.
See also the [INSTALL](../INSTALL) file for more information.

## Selecting tests

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

## Developing RPM

For manual testing of RPM, run:

    make shell

This will drop you into a containerized shell with your RPM checkout built and
installed into the configured prefix.  The container runs a minimal version of
your host OS with only the basic tools installed, and has the `tests` directory
mounted at `/srv` for your convenience.

For any RPM source changes to take effect, simply rerun this target, any other
changes to the filesystem will be retained.

To factory-reset the container (drop any of your changes), run:

    make reset

## How it works

### Architecture

The test suite is written using GNU Autotest and, once built, is a standalone
Bourne shell script named `rpmtests`.  The script is intended to be run as root
and will exercise the RPM installation in the root filesystem that's preferably
mounted as read-only.

Each test in the suite that needs write access to the root filesystem (such as
to install packages) runs RPM in a mutable, disposable container (a *snapshot*)
on top of the root filesystem.  This is to prevent the individual tests from
affecting each other.

When hacking on RPM, one typically does not wish to install the build artifacts
into the host system and remount it as read-only.  To avoid that, `make check`
creates a minimal OS filesystem tree that mirrors the host, `make install`s RPM
into it and runs the `rpmtests` script in a container on top.  This completely
isolates the test suite from the host.

The container technology used is a combination of
[Bubblewrap](https://github.com/containers/bubblewrap/),
[OverlayFS](https://docs.kernel.org/filesystems/overlayfs.html) and Linux
`namespaces(7)`.  This allows for spawning a large number of lightweight
containers, some in parallel, on top of a shared, read-only filesystem, with
minimal overhead and thus very quickly.  Thanks to the use of namespaces, it
works under a regular, non-root user.  Since most of these technologies are
only available on Linux, this currently limits the test suite to Linux hosts
only.

### Making the tree

The `mktree` executable is responsible for creating the filesystem tree and is
invoked on `make tree` (which is a dependency of `make check` or `make shell`).
The executable is made during CMake configuration by choosing an implementation
(a *backend*) native to the running host, configuring it and copying it to the
build directory under the `mktree` name.

Most backends use the native package manager such as DNF or Zypper to install
RPM's runtime dependencies matching the development headers used in the build,
the test dependencies, and finally RPM itself using `make install` with the
appropriate `$DESTDIR` value.  The tree is then cached in the form of layers
(OS and RPM) and reused on subsequent `make check` runs, with only the RPM
layer being redone.

Currently, only Fedora Linux is supported natively with `mktree.fedora`, other
distros automatically fall back to `mktree.podman` which is an implementation
using Podman/Docker and the official Fedora OCI image to achieve the same, with
the difference being that RPM is configured and built in a container as well.
This makes it more portable and thus ideal for our CI purposes where we
currently run Ubuntu VMs, but it is not optimal for iterative `make check` use
as it does not reuse the existing build artifacts.

## Advanced features

### Common OS layer

If you use multiple CMake build directories during development, you may want
them to reuse the same OS layer, to save time and disk space.  To enable that,
simply do this from the root of the *source* directory:

    mkdir mktree.output

This directory will then be used by `mktree` to store the OS layer, instead of
the one in the build directory.

Note that if you're using `git-worktree(1)`, the `mktree.output` directory will
only be looked for in the original (full) checkout.

### Rebuilding the OS layer

Sometimes, you may want to recreate this layer, e.g. if some RPM dependencies
change and/or to update the software installed in the layer.  Do it simply by
running:

    make clean

If you're using a [common OS layer](#common-os-layer), you have to delete it
manually from the root of the *source* directory:

    rm -rf mktree.output/

Next time the tree is needed, the OS layer will be rebuilt.

### Interactive test-like environment

This is like `make shell` on steroids, invoke it with:

    make env

This shell runs natively on your host, sources the `atlocal` file and mounts a
test tree at `$RPMTEST`, much like what a typical test would do.  The advantage
over `make shell` is that you can use your native tools to view and manipulate
the contents of the filesystem.

Note that the filesystem mounted at `$RPMTEST` is the same as the one used by
`make shell`.  In fact, `make shell` is just a shorthand for

    make env
    runroot_other $SHELL

with a few extras such as the `tests` directory mounted at `/srv`.

A `motd(5)`-like piece of text is printed upon entering `make env` which
contains more information on how to use it.

### Specifying a mktree backend

To override the autodetection, use the CMake option `MKTREE_BACKEND` with the
desired backend name (`mktree` suffix).  This feature can be useful if you wish
to use an alternative backend.

For example, if you already use a throwaway development container or VM with
RPM's build dependencies, you may prefer to just reuse the same filesystem to
run the test suite against.  In such a case, configure your build with:

    cmake -DMKTREE_BACKEND=rootfs ...

In the future, this option may also be useful if we add an alternative, OS
agnostic backend that e.g. reflinks the required binaries and libraries from
the host instead of installing them from packages.

### Running CI locally

If you wish to verify that your changes pass in our CI before opening a PR, the
following will run the same CI setup locally (needs Podman or Docker):

    make ci

This is equivalent to doing:

    cmake -DMKTREE_BACKEND=podman ...
    make check

## Known Issues

CONTINUE HERE
