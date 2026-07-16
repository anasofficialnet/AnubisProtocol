FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    socat \
    python3 \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════
# COMPILE THE SUID BINARY
# ═══════════════════════════════════════════
COPY anubis.c /tmp/anubis.c
RUN gcc -o /usr/local/bin/anubis_protocol /tmp/anubis.c && \
    chmod u+s /usr/local/bin/anubis_protocol && \
    chown root:root /usr/local/bin/anubis_protocol && \
    rm /tmp/anubis.c

# ═══════════════════════════════════════════
# CREATE THE ROOT FLAG
# ═══════════════════════════════════════════
RUN echo "necrosand{TH3_ANUB1S_PR0T0C0L_C0MPL3T3}" > /root/root.txt && \
    chmod 600 /root/root.txt

# ═══════════════════════════════════════════
# COPY THE WEB SERVICE & ENTRYPOINT
# ═══════════════════════════════════════════
COPY service.py /opt/service.py
COPY exploit_template.py /opt/exploit_template.py
COPY sanctum_wall.png /opt/sanctum_wall.png
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080 9999

CMD ["/start.sh"]
