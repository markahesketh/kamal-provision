FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create docker group (we won't install docker, just need the group)
RUN groupadd -f docker

# Configure SSH
RUN mkdir /var/run/sshd
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
RUN echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
RUN echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

# Create .ssh directory for root
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
