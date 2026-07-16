#!/bin/bash


# Start the binary as an interactive service via socat on port 9999
# Players send their payload to this port to exploit the binary remotely
socat TCP-LISTEN:9999,reuseaddr,fork EXEC:/usr/local/bin/anubis_protocol,pty,rawer &

# Start the info/download web service on port 8080 (foreground)
python3 /opt/service.py
