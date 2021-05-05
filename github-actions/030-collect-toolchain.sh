#!/bin/bash
set -ex

source $HOME/.build_env

toolchain_version=`cat build/config/version`
name=swift-android-$toolchain_version

out=$HOME/out/$name
out_toolchain=$out/toolchain
out_bin=$out_toolchain/usr/bin
out_lib=$out_toolchain/usr/lib

mkdir -p $out
mkdir -p $out_toolchain
mkdir -p $out_bin
mkdir -p $out_lib

input_bin=$HOME/toolchain-bin
input_arm64_v8a_libs=$HOME/swift-android-5.4-arm64-v8a-libs
input_armeabi_v7a_libs=$HOME/swift-android-5.4-armeabi-v7a-libs
input_x86_libs=$HOME/swift-android-5.4-x86-libs
input_x86_64_libs=$HOME/swift-android-5.4-x86_64-libs
input_clang_libs=$HOME/swift-android-5.4-clang-libs

pushd $out

    # Copy binn from mac os toolchain
    rsync -av $input_bin $out_bin

    # Copy clanng headers
    rsync -av $input_clang_libs $out_lib \
        --exclude '/10.0.0/lib' \

    # Copy platform libraries
    rsync -av $input_arm64_v8a_libs $out_lib
    rsync -av $input_armeabi_v7a_libs $out_lib
    rsync -av $input_x86_libs $out_lib
    rsync -av $input_x86_64_libs $out_lib

    # Bundle NDK headers
    mkdir -p $out_toolchain/ndk-android-21/usr
    rsync -av $ANDROID_NDK/sysroot/usr/include $out_toolchain/ndk-android-21/usr

    # Patch Glibc module
    for swift_arch in aarch64 armv7 x86_64 i686
    do
        glibc_modulemap="$out_toolchain/usr/lib/swift-$swift_arch/android/$swift_arch/glibc.modulemap"

        if [[ ! -f "$glibc_modulemap.orig" ]]
        then
            cp "$glibc_modulemap" "$glibc_modulemap.orig"
        fi

        sed -e 's@/home/runner/android-ndk-r21e/toolchains/llvm/prebuilt/linux-x86_64/sysroot@../../../../../ndk-android-21@' < "$glibc_modulemap.orig" > "$glibc_modulemap"
    done
popd

rsync -av shims/`uname`/ $out_toolchain
rsync -av src/tools/ $out

echo $toolchain_version > $out/VERSION

pushd $(dirname $out)
    zip -y -r $name.zip $name
popd

