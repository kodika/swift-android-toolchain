#!/bin/bash
set -ex

source $HOME/.build_env
function finish {
    exit_code=$?
    set +e
    unlink $DST_ROOT/swift-nightly-install/usr/lib/swift
    exit $exit_code
}
trap finish EXIT

self_dir=$(realpath $(dirname $0))

arch=$1 # arm64 arm x86 x86_64
swift_arch=$2 # aarch64 armv7 x86 i686
abi=$3 # arm64-v8a armeabi-v7a x86 x86_64

dispatch_build_dir=/tmp/swift-corelibs-libdispatch-$arch
foundation_build_dir=/tmp/foundation-$arch
xctest_build_dir=/tmp/xctest-$arch
crypto_build_dir=/tmp/swift-crypto-$arch

foundation_dependencies=$FOUNDATION_DEPENDENCIES/$arch
icu_libs=$ICU_LIBS/$abi

rm -rf $dispatch_build_dir
rm -rf $foundation_build_dir
rm -rf $xctest_build_dir
rm -rf $crypto_build_dir

mkdir -p $dispatch_build_dir
mkdir -p $foundation_build_dir
mkdir -p $xctest_build_dir
mkdir -p $crypto_build_dir

ln -sfn $DST_ROOT/swift-nightly-install/usr/lib/swift-$swift_arch $DST_ROOT/swift-nightly-install/usr/lib/swift

pushd $dispatch_build_dir
    cmake $DISPATCH_SRC \
        -G Ninja \
        -C $self_dir/common-flags.cmake \
        -C $self_dir/common-flags-$arch.cmake \
        \
        -DENABLE_SWIFT=YES 

    cmake --build $dispatch_build_dir
popd

pushd $foundation_build_dir
    cmake $FOUNDATION_SRC \
        -G Ninja \
        -C $self_dir/common-flags.cmake \
        -C $self_dir/common-flags-$arch.cmake \
        \
        -Ddispatch_DIR=$dispatch_build_dir/cmake/modules \
        \
        -DICU_INCLUDE_DIR=$icu_libs/include \
        -DICU_UC_LIBRARY=$icu_libs/libicuucswift.so \
        -DICU_UC_LIBRARY_RELEASE=$icu_libs/libicuucswift.so \
        -DICU_I18N_LIBRARY=$icu_libs/libicui18nswift.so \
        -DICU_I18N_LIBRARY_RELEASE=$icu_libs/libicui18nswift.so \
        \
        -DCURL_LIBRARY=$foundation_dependencies/lib/libcurl.so \
        -DCURL_INCLUDE_DIR=$foundation_dependencies/include \
        \
        -DLIBXML2_LIBRARY=$foundation_dependencies/lib/libxml2.so \
        -DLIBXML2_INCLUDE_DIR=$foundation_dependencies/include/libxml2 \
        \
        -DCMAKE_HAVE_LIBC_PTHREAD=YES

    cmake --build $foundation_build_dir
popd

pushd $xctest_build_dir
    cmake $XCTEST_SRC \
        -G Ninja \
        -C $self_dir/common-flags.cmake \
        -C $self_dir/common-flags-$arch.cmake \
        \
        -DENABLE_TESTING=NO \
        -Ddispatch_DIR=$dispatch_build_dir/cmake/modules \
        -DFoundation_DIR=$foundation_build_dir/cmake/modules

    cmake --build $xctest_build_dir
popd

pushd $crypto_build_dir
    cmake $CRYPTO_SRC \
        -G Ninja \
        -C $self_dir/common-flags.cmake \
        -C $self_dir/common-flags-$arch.cmake \
        -Ddispatch_DIR=$dispatch_build_dir/cmake/modules \
        -DFoundation_DIR=$foundation_build_dir/cmake/modules

    cmake --build $crypto_build_dir
popd

dispatch_build_dir=/tmp/swift-corelibs-libdispatch-$arch
foundation_build_dir=/tmp/foundation-$arch
xctest_build_dir=/tmp/xctest-$arch

ln -sfn $DST_ROOT/swift-nightly-install/usr/lib/swift-$swift_arch $DST_ROOT/swift-nightly-install/usr/lib/swift

# We need to install dispatch at the end because it is impossible to build foundation after dispatch installed
cmake --build $dispatch_build_dir --target install
cmake --build $foundation_build_dir --target install
cmake --build $xctest_build_dir --target install
cmake --build $crypto_build_dir --target install

# Copy dependency headers and libraries
swift_include=$DST_ROOT/swift-nightly-install/usr/lib/swift-$swift_arch
dst_libs=$DST_ROOT/swift-nightly-install/usr/lib/swift-$swift_arch/android

rsync -av $ANDROID_NDK/sources/cxx-stl/llvm-libc++/libs/$abi/libc++_shared.so $dst_libs

rsync -av $icu_libs/libicu{uc,i18n,data}swift.so $dst_libs
rsync -av $foundation_dependencies/lib/libcrypto.a $dst_libs
rsync -av $foundation_dependencies/lib/libssl.a $dst_libs
rsync -av $foundation_dependencies/lib/libcurl.* $dst_libs
rsync -av $foundation_dependencies/lib/libxml2.* $dst_libs

cp -r $icu_libs/include/unicode $swift_include
cp -r $foundation_dependencies/include/openssl $swift_include
cp -r $foundation_dependencies/include/libxml2/libxml $swift_include
cp -r $foundation_dependencies/include/curl $swift_include
