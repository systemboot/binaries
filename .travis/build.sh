#!/usr/bin/env bash
set -e

BASEDIR="${PWD}"
KEXEC_TOOLS_VERSION=tags/v2.0.17

git clone https://github.com/horms/kexec-tools.git
cd kexec-tools
git checkout -b "${KEXEC_TOOLS_VERSION}"
./bootstrap
./configure
make
strip build/sbin/*
