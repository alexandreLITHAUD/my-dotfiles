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
        error "Unsupported OS: $OS"
        exit 1
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

download_tools() {
    log "Downloading additional tools..."
    
    # Define tools array
    local tools=("gpg" "age" "sops" "tig" "meld" "micro" "wget" "curl" "bat" "jump" "htop" "tree")
    
    case $OS in
        "macOS")
            # Install Homebrew if not present
            if ! command -v brew &> /dev/null; then
                log "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            # Install CLI tools
            for tool in "${tools[@]}"; do
                if ! command -v $tool &> /dev/null; then
                    case $tool in
                        "gpg") brew install gnupg ;;
                        "bat") brew install bat ;;
                        "jump") brew install jump ;;
                        *) brew install $tool ;;
                    esac
                fi
            done
            ;;
            
        "Ubuntu"|"Debian"|"Linux Mint")
            # Add required repositories
            sudo apt-get update
            
            # Install tools
            for tool in "${tools[@]}"; do
                case $tool in
                    "sops")
                        if ! command -v sops &> /dev/null; then
                            local sops_version="v3.7.3"
                            wget https://github.com/mozilla/sops/releases/download/${sops_version}/sops-${sops_version}.linux.amd64
                            chmod +x sops-${sops_version}.linux.amd64
                            sudo mv sops-${sops_version}.linux.amd64 /usr/local/bin/sops
                        fi
                        ;;
                    "bat")
                        sudo apt-get install -y batcat
                        # Create bat alias if it doesn't exist
                        if ! command -v bat &> /dev/null; then
                            sudo ln -s /usr/bin/batcat /usr/local/bin/bat
                        fi
                        ;;
                    "micro")
                        if ! command -v micro &> /dev/null; then
                            curl https://getmic.ro | bash
                            sudo mv micro /usr/local/bin/
                        fi
                        ;;
                    "jump")
                        if ! command -v jump &> /dev/null; then
                            sudo apt-get install build-essential
                            git clone https://github.com/gsamokovarov/jump.git /tmp/jump
                            cd /tmp/jump
                            make
                            sudo make install
                            cd -
                        fi
                        ;;
                    *)
                        sudo apt-get install -y $tool
                        ;;
                esac
            done
            ;;
            
        "Fedora")
            # Enable required repositories
            sudo dnf install -y dnf-plugins-core
            
            for tool in "${tools[@]}"; do
                case $tool in
                    "age")
                        if ! command -v age &> /dev/null; then
                            sudo dnf copr enable -y FiloSottile/age
                            sudo dnf install -y age
                        fi
                        ;;
                    "sops")
                        if ! command -v sops &> /dev/null; then
                            sudo dnf install -y sops
                        fi
                        ;;
                    "bat")
                        sudo dnf install -y bat
                        ;;
                    *)
                        sudo dnf install -y $tool
                        ;;
                esac
            done
            ;;
            
        "Arch Linux")
            for tool in "${tools[@]}"; do
                case $tool in
                    "bat") sudo pacman -S --noconfirm bat ;;
                    "gpg") sudo pacman -S --noconfirm gnupg ;;
                    *) sudo pacman -S --noconfirm $tool ;;
                esac
            done
            ;;
            
        *)
            error "Unsupported OS for automatic tool installation"
            exit 1
            ;;
    esac
    
    log "Tools installation completed!"
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
    install_tools
    setup_ssh
    setup_git
    setup_zsh
    setup_tmux
    
    log "Installation complete! Please restart your terminal."
    log "Note: Some changes might require a system restart to take effect."
}

# Run main function
main