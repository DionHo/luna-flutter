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
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        liblzma-dev \
        libstdc++-12-dev \
        unzip \
        xz-utils \
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
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

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
