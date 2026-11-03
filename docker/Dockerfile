FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server \
    python3 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible && \
    chmod 440 /etc/sudoers.d/ansible

RUN mkdir -p /home/ansible/.ssh /run/sshd && \
    chown -R ansible:ansible /home/ansible/.ssh && \
    chmod 700 /home/ansible/.ssh

RUN printf '%s\n' \
    'PubkeyAuthentication yes' \
    'PasswordAuthentication no' \
    'PermitRootLogin no' \
    > /etc/ssh/sshd_config.d/lab.conf

COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 22 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
