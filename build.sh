#!/usr/bin/env bash
set -exu

BASEDIR="${PWD}"
OUTDIR="${BASEDIR}/build"
KEXEC_TOOLS_VERSION="tags/v2.0.17"
FLASHROM_VERSION="tags/v1.0"
MEMTESTER_VERSION=4.3.0

rm -rf "${OUTDIR}"
mkdir -p "${OUTDIR}"

# build kexec-tools
cd "${OUTDIR}"
git clone git://git.kernel.org/pub/scm/utils/kernel/kexec/kexec-tools.git
cd kexec-tools
git checkout -b "${KEXEC_TOOLS_VERSION}"
./bootstrap
# just optimize for space. Kexec uses kernel headers so we cannot use musl-gcc
# here. See https://wiki.musl-libc.org/faq.html#Q:-Why-am-I-getting- 
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
# no musl-gcc here either, as flashrom needs libpci-dev (we may remove PCI
# programmers from the build at a later stage though)
CFLAGS=-Os make
strip flashrom
du -hs flashrom
ldd flashrom

# build memtester
cd "${OUTDIR}"
wget "http://pyropus.ca/software/memtester/old-versions/memtester-${MEMTESTER_VERSION}.tar.gz"
tar xvzf "memtester-${MEMTESTER_VERSION}".tar.gz
ln -s "memtester-${MEMTESTER_VERSION}" memtester
cd "memtester-${MEMTESTER_VERSION}"
CFLAGS=-Os CC=musl-gcc make # build statically
du -hs memtester
ldd memtester
