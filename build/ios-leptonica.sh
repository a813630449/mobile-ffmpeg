#!/bin/bash

if [[ -z ${ARCH} ]]; then
    echo -e "(*) ARCH not defined\n"
    exit 1
fi

if [[ -z ${IOS_MIN_VERSION} ]]; then
    echo -e "(*) IOS_MIN_VERSION not defined\n"
    exit 1
fi

if [[ -z ${TARGET_SDK} ]]; then
    echo -e "(*) TARGET_SDK not defined\n"
    exit 1
fi

if [[ -z ${SDK_PATH} ]]; then
    echo -e "(*) SDK_PATH not defined\n"
    exit 1
fi

if [[ -z ${BASEDIR} ]]; then
    echo -e "(*) BASEDIR not defined\n"
    exit 1
fi

# ENABLE COMMON FUNCTIONS
. ${BASEDIR}/build/ios-common.sh

# PREPARING PATHS & DEFINING ${INSTALL_PKG_CONFIG_DIR}
LIB_NAME="leptonica"
set_toolchain_clang_paths ${LIB_NAME}

# PREPARING FLAGS
TARGET_HOST=$(get_target_host)
export CFLAGS="$(get_cflags ${LIB_NAME})"
export CXXFLAGS="$(get_cxxflags ${LIB_NAME})"
export CPPFLAGS="-I${BASEDIR}/prebuilt/ios-$(get_target_build_directory)/giflib/include"
export LDFLAGS="$(get_ldflags ${LIB_NAME}) -L${BASEDIR}/prebuilt/ios-$(get_target_build_directory)/giflib/lib -lgif"
export PKG_CONFIG_LIBDIR="${INSTALL_PKG_CONFIG_DIR}"

export LIBPNG_CFLAGS="$(pkg-config --cflags libpng)"
export LIBPNG_LIBS="$(pkg-config --libs --static libpng)"

export LIBWEBP_CFLAGS="$(pkg-config --cflags libwebp)"
export LIBWEBP_LIBS="$(pkg-config --libs --static libwebp)"

export LIBTIFF_CFLAGS="$(pkg-config --cflags libtiff-4)"
export LIBTIFF_LIBS="$(pkg-config --libs --static libtiff-4)"

export ZLIB_CFLAGS="$(pkg-config --cflags zlib)"
export ZLIB_LIBS="$(pkg-config --libs --static zlib)"

export JPEG_CFLAGS="$(pkg-config --cflags libjpeg)"
export JPEG_LIBS="$(pkg-config --libs --static libjpeg)"

cd ${BASEDIR}/src/${LIB_NAME} || exit 1

make distclean 2>/dev/null 1>/dev/null

# RECONFIGURING IF REQUESTED
if [[ ${RECONF_leptonica} -eq 1 ]]; then
    autoreconf_library ${LIB_NAME}
fi

./configure \
    --prefix=${BASEDIR}/prebuilt/ios-$(get_target_build_directory)/${LIB_NAME} \
    --with-pic \
    --with-zlib \
    --with-libpng \
    --with-jpeg \
    --with-giflib \
    --with-libtiff \
    --with-libwebp \
    --enable-static \
    --disable-shared \
    --disable-fast-install \
    --disable-programs \
    --host=${TARGET_HOST} || exit 1

make ${MOBILE_FFMPEG_DEBUG} -j$(get_cpu_count) || exit 1

# MANUALLY COPY PKG-CONFIG FILES
cp lept.pc ${INSTALL_PKG_CONFIG_DIR}

make install || exit 1
