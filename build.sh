#!/usr/bin/env bash

# From https://github.com/gudzpoz/luajava/blob/main/luajit/jni/scripts/build-android.sh
# From https://github.com/mjansson/lua_lib/blob/master/lua/luajit/build-android.sh
# Fixed https://github.com/LuaJIT/LuaJIT/issues/440#issuecomment-438809840

LUAJIT_SRC=src
OPT_DIR=opt

export ANDROID_NDK_HOME=/Users/mac/Library/Android/sdk/ndk/27.0.12077973


# 检查 NDK 环境变量
if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$ANDROID_NDK_LATEST_HOME" ]; then
    echo "错误: 未设置 ANDROID_NDK_HOME 或 ANDROID_NDK_LATEST_HOME 环境变量!}"
    exit 1
fi

NDK="${ANDROID_NDK_HOME:-$ANDROID_NDK_LATEST_HOME}"
echo "Using NDK: $NDK"

# 清理并准备输出目录
echo "########## Cleaning up ##########"
rm -rf $OPT_DIR
mkdir -p $OPT_DIR
rm *.a 1>/dev/null 2>/dev/null

HOST_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/$HOST_OS-x86_64
NDKB=$TOOLCHAIN/bin
NDKAPI=26


echo "########## Building arm64-v8a ##########"
TARGET=aarch64-linux-android
NDKP=$NDKB/${TARGET}-
NDKCC=$NDKB/${TARGET}${NDKAPI}-clang
NDKARCH="-Os -DLUAJIT_ENABLE_LUA52COMPAT -DLUAJIT_ENABLE_GC64=1 \
-DLJ_ABI_SOFTFP=0 -DLJ_ARCH_HASFPU=1 -DNO_RTLD_DEFAULT=1 -march=armv8-a"

# 编译 LuaJIT
echo "########## Running make ##########"
make -j$(nproc) HOST_CC="gcc -m64" CROSS="$NDKP" \
     STATIC_CC="$NDKCC" DYNAMIC_CC="$NDKCC -fPIC" \
     TARGET_LD="$NDKCC" TARGET_AR="$NDKB/llvm-ar rcus" TARGET_STRIP="$NDKB/llvm-strip" \
     CFLAGS="-fPIC" TARGET_FLAGS="$NDKARCH" TARGET_SYS=Android \
     clean amalg


# 移动结果文件到目标目录
echo "########## Moving result ##########"
mkdir -p "$OPT_DIR/arm64-v8a"
mv "$LUAJIT_SRC/libluajit.a" "$OPT_DIR/arm64-v8a/libluajit.a"
mv "$LUAJIT_SRC/libluajit.so" "$OPT_DIR/arm64-v8a/libluajit.so"
echo "构建完成!"
