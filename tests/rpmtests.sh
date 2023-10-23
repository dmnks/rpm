#!/bin/bash
#
# Wrapper around rpmtests that adds a couple of useful options:
#   -O, --output DIRECTORY
#       like -C but loads atlocal from the script's directory if missing
#   -L, --log
#       print the test log when done
#   -S, --shell [COMMAND]
#       create an empty test and run a shell (or COMMAND) in it
#   -R, --reset
#       delete the test created with --shell

SCRIPT_DIR=$(dirname $(readlink -f $0))
SCRIPT_FILES="atlocal mktree.common"

PRINT_LOG=0
RC=0

SHELL_DIR=$PWD/rpmtests.dir/shell
RUN_SHELL=0

fixperms()
{
    chmod -Rf u+rwX "$@"
}

while [ $# != 0 ]; do
    case $1 in
        -O | --output )
            cd "$2"
            shift
        ;;
        -L | --log )
            PRINT_LOG=1
        ;;
        -S | --shell )
            RUN_SHELL=1
        ;;
        -R | --reset )
            rm -rf "$SHELL_DIR"
            exit
        ;;
        *)
            break
        ;;
    esac
    shift
done

# Symlink script files into $PWD, prefer local versions though
for file in $SCRIPT_FILES; do
    [ -f "$file" ] || ln -s $SCRIPT_DIR/$file .
done

# Run the test suite (or a shell)
if [ $RUN_SHELL == 0 ]; then
    $SCRIPT_DIR/rpmtests "$@"; RC=$?
    [ $PRINT_LOG == 1 ] && cat rpmtests.log
    fixperms rpmtests.dir/*/{diff,work}
else
    # Emulate a single, writable test (RPMTEST_SETUP)
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
    fixperms $SHELL_DIR
fi

# Clean up the symlinks
for file in $SCRIPT_FILES; do
    [ -L "$file" ] && rm "$file"
done

exit $RC
