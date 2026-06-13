#!/usr/bin/env bash
# ShadowDeck v2 — Blue Team | Log Analyzer Module
# modules/blue/loganalyzer.sh

RESET='\033[0m'
GREEN='\033[38;5;82m'
GREEN_DIM='\033[38;5;22m'
GREEN_HI='\033[38;5;118m'
RED='\033[38;5;196m'
AMBER='\033[38;5;214m'
CYAN='\033[38;5;51m'
BOLD='\033[1m'

LOGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../logs" && pwd)"
WORK_DIR="$LOGS_DIR/loganalyzer"
mkdir -p "$WORK_DIR"

dim_line()  { echo -e "${GREEN_DIM}$(printf '─%.0s' {1..70})${RESET}"; }
thick_line(){ echo -e "${GREEN}$(printf '═%.0s' {1..70})${RESET}"; }
info()  { echo -e "${CYAN}[*]${RESET} $1"; }
ok()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${AMBER}[!]${RESET} $1"; }
err()   { echo -e "${RED}[✗]${RESET} $1"; }
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [LOGANALYZER] $1" >> "$LOGS_DIR/shadowdeck.log"; }
press_enter() { echo -e "\n${GREEN_DIM}  Press Enter to return...${RESET}"; read -r; }

pick_log() {
    echo ""
    echo -e "  ${GREEN_HI}Common log paths:${RESET}"
    echo -e "  ${GREEN_DIM}[1]${RESET} /var/log/auth.log       ${GREEN_DIM}[2]${RESET} /var/log/syslog"
    echo -e "  ${GREEN_DIM}[3]${RESET} /var/log/apache2/access.log  ${GREEN_DIM}[4]${RESET} /var/log/nginx/access.log"
    echo -e "  ${GREEN_DIM}[5]${RESET} /var/log/kern.log        ${GREEN_DIM}[6]${RESET} Custom path"
    echo -ne "\n  ${GREEN}Select${RESET}: "
    read -r lchoice
    case "$lchoice" in
        1) LOGFILE="/var/log/auth.log" ;;
        2) LOGFILE="/var/log/syslog" ;;
        3) LOGFILE="/var/log/apache2/access.log" ;;
        4) LOGFILE="/var/log/nginx/access.log" ;;
        5) LOGFILE="/var/log/kern.log" ;;
        6) echo -ne "  ${GREEN}Path${RESET}: "; read -r LOGFILE ;;
        *) err "Invalid"; return 1 ;;
    esac
    if [[ ! -f "$LOGFILE" ]]; then
        err "Log not found: $LOGFILE"
        return 1
    fi
    ok "Log: $LOGFILE"
    return 0
}

# ── AUTH LOG ANALYSIS ─────────────────────────────────────────
run_auth_analysis() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[LOG ANALYZER] Auth Log Analysis${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Failed SSH logins       ${GREEN_DIM}(brute force detect)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Top attacking IPs       ${GREEN_DIM}(sorted by count)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Successful logins       ${GREEN_DIM}(accepted passwords)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} Invalid usernames       ${GREEN_DIM}(enumeration attempts)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Sudo usage              ${GREEN_DIM}(privilege escalation)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} New user accounts       ${GREEN_DIM}(useradd/adduser)${RESET}"
        echo -e "  ${GREEN}[7]${RESET} Root login attempts     ${GREEN_DIM}(direct root access)${RESET}"
        echo -e "  ${GREEN}[8]${RESET} Full auth summary       ${GREEN_DIM}(all of the above)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@auth${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        # Default to auth.log
        LOGFILE="/var/log/auth.log"
        if [[ ! -f "$LOGFILE" ]]; then
            warn "auth.log not found — pick manually"
            pick_log || { press_enter; continue; }
        fi

        local out="$WORK_DIR/auth_$(date +%H%M%S).txt"

        case "$choice" in
            1)
                info "Failed SSH login attempts..."
                grep "Failed password" "$LOGFILE" | tee "$out"
                echo ""
                ok "Total: $(grep -c 'Failed password' "$LOGFILE" 2>/dev/null) failed attempts"
                ;;
            2)
                info "Top attacking IPs..."
                grep "Failed password" "$LOGFILE" | \
                    awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | \
                    sort | uniq -c | sort -rn | head -20 | tee "$out"
                ;;
            3)
                info "Successful logins..."
                grep "Accepted password\|Accepted publickey" "$LOGFILE" | tee "$out"
                echo ""
                ok "Total: $(grep -c 'Accepted' "$LOGFILE" 2>/dev/null) successful logins"
                ;;
            4)
                info "Invalid username attempts..."
                grep "Invalid user" "$LOGFILE" | \
                    awk '{print $8}' | sort | uniq -c | sort -rn | head -20 | tee "$out"
                ;;
            5)
                info "Sudo usage..."
                grep "sudo" "$LOGFILE" | grep -v "pam_unix" | tee "$out"
                ;;
            6)
                info "New user accounts created..."
                grep -i "useradd\|adduser\|new user" "$LOGFILE" | tee "$out"
                ;;
            7)
                info "Root login attempts..."
                grep "root" "$LOGFILE" | grep -i "failed\|invalid\|accepted" | tee "$out"
                ;;
            8)
                local full_out="$WORK_DIR/auth_full_$(date +%H%M%S).txt"
                {
                    echo "=== AUTH LOG SUMMARY: $LOGFILE ==="
                    echo "Generated: $(date)"
                    echo ""
                    echo "--- FAILED LOGIN COUNT ---"
                    grep -c "Failed password" "$LOGFILE" 2>/dev/null || echo "0"
                    echo ""
                    echo "--- TOP 10 ATTACKING IPs ---"
                    grep "Failed password" "$LOGFILE" | \
                        awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | \
                        sort | uniq -c | sort -rn | head -10
                    echo ""
                    echo "--- SUCCESSFUL LOGINS ---"
                    grep "Accepted password\|Accepted publickey" "$LOGFILE"
                    echo ""
                    echo "--- INVALID USERNAMES (top 10) ---"
                    grep "Invalid user" "$LOGFILE" | awk '{print $8}' | \
                        sort | uniq -c | sort -rn | head -10
                    echo ""
                    echo "--- SUDO USAGE ---"
                    grep "sudo" "$LOGFILE" | grep -v "pam_unix" | tail -20
                    echo ""
                    echo "--- NEW USERS CREATED ---"
                    grep -i "useradd\|adduser\|new user" "$LOGFILE"
                } | tee "$full_out"
                ok "Full report → $full_out"
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac
        [[ "$choice" != "8" ]] && ok "Output → $out"
        press_enter
    done
}

# ── WEB LOG ANALYSIS ──────────────────────────────────────────
run_web_analysis() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[LOG ANALYZER] Web Access Log Analysis${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Top 20 requesting IPs"
        echo -e "  ${GREEN}[2]${RESET} HTTP status code breakdown"
        echo -e "  ${GREEN}[3]${RESET} Top requested URLs"
        echo -e "  ${GREEN}[4]${RESET} Large file transfers     ${GREEN_DIM}(>1MB — data exfil detect)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} SQLi attempts            ${GREEN_DIM}(union/select/drop)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} XSS attempts             ${GREEN_DIM}(script tags)${RESET}"
        echo -e "  ${GREEN}[7]${RESET} Scanner detection        ${GREEN_DIM}(nikto/nmap/sqlmap/nessus)${RESET}"
        echo -e "  ${GREEN}[8]${RESET} LFI/traversal attempts   ${GREEN_DIM}(../etc/passwd)${RESET}"
        echo -e "  ${GREEN}[9]${RESET} POST requests            ${GREEN_DIM}(form submissions)${RESET}"
        echo -e "  ${GREEN}[10]${RESET} 404 flood detect        ${GREEN_DIM}(dir brute force)${RESET}"
        echo -e "  ${GREEN}[11]${RESET} Full web threat report  ${GREEN_DIM}(all checks)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@weblogs${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        pick_log || { press_enter; continue; }
        local out="$WORK_DIR/weblog_$(date +%H%M%S).txt"

        case "$choice" in
            1)
                info "Top 20 requesting IPs..."
                awk '{print $1}' "$LOGFILE" | sort | uniq -c | sort -rn | head -20 | tee "$out"
                ;;
            2)
                info "HTTP status code breakdown..."
                awk '{print $9}' "$LOGFILE" | sort | uniq -c | sort -rn | tee "$out"
                ;;
            3)
                info "Top 20 requested URLs..."
                awk '{print $7}' "$LOGFILE" | sort | uniq -c | sort -rn | head -20 | tee "$out"
                ;;
            4)
                info "Large transfers (>1MB)..."
                awk '$10 > 1000000 {print $1, $7, $10, "bytes"}' "$LOGFILE" | tee "$out"
                echo ""
                ok "Count: $(awk '$10 > 1000000' "$LOGFILE" | wc -l) large transfers"
                ;;
            5)
                info "SQL injection attempts..."
                grep -i "union\|select\|insert\|drop\|truncate\|sleep(\|benchmark(\|0x\|char(" "$LOGFILE" | tee "$out"
                echo ""
                ok "Count: $(grep -ci "union\|select\|drop" "$LOGFILE") SQLi-pattern hits"
                ;;
            6)
                info "XSS attempts..."
                grep -i "script\|onerror\|onload\|alert(\|javascript:" "$LOGFILE" | tee "$out"
                echo ""
                ok "Count: $(grep -ci "script\|onerror\|alert(" "$LOGFILE") XSS-pattern hits"
                ;;
            7)
                info "Scanner signatures detected..."
                grep -i "nikto\|nmap\|sqlmap\|nessus\|masscan\|dirbuster\|gobuster\|hydra\|metasploit\|python-requests\|curl\|wget" "$LOGFILE" | tee "$out"
                ;;
            8)
                info "LFI/path traversal attempts..."
                grep -i "\.\./\|etc/passwd\|etc/shadow\|proc/self\|windows/win.ini\|boot.ini" "$LOGFILE" | tee "$out"
                ;;
            9)
                info "POST requests..."
                grep '"POST' "$LOGFILE" | tee "$out"
                echo ""
                ok "Count: $(grep -c '"POST' "$LOGFILE") POST requests"
                ;;
            10)
                info "404 flood (dir brute force detect)..."
                awk '$9==404 {print $1}' "$LOGFILE" | sort | uniq -c | sort -rn | head -20 | tee "$out"
                echo ""
                local total_404
                total_404=$(awk '$9==404' "$LOGFILE" | wc -l)
                warn "Total 404s: $total_404"
                ;;
            11)
                local full_out="$WORK_DIR/web_threat_report_$(date +%H%M%S).txt"
                {
                    echo "=== WEB THREAT REPORT: $LOGFILE ==="
                    echo "Generated: $(date)"
                    echo ""
                    echo "--- TOP 10 IPs ---"
                    awk '{print $1}' "$LOGFILE" | sort | uniq -c | sort -rn | head -10
                    echo ""
                    echo "--- STATUS CODES ---"
                    awk '{print $9}' "$LOGFILE" | sort | uniq -c | sort -rn
                    echo ""
                    echo "--- SQLi ATTEMPTS (count) ---"
                    grep -ci "union\|select\|drop\|sleep(" "$LOGFILE" 2>/dev/null || echo "0"
                    echo ""
                    echo "--- XSS ATTEMPTS (count) ---"
                    grep -ci "script\|onerror\|alert(" "$LOGFILE" 2>/dev/null || echo "0"
                    echo ""
                    echo "--- LFI ATTEMPTS ---"
                    grep -i "\.\./\|etc/passwd\|etc/shadow" "$LOGFILE"
                    echo ""
                    echo "--- SCANNERS DETECTED ---"
                    grep -i "nikto\|sqlmap\|nessus\|masscan\|dirbuster\|gobuster" "$LOGFILE"
                    echo ""
                    echo "--- 404 FLOOD (top 10 IPs) ---"
                    awk '$9==404 {print $1}' "$LOGFILE" | sort | uniq -c | sort -rn | head -10
                    echo ""
                    echo "--- LARGE TRANSFERS >1MB ---"
                    awk '$10 > 1000000 {print $1, $7, $10, "bytes"}' "$LOGFILE" | head -10
                } | tee "$full_out"
                ok "Full report → $full_out"
                press_enter; continue
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac
        ok "Output → $out"
        press_enter
    done
}

# ── CUSTOM GREP HUNTER ────────────────────────────────────────
run_grep_hunter() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[LOG ANALYZER] Custom Grep Hunter${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Search keyword          ${GREEN_DIM}(case insensitive)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Search by IP address"
        echo -e "  ${GREEN}[3]${RESET} Search by date/time     ${GREEN_DIM}(e.g. Jun 13)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} Search by user          ${GREEN_DIM}(username mentions)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Regex pattern search"
        echo -e "  ${GREEN}[6]${RESET} Multi-keyword AND       ${GREEN_DIM}(grep piped)${RESET}"
        echo -e "  ${GREEN}[7]${RESET} Count occurrences       ${GREEN_DIM}(-c flag)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@grep${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        pick_log || { press_enter; continue; }
        local out="$WORK_DIR/grep_$(date +%H%M%S).txt"
        local cmd=""

        case "$choice" in
            1)
                echo -ne "  ${GREEN}Keyword${RESET}: "; read -r KW
                cmd="grep -i \"$KW\" \"$LOGFILE\""
                ;;
            2)
                echo -ne "  ${GREEN}IP address${RESET}: "; read -r IP
                cmd="grep \"$IP\" \"$LOGFILE\""
                ;;
            3)
                echo -ne "  ${GREEN}Date/time string${RESET} (e.g. 'Jun 13' or '13/Jun'): "; read -r DT
                cmd="grep \"$DT\" \"$LOGFILE\""
                ;;
            4)
                echo -ne "  ${GREEN}Username${RESET}: "; read -r USER
                cmd="grep -i \"$USER\" \"$LOGFILE\""
                ;;
            5)
                echo -ne "  ${GREEN}Regex pattern${RESET}: "; read -r REGEX
                cmd="grep -E \"$REGEX\" \"$LOGFILE\""
                ;;
            6)
                echo -ne "  ${GREEN}Keyword 1${RESET}: "; read -r KW1
                echo -ne "  ${GREEN}Keyword 2${RESET}: "; read -r KW2
                cmd="grep -i \"$KW1\" \"$LOGFILE\" | grep -i \"$KW2\""
                ;;
            7)
                echo -ne "  ${GREEN}Keyword${RESET}: "; read -r KW
                cmd="grep -ci \"$KW\" \"$LOGFILE\""
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac

        echo ""
        info "Running: ${CYAN}$cmd${RESET}"
        dim_line
        log "CMD: $cmd"
        eval "$cmd" 2>&1 | tee "$out"
        ok "Output → $out"
        press_enter
    done
}

# ── IOC HUNTER ────────────────────────────────────────────────
run_ioc_hunter() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[LOG ANALYZER] IOC Hunter — Indicator of Compromise${RESET}"
    thick_line
    pick_log || { press_enter; return; }

    local out="$WORK_DIR/ioc_$(date +%H%M%S).txt"
    local hits=0

    {
        echo "=== IOC HUNT REPORT ==="
        echo "Log: $LOGFILE"
        echo "Date: $(date)"
        echo ""

        echo "--- [1] BRUTE FORCE INDICATORS ---"
        local bf
        bf=$(grep -c "Failed password\|authentication failure\|Invalid user" "$LOGFILE" 2>/dev/null || echo 0)
        echo "Auth failures: $bf"
        if [[ "$bf" -gt 50 ]]; then
            echo "[!] HIGH — possible brute force ($bf failures)"
            ((hits++))
        fi

        echo ""
        echo "--- [2] PRIVILEGE ESCALATION ---"
        grep -i "sudo\|su -\|NOPASSWD\|sudoers" "$LOGFILE" | grep -v "pam_unix" | head -10
        grep -c "sudo" "$LOGFILE" 2>/dev/null | xargs echo "Sudo events:"

        echo ""
        echo "--- [3] LATERAL MOVEMENT (SSH) ---"
        grep "Accepted" "$LOGFILE" | head -10
        local accepted
        accepted=$(grep -c "Accepted" "$LOGFILE" 2>/dev/null || echo 0)
        echo "Successful SSH logins: $accepted"

        echo ""
        echo "--- [4] WEB ATTACKS ---"
        local sqli xss lfi
        sqli=$(grep -ci "union.*select\|sleep(\|benchmark(" "$LOGFILE" 2>/dev/null || echo 0)
        xss=$(grep -ci "<script\|onerror=\|alert(" "$LOGFILE" 2>/dev/null || echo 0)
        lfi=$(grep -ci "\.\./\|etc/passwd" "$LOGFILE" 2>/dev/null || echo 0)
        echo "SQLi patterns: $sqli"
        echo "XSS patterns:  $xss"
        echo "LFI patterns:  $lfi"
        [[ "$sqli" -gt 0 ]] && { echo "[!] SQLi attempts detected"; ((hits++)); }
        [[ "$xss" -gt 0 ]]  && { echo "[!] XSS attempts detected"; ((hits++)); }
        [[ "$lfi" -gt 0 ]]  && { echo "[!] LFI attempts detected"; ((hits++)); }

        echo ""
        echo "--- [5] RECON / SCANNING ---"
        grep -i "nikto\|sqlmap\|nessus\|masscan\|dirbuster\|gobuster\|nmap" "$LOGFILE" | head -5
        local scanners
        scanners=$(grep -ci "nikto\|sqlmap\|nessus\|masscan\|dirbuster\|gobuster" "$LOGFILE" 2>/dev/null || echo 0)
        [[ "$scanners" -gt 0 ]] && { echo "[!] Scanner activity detected"; ((hits++)); }

        echo ""
        echo "--- [6] DATA EXFILTRATION ---"
        awk '$10 > 5000000 {print "[!] Large transfer:", $1, $7, $10, "bytes"}' "$LOGFILE" | head -10

        echo ""
        echo "--- [7] SUSPICIOUS USER AGENTS ---"
        grep -i "curl\|wget\|python\|perl\|ruby\|go-http" "$LOGFILE" | \
            awk -F'"' '{print $6}' | sort | uniq -c | sort -rn | head -10

        echo ""
        echo "==============================="
        echo "TOTAL IOC HITS: $hits"
        if [[ "$hits" -eq 0 ]]; then
            echo "STATUS: CLEAN (no obvious IOCs)"
        elif [[ "$hits" -lt 3 ]]; then
            echo "STATUS: LOW RISK — review manually"
        else
            echo "STATUS: [!] HIGH RISK — investigate immediately"
        fi
        echo "==============================="

    } | tee "$out"

    ok "IOC report → $out"
    press_enter
}

# ── LIVE LOG MONITOR ──────────────────────────────────────────
run_live_monitor() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[LOG ANALYZER] Live Log Monitor${RESET}"
    thick_line
    pick_log || { press_enter; return; }

    echo ""
    echo -e "  ${GREEN}[1]${RESET} Monitor all entries     ${GREEN_DIM}(tail -f)${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Monitor + filter        ${GREEN_DIM}(tail -f | grep)${RESET}"
    echo -e "  ${GREEN}[3]${RESET} Monitor + highlight     ${GREEN_DIM}(color keywords)${RESET}"
    echo -ne "\n  ${GREEN_HI}monitor${RESET}${GREEN} > ${RESET}"
    read -r choice

    warn "Press Ctrl+C to stop monitoring"
    echo ""
    sleep 1

    case "$choice" in
        1)
            tail -f "$LOGFILE"
            ;;
        2)
            echo -ne "  ${GREEN}Filter keyword${RESET}: "; read -r KW
            tail -f "$LOGFILE" | grep -i --line-buffered "$KW"
            ;;
        3)
            # Colorize key events
            tail -f "$LOGFILE" | \
                GREP_COLOR='01;31' grep -i --color=always "failed\|error\|invalid\|attack" | \
                GREP_COLOR='01;32' grep -i --color=always "accepted\|success\|ok" || \
            tail -f "$LOGFILE" | grep -i --line-buffered \
                -e "Failed" -e "Invalid" -e "error" \
                -e "Accepted" -e "success"
            ;;
        *) warn "Invalid" ;;
    esac
    press_enter
}

# ── MAIN MENU ─────────────────────────────────────────────────
while true; do
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[ BLUE TEAM → LOG ANALYZER ]${RESET}"
    thick_line
    echo -e "  ${GREEN}[1]${RESET} Auth Log Analysis    ${GREEN_DIM}— SSH brute, sudo, new users${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Web Log Analysis     ${GREEN_DIM}— SQLi, XSS, LFI, scanners, 404 flood${RESET}"
    echo -e "  ${GREEN}[3]${RESET} Custom Grep Hunter   ${GREEN_DIM}— keyword/IP/date/regex search${RESET}"
    echo -e "  ${GREEN}[4]${RESET} IOC Hunter           ${GREEN_DIM}— automated threat indicator scan${RESET}"
    echo -e "  ${GREEN}[5]${RESET} Live Log Monitor     ${GREEN_DIM}— tail -f with optional filter${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back to Dashboard${RESET}"
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@loganalyzer${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1) run_auth_analysis ;;
        2) run_web_analysis ;;
        3) run_grep_hunter ;;
        4) run_ioc_hunter ;;
        5) run_live_monitor ;;
        0) exit 0 ;;
        *) warn "Invalid option"; sleep 0.8 ;;
    esac
done
