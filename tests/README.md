# Test suite

To run these tests, you need at least these programs on the host:

1. [autom4te](https://www.gnu.org/software/autoconf/)
1. [bubblewrap](https://github.com/containers/bubblewrap/)
1. [grep](https://www.gnu.org/software/grep/)
1. [id](https://www.gnu.org/software/coreutils/)
1. [unshare](https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/)

Then run the command

    make check

The number of tests performed depends on features enabled at configure time,
e.g. `-DENABLE_PYTHON=<ON|OFF>`.  See also the [INSTALL](../INSTALL) file for
more information.

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
a specific `-jN` value to limit.

## Writing tests

Tests are written in
[Autotest](https://www.gnu.org/software/autoconf/manual/autoconf-2.68/html_node/Using-Autotest.html#Using-Autotest).
Our specifics are:

* Use the `RPMTEST_CHECK` wrapper macro in place of `AT_CHECK`
* Put the `RPMDB_INIT` macro at the beginning of a test if you need the RPMDB
* Use the `runroot` command to execute RPM in a per-test container
* Inspect or modify the container filesystem at the path stored in `$RPMTEST`

You can run arbitrary non-RPM commands in the container using the
`runroot_other` command.

## Isolation

Each test gets a pristine filesystem tree mounted at `$RPMTEST` with RPM
installed and ready to use.  Issuing `runroot` then runs a container (using
bubblewrap) on top of that tree.

CONTINUE HERE
The filesystem consists of four layers.  The first three (the "image" or
overlayfs lowerdirs) are: the *base* layer (RPM's runtime and test
dependencies), the *data* layer (test resource files), and the *install* layer
(RPM installation).  The fourth layer records during test execution).

All the layers are stored in the build directory and reused if unchanged.  The
base layer is composed by the host distribution specific `mktree` script.

Any changes made to `$RPMTEST` trees during test execution are stored in
Autotest specific per-test directories under `rpmtests.dir`.

For extra safety, `make check` runs the `rpmtests` script itself in a container
(using the same image) to prevent a misbehaving test from modifying your host
filesystem.  The container is also made read-only to preemptively detect such
accidental writes.

## Interactive testing

To drop into a shell that replicates the environment of a single test, run:

    make env

There, you can use the usual commands and variables available in a test, e.g:

    runroot rpm ...
    ls $RPMTEST

On a Fedora host, you can also manage the `$RPMTEST` tree with DNF from the
host using a builtin wrapper, e.g:

    dnf install ...

The `$RPMTEST` tree is persistent across `make env` runs.  To factory-reset it,
run:

    make reset

Any changes made to `$RPMTEST` are stored in the `$SANDBOX` directory.  You can
change these values arbitrarily to create multiple trees.  To mount/unmount a
tree, use the `sandbox` builtin, see `sandbox --help` for details.

## Development container

To quickly test-drive your RPM checkout in a container, run:

    make shell
    rpm ...

This is just a shorthand for

    make env
    runroot_other <shell>

Where `<shell>` is root's default shell as configured in the image.

You can also manually run the test suite from this container:

    ./rpmtests ...

This is exactly what `make check` does behind the scenes.  Note that while this
will also work in `make env`, it is recommended that you only run the test
suite in a container, as discussed above.

## Extending the image

To adjust the image to your liking, such as to install your favorite
development tools, create an executable script named `mktree.extra` in this
directory.  It will be automatically run by `mktree`.  Ideally, `mktree`
exports a convenience wrapper to invoke the host's package manager with the
necessary flags, such as that defined in `mktree.fedora` for DNF.  Thus on
Fedora, the `mktree.extra` script may be as simple as:

    #!/bin/bash
    dnf install -y ...

Note that this feature is only meant for the `make shell` use case.  If the
test you're writing requires additional tools, you need to put them into the
distribution specific `mktree` scripts instead.
