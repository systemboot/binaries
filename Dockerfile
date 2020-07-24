FROM centos:8

LABEL BUILD="docker build -t systemboot/binaries -f Dockerfile ."
LABEL RUN="docker run --rm -it -v "${PWD}/build:/work/build" systemboot/binaries"


# enable repo for glibc-static
RUN dnf install -y dnf-plugin-config-manager
RUN dnf config-manager --enable PowerTools
# Install dependencies
RUN dnf install -y \
        git \
        ca-certificates \
        pkg-config \
        autoconf \
        automake \
        cmake \
        make \
        clang \
        glibc-static glibc-devel \
        zlib-static zlib-devel \
        `# to download memtester` \
        wget \
        `# for util-linux` \
        gettext-autopoint bison libtool

WORKDIR /work
COPY build.sh .
CMD ./build.sh
