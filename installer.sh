#!/bin/bash

# Exit on error
set -e 

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

                    if [ $VERBOSE -eq 1 ]; then
                        brew install $package
                    else
                        brew install $package > /dev/null 2>&1
                    fi
                fi
            done
            ;;
        "Ubuntu"|"Debian"|"Linux Mint")
            sudo apt-get update
            for package in "${packages[@]}"; do
                if ! command -v $package &> /dev/null; then
                    log "Installing $package..."

                    if [ $VERBOSE -eq 1 ]; then
                        sudo apt-get install -y $package
                    else
                        sudo apt-get install -y $package > /dev/null 2>&1
                    fi
                fi
            done
            ;;
        "Fedora")
            for package in "${packages[@]}"; do
                if ! command -v $package &> /dev/null; then
                    log "Installing $package..."

                    if [ $VERBOSE -eq 1 ]; then
                        sudo dnf install -y $package
                    else
                        sudo dnf install -y $package > /dev/null 2>&1
                    fi
                fi
            done
            ;;
        "Arch Linux")
            for package in "${packages[@]}"; do
                if ! command -v $package &> /dev/null; then
                    log "Installing $package..."

                    if [ $VERBOSE -eq 1 ]; then
                        sudo pacman -S --noconfirm $package
                    else
                        sudo pacman -S --noconfirm $package > /dev/null 2>&1
                    fi
                fi
            done
            ;;
        *)
            error "Unsupported OS for automatic package installation"
            exit 1
            ;;
    esac
}

install_tools() {
    log "Downloading additional tools..."
    
    # Define tools array
    local tools=("wget" "curl" "gpg" "age" "sops" "tig" "meld" "micro" "bat" "jump" "htop" "tree" "fzf")
    
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
                    
                    if [ $VERBOSE -eq 1 ]; then
                        case $tool in
                            "gpg") brew install gnupg ;;
                            "bat") brew install bat ;;
                            "jump") brew install jump ;;
                            *) brew install $tool ;;
                        esac
                    else
                        case $tool in
                            "gpg") brew install gnupg > /dev/null 2>&1 ;;
                            "bat") brew install bat > /dev/null 2>&1 ;;
                            "jump") brew install jump > /dev/null 2>&1 ;;
                            *) brew install $tool ;;
                        esac
                    fi
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

                            if [ $VERBOSE -eq 1 ]; then
                                wget https://github.com/mozilla/sops/releases/download/${sops_version}/sops-${sops_version}.linux.amd64
                                chmod +x sops-${sops_version}.linux.amd64
                                sudo mv sops-${sops_version}.linux.amd64 /usr/local/bin/sops
                            else
                                wget https://github.com/mozilla/sops/releases/download/${sops_version}/sops-${sops_version}.linux.amd64 > /dev/null 2>&1
                                chmod +x sops-${sops_version}.linux.amd64 > /dev/null 2>&1
                                sudo mv sops-${sops_version}.linux.amd64 /usr/local/bin/sops > /dev/null 2>&1
                            fi
                        fi
                        ;;
                    "micro")
                        if ! command -v micro &> /dev/null; then

                            if [ $VERBOSE -eq 1 ]; then
                                curl https://getmic.ro | bash
                                sudo mv micro /usr/local/bin/
                            else
                                curl https://getmic.ro | bash > /dev/null 2>&1
                                sudo mv micro /usr/local/bin/ > /dev/null 2>&1
                            fi
                        fi
                        ;;
                    "jump")
                        if ! command -v jump &> /dev/null; then

                            if [ $VERBOSE -eq 1 ]; then
                                sudo apt-get install -y build-essential golang
                                git clone https://github.com/gsamokovarov/jump.git /tmp/jump
                                cd /tmp/jump
                                make
                                sudo chmod +x /tmp/jump/jump
                                sudo mv /tmp/jump/jump /usr/local/bin
                                cd -
                            else
                                sudo apt-get install -y build-essential golang > /dev/null 2>&1
                                git clone https://github.com/gsamokovarov/jump.git /tmp/jump > /dev/null 2>&1
                                cd /tmp/jump > /dev/null 2>&1
                                make > /dev/null 2>&1
                                sudo chmod +x /tmp/jump/jump > /dev/null 2>&1
                                sudo mv /tmp/jump/jump /usr/local/bin > /dev/null 2>&1
                                cd - > /dev/null 2>&1
                            fi
                        fi
                        ;;
                    *)
                        if [ $VERBOSE -eq 1 ]; then
                            sudo apt-get install -y $tool
                        else
                            sudo apt-get install -y $tool > /dev/null 2>&1
                        fi
                        ;;
                esac
            done
            ;;
            
        "Fedora"|"CentOS Linux")
            # Enable required repositories
            sudo dnf install -y dnf-plugins-core
            
            for tool in "${tools[@]}"; do
                case $tool in
                    "age")
                        if ! command -v age &> /dev/null; then

                            if [ $VERBOSE -eq 1 ]; then
                                sudo dnf copr enable -y FiloSottile/age
                                sudo dnf install -y age
                            else
                                sudo dnf copr enable -y FiloSottile/age > /dev/null 2>&1
                                sudo dnf install -y age > /dev/null 2>&1
                            fi
                        fi
                        ;;
                    "sops")
                        if ! command -v sops &> /dev/null; then

                            if [ $VERBOSE -eq 1 ]; then
                                sudo dnf install -y sops
                            else
                                sudo dnf install -y sops > /dev/null 2>&1
                            fi
                        fi
                        ;;
                    "bat")
                        if [ $VERBOSE -eq 1 ]; then
                            sudo dnf install -y bat
                        else
                            sudo dnf install -y bat > /dev/null 2>&1
                        fi
                        ;;
                    *)
                        if [ $VERBOSE -eq 1 ]; then
                            sudo dnf install -y $tool
                        else
                            sudo dnf install -y $tool > /dev/null 2>&1
                        fi
                        ;;
                esac
            done
            ;;
            
        "Arch Linux")
            for tool in "${tools[@]}"; do

                if [ $VERBOSE -eq 1 ]; then
                    case $tool in
                        "bat") sudo pacman -S --noconfirm bat ;;
                        "gpg") sudo pacman -S --noconfirm gnupg ;;
                        *) sudo pacman -S --noconfirm $tool ;;
                    esac
                else
                    case $tool in
                        "bat") sudo pacman -S --noconfirm bat > /dev/null 2>&1 ;;
                        "gpg") sudo pacman -S --noconfirm gnupg > /dev/null 2>&1 ;;
                        *) sudo pacman -S --noconfirm $tool > /dev/null 2>&1 ;;
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
        if [ ! -z  "$SSH_EMAIL" ]; then
            email=$SSH_EMAIL
        else
            read -p "Enter your email for SSH key: " email
        fi

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

        if [ ! -z "$GIT_EMAIL" ]; then
            git_email=$GIT_EMAIL
        else
            read -p "Enter your Git email: " git_email
        fi

        if [ ! -z "$GIT_USERNAME" ]; then
            git_username=$GIT_USERNAME
        else
            read -p "Enter your Git username: " git_username
        fi
        
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

        if [ $VERBOSE -eq 1 ]; then
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        else
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2&1
        fi
    fi
    
    if [ $VERBOSE -eq 1 ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions > /dev/null 2>&1
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting > /dev/null 2>&1
    fi

    # Backup existing configs
    [ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup
    [ -f ~/.zsh_aliases ] && mv ~/.zsh_aliases ~/.zsh_aliases.backup
    
    # Copy new configs
    cp files/zsh/zshrc ~/.zshrc
    cp files/zsh/zsh_aliases ~/.zsh_aliases
    
    # Set Zsh as default shell
    # if [ "$SHELL" != "$(which zsh)" ]; then
    #     chsh -s "$(which zsh)"
    # fi

    log "For Linux users if the default shell is not changed. Please use this command : sudo sh -c 'echo $(which zsh) >> /etc/shells'"
}

# Configure Tmux
setup_tmux() {
    log "Configuring Tmux..."
    [ -f ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.backup
    cp files/tmux/tmux.conf ~/.tmux.conf
    
    # Install Tmux Plugin Manager
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        if [ $VERBOSE -eq 1]; then
            git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        else
            git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm > /dev/null 2>&1
        fi
        log "Install Tmux plugins by pressing prefix + I (capital I) after starting Tmux"
    fi
}

# Main installation function
main() {

    VERBOSE=0
    SSH_EMAIL=""
    GIT_EMAIL=""
    GIT_USERNAME=""

    while getopts "h?vs:g:u:" opt; do
        case "$opt" in
        h|\?)
            echo "Usage: $0 [-v] [-s ssh email] [-g git email] [-u git username]"
            exit 0
            ;;
        v)  VERBOSE=1
            ;;
        s)  SSH_EMAIL=$OPTARG
            ;;
        g)  GIT_EMAIL=$OPTARG
            ;;
        u)  GIT_USERNAME=$OPTARG
            ;;
        esac
    done

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
