# Testing

To run these tests, you need at least these dependencies on the host:

1.    [bwrap](https://github.com/containers/bubblewrap/)
1.    [gdb](https://www.gnu.org/software/gdb/)
1.    [gnupg](https://www.gnupg.org/) >= 2.0

Then run the command

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

To drop into a test-like shell, run:

    make env

See the printed help for details on how to use it.

You can also run a containerized shell with your RPM checkout built, installed
and ready to use:

    make shell

This is equivalent to running:

    make env
    snapshot shell

To factory-reset the container, run:

    make reset

## How it works

The test suite is written using GNU Autotest and, once built, is a standalone
Bourne shell script named `rpmtests`.  The script is supposed to be run as root
and exercises the RPM installation in the root filesystem, preferably mounted
as read-only.

Each test in the suite that needs write access to the root filesystem (such as
to install packages) runs RPM in a mutable, disposable container (a *snapshot*)
on top of the root filesystem, using Bubblewrap and OverlayFS.

Since running the test suite natively as root and installing build artifacts
into the system is usually not desired on a workstation, `make check` runs the
`rpmtests` script itself in a container on top of an OS filesystem tree that
mirrors the running host and contains a fresh `make install` from the build
directory.  This all works without root privileges thanks to the use of Linux
`namespaces(7)`.

### Building the tree

The `mktree` executable is responsible for setting up the filesystem tree and
running containers against it.  It is invoked by `make tree` which in turn is
invoked by `make check`, `make env` and `make shell`, and may also be invoked
directly if one wishes to avoid the CMake overhead.

The executable is made during CMake configuration by choosing a *backend* (one
of the files starting with `mktree.`) that's native to the host, configuring it
and copying it to the build directory with the suffix stripped.

Native backends use a package manager such as DNF or Zypper to bootstrap the
tree with RPM's runtime dependencies matching the development headers used, RPM
itself by running `make install` from the build directory with the `DESTDIR`
environment variable set accordingly, and all the required test binaries.

If no native backend is available, `mktree.podman` will be chosen as a fallback
which performs the whole RPM build process in a Fedora container and reuses the
same image for the tests.  This backend is primarily intended for use in our CI
where portability is key (currently, Ubuntu VMs through GitHub Actions) and is
therefore not optimized for iterative `make check` use.

Developers wishing to contribute a native backend for their platform of choice
are encouraged to consult the `mktree.README` file for the details on how to
write one.
