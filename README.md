# PERSONAL CONFIGURATION

This repo stores the dotfiles for zsh, git and tmux. If you want to install my configuration just use the install.sh script. It works for Ubuntu, Mint, Debian, MacOS, Fedora, Centos and Arch.

You can also use the dockerfile to create a ubuntu container with all my configuration. 

>> Here is the project architecture
```
.
├── README.md
├── apps.txt
├── files
│   ├── git
│   │   └── gitconfig
│   ├── tmux
│   │   └── tmux.conf
│   └── zsh
│       ├── zsh_aliases
│       └── zshrc
└── installer.sh
```

You can pull my docker container using this command : `docker push alexandrelithaud/personal_ubuntu_conf:latest`