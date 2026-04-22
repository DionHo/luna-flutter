FROM mcr.microsoft.com/devcontainers/base:noble

# Flutter Linux desktop build dependencies (matches flutter doctor requirements)
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        liblzma-dev \
        libstdc++-12-dev \
        curl \
        unzip \
        xz-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Flutter SDK — cloned from the stable channel and pre-warmed for Linux
# Override FLUTTER_CHANNEL at build time to pin a specific release tag.
ARG FLUTTER_CHANNEL=stable
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --depth 1 --branch "${FLUTTER_CHANNEL}" \
        https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
    && flutter precache --linux \
    && chown -R vscode:vscode "${FLUTTER_HOME}"
