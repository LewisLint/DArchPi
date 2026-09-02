FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
        base-devel \
        curl \
        dosfstools \
        e2fsprogs \
        git \
        sudo \
        tar \
        udev \
        util-linux \
        wget \
        xz \
    && useradd --create-home --shell /bin/bash vscode \
    && printf 'vscode ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode \
    && pacman -Scc --noconfirm

WORKDIR /workspaces/DArchPi
USER vscode