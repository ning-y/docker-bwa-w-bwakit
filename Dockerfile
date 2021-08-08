FROM alpine:3.12.0

# zlib-dev for bwa, perl for bwakit, python2 for V8 (for K8, for bwa-postalt.js)
RUN apk add --update-cache build-base zlib-dev perl python2

## INSTALL BWA
# For this release of bwa we must use alpine 3.12.0 for gcc 9.3.0-r2, because
# alpine > 3.13.0's gcc 10 breaks bwa compilation
# (https://github.com/lh3/bwa/issues/275). Using alpine > 3.13.0 and trying a
# version-specific installation of gcc seems to break dependencies.
RUN wget https://github.com/lh3/bwa/releases/download/v0.7.17/bwa-0.7.17.tar.bz2
RUN tar -xf bwa-0.7.17.tar.bz2
WORKDIR /bwa-0.7.17
ENV PATH="/bwa-0.7.17:/bwa-0.7.17/bwakit:${PATH}"

## INSTALL seqtk
# bwakit/run-bwamem outputs a shell command which uses seqtk
WORKDIR /
RUN wget https://github.com/lh3/seqtk/archive/refs/tags/v1.3.tar.gz
RUN tar -xf v1.3.tar.gz
WORKDIR /seqtk-1.3
RUN make
ENV PATH="/seqtk-1.3:${PATH}"

## INSTALL K8
# k8 is a javascript engine required for bwakit/bwa-postalt.js
WORKDIR /
RUN wget https://github.com/attractivechaos/k8/releases/download/0.2.5/k8-0.2.5.tar.bz2
RUN tar -xf k8-0.2.5.tar.bz2
WORKDIR /k8-0.2.5
# These instructions are from the k8 README, except I use x64.debug as the V8
# build target instead of x64.release, because the latter gave me a segfault,
# and https://bugs.chromium.org/p/v8/issues/detail?id=2195 suggested that making
# x64.debug could be a fix --- and it did fix the segfault.
RUN wget -O- https://github.com/attractivechaos/k8/releases/download/v0.2.1/v8-3.16.4.tar.bz2 | tar jxf -
RUN cd v8-3.16.4 && make -j4 x64.debug
WORKDIR /k8-0.2.5/v8-3.16.4
RUN g++ -O2 -Wall -o k8 -Iinclude ../k8.cc -lpthread -lz `find out -name "libv8_base.a"` `find out -name "libv8_snapshot.a"`
ENV PATH="/k8-0.2.5/v8-3.16.4:${PATH}"

WORKDIR /
