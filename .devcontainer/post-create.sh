#!/bin/bash

# Post-create script for dev container
# Installs dependencies, builds the project, and configures authentication

set -e

echo "🚀 Starting post-create setup..."

# Install dependencies and build
echo "📦 Installing dependencies and building project..."
make install && make build

# Auto-authenticate GitHub CLI in Codespaces (uses built-in GITHUB_TOKEN)
if [ -n "$CODESPACE_NAME" ] && [ -n "$GITHUB_TOKEN" ]; then
  echo "🔐 Auto-authenticating GitHub CLI in Codespaces..."
  echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null && \
    echo "✅ GitHub CLI authenticated automatically" || \
    echo "⚠️  GitHub CLI auto-auth failed, run: gh auth login"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     ✅ SETUP COMPLETE!                           ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║                                                                  ║"
echo "║  Start both servers with ONE command:                           ║"
echo "║                                                                  ║"
echo "║      make dev                                                    ║"
echo "║                                                                  ║"
echo "║  Or use VS Code: Ctrl+Shift+B → 'Start Development'             ║"
echo "║                                                                  ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  URLs (after starting):                                         ║"
echo "║    • Frontend:  http://localhost:5137                           ║"
echo "║    • API Docs:  http://localhost:3000/api-docs/                 ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
if [ -z "$CODESPACE_NAME" ]; then
  echo "💡 If GitHub CLI needs auth, run: gh auth login"
fi
echo "💡 Copilot authenticates automatically via VS Code extension"
echo ""
