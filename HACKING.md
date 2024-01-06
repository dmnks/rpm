# Hacking on RPM

One quick and easy way to get started with RPM development on Linux is to use
[Toolbox](https://containertoolbx.org/) to create a containerized development
environment where you can both build *and* run RPM from your local source tree.

This removes the need to manually hunt for and install the correct build
dependencies on your host distro as well as allows you to experiment with RPM
features such as transactions or other privileged, system-wide operations,
without the risk of breaking your host system.  It's also useful if you're
running an immutable distro such as [Fedora
Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/).

For this purpose, we provide a batteries-included, Toolbox-ready
[Containerfile](tests/Dockerfile.fedora) based on the latest stable Fedora
release that bundles all the necessary dependencies as well as some basic
development tools.

## Getting Started

First, make sure you have Toolbox installed.  On Fedora, get it with the
following command:

    sudo dnf install toolbox

Next, clone and enter the RPM repository:

    git clone https://github.com/rpm-software-management/rpm.git
    cd rpm/

Now, build a Toolbox image (we'll name it `rpm-toolbox` here but you can use
any name you wish):

    podman build --target base -t rpm-toolbox -f tests/Dockerfile .

Then, create a Toolbox container from the freshly built image:

    toolbox create -i rpm-toolbox

> [!TIP]
> To learn more about Toolbox, view the `toolbox(1)` man page or visit the
> project's [home page](https://containertoolbx.org/).

Finally, make your code changes in your favorite editor on the host as you
normally would.  Then, once you're ready to take them for a spin, continue
below.

## Building RPM

First, enter the Toolbox container you've just created:

    toolbox enter rpm-toolbox
    ⬢[user@toolbox rpm]$

Toolbox mounts your `$HOME` directory from the host so you can access all your
files from within the container as normal.  It also retains the current working
directory when you enter it which means you should now be in your source tree's
top-level directory.

In our freshly created Toolbox, no RPM installation is present yet.  To install
one, do a build and install the artifacts (the default prefix is `/usr/local`):

    ⬢[user@toolbox rpm]$ mkdir _build
    ⬢[user@toolbox rpm]$ cd _build/
    ⬢[user@toolbox _build]$ cmake ..
    ⬢[user@toolbox _build]$ make
    ⬢[user@toolbox _build]$ sudo make install

> [!TIP]
> Consider disabling plugin support with the CMake option
> `-DENABLE_PLUGINS=OFF` since some of the plugins are not designed to work in
> containers and may therefore produce error messages during RPM transactions.

## Running RPM

You can now invoke RPM as usual:

    ⬢[user@toolbox _build]$ sudo rpm ...

Next time you make changes to the source tree, simply re-run `sudo make
install` from the build directory to update the installation.  In most cases,
this will suffice, however if you make changes to the installation procedure
itself or move build artifacts around, you may need to start
[afresh](#factory-reset).

To run the test-suite:

    ⬢[user@toolbox _build]$ sudo make check

> [!IMPORTANT]
> The test-suite will exercise your RPM build against *this* Toolbox's root
> filesystem so make sure its reasonably close to the pristine condition (such
> as, the basic system paths and utilities are still present and working)
> before running the test-suite.  Otherwise, unexpected test failures may
> occur.  If in doubt, just [re-create](#factory-reset) the Toolbox.

> [!TIP]
> For more information on the test-suite itself, see the dedicated
> [README](tests/README.md) file.

## Tips & Tricks

### Factory Reset

When you break your Toolbox container, don't worry!  You can easily re-create
it as follows (from the host):

    toolbox rm -f rpm-toolbox
    toolbox create -i rpm-toolbox

### Multiple Toolboxes

Sometimes, it can be handy to keep separate Toolboxes around for different
purposes, such as when working on different RPM features.  To create another
Toolbox, supply a name for it, as follows:

    toolbox create -i rpm-toolbox <name>

To list your current Toolboxes:

    toolbox list

### Installing Additional Software

The Toolbox image includes DNF so as long as the RPM installation works and is
ABI-compatible with it, you can use DNF to install packages as normal, for
example:

    ⬢[user@toolbox ~]$ sudo dnf install gdb

Otherwise, or if your experiments have broken the Toolbox's filesystem beyond
repair but you still wish to install something (e.g. a utility to diagnose the
issue), if you're running Fedora on the host, you can use your host's DNF
instance as follows:

    podman unshare
    [root@host ~]$ root=$(podman mount rpm-toolbox)
    [root@host ~]$ dnf --installroot=$root install <package>
    [root@host ~]$ podman umount rpm-toolbox
    [root@host ~]$ exit

### Debugging

For the best debugging experience, e.g. with `gdb` (not included in the image
by default), make sure to export the following `CFLAGS` variable in the Toolbox
container, *before* building and installing RPM:

    export CFLAGS="-O0 -g3"

### Integration with Sibling Projects

If you're hacking on a project that RPM depends on (such as our friends at
[rpm-sequoia](https://github.com/rpm-software-management/rpm-sequoia) or
[popt](https://github.com/rpm-software-management/popt)) and wish to test it
against your local RPM build, just build & *install* the project into the same
Toolbox, and then run RPM's test-suite as usual.  Since the test-suite reuses
the Toolbox container for its base image (as mentioned above), the other
project (e.g. a library) will therefore be automatically linked against and
used by RPM during the tests, without having to manually set any environment
variables.
