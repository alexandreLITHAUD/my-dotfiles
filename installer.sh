#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logger function
log() {
    echo -e "${GREEN}[+]${NC} $1"
}

error() {
    echo -e "${RED}[!]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    elif [ "$(uname)" = "Darwin" ]; then
        OS="macOS"
    else
        OS="Unknown"
    fi
    log "Detected OS: $OS"
}

# Check and install dependencies
install_dependencies() {
    local packages=("git" "zsh" "tmux")
    
    case $OS in
        "macOS")
            if ! command -v brew &> /dev/null; then
                log "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            for package in "${packages[@]}"; do
                if ! command -v $package &> /dev/null; then
                    log "Installing $package..."
                    brew install $package
                fi
            done
            ;;
        "Ubuntu"|"Debian"|"Linux Mint")
            sudo apt-get update
            for package in "${packages[@]}"; do
                if ! command -v $package &> /dev/null; then
                    log "Installing $package..."
                    sudo apt-get install -y $package
                fi
            done
            ;;
        "Fedora")
            for package in "${packages[@]}"; do
                if ! command -v $package &> /dev/null; then
                    log "Installing $package..."
                    sudo dnf install -y $package
                fi
            done
            ;;
        "Arch Linux")
            for package in "${packages[@]}"; do
                if ! command -v $package &> /dev/null; then
                    log "Installing $package..."
                    sudo pacman -S --noconfirm $package
                fi
            done
            ;;
        *)
            error "Unsupported OS for automatic package installation"
            exit 1
            ;;
    esac
}

# Create SSH key
setup_ssh() {
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        log "Generating SSH key..."
        read -p "Enter your email for SSH key: " email
        ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""
        
        # Start ssh-agent and add key
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        
        # Display public key
        log "Your SSH public key:"
        cat ~/.ssh/id_ed25519.pub
        log "Add this key to your Git provider (GitHub, GitLab, etc.)"
    else
        warn "SSH key already exists at ~/.ssh/id_ed25519"
    fi
}

# Configure Git
setup_git() {
    log "Configuring Git..."
    if [ ! -f ~/.gitconfig ]; then
        cp files/git/gitconfig ~/.gitconfig
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
    else
        warn "Git config already exists"
    fi
}

# Configure Zsh
setup_zsh() {
    log "Configuring Zsh..."
    
    # Install Oh My Zsh if not present
    if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

    # Backup existing configs
    [ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup
    [ -f ~/.zsh_aliases ] && mv ~/.zsh_aliases ~/.zsh_aliases.backup
    
    # Copy new configs
    cp files/zsh/zshrc ~/.zshrc
    cp files/zsh/zsh_aliases ~/.zsh_aliases
    
    # Set Zsh as default shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
    fi

    log "Fir Linux users if the default shell is not changed. Please use this command : sudo sh -c 'echo $(which zsh) >> /etc/shells'"
}

# Configure Tmux
setup_tmux() {
    log "Configuring Tmux..."
    [ -f ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.backup
    cp files/tmux/tmux.conf ~/.tmux.conf
    
    # Install Tmux Plugin Manager
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        log "Install Tmux plugins by pressing prefix + I (capital I) after starting Tmux"
    fi
}

# Main installation function
main() {
    log "Starting installation..."
    
    detect_os
    install_dependencies
    setup_ssh
    setup_git
    setup_zsh
    setup_tmux
    
    log "Installation complete! Please restart your terminal."
    log "Note: Some changes might require a system restart to take effect."
}

# Run main function
main