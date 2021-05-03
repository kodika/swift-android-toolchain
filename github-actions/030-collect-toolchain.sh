#!/bin/bash
set -ex

toolchain_version=`cat build/config/version`
name=swift-android-$toolchain_version

out=out/$name
out_toolchain=$out/toolchain
out_bin=$out_toolchain/usr/bin
out_lib=$out_toolchain/usr/lib

mkdir -p $out
mkdir -p $out_toolchain
mkdir -p $out_bin

pushd $HOME
    tar -xvf swift-android-5.4-bin.tar
popd

input_bin=~/swift-android-5.4-bin
input_arm64-v8a_libs=~/swift-android-5.4-arm64-v8a-libs
input_armeabi-v7a_libs=~/swift-android-5.4-armeabi-v7a-libs
input_x86_libs=~/swift-android-5.4-x86-libs
input_x86_64_libs=~/swift-android-5.4-x86_64-libs
input_clang_libs=~/swift-android-5.4-clang-libs

pushd $linux_out
    mkdir -p usr/bin

    rsync -av $input_bin $out_bin \
        --include swift \
        --include swift-autolink-extract \
        --include swift-stdlib-tool \
        --include swiftc \
        --include swift-frontend \
        --exclude '*'

    rsync -av $input_clang_libs $out_lib \
        --exclude '/lib' \

    rsync -av $input_arm64-v8a_libs $out_lib
    rsync -av $input_armeabi-v7a_libs $out_lib
    rsync -av $input_x86_libs $out_lib
    rsync -av $input_x86_64_libs $out_lib

    ## Bundle NDK headers and patch glibc
    mkdir -p $out_toolchain/ndk-android-21/usr
    rsync -av $ANDROID_NDK/sysroot/usr/include $out_toolchain/ndk-android-21/usr

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

