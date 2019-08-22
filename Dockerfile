# Pull base image.
FROM openjdk:jdk-alpine

MAINTAINER Dominik Hahn <dominik@monostream.com>
MAINTAINER Cedric Gatay <c.gatay@code-troopers.com>

# Set ENV
ENV ANDROID_SDK_VERSION=r29.0.2
ENV ANDROID_BUILD_TOOLS_VERSION=build-tools-22.0.1,build-tools-23.0.3,build-tools-24.0.3,build-tools-25.0.3,build-tools-26.0.2,build-tools-27.0.3,build-tools-29.0.2
ENV ANDROID_SDK_FILENAME=tools_${ANDROID_SDK_VERSION}-linux.zip
ENV ANDROID_SDK_URL=https://dl.google.com/android/repository/${ANDROID_SDK_FILENAME}
ENV ANDROID_API_LEVELS=android-17,android-18,android-19,android-20,android-21,android-22,android-23,android-24,android-25,android-26,android-27
ENV ANDROID_HOME=/usr/local/bin/android-sdk-linux
ENV PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

# https://github.com/frol/docker-alpine-glibc/blob/master/Dockerfile
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.25-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

ENV LANG=C.UTF-8

# Install dependencies and Android SDK
RUN apk add --quiet --no-cache libstdc++ bash && \
    apk add --quiet --no-cache --virtual build-dependencies curl unzip&& \
    curl --create-dirs -sSLo ${ANDROID_HOME}/${ANDROID_SDK_FILENAME} ${ANDROID_SDK_URL} && \
    unzip -q ${ANDROID_HOME}/${ANDROID_SDK_FILENAME} -d ${ANDROID_HOME} && \
    rm -rf ${ANDROID_HOME}/${ANDROID_SDK_FILENAME} && \
    (while sleep 3; do echo "y"; done) | android -s --clear-cache update sdk --no-ui --force --all --filter tools,platform-tools,${ANDROID_BUILD_TOOLS_VERSION},${ANDROID_API_LEVELS},extra-android-m2repository,extra-google-m2repository && \
    apk del build-dependencies && \
    rm -rf /var/cache/* /tmp/*

# This accepts the licenses, please keep that in mind, you have to conform to the license.
RUN mkdir -p "$ANDROID_HOME/licenses" &&\
    echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e" > "$ANDROID_HOME/licenses/android-sdk-license" &&\
    echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license"
