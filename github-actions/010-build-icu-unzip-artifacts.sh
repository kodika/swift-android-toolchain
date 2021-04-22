#!/bin/bash
set -ex

source $HOME/.build_env

arch=$1

pushd $ICU_LIBS/$arch
	unzip icu-$arch.zip
popd