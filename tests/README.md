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

Each test gets a pristine, minimal OS filesystem mounted at `$RPMTEST` with an
RPM installation inside.  Issuing `runroot` then runs the given command in a
lightweight container on top of that tree.

The filesystem is a union mount of the *image* tree (immutable) and *test* tree
(writable).  The image tree is itself a union of the *base* tree (RPM's runtime
and test dependencies) made by the host distribution specific `mktree` script,
the *data* tree (test resource files) and the RPM *installation* tree.

All trees are stored in the build directory and recreated separately if their
corresponding sources have changed, except for the test tree which is created
once for each test and starts empty.

For extra safety, `make check` runs the `rpmtests` script in its own container
(using the same image) to prevent a misbehaved test from modifying your host
filesystem.  The container is also made read-only to preemptively detect such
accidental writes.

## Interactive testing

To drop into a shell that replicates the environment of a single test, run:

    make sandbox

There, you can use the usual commands and variables available in a test, e.g:

    runroot rpm ...
    ls $RPMTEST

Unlike an actual test, the shell runs in your host filesystem, allowing you to
use all your programs normally and manage the contents of `$RPMTEST` like any
other directory on the host.  For example, on Fedora, you can install extra
packages into the filesystem like this:

    dnf install --installroot=$RPMTEST ...

The `$RPMTEST` filesystem is persistent across `make sandbox` runs.  To factory
reset it, run:

    make reset

### Handy aliases

Some common operations have useful aliases defined in `make sandbox`, namely:

* `rpm` for `runroot rpm`
* `dnf` for `dnf --installroot=$RPMTEST` (only on Fedora)

### Managing filesystems

You can create multiple filesystems from the same image with the `rpmtest`
command, e.g:

    rpmtest umount          # unmount $RPMTEST
    rpmtest mount mytest    # mount a new "mytest" filesystem at $RPMTEST
    runroot rpm ...

Note that the filesystem that's automatically mounted when executing `make
sandbox` is named "default".

For all available options, see the output of the command:

    rpmtest --help

### Development container

TODO

## Extending the image

To adjust the image to your liking, such as to install your favorite
development tools, create an executable script named `mktree.extra` in the
built `tests` directory.  It will be automatically run by `mktree`.

Ideally, `mktree` exports a convenience wrapper to invoke the host's package
manager with the necessary flags, such as that defined in `mktree.fedora` for
DNF.  Thus on Fedora, the `mktree.extra` script may be as simple as:

    #!/bin/sh
    dnf install -y ...

Note that this feature is only meant for the `make shell` use case.  If the
test you're writing requires additional tools, you need to put them into the
distribution specific `mktree` scripts instead.
