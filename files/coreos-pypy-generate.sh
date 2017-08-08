#! /bin/bash

set -ex

set -o  pipefail

cd

PYPY_VER=$1
PYTHON_VER=$2
WGET_URL=$3
WGET_ENV=$4

BIN_DIR=/opt/bin
INSTALL_DIR=/opt/portable-pypy${PYTHON_VER}-${PYPY_VER}
INSTALL_TMP=/opt/portable-pypy${PYTHON_VER}-${PYPY_VER}.tmp
INSTALL_GUARD=${INSTALL_DIR}/.coreos-pypy-installed

machine=$(uname -m)
case ${machine} in
	x86_64 )
		;;
	* )
		echo    "Error: Unknown machine type ${machine}" >&2
        exit    1
		;;
esac

if [ -z "${WGET_URL}" ]; then
    WGET_URL=https://bitbucket.org/squeaky/portable-pypy/downloads/pypy${PYTHON_VER}-${PYPY_VER}-linux_x86_64-portable.tar.bz2
fi

if  [ ! -e "${INSTALL_GUARD}" ]; then
    if  [ -d "${INSTALL_DIR}" ]; then
        rm  -rf "${INSTALL_DIR}"
    fi
    if  [ -d "${INSTALL_TMP}" ]; then
        rm  -rf "${INSTALL_TMP}"
    fi
    mkdir   -p  ${INSTALL_TMP}
    if [ -e "${WGET_URL}" ]; then
        tar -xjf "${WGET_URL}" -C "${INSTALL_TMP}" && {
            for f in "${INSTALL_TMP}"/* ; do
                mv   "${f}" "${INSTALL_DIR}"  && touch   "${INSTALL_GUARD}"
                break   1
            done
        }
    else
        env ${WGET_ENV} wget -O - "${WGET_URL}" | tar -xjf - -C "${INSTALL_TMP}" && {
            for f in "${INSTALL_TMP}"/* ; do
                mv   "${f}" "${INSTALL_DIR}"  && touch   "${INSTALL_GUARD}"
                break   1
            done
        }
    fi
fi

if  [ -d "${INSTALL_TMP}" ]; then
    rm  -rf "${INSTALL_TMP}"
fi

if  [ ! -e "${INSTALL_GUARD}" ]; then
	echo    "Error: pypy install failed" >&2
    exit    2
fi

if  [ ! -e "${BIN_DIR}" ]; then
    mkdir   -p  "${BIN_DIR}"
fi

for f in pypy virtualenv-pypy ; do
    if  [ -e "${BIN_DIR}/${f}" ]; then
        rm  -f  "${BIN_DIR}/${f}"
    fi
    ln  -fs  "${INSTALL_DIR}/bin/${f}"   "${BIN_DIR}/${f}"
done

exit    0