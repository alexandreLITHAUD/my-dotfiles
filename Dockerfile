FROM ubuntu:noble

# Add arguments for script
ARG GIT_EMAIL=alexandre.ltd71@gmail.com
ARG GIT_USERNAME=alexandre_lithaud

ARG SSH_EMAIL=alexandre.ltd71@gmail.com

# Change TY for Docker
ENV TY=Europe/Paris

# Remove unwanted interactive promts
ENV DEBIAN_FRONTEND=noninteractive

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

RUN bash ./installer.sh -s $SSH_EMAIL -g $GIT_EMAIL -u $GIT_USERNAME
