#!/usr/bin/env bash
set -ex

BASEDIR="${PWD}"
OUTDIR="${BASEDIR}/build"
KEXEC_TOOLS_VERSION="tags/v2.0.17"
FLASHROM_VERSION="tags/v1.0"

rm -rf "${OUTDIR}"
mkdir -p "${OUTDIR}"

# build kexec-tools
cd "${OUTDIR}"
git clone https://github.com/horms/kexec-tools.git
cd kexec-tools
git checkout -b "${KEXEC_TOOLS_VERSION}"
./bootstrap
CFLAGS=-Os ./configure
make
strip build/sbin/kexec
du -hs build/sbin/kexec
ldd build/sbin/kexec

# build flashrom
cd "${OUTDIR}"
git clone https://review.coreboot.org/cgit/flashrom.git
cd flashrom
git checkout -b "${FLASHROM_VERSION}"
make
strip flashrom
du -hs flashrom
ldd flashrom
