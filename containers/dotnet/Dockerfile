FROM ubuntu:24.04

ARG LAZYGIT_VERSION=0.59.0
ARG DEBIAN_FRONTEND=noninteractive

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    git \
    zsh \
    tmux \
    software-properties-common \
    ca-certificates \
    gpg \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Neovim
RUN add-apt-repository ppa:neovim-ppa/unstable \
    && apt-get update && apt-get install -y --no-install-recommends neovim \
    && rm -rf /var/lib/apt/lists/*

# .NET SDK 8, 9, 10 (via dotnet-install script for arm64 compatibility)
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="$DOTNET_ROOT:$PATH"
RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 8.0 --install-dir "$DOTNET_ROOT" \
    && ./dotnet-install.sh --channel 9.0 --install-dir "$DOTNET_ROOT" \
    && ./dotnet-install.sh --channel 10.0 --quality preview --install-dir "$DOTNET_ROOT" \
    && rm dotnet-install.sh

# lazygit
RUN ARCH=$(dpkg --print-architecture) \
    && curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz" \
    && tar xf lazygit.tar.gz lazygit \
    && install lazygit /usr/local/bin/ \
    && rm lazygit lazygit.tar.gz

# yazi
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then YAZI_ARCH="x86_64"; else YAZI_ARCH="aarch64"; fi \
    && curl -Lo yazi.zip "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${YAZI_ARCH}-unknown-linux-gnu.zip" \
    && unzip yazi.zip \
    && install yazi-${YAZI_ARCH}-unknown-linux-gnu/yazi /usr/local/bin/ \
    && rm -rf yazi.zip yazi-${YAZI_ARCH}-unknown-linux-gnu

# eza
RUN mkdir -p /etc/apt/keyrings \
    && wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" > /etc/apt/sources.list.d/gierens.list \
    && apt-get update && apt-get install -y eza \
    && rm -rf /var/lib/apt/lists/*

# bat
RUN apt-get update && apt-get install -y bat \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

# ripgrep + fd + fzf + direnv
RUN apt-get update && apt-get install -y --no-install-recommends \
    ripgrep \
    fd-find \
    fzf \
    direnv \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# zoxide
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash \
    && cp /root/.local/bin/zoxide /usr/local/bin/

# Create non-root user
RUN useradd -m -s /bin/zsh dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to dev user for user-level setup
USER dev
WORKDIR /home/dev

# Oh-My-Zsh + plugins
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# TPM (Tmux Plugin Manager)
RUN mkdir -p ~/.config/tmux/plugins \
    && git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Dotfiles
RUN git clone https://github.com/tuliopaim/dotfiles-linux.git ~/dotfiles \
    && git clone https://github.com/tuliopaim/nvim.git ~/.config/nvim \
    && ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc \
    && mkdir -p ~/.config/tmux \
    && ln -sf ~/dotfiles/tmux/.tmux.conf ~/.config/tmux/tmux.conf

# Pre-install neovim plugins
RUN nvim --headless "+Lazy! sync" +qa || true

# Pre-install tmux plugins
RUN ~/.config/tmux/plugins/tpm/bin/install_plugins || true

WORKDIR /workspace
ENTRYPOINT ["zsh"]
