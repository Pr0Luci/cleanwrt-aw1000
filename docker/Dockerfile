# CleanWRT pinned build environment.
#
# The host toolchain is the biggest uncontrolled input of a "reproducible" firmware
# build. This image pins it: the same container produces the same build anywhere.
#
# Build:   docker build -t cleanwrt-builder docker/
# Run:     docker run --rm -v <abs-path-openwrt-tree>:/build \
#                     -v <abs-path-this-repo>:/cleanwrt \
#                     cleanwrt-builder \
#                     /cleanwrt/tools/cw-release-build.sh /build --clean
#
# The base image is pinned by digest (debian bookworm-slim). To move it:
#   docker pull debian:bookworm-slim
#   docker images --digests debian        # copy the digest into the FROM line

FROM debian@sha256:7ff6ba31527b9e336162fa061746c366c4b2032f4d2cff2078bea43f78efe3f8

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      --no-install-recommends \
      build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
      gettext git libncurses-dev libssl-dev python3 python3-setuptools \
      python3-distutils rsync swig unzip zlib1g-dev file wget zstd texinfo \
      curl ca-certificates jq xz-utils bison flex && \
    rm -rf /var/lib/apt/lists/*

# Some OpenWrt host tools refuse to configure as root.
ENV FORCE_UNSAFE_CONFIGURE=1

# The tree and this repository are bind-mounted from the host and owned by another
# user, so git must trust them.
RUN git config --system --add safe.directory '*'

WORKDIR /build
