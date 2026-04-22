#!/bin/zsh

export PATH="$PATH:$HOME/.maestro/bin"

if ! command -v maestro &> /dev/null; then
  echo "Maestro CLI not found. Install it with: curl -Ls https://get.maestro.mobile.dev | bash"
  exit 1
fi

echo "Starting Maestro MCP server ($(maestro --version 2>/dev/null | grep -o '[0-9.]*' | head -1))..."
maestro mcp
