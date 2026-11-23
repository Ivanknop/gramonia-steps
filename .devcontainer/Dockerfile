FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG FLUTTER_CHANNEL=stable
ARG ANDROID_CMDLINE_TOOLS=13114758
# Lo que usa el build hoy: compileSdk 37 (lo pide permission_handler) y 36
# (lo usan los plugins de Flutter), más las herramientas que pide Gradle.
ARG ANDROID_PLATFORMS="platforms;android-37.0 platforms;android-36"
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK=28.2.13676358
ARG ANDROID_CMAKE=3.22.1

ENV DEBIAN_FRONTEND=noninteractive \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/home/vscode/.pub-cache
ENV PATH=${FLUTTER_HOME}/bin:${PUB_CACHE}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-17-jdk-headless curl git unzip xz-utils zip ca-certificates \
        libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev \
        python3-pil python3-numpy python3-scipy webp \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && curl -fsSL -o /tmp/cmdtools.zip \
       https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip \
    && unzip -q /tmp/cmdtools.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm /tmp/cmdtools.zip \
    && yes | sdkmanager --licenses > /dev/null \
    && sdkmanager --install "platform-tools" ${ANDROID_PLATFORMS} \
       "build-tools;${ANDROID_BUILD_TOOLS}" "ndk;${ANDROID_NDK}" "cmake;${ANDROID_CMAKE}"

RUN git clone --depth 1 -b ${FLUTTER_CHANNEL} https://github.com/flutter/flutter.git ${FLUTTER_HOME}

RUN chown -R vscode:vscode ${FLUTTER_HOME} ${ANDROID_HOME}

USER vscode
RUN git config --global --add safe.directory ${FLUTTER_HOME} \
    && flutter config --no-analytics --enable-android --no-enable-web --no-enable-linux-desktop \
    && flutter precache --android \
    && yes | flutter doctor --android-licenses > /dev/null \
    && flutter doctor -v || true