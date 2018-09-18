#!/usr/bin/env bash
set -x -e

########################################
# download & build depend software
########################################

WORK_DIR=`pwd`
DEPS_SOURCE=`pwd`/thirdsrc
DEPS_PREFIX=`pwd`/thirdparty
DEPS_CONFIG="--prefix=${DEPS_PREFIX} --disable-shared --with-pic"
FLAG_DIR=`pwd`/.build

export PATH=${DEPS_PREFIX}/bin:$PATH
mkdir -p ${DEPS_SOURCE} ${DEPS_PREFIX} ${FLAG_DIR}

cd ${DEPS_SOURCE}

# protobuf
if [ ! -f "${FLAG_DIR}/protobuf" ] \
    || [ ! -f "${DEPS_PREFIX}/lib/libprotobuf.a" ] \
    || [ ! -d "${DEPS_PREFIX}/include/google/protobuf" ]; then
    git clone https://github.com/protocolbuffers/protobuf.git
    cd protobuf
    git checkout v3.6.1
    git checkout -b 3_6_1
    autoreconf -ivf
    ./configure ${DEPS_CONFIG}
    make -j8
    make install
    cd -
    touch8 "${FLAG_DIR}/protobuf"
fi

# gflags
if [ ! -f "${FLAG_DIR}/gflags" ] \
    || [ ! -f "${DEPS_PREFIX}/lib/libgflags.a" ] \
    || [ ! -d "${DEPS_PREFIX}/include/gflags" ]; then
    git clone https://github.com/gflags/gflags.git
    cd gflags
    git checkout v2.2.1
    git checkout -b 2_2_1
    cmake -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX} -DGFLAGS_NAMESPACE=google -DCMAKE_CXX_FLAGS=-fPIC
    make -j8
    make install
    cd -
    touch "${FLAG_DIR}/gflags"
fi

# grpc
if [ ! -f "${FLAG_DIR}/grpc" ]; then
    git clone https://github.com/grpc/grpc.git
    cd grpc
    git checkout v1.15.0
    git checkout -b 1_15_0
    git submodule update --init
    make -j8
    cd -1
    touch "${FLAG_DIR}/grpc"
fi

# gtest
if [ ! -f "${FLAG_DIR}/gtest" ]; then
    git clone https://github.com/google/googletest.git
    cd googletest
    git checkout release-1.8.1
    git checkout -b 1_8_1
    autoreconf -ivf
    ./configure ${DEPS_CONFIG}
    make -j8
    cp -a googletest/lib/* ${DEPS_PREFIX}/lib
    cp -a googlemock/lib/* ${DEPS_PREFIX}/lib
    cp -a googletest/include/gtest ${DEPS_PREFIX}/include
    cp -a googlemock/include/gmock ${DEPS_PREFIX}/include
    cd -
    touch "${FLAG_DIR}/gtest"
fi

# rocksdb
if [ ! -f "${FLAG_DIR}/rocksdb" ] \
    || [ ! -f "${DEPS_PREFIX}/lib/librocksdb.a" ] \
    || [ ! -d "${DEPS_PREFIX}/include/rocksdb" ]; then
    git clone https://github.com/facebook/rocksdb.git
    git checkout v5.15.10
    git checkout -b 5_15_10
    make shared_lib -j8
    cp -a librocksdb.so.5.15.10 ${DEPS_PREFIX}/lib/librocksdb.so
    cp -a include/rocksdb ${DEPS_PREFIX}/include
    cd -
    touch "${FLAG_DIR}/rocksdb"
fi

cd ${WORK_DIR}

########################################
# config depengs.mk
########################################

echo "PROTOBUF_PATH=./thirdparty" >> depends.mk
echo "PROTOC_PATH=./thirdparty/bin/" >> depends.mk
echo 'PROTOC=$(PROTOC_PATH)protoc' >> depends.mk
echo "GRPC_PATH=./thirdparty" >> depends.mk
echo "GFLAG_PATH=./thirdparty" >> depends.mk
echo "GTEST_PATH=./thirdparty" >> depends.mk

########################################
# build ColaKV
########################################

make clean
make -j4
