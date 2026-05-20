#!/bin/bash

# ============================================
#   SHADOWDECK - KALI EDITION
#   by shadowpk
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
 ███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗██████╗ ██╗  ██╗
 ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║██╔══██╗██║ ██╔╝
 ███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║██████╔╝█████╔╝ 
 ╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║██╔═══╝ ██╔═██╗ 
 ███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝██║     ██║  ██╗
 ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝     ╚═╝  ╚═╝
EOF
    echo -e "${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${YELLOW}User:${NC} shadowpk   ${YELLOW}Host:${NC} kali-nethunter   ${YELLOW}Mode:${NC} ${RED}KALI EDITION${NC}"
    echo -e " ${YELLOW}Time:${NC} $(date '+%d %b %Y | %H:%M:%S')"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

pause() {
    echo ""
    echo -e "${YELLOW}[Press ENTER to return to menu]${NC}"
    read
}

# ─── TOOLS ───────────────────────────────────────────

nmap_scan() {
    echo -e "${CYAN}[ NMAP SCAN ]${NC}"
    echo -e "1) Quick Scan (top ports)"
    echo -e "2) Full Port Scan"
    echo -e "3) Service/Version Detection"
    echo -e "4) OS Detection (requires root)"
    read -p "Choose: " ns
    read -p "Target (IP or domain): " target
    case $ns in
        1) nmap -sT --top-ports 100 $target ;;
        2) nmap -sT -p- $target ;;
        3) nmap -sT -sV $target ;;
        4) sudo nmap -sT -O $target ;;
        *) echo "Invalid" ;;
    esac
    pause
}

whois_lookup() {
    echo -e "${CYAN}[ WHOIS LOOKUP ]${NC}"
    read -p "Domain or IP: " target
    whois $target
    pause
}

ping_test() {
    echo -e "${CYAN}[ PING TEST ]${NC}"
    read -p "Target: " target
    read -p "Count [default 4]: " count
    count=${count:-4}
    ping -c $count $target
    pause
}

traceroute_tool() {
    echo -e "${CYAN}[ TRACEROUTE ]${NC}"
    read -p "Target: " target
    traceroute $target
    pause
}

ip_info() {
    echo -e "${CYAN}[ IP INFO ]${NC}"
    read -p "IP address: " ip
    curl -s "https://ipinfo.io/$ip" | python3 -m json.tool 2>/dev/null || curl -s "https://ipinfo.io/$ip"
    pause
}

password_check() {
    echo -e "${CYAN}[ PASSWORD STRENGTH CHECK ]${NC}"
    read -p "Enter password: " -s pass
    echo ""
    len=${#pass}
    score=0
    [[ $len -ge 8 ]] && score=$((score+1))
    [[ $len -ge 12 ]] && score=$((score+1))
    [[ "$pass" =~ [A-Z] ]] && score=$((score+1))
    [[ "$pass" =~ [a-z] ]] && score=$((score+1))
    [[ "$pass" =~ [0-9] ]] && score=$((score+1))
    [[ "$pass" =~ [\!\@\#\$\%\^\&\*] ]] && score=$((score+1))
    echo -e "Length: $len characters"
    if [ $score -le 2 ]; then
        echo -e "${RED}Strength: WEAK${NC}"
    elif [ $score -le 4 ]; then
        echo -e "${YELLOW}Strength: MODERATE${NC}"
    else
        echo -e "${GREEN}Strength: STRONG${NC}"
    fi
    pause
}

dns_lookup() {
    echo -e "${CYAN}[ DNS LOOKUP ]${NC}"
    read -p "Domain: " domain
    echo -e "\n${YELLOW}A Records:${NC}"
    dig +short A $domain
    echo -e "\n${YELLOW}MX Records:${NC}"
    dig +short MX $domain
    echo -e "\n${YELLOW}NS Records:${NC}"
    dig +short NS $domain
    echo -e "\n${YELLOW}TXT Records:${NC}"
    dig +short TXT $domain
    pause
}

open_ports() {
    echo -e "${CYAN}[ SHOW OPEN PORTS - LOCAL ]${NC}"
    ss -tulnp 2>/dev/null || netstat -tulnp
    pause
}

public_ip() {
    echo -e "${CYAN}[ MY PUBLIC IP ]${NC}"
    echo -e "Public IP: ${GREEN}$(curl -s ifconfig.me)${NC}"
    echo -e "Alt check:  ${GREEN}$(curl -s icanhazip.com)${NC}"
    pause
}

system_monitor() {
    echo -e "${CYAN}[ SYSTEM MONITOR ]${NC}"
    echo -e "\n${YELLOW}── CPU & Memory ──${NC}"
    free -h
    echo -e "\n${YELLOW}── Disk Usage ──${NC}"
    df -h /
    echo -e "\n${YELLOW}── Top Processes ──${NC}"
    top -bn1 | head -20
    pause
}

nikto_scan() {
    echo -e "${CYAN}[ NIKTO WEB SCANNER ]${NC}"
    read -p "Target URL (e.g. http://example.com): " target
    if command -v nikto &>/dev/null; then
        nikto -h $target
    else
        echo -e "${RED}Nikto not installed. Run: sudo apt install nikto${NC}"
    fi
    pause
}

gobuster_scan() {
    echo -e "${CYAN}[ GOBUSTER - DIRECTORY BRUTE FORCE ]${NC}"
    read -p "Target URL: " target
    read -p "Wordlist path [default: /usr/share/wordlists/dirb/common.txt]: " wlist
    wlist=${wlist:-/usr/share/wordlists/dirb/common.txt}
    if command -v gobuster &>/dev/null; then
        gobuster dir -u $target -w $wlist
    else
        echo -e "${RED}Gobuster not installed. Run: sudo apt install gobuster${NC}"
    fi
    pause
}

hydra_brute() {
    echo -e "${CYAN}[ HYDRA - LOGIN BRUTE FORCE ]${NC}"
    echo -e "${RED}[!] Only use on systems you own or have permission to test!${NC}"
    read -p "Target IP: " target
    read -p "Service (ssh/ftp/http-post-form): " service
    read -p "Username: " user
    read -p "Wordlist path: " wlist
    if command -v hydra &>/dev/null; then
        hydra -l $user -P $wlist $target $service
    else
        echo -e "${RED}Hydra not installed. Run: sudo apt install hydra${NC}"
    fi
    pause
}

arp_scan() {
    echo -e "${CYAN}[ ARP SCAN - LOCAL NETWORK ]${NC}"
    read -p "Network range (e.g. 192.168.1.0/24): " range
    if command -v arp-scan &>/dev/null; then
        sudo arp-scan $range
    else
        echo -e "${YELLOW}arp-scan not found. Trying nmap...${NC}"
        nmap -sn $range
    fi
    pause
}

hash_id() {
    echo -e "${CYAN}[ HASH IDENTIFIER ]${NC}"
    read -p "Enter hash: " hash
    len=${#hash}
    echo -e "\nHash length: $len characters"
    case $len in
        32)  echo -e "Possible: ${GREEN}MD5${NC}" ;;
        40)  echo -e "Possible: ${GREEN}SHA1${NC}" ;;
        56)  echo -e "Possible: ${GREEN}SHA224${NC}" ;;
        64)  echo -e "Possible: ${GREEN}SHA256${NC}" ;;
        96)  echo -e "Possible: ${GREEN}SHA384${NC}" ;;
        128) echo -e "Possible: ${GREEN}SHA512${NC}" ;;
        *)   echo -e "Possible: ${YELLOW}Unknown / NTLM / bcrypt${NC}" ;;
    esac
    if command -v hash-identifier &>/dev/null; then
        echo $hash | hash-identifier
    fi
    pause
}

ssl_check() {
    echo -e "${CYAN}[ SSL CERTIFICATE CHECKER ]${NC}"
    read -p "Domain (without https://): " domain
    echo | openssl s_client -connect $domain:443 -servername $domain 2>/dev/null | openssl x509 -noout -dates -subject -issuer
    pause
}

subdomain_finder() {
    echo -e "${CYAN}[ SUBDOMAIN FINDER ]${NC}"
    read -p "Domain: " domain
    echo -e "${YELLOW}Common subdomains check:${NC}"
    for sub in www mail ftp admin dev api vpn smtp pop3 test staging; do
        result=$(host $sub.$domain 2>/dev/null | grep "has address")
        if [ ! -z "$result" ]; then
            echo -e "${GREEN}[+] $sub.$domain${NC} → $result"
        fi
    done
    echo -e "\n${YELLOW}For deep scan install: sudo apt install subfinder${NC}"
    pause
}

netcat_listener() {
    echo -e "${CYAN}[ NETCAT LISTENER ]${NC}"
    read -p "Port to listen on: " port
    echo -e "${YELLOW}Listening on port $port... (CTRL+C to stop)${NC}"
    nc -lvnp $port
    pause
}

packet_capture() {
    echo -e "${CYAN}[ PACKET CAPTURE - tcpdump ]${NC}"
    echo -e "${YELLOW}Available interfaces:${NC}"
    ip link show | grep '^[0-9]' | awk '{print $2}' | tr -d ':'
    read -p "Interface: " iface
    read -p "Packet count [default 20]: " count
    count=${count:-20}
    sudo tcpdump -i $iface -c $count
    pause
}

msf_launch() {
    echo -e "${CYAN}[ METASPLOIT FRAMEWORK ]${NC}"
    if command -v msfconsole &>/dev/null; then
        msfconsole
    else
        echo -e "${RED}Metasploit not installed.${NC}"
        echo -e "Install with: ${YELLOW}sudo apt install metasploit-framework${NC}"
    fi
    pause
}

# ─── MAIN MENU ───────────────────────────────────────

main_menu() {
    while true; do
        banner
        echo -e "${WHITE}  ╔══════════════════════════════╗${NC}"
        echo -e "${WHITE}  ║       [ TOOL MENU ]          ║${NC}"
        echo -e "${WHITE}  ╚══════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}  ── NETWORK ──${NC}"
        echo -e "  ${CYAN}1)${NC}  Nmap Scan"
        echo -e "  ${CYAN}2)${NC}  Whois Lookup"
        echo -e "  ${CYAN}3)${NC}  Ping Test"
        echo -e "  ${CYAN}4)${NC}  Traceroute"
        echo -e "  ${CYAN}5)${NC}  IP Info"
        echo -e "  ${CYAN}6)${NC}  DNS Lookup"
        echo -e "  ${CYAN}7)${NC}  Show Open Ports"
        echo -e "  ${CYAN}8)${NC}  My Public IP"
        echo -e "  ${CYAN}9)${NC}  ARP Scan (LAN)"
        echo -e "  ${CYAN}10)${NC} Subdomain Finder"
        echo -e "  ${CYAN}11)${NC} SSL Certificate Check"
        echo ""
        echo -e "${RED}  ── PENTESTING ──${NC}"
        echo -e "  ${CYAN}12)${NC} Nikto Web Scanner"
        echo -e "  ${CYAN}13)${NC} Gobuster Dir Scan"
        echo -e "  ${CYAN}14)${NC} Hydra Brute Force"
        echo -e "  ${CYAN}15)${NC} Netcat Listener"
        echo -e "  ${CYAN}16)${NC} Packet Capture"
        echo -e "  ${CYAN}17)${NC} Metasploit Launch"
        echo ""
        echo -e "${YELLOW}  ── UTILS ──${NC}"
        echo -e "  ${CYAN}18)${NC} Password Strength Check"
        echo -e "  ${CYAN}19)${NC} Hash Identifier"
        echo -e "  ${CYAN}20)${NC} System Monitor"
        echo ""
        echo -e "  ${RED}0)${NC}  Exit"
        echo ""
        echo -ne "${GREEN}shadowpk@kali ${CYAN}➜ ${NC}Choose option: "
        read choice

        case $choice in
            1)  nmap_scan ;;
            2)  whois_lookup ;;
            3)  ping_test ;;
            4)  traceroute_tool ;;
            5)  ip_info ;;
            6)  dns_lookup ;;
            7)  open_ports ;;
            8)  public_ip ;;
            9)  arp_scan ;;
            10) subdomain_finder ;;
            11) ssl_check ;;
            12) nikto_scan ;;
            13) gobuster_scan ;;
            14) hydra_brute ;;
            15) netcat_listener ;;
            16) packet_capture ;;
            17) msf_launch ;;
            18) password_check ;;
            19) hash_id ;;
            20) system_monitor ;;
            0)  echo -e "${RED}Exiting ShadowDeck...${NC}"; exit 0 ;;
            *)  echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}


main_menu
