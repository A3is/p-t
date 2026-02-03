#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

# Big Graphic Title
echo -e "${CYAN}"
cat << "EOF"
██████╗  █████╗  ██████╗ ███████╗████████╗
██╔══██╗██╔══██╗██╔════╝ ██╔════╝╚══██╔══╝
██████╔╝███████║██║  ███╗█████╗     ██║   
██╔═══╝ ██╔══██║██║   ██║██╔══╝     ██║   
██║     ██║  ██║╚██████╔╝███████╗   ██║   
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   
            Paqet Tunnel
EOF
echo -e "${NC}"

# Small subtitle
echo -e "        Script written by : A3is\n"

# ===== OS Check =====
if ! grep -qi "ubuntu" /etc/os-release; then
    echo -e "${RED}Error:${NC} This script requires Ubuntu 22.x"
    exit 1
fi

UBUNTU_VERSION=$(lsb_release -rs | cut -d'.' -f1)

if [ "$UBUNTU_VERSION" -ne 22 ]; then
    echo -e "${RED}Error:${NC} This script requires Ubuntu 22.x"
    exit 1
fi

# ===== GLIBC Check =====
GLIBC_VERSION=$(ldd --version | head -n1 | awk '{print $NF}')

REQUIRED_GLIBC="2.34"

if dpkg --compare-versions "$GLIBC_VERSION" lt "$REQUIRED_GLIBC"; then
    echo -e "${RED}Error:${NC} glibc version is too low"
    echo -e "${RED}Required:${NC}"
    echo -e " - Ubuntu 22.x"
    echo -e " - glibc >= 2.34"
    exit 1
fi

echo -e "${GREEN}✔ System requirements satisfied.${NC}"
