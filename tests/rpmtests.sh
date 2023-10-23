#!/bin/bash
#
# Wrapper for rpmtests that looks for atlocal in the script's directory instead
# of $PWD or the one specified with -C.  In addition, implements the following
# extra options:
#   -S, --shell [CMD]
#       creates an empty test (if none exists) and runs a shell (or CMD) in it
#   -R, --reset
#       deletes the test created with --shell
#   -L, --log
#       print the test log when done

SCRIPT_DIR=$(dirname $(readlink -f $0))
SCRIPT_FILES="rpmtests atlocal mktree.common"

TARGET_DIR=$PWD
PRINT_LOG=0
RC=0

SHELL_DIR=$PWD/rpmtests.shell
RUN_SHELL=0

fix_perm()
{
    chmod -Rf u+rwX "$@"
}

cd "$SCRIPT_DIR"

while [ $# != 0 ]; do
    case $1 in
        -C | --directory )
            TARGET_DIR="$2"
            shift
        ;;
        -S | --shell )
            RUN_SHELL=1
        ;;
        -R | --reset )
            rm -rf "$SHELL_DIR"
            exit
        ;;
        -L | --log )
            PRINT_LOG=1
        ;;
        *)
            break
        ;;
    esac
    shift
done

# Symlink script files into $TARGET_DIR, prefer local versions though
for file in $SCRIPT_FILES; do
    [ -f "$TARGET_DIR/$file" ] || ln -s $PWD/$file $TARGET_DIR/
done

cd "$TARGET_DIR"

# Run the test suite (or a shell)
if [ $RUN_SHELL == 0 ]; then
    ./rpmtests "$@"; RC=$?
    [ $PRINT_LOG == 1 ] && cat rpmtests.log
    fix_perm rpmtests.dir/*/work
else
    set -a
    source ./atlocal
    trap : INT
    RPMTEST=$SHELL_DIR/tree
    snapshot mount $SHELL_DIR
    if [ $# == 0 ]; then
        $SHELL
    else
        "$@"
    fi
    snapshot umount
    fix_perm $SHELL_DIR
fi

# Clean up the symlinks
for file in $SCRIPT_FILES; do
    [ -L "$file" ] && rm "$file"
done

exit $RC
