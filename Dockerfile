FROM ubuntu:noble

# Install required packages
RUN apt-get update && apt-get install -y \
    git \
    sudo

# Create a non-root user
ARG USERNAME=developer

# Create the user without specifying UID/GID
RUN useradd -m $USERNAME \
    && usermod -aG sudo $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME

# Switch to non-root user
USER $USERNAME

# Set working directory in user's home
WORKDIR /home/$USERNAME

# Clone dotfiles repository
RUN git clone https://github.com/alexandreLITHAUD/my-dotfiles.git

WORKDIR /home/$USERNAME/my-dotfiles