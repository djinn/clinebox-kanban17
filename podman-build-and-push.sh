#!/usr/bin/env bash
# ── Cline Kanban — Build & Push Container Image ─────────────────────
# Builds the Kanban container image using Podman and pushes it to
# GitHub Container Registry (ghcr.io).
#
# Prerequisites:
#   - podman installed
#   - GitHub token with write:packages scope
#
# Usage:
#   ./podman-build-and-push.sh
#   GITHUB_TOKEN=ghp_xxx ./podman-build-and-push.sh
# ====================================================================

set -euo pipefail

IMAGE_NAME="ghcr.io/djinn/clinebox-kanban"
IMAGE_TAG="latest"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$GITHUB_TOKEN" ] && [ -f "${HOME}/.config/gh/token" ]; then
  GITHUB_TOKEN="$(cat "${HOME}/.config/gh/token" 2>/dev/null || true)"
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is not set."
  echo "Generate one at: https://github.com/settings/tokens (scope: write:packages)"
  echo "Then run: GITHUB_TOKEN=ghp_xxx ./podman-build-and-push.sh"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "═══ Cline Kanban — Build & Push ═══"
echo ""

# ── Step 1: Build the container image ─────────────────────────────
echo "▸ Building container image: ${FULL_IMAGE}"
cd "${ROOT_DIR}"

podman build -t "${FULL_IMAGE}" -f Dockerfile .

echo "✓ Build complete"
echo ""

# ── Step 2: Push to GitHub Container Registry ─────────────────────
echo "▸ Authenticating with ghcr.io..."
echo "${GITHUB_TOKEN}" | podman login ghcr.io -u djinn --password-stdin

echo "▸ Pushing image to ${FULL_IMAGE}"
podman push "${FULL_IMAGE}"

echo ""
echo "═══ Done! ═══"
echo "Image pushed: ${FULL_IMAGE}"
echo ""
echo "Next steps:"
echo "  1. Push the wrangler.jsonc changes to GitHub:"
echo "     git push origin main"
echo "  2. Click 'Deploy to Cloudflare' button on GitHub"
echo "     or re-deploy from Cloudflare dashboard"
