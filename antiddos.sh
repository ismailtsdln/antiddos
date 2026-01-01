#!/bin/bash

# antiddos - Linux Server IPTables Anti-DDoS Script
# Author: Ismail Tasdelen
# Description: This script sets up iptables rules to protect against common DDoS attacks with enhanced visuals and features.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Symbols
CHECK="✅"
CROSS="❌"
INFO="ℹ️"
WARN="⚠️"
FIRE="🔥"

# Paths
IPT=$(which iptables)
IPS=$(which iptables-save)

function show_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "    ___         __  _     ____  ____       "
    echo "   /   |  ____ / /_(_)   / __ \/ __ \____  "
    echo "  / /| | / __ \ __/ /   / / / / / / / __ \ "
    echo " / ___ |/ / / / /_/ /   / /_/ / /_/ / /_/ /"
    echo "/_/  |_/_/ /_/\__/_/___/_____/_____/\____/ "
    echo "                  /___/                    "
    echo -e "${NC}"
    echo -e "${BLUE}    Linux Server Anti-DDoS Firewall Management Tool${NC}"
    echo -e "${BLUE}    Version: 2.0.0 | Developer: Ismail Tasdelen${NC}"
    echo ""
}

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   show_banner
   echo -e "${RED}${CROSS} Error: This script must be run as root.${NC}"
   exit 1
fi

function clear_rules() {
    echo -e "${YELLOW}${INFO} Clearing all iptables rules...${NC}"
    $IPT -P INPUT ACCEPT
    $IPT -P FORWARD ACCEPT
    $IPT -P OUTPUT ACCEPT
    $IPT -t nat -F
    $IPT -t mangle -F
    $IPT -F
    $IPT -X
    echo -e "${GREEN}${CHECK} Rules cleared successfully.${NC}"
}

function stop_antiddos() {
    clear_rules
}

function status_antiddos() {
    show_banner
    echo -e "${PURPLE}${BOLD}--- PROTECTION STATUS ---${NC}"
    
    # Check if chains exist
    if $IPT -L SYN_FLOOD >/dev/null 2>&1; then
        echo -e "${GREEN}${CHECK} Anti-DDoS rules are ACTIVE${NC}"
    else
        echo -e "${RED}${CROSS} Anti-DDoS rules are INACTIVE${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}${BOLD}Active Rule Sets:${NC}"
    $IPT -nL --line-numbers | grep -E "SYN_FLOOD|UDP_FLOOD|ICMP_FLOOD|PORT_SCAN|connlimit"
}

function start_antiddos() {
    show_banner
    echo -e "${YELLOW}${INFO} Applying Anti-DDoS rules...${NC}"

    # Flush existing rules to avoid duplicates if restarting
    $IPT -F
    $IPT -X

    # 1. Drop invalid packets
    echo -e "${CYAN}   - Setting up Invalid packet filtering...${NC}"
    $IPT -A INPUT -m state --state INVALID -j DROP

    # 2. Drop packets with problematic TCP flags
    echo -e "${CYAN}   - Setting up TCP flag filtering...${NC}"
    $IPT -A INPUT -p tcp --tcp-flags ALL ACK,RST,SYN,FIN -j DROP
    $IPT -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
    $IPT -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    $IPT -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    $IPT -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    $IPT -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
    $IPT -A INPUT -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
    $IPT -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

    # 3. Drop fragmented packets
    echo -e "${CYAN}   - Setting up Fragment packet filtering...${NC}"
    $IPT -A INPUT -f -j DROP

    # 4. Limit connections per IP
    echo -e "${CYAN}   - Setting up TCP connection limit (20/IP)...${NC}"
    $IPT -A INPUT -p tcp --syn -m connlimit --connlimit-above 20 -j DROP

    # 5. SYN Flood Protection
    echo -e "${CYAN}   - Setting up SYN Flood protection...${NC}"
    $IPT -N SYN_FLOOD
    $IPT -A INPUT -p tcp --syn -j SYN_FLOOD
    $IPT -A SYN_FLOOD -m limit --limit 1/s --limit-burst 3 -j RETURN
    $IPT -A SYN_FLOOD -j DROP

    # 6. UDP Flood Protection
    echo -e "${CYAN}   - Setting up UDP Flood protection...${NC}"
    $IPT -N UDP_FLOOD
    $IPT -A INPUT -p udp -j UDP_FLOOD
    $IPT -A UDP_FLOOD -m limit --limit 10/s --limit-burst 20 -j RETURN
    $IPT -A UDP_FLOOD -j DROP

    # 7. ICMP (Ping) Flood Protection
    echo -e "${CYAN}   - Setting up ICMP Flood protection...${NC}"
    $IPT -N ICMP_FLOOD
    $IPT -A INPUT -p icmp -j ICMP_FLOOD
    $IPT -A ICMP_FLOOD -m limit --limit 1/s --limit-burst 4 -j RETURN
    $IPT -A ICMP_FLOOD -j DROP

    # 8. Protection against port scanning
    echo -e "${CYAN}   - Setting up Port Scan protection...${NC}"
    $IPT -N PORT_SCAN
    $IPT -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
    $IPT -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j DROP

    echo -e "${GREEN}${CHECK}${BOLD} Anti-DDoS rules applied successfully!${NC}"
}

function whitelist_ip() {
    local ip=$1
    if [[ -z "$ip" ]]; then
        echo -e "${RED}${CROSS} Error: IP address is required.${NC}"
        return
    fi
    echo -e "${GREEN}${CHECK} Whitelisting IP: $ip${NC}"
    $IPT -I INPUT -s "$ip" -j ACCEPT
}

function blacklist_ip() {
    local ip=$1
    if [[ -z "$ip" ]]; then
        echo -e "${RED}${CROSS} Error: IP address is required.${NC}"
        return
    fi
    echo -e "${RED}${WARN} Blacklisting IP: $ip${NC}"
    $IPT -I INPUT -s "$ip" -j DROP
}

function monitor_traffic() {
    show_banner
    echo -e "${BOLD}${FIRE} Entering real-time monitoring mode (Press Ctrl+C to exit)...${NC}"
    echo ""
    # We use a loop instead of watch because watch might not be installed or behave differently
    while true; do
        clear
        show_banner
        echo -e "${BOLD}${BLUE}--- REAL-TIME DROPPED PACKETS ---${NC}"
        $IPT -L -n -v | grep -E "DROP|REJECT" | grep -v "0     0"
        echo ""
        echo -e "${BOLD}${BLUE}--- CURRENT CONNECTIONS SUMMARY ---${NC}"
        if command -v ss >/dev/null; then
            ss -s
        else
            netstat -ant | awk '{print $6}' | sort | uniq -c | sort -n
        fi
        sleep 2
    done
}

function save_persistence() {
    echo -e "${YELLOW}${INFO} Saving current rules for persistence...${NC}"
    if [[ -d "/etc/iptables" ]]; then
        $IPS > /etc/iptables/rules.v4
        echo -e "${GREEN}${CHECK} Rules saved to /etc/iptables/rules.v4${NC}"
    else
        echo -e "${RED}${CROSS} Error: /etc/iptables directory not found. Please install iptables-persistent.${NC}"
    fi
}

case "$1" in
    start)
        start_antiddos
        ;;
    stop)
        stop_antiddos
        ;;
    status)
        status_antiddos
        ;;
    restart)
        stop_antiddos
        start_antiddos
        ;;
    clear)
        clear_rules
        ;;
    whitelist)
        whitelist_ip "$2"
        ;;
    blacklist)
        blacklist_ip "$2"
        ;;
    monitor)
        monitor_traffic
        ;;
    save)
        save_persistence
        ;;
    *)
        show_banner
        echo -e "${BOLD}Usage:${NC} $0 {start|stop|restart|status|clear|whitelist|blacklist|monitor|save}"
        echo ""
        echo -e "  ${CYAN}start${NC}      : Apply all Anti-DDoS rules"
        echo -e "  ${CYAN}stop${NC}       : Remove all rules"
        echo -e "  ${CYAN}status${NC}     : Show current protection status"
        echo -e "  ${CYAN}monitor${NC}    : Show real-time traffic dashboard"
        echo -e "  ${CYAN}whitelist${NC}  : Whitelist an IP address (${BOLD}usage:${NC} whitelist <IP>)"
        echo -e "  ${CYAN}blacklist${NC}  : Blacklist an IP address (${BOLD}usage:${NC} blacklist <IP>)"
        echo -e "  ${CYAN}save${NC}       : Save rules for persistence (requires iptables-persistent)"
        exit 1
esac

exit 0
