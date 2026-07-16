FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production

RUN apt-get update && apt-get install -y \
    openssh-server \
    vsftpd \
    iproute2 \
    iputils-ping \
    net-tools \
    curl \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Admin root password used for debugging inside the gateway container.
RUN echo "root:toor" | chpasswd

RUN useradd -m -s /bin/bash khasem_7th_scribe && \
    echo "khasem_7th_scribe:!locked!" | chpasswd && \
    mkdir -p /home/khasem_7th_scribe/.ssh && \
    chmod 700 /home/khasem_7th_scribe/.ssh

RUN echo "necrosand{TH3_SANDS_H4V3_D3C31V3D_Y0U}" > /home/khasem_7th_scribe/user.txt && \
    chown root:khasem_7th_scribe /home/khasem_7th_scribe/user.txt && \
    chmod 400 /home/khasem_7th_scribe/user.txt

COPY ssh/gen_fake_flag.sh /tmp/gen_fake_flag.sh
RUN chmod +x /tmp/gen_fake_flag.sh && /tmp/gen_fake_flag.sh && rm /tmp/gen_fake_flag.sh && \
    chmod 400 /home/khasem_7th_scribe/flag.txt

COPY ssh/banner.sh /tmp/banner.sh
RUN cat /tmp/banner.sh >> /home/khasem_7th_scribe/.bashrc && \
    rm /tmp/banner.sh

RUN mkdir -p /home/khasem_7th_scribe/.archives
COPY ssh/sacred_testament.txt /home/khasem_7th_scribe/.archives/.burial_record
RUN chown -R root:khasem_7th_scribe /home/khasem_7th_scribe/.archives && \
    chmod 750 /home/khasem_7th_scribe/.archives && \
    chmod 440 /home/khasem_7th_scribe/.archives/.burial_record

RUN chown -R root:khasem_7th_scribe /home/khasem_7th_scribe && \
    chmod 750 /home/khasem_7th_scribe && \
    chown -R khasem_7th_scribe:khasem_7th_scribe /home/khasem_7th_scribe/.ssh

RUN chmod 444 /home/khasem_7th_scribe/.bashrc

RUN mkdir -p /home/khasem_7th_scribe/bin && \
    ln -s /usr/bin/ls /home/khasem_7th_scribe/bin/ls && \
    ln -s /usr/bin/cat /home/khasem_7th_scribe/bin/cat && \
    ln -s /usr/bin/id /home/khasem_7th_scribe/bin/id && \
    ln -s /usr/bin/whoami /home/khasem_7th_scribe/bin/whoami && \
    ln -s /usr/bin/pwd /home/khasem_7th_scribe/bin/pwd && \
    ln -s /usr/bin/hostname /home/khasem_7th_scribe/bin/hostname && \
    ln -s /usr/bin/ping /home/khasem_7th_scribe/bin/ping && \
    ln -s /usr/bin/curl /home/khasem_7th_scribe/bin/curl && \
    ln -s /sbin/ip /home/khasem_7th_scribe/bin/ip && \
    ln -s /usr/bin/head /home/khasem_7th_scribe/bin/head && \
    ln -s /usr/bin/tail /home/khasem_7th_scribe/bin/tail && \
    ln -s /usr/bin/grep /home/khasem_7th_scribe/bin/grep && \
    ln -s /usr/bin/echo /home/khasem_7th_scribe/bin/echo && \
    ln -s /usr/bin/env /home/khasem_7th_scribe/bin/env && \
    ln -s /usr/bin/clear /home/khasem_7th_scribe/bin/clear && \
    ln -s /usr/bin/ssh /home/khasem_7th_scribe/bin/ssh

RUN printf 'export PATH="$HOME/bin"\nreadonly PATH\nexport HISTFILE=/dev/null\nreadonly HISTFILE\n' > /home/khasem_7th_scribe/.bash_profile && \
    chown root:khasem_7th_scribe /home/khasem_7th_scribe/.bash_profile && \
    chmod 444 /home/khasem_7th_scribe/.bash_profile && \
    rm -f /home/khasem_7th_scribe/.profile /home/khasem_7th_scribe/.bash_logout

RUN mkdir -p /run/sshd
COPY ssh/sshd_config /etc/ssh/sshd_config

RUN ssh-keygen -t rsa -b 2048 \
        -f /tmp/khasem_id_rsa \
        -C "khasem_7th_scribe@anubis-protocol" \
        -N "" -q && \
    cp /tmp/khasem_id_rsa.pub /home/khasem_7th_scribe/.ssh/authorized_keys && \
    chmod 600 /home/khasem_7th_scribe/.ssh/authorized_keys && \
    chown khasem_7th_scribe:khasem_7th_scribe /home/khasem_7th_scribe/.ssh && \
    chown khasem_7th_scribe:khasem_7th_scribe /home/khasem_7th_scribe/.ssh/authorized_keys

COPY ftp/vsftpd.conf /etc/vsftpd.conf
RUN mkdir -p /var/ftp/pub && \
    mkdir -p /var/run/vsftpd/empty && \
    chown nobody:nogroup /var/ftp/pub && \
    chmod 555 /var/ftp/pub
COPY ftp/warning.txt /var/ftp/pub/warning.txt
COPY ftp/archivist_dictionary.txt /var/ftp/pub/archivist_dictionary.txt
RUN chmod 444 /var/ftp/pub/warning.txt && \
    chmod 444 /var/ftp/pub/archivist_dictionary.txt

COPY server/ /opt/server/
WORKDIR /opt/server
RUN npm install --production

RUN cp /tmp/khasem_id_rsa /opt/server/khasem_id_rsa && \
    chmod 644 /opt/server/khasem_id_rsa

RUN node init-db.js

COPY web/ /opt/server/public/

RUN rm -f /tmp/khasem_id_rsa /tmp/khasem_id_rsa.pub

RUN rm -f /usr/bin/wget /usr/bin/nc /usr/bin/ncat /usr/bin/netcat \
    /usr/bin/python3 /usr/bin/python /usr/bin/perl /usr/bin/ruby \
    /usr/bin/gcc /usr/bin/g++ /usr/bin/cc /usr/bin/make \
    /usr/bin/vi /usr/bin/vim /usr/bin/nano /usr/bin/ed \
    /usr/bin/scp /usr/bin/sftp \
    /usr/bin/socat /usr/bin/nmap /usr/bin/telnet \
    /usr/bin/apt /usr/bin/apt-get /usr/bin/dpkg 2>/dev/null || true

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 21 22 80

CMD ["/start.sh"]
