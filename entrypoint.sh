#!/bin/bash
set -e

# Set default values
## IP Address to bind netinstall to
NETINSTALL_ADDR="${NETINSTALL_ADDR:="192.168.88.1"}"
## Target device architecture
NETINSTALL_ARCH="${NETINSTALL_ARCH:="arm64"}"
## Target version to install
NETINSTALL_VER="${NETINSTALL_VER:="7.14.1"}"
## Netinstall Arguments, can be set via NETINSTALL_RESET as well
NETINSTALL_ARGS="${NETINSTALL_ARGS:=""}"
## Packages to add to netinstall (eg. routeros, container)
NETINSTALL_PKGS="${NETINSTALL_PKGS:="routeros"}"
## Location of npk files, should not be changed under normal usage!
NPK_DIR="${NPK_DIR:="/app/images/"}"


# Apply additional logic
## Check if NETINSTALL_RESET variable set, and add "-b -r" to NETINSTALL_ARGS
## to remove branding and reset to default
if [ "${NETINSTALL_RESET}" ]; then
    NETINSTALL_ARGS="${NETINSTALL_ARGS} -b -r"
fi

# Check if using NETINSTALL_NPK or NETINSTALL_PKGS
if [[ -z "$NETINSTALL_NPK" ]]; then
    # Apply logic to match npk names for v6 vs v7
    if [[ ${NETINSTALL_VER} =~ (^6\.) ]]; then
        ARCH_VER_NAME="${NETINSTALL_ARCH}-${NETINSTALL_VER}"
    else
        ARCH_VER_NAME="${NETINSTALL_VER}-${NETINSTALL_ARCH}"
    fi

    # Check and build list of packages
    NPK_ARG=""
    for PKG in $NETINSTALL_PKGS; do
        NPK_FILE="$NPK_DIR$PKG-$ARCH_VER_NAME.npk"
        if test -f $NPK_FILE; then
            echo "[INFO] Found $NPK_FILE"
            NPK_ARG="$NPK_ARG$NPK_FILE ";
        else
            >&2 echo "[WARNING] Unable to find $NPK_FILE skipping"
        fi
    done
else
    echo "Using NETINSTALL_NPK logic"
    if test -f $NETINSTALL_NPK; then
        NPK_ARG=$NETINSTALL_NPK
    else
        echo "Unable to find $NETINSTALL_NPK"
        exit 0
    fi
fi

# Build netinstall command
NETINSTALL_CMD="/app/netinstall-cli $NETINSTALL_ARGS -a $NETINSTALL_ADDR $NPK_ARG"

# Look for the script
exec ls -R /app/

# Detect host arch and execute netinstall
if [[ $(uname -m) =~ (i[1-6]86|amd64) ]]; then
    echo "[INFO] Starting netinstall ($NETINSTALL_CMD)"
    exec $NETINSTALL_CMD
else
    echo "[INFO] Starting netinstall via qemu ($NETINSTALL_CMD)"
    exec /app/qemu-i386-static $NETINSTALL_CMD
fi