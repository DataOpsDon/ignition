#!/bin/bash

# Configuration: Use arguments if provided, otherwise fallback to environment variables or defaults
HOST="${1:-${TARGET_HOST:-google.com}}"
PORT="${2:-${TARGET_PORT:-443}}"
TIMEOUT="${3:-${CONNECT_TIMEOUT:-10}}"

echo "##[section]--- Network Connectivity Check ---"
echo "Target:  $HOST"
echo "Port:    $PORT"
echo "Timeout: ${TIMEOUT}s"
echo ""

# 0. Build Agent Identity
echo "##[section]0. Build Agent IP Address"
echo "Internal IP(s): $(hostname -I)"
echo "Public IP:      $(curl -s https://api.ipify.org || echo 'Unable to fetch public IP')"
echo ""

# 1. DNS Resolution
echo "##[section]1. DNS Resolution (nslookup)"
if nslookup "$HOST"; then
    echo "SUCCESS: DNS resolution completed."
else
    echo "##vso[task.logissue type=warning]DNS lookup failed for $HOST. Verify DNS/Private Zone settings."
fi
echo ""

# 2. TCP Connectivity
echo "##[section]2. TCP Connectivity Check"
# Attempt to connect; redirect stderr to stdout to capture specific 'nc' errors
if nc -zv -w "$TIMEOUT" "$HOST" "$PORT" 2>&1; then
    echo "##[section]SUCCESS: Reached $HOST on port $PORT."
else
    echo "##vso[task.logissue type=error]FAILED: Connection to $HOST:$PORT timed out or was refused."
    exit 1
fi