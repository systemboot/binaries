#!/usr/bin/env bash
set -exu

BASEDIR="${PWD}"
OUTDIR="${BASEDIR}/build"
KEXEC_TOOLS_VERSION="tags/v2.0.20"
FLASHROM_VERSION="tags/v1.1"
MEMTESTER_VERSION=4.3.0
VPD_VERSION="release-R85-13310.B"

rm -rf "${OUTDIR}"
mkdir -p "${OUTDIR}/binaries"

check_if_statically_linked() {
    f=$1
    # ldd exits with an error if it's not a dynamic executable, so exit 1 here
    # is used as a non-static binary indicator.
    ldd "${f}" && \
        (
            echo "ERROR: $f is not statically linked"
            exit 1
        ) || \
            true # all good
}

# build kexec-tools
cd "${OUTDIR}"
git clone git://git.kernel.org/pub/scm/utils/kernel/kexec/kexec-tools.git
cd kexec-tools
git checkout -b "${KEXEC_TOOLS_VERSION}"
./bootstrap
# just optimize for space. Kexec uses kernel headers so we cannot use musl-gcc
# here. See https://wiki.musl-libc.org/faq.html#Q:-Why-am-I-getting- 
CFLAGS=-Os LDFLAGS=-static ./configure
make
strip build/sbin/kexec
du -hs build/sbin/kexec
check_if_statically_linked build/sbin/kexec
cp build/sbin/kexec "${OUTDIR}/binaries/kexec-${KEXEC_TOOLS_VERSION#tags/}"

# build flashrom
cd "${OUTDIR}"
git clone https://review.coreboot.org/cgit/flashrom.git
cd flashrom
git checkout -b "${FLASHROM_VERSION}"
# no musl-gcc here either, as flashrom needs libpci-dev (we may remove PCI
# programmers from the build at a later stage though)
CONFIG_STATIC=yes \
    CONFIG_ENABLE_LIBPCI_PROGRAMMERS=no \
    CONFIG_ENABLE_LIBUSB1_PROGRAMMERS=no \
    make
strip flashrom
du -hs flashrom
check_if_statically_linked flashrom
cp flashrom "${OUTDIR}/binaries/flashrom-${FLASHROM_VERSION#tags/}"

# build memtester
cd "${OUTDIR}"
wget "http://pyropus.ca/software/memtester/old-versions/memtester-${MEMTESTER_VERSION}.tar.gz"
tar xvzf "memtester-${MEMTESTER_VERSION}".tar.gz
ln -s "memtester-${MEMTESTER_VERSION}" memtester
cd "memtester-${MEMTESTER_VERSION}"
CFLAGS=-Os CC=musl-gcc make # build statically
du -hs memtester
check_if_statically_linked memtester
cp memtester "${OUTDIR}/binaries/memtester-${MEMTESTER_VERSION}"

# build vpd
cd "${OUTDIR}"
git clone https://chromium.googlesource.com/chromiumos/platform/vpd
cd vpd
git checkout "${VPD_VERSION}"
make
# rename vpd_s to vpd for our purposes. This overwrites the original,
# dynamically linked, vpd binary, but we don't need it.
mv vpd_s vpd
strip vpd
du -hs vpd
check_if_statically_linked vpd
cp vpd "${OUTDIR}/binaries/vpd-${VPD_VERSION}"


# Create tarball
cd "${OUTDIR}"
tar czf release.tar.gz \
    "binaries/kexec-${KEXEC_TOOLS_VERSION#tags/}" \
    "binaries/flashrom-${FLASHROM_VERSION#tags/}" \
    "binaries/memtester-${MEMTESTER_VERSION}" \
    "binaries/vpd-${VPD_VERSION}"
tar tzf release.tar.gz
