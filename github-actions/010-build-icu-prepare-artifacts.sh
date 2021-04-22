#!/bin/bash
set -ex

source $HOME/.build_env

for arch in arm64-v8a armeabi-v7a x86 x86_64
do
	pushd $ICU_LIBS/$arch
		zip -r icu-$arch.zip include/ lib/ *.so
	popd
done