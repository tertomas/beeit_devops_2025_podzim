#!/bin/sh

echo "=== Akut├íln├ş shell ==="
echo "$SHELL"

echo ""
echo "=== U┼żivatel ==="
whoami

echo ""
echo "=== Verze linuxu ==="
if [ -f /etc/os-release ]; then
    cat /etc/os-release
else
    echo "/etc/os-release not found."
fi

echo ""
echo "=== Environment├íln├ş prom─Ťnn├ę ==="
printenv
