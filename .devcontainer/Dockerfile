# Slim base: ubuntu:24.04 instead of mcr.microsoft.com/devcontainers/base:noble
# This drops ~600 MB of devcontainers tooling (nvm, Node.js, oh-my-zsh) that
# a Flutter-only environment does not need.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Core devcontainer requirements + Flutter Linux desktop build dependencies.
# curl/ca-certificates are required by both the devcontainers CLI (VS Code
# server bootstrap) and flutter's first-run SDK download.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash sudo git curl ca-certificates \
    wget gnupg \
        clang \
        cmake \
        ninja-build \
        pkg-config \
    openjdk-17-jdk \
        libgtk-3-dev \
        liblzma-dev \
        libstdc++-12-dev \
        unzip \
        xz-utils \
        # sqflite (SQLite Flutter plugin) needs the dev headers at link time
        libsqlite3-dev \
        # audioplayers_linux uses GStreamer for audio playback
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        gstreamer1.0-plugins-good \
        # nobodywho (flutter_rust_bridge / llama.cpp) requires the LLVM LLD linker
        # and llvm-ar for the Rust build toolchain
        lld \
        llvm \
        # mesa-utils provides eglinfo, fixing the flutter doctor warning
        mesa-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create the "vscode" user (UID 1000) that the devcontainers CLI expects.
# ubuntu:24.04 ships with a built-in "ubuntu" user at UID 1000, so we
# remove it first, then create the "vscode" user in its place.
# The CLI's updateUID step remaps this UID to match the host user and
# re-owns /home/vscode, but intentionally skips large trees like /opt/flutter.
RUN userdel -r ubuntu \
    && useradd -m -s /bin/bash -u 1000 vscode \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

# Flutter SDK — cloned from the stable channel.
# flutter precache --linux is intentionally omitted here: the ~1.2 GB of
# engine artifacts would bloat the image; they are fetched on first build.
# Override FLUTTER_CHANNEL at build time to pin a specific release tag.
ARG FLUTTER_CHANNEL=stable
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

RUN git clone --depth 1 --branch "${FLUTTER_CHANNEL}" \
        https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
    # Make the SDK world-readable/writable so any UID can use it — the
    # devcontainers CLI remaps the vscode UID but does NOT re-own large
    # directories outside of /home/vscode.  Using chmod instead of chown
    # sidesteps that entirely.  This is appropriate for a single-user
    # dev container where the SDK is a shared runtime, not user data.
    && chmod -R a+rwX "${FLUTTER_HOME}"

# System-wide safe.directory entry written to /etc/gitconfig.
# This survives the devcontainers UID remap: /opt/flutter stays owned by
# UID 1000 after the remap, but /etc/gitconfig is untouched and still allows
# git operations for the remapped vscode user.
RUN git config --system --add safe.directory "${FLUTTER_HOME}"

# Android SDK command-line tools + core build components.
# Installs platform-tools, build-tools, and Android platform 36 so Android
# builds work in the devcontainer without extra manual setup.
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && cd /tmp \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -O cmdline-tools.zip \
    && unzip -q cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
    && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
    && yes | sdkmanager --licenses > /dev/null \
    && sdkmanager --install \
        "platform-tools" \
        "platforms;android-36" \
        "build-tools;36.0.0" \
        "ndk;28.2.13676358" \
        "cmake;3.22.1" \
    && chmod -R a+rwX "${ANDROID_HOME}" \
    && rm -f /tmp/cmdline-tools.zip

# GitHub CLI — used by build_windows_cross.sh to trigger the GitHub Actions
# Windows build workflow and download the resulting artifact.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
