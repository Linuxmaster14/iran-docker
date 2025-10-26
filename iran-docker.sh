#!/bin/bash

# Iran Docker Management Script
# Author: https://github.com/Linuxmaster14

RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

# Check if script is running with root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error:${NC} Please run this script as root (use sudo)"
    exit 1
fi

# Main menu options
main_menu_items=("Set DNS" "Install Docker" "Update Docker" "Set Docker Proxy" "Exit")

# Available DNS providers and their servers
dns_options=("Shecan" "Radar" "Electro" "Begzar" "DNSPro" "403" "DynX" "Google" "Cloudflare" "Reset to Default")
declare -A dns_servers=(
    ["Shecan"]="178.22.122.100 185.51.200.2"
    ["Radar"]="10.202.10.10 10.202.10.11"
    ["Electro"]="78.157.42.100 78.157.42.101"
    ["Begzar"]="185.55.226.26 185.55.226.25"
    ["DNSPro"]="87.107.110.109 87.107.110.110"
    ["403"]="10.202.10.202 10.202.10.102"
	["DynX"]="10.70.95.150 10.70.95.162"
    ["Google"]="8.8.8.8 8.8.4.4"
    ["Cloudflare"]="1.1.1.1 1.0.0.1"
    ["Reset to Default"]="127.0.0.53"
)

# Iranian Docker registry mirrors
registry_proxies=(
    "docker.kernel.ir"
    "focker.ir"
    "registry.docker.ir"
    "docker.arvancloud.ir"
    "docker.haiocloud.com"
    "docker.iranserver.com"
    "docker.mobinhost.com"
    "hub.mecan.ir"
)

# DNS Management Functions
backup_resolv() {
    cp /etc/resolv.conf "/etc/resolv.conf.bak.$(date +%Y%m%d_%H%M%S)"
}

ping_proxy() {
    local domain="$1"
    local times=($(ping -c 3 -W 1 "$domain" 2>/dev/null | grep -oP 'time=\K[0-9.]+'))
    
    if [ ${#times[@]} -gt 0 ]; then
        printf '%s\n' "${times[@]}" | sort -n | head -1
    else
        echo "timeout"
    fi
}


# Set DNS servers based on user selection
set_dns() {
    echo
    for i in "${!dns_options[@]}"; do
        echo "  $((i + 1))) ${dns_options[$i]}"
    done
    echo "  0) Back"
    echo
    read -rp "Select DNS (0-${#dns_options[@]}): " dns_choice

    if [[ "$dns_choice" == "0" ]]; then return; fi
    if [[ ! "$dns_choice" =~ ^[0-9]+$ ]] || (( dns_choice < 1 || dns_choice > ${#dns_options[@]} )); then
        echo -e "${RED}Invalid DNS option${NC}"; return
    fi

    provider="${dns_options[$((dns_choice - 1))]}"
    dns_list="${dns_servers[$provider]}"

    # Create backup before making changes
    backup_resolv

    # Write new DNS configuration
    {
        echo "# DNS updated on $(date) by iran-docker script"
        for dns in $dns_list; do
            echo "nameserver $dns"
        done
        if [ "$provider" != "Reset to Default" ]; then
            echo "options edns0 trust-ad"
            grep "^search" /etc/resolv.conf 2>/dev/null
        fi
    } > /etc/resolv.conf

    echo -e "${GREEN}DNS updated to:${NC} $provider"
}

# Docker Management Functions

install_docker() {
    # Check if Docker is already installed
    if command -v docker >/dev/null 2>&1; then
        version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
        if [ -n "$version" ]; then
            echo -e "${GREEN}Docker is already installed. Version: $version${NC}"
            return
        fi
    fi

    echo -e "${CYAN}Starting Docker installation...${NC}"

    # Update package lists
    echo -e "${GREEN}Updating package lists...${NC}"
    if ! apt-get update -qq >/dev/null 2>&1; then
        echo -e "${RED}Error:${NC} Failed to update package lists."
        return 1
    fi

    # Upgrade system packages
    echo -e "${GREEN}Upgrading system packages...${NC}"
    if ! apt-get upgrade -y -qq >/dev/null 2>&1; then
        echo -e "${RED}Error:${NC} Failed to upgrade packages."
        return 1
    fi

    # Install required dependencies
    echo -e "${GREEN}Installing required packages (curl)...${NC}"
    if ! apt-get install -y -qq curl >/dev/null 2>&1; then
        echo -e "${RED}Error:${NC} Failed to install prerequisites."
        return 1
    fi

    # Download and run Docker installation script
    echo -e "${GREEN}Downloading and installing Docker...${NC}"
    if ! curl -fsSL https://get.docker.com | sh >/dev/null 2>&1; then
        echo -e "${RED}Error:${NC} Docker installation script failed."
        return 1
    fi

    # Verify Docker installation
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}Error:${NC} Docker command not found after installation."
        return 1
    fi

    # Get and display Docker version
    version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    if [ -z "$version" ]; then
        echo -e "${RED}Error:${NC} Could not retrieve Docker version."
        return 1
    fi

    echo -e "${GREEN}Docker installed successfully. Version: $version${NC}"
}

# Update Docker to the latest version
update_docker() {
    # Check if Docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}Docker is not installed.${NC} Please install it first."
        return
    fi

    echo -e "${CYAN}Updating Docker to the latest version...${NC}"

    # Download and run Docker installation script (also works for updates)
    echo -e "${GREEN}Downloading and installing Docker...${NC}"
    if ! curl -fsSL https://get.docker.com | sh >/dev/null 2>&1; then
        echo -e "${RED}Error:${NC} Docker update script failed."
        return 1
    fi

    # Display updated version
    version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    echo -e "${GREEN}Docker updated successfully. Version: $version${NC}"
}

# Configure Docker to use Iranian registry mirrors
set_docker_proxy() {
    echo
    echo -e "${CYAN}Select Docker Registry Mirror:${NC}"
    for i in "${!registry_proxies[@]}"; do
        echo "  $((i + 1))) https://${registry_proxies[$i]}"
    done
    echo "  0) Back"
    echo
    read -rp "Select (0-${#registry_proxies[@]}): " proxy_choice

    if [[ "$proxy_choice" == "0" ]]; then return; fi
    if [[ ! "$proxy_choice" =~ ^[0-9]+$ ]] || (( proxy_choice < 1 || proxy_choice > ${#registry_proxies[@]} )); then
        echo -e "${RED}Invalid option${NC}"; return
    fi

    mirror="${registry_proxies[$((proxy_choice - 1))]}"
    
    # Create Docker configuration directory
    mkdir -p /etc/docker
    
    # Create daemon.json with registry mirror configuration
    echo -e "{\n  \"registry-mirrors\": [\"https://$mirror\"]\n}" > /etc/docker/daemon.json

    # Restart Docker service to apply changes
    systemctl restart docker

    echo -e "${GREEN}Docker proxy set to:${NC} $mirror"
}

# Main Menu and Program Entry Point
main_menu() {
    while true; do
        echo
        echo -e "${CYAN}Main Menu:${NC}"
        for i in "${!main_menu_items[@]}"; do
            echo "  $((i + 1))) ${main_menu_items[$i]}"
        done
        echo
        read -rp "Select an option (1-${#main_menu_items[@]}): " choice

        case "$choice" in
            1) set_dns ;;
            2) install_docker ;;
            3) update_docker ;;
            4) set_docker_proxy ;;
            5) echo -e "${CYAN}Bye.${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice${NC}" ;;
        esac
    done
}

# Start the program
main_menu
