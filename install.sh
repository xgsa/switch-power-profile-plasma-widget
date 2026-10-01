#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID=$(sed -n 's/^X-KDE-PluginInfo-Name=//p' package/metadata.desktop)
if [ -z "${PROJECT_ID}" ]; then
    echo "Installation failed: X-KDE-PluginInfo-Name not found in package/metadata.desktop" >&2
    exit 1
fi

INSTALL_LOCATION="${HOME}/.local/share/plasma/plasmoids/${PROJECT_ID}"

echo "Installing ${PROJECT_ID}"

# Remove the previous installation so that stale files don't linger
rm -rf "${INSTALL_LOCATION}"
mkdir -p "${INSTALL_LOCATION}"
cp -R "package/." "${INSTALL_LOCATION}/"

echo "Successfully installed ${PROJECT_ID} to ${INSTALL_LOCATION}/"
