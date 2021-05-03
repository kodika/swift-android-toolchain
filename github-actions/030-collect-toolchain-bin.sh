#!/bin/bash
set -ex

source $HOME/.build_env

toolchain_version=`cat build/config/version`
name=swift-android-$toolchain_version

out_bin=~/toolchain-bin
out_bin=`realpath $out_bin`
mkdir -p $out_bin

cp -f /usr/local/bin/pkg-config $out_bin
cp -f /usr/local/bin/ninja $out_bin

rsync -av $SWIFT_SRC/build/Ninja-ReleaseAssert+stdlib-Release/swift-macosx-x86_64/bin/ $out_bin \
        --include swift \
        --include swift-autolink-extract \
        --include swift-stdlib-tool \
        --include swiftc \
        --include swift-frontend \
        --exclude '*'

pushd $HOME
    tar -cvf swift-android-$name-bin.tar toolchain-bin
popd
