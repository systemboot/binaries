#!/usr/bin/env bash
set -exu

BASEDIR="${PWD}"
BUILDDIR="${BASEDIR}/build"
KEXEC_TOOLS_VERSION="v2.0.20"
PCIUTILS_VERSION="v3.7.0"
FLASHROM_VERSION="95d822e342d48bea27fb3a606b1670994c3ce5d0" # prerelease for new hardware
MEMTESTER_VERSION="4.3.0"
UTILLINUX_VERSION="v2.36"
VPD_VERSION="release-R85-13310.B"

#rm -rf "${BUILDDIR}"/*
mkdir -p "${BUILDDIR}/binaries"

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
cd "${BUILDDIR}"
git clone git://git.kernel.org/pub/scm/utils/kernel/kexec/kexec-tools.git
cd kexec-tools
git checkout "${KEXEC_TOOLS_VERSION}"
./bootstrap
# just optimize for space. Kexec uses kernel headers so we cannot use musl-gcc
# here. See https://wiki.musl-libc.org/faq.html#Q:-Why-am-I-getting- 
CFLAGS=-Os LDFLAGS=-static ./configure || (cat config.log ; exit 1)
make
strip build/sbin/kexec
du -hs build/sbin/kexec
check_if_statically_linked build/sbin/kexec
cp build/sbin/kexec "${BUILDDIR}/binaries/kexec-${KEXEC_TOOLS_VERSION}"

# build pciutils statically without udev support

cd "${BUILDDIR}"
git clone https://github.com/pciutils/pciutils.git
cd pciutils
git checkout "${PCIUTILS_VERSION}"
make HWDB=no SHARED=no
make install-lib

# build flashrom
cd "${BUILDDIR}"
git clone https://review.coreboot.org/cgit/flashrom.git
cd flashrom
git checkout "${FLASHROM_VERSION}"

# no musl-gcc here either, as flashrom needs libpci-dev
CONFIG_STATIC=yes \
    CONFIG_ENABLE_LIBPCI_PROGRAMMERS=yes \
    CONFIG_ENABLE_LIBUSB0_PROGRAMMERS=no \
    CONFIG_ENABLE_LIBUSB1_PROGRAMMERS=no \
    CONFIG_INTERNAL=yes \
    make || (cat build_details.txt ; exit 1)
strip flashrom
du -hs flashrom
check_if_statically_linked flashrom
cp flashrom "${BUILDDIR}/binaries/flashrom-${FLASHROM_VERSION}"

# build memtester
cd "${BUILDDIR}"
wget "http://pyropus.ca/software/memtester/old-versions/memtester-${MEMTESTER_VERSION}.tar.gz"
tar xvzf "memtester-${MEMTESTER_VERSION}".tar.gz
ln -s "memtester-${MEMTESTER_VERSION}" memtester
cd "memtester-${MEMTESTER_VERSION}"
CFLAGS=-Os CC=musl-gcc make # build statically
du -hs memtester
check_if_statically_linked memtester
cp memtester "${BUILDDIR}/binaries/memtester-${MEMTESTER_VERSION}"

# CentOS does not provide static libuuid, so we have to build it on our own :(
# libuuid is part of the LARGE util-linux package.
cd "${BUILDDIR}"
git clone https://github.com/karelzak/util-linux.git
cd util-linux
git checkout "${UTILLINUX_VERSION}"
./autogen.sh
./configure --without-udev --disable-all-programs --enable-libuuid
make LDFLAGS="--static"
make install

# build vpd
cd "${BUILDDIR}"
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
cp vpd "${BUILDDIR}/binaries/vpd-${VPD_VERSION}"


# Create tarball
cd "${BUILDDIR}"
tar czf release.tar.gz \
    "binaries/kexec-${KEXEC_TOOLS_VERSION}" \
    "binaries/flashrom-${FLASHROM_VERSION}" \
    "binaries/memtester-${MEMTESTER_VERSION}" \
    "binaries/vpd-${VPD_VERSION}"
echo "Current working directory: $PWD"
tar tvzf release.tar.gz
