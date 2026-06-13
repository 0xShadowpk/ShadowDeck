#!/usr/bin/env bash
# ShadowDeck v2 — Red Team | Recon Module
# modules/red/recon.sh

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
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [RECON] $1" >> "$LOGS_DIR/shadowdeck.log"; }

get_target() {
    echo -ne "\n  ${GREEN_HI}Target IP/Domain${RESET} ${GREEN_DIM}(e.g. 10.10.10.10 or example.com)${RESET}: "
    read -r TARGET
    if [[ -z "$TARGET" ]]; then
        err "No target specified."; sleep 1; return 1
    fi
    log "Target set: $TARGET"
    return 0
}

get_output_file() {
    local prefix="$1"
    echo -ne "  ${GREEN_DIM}Save output to file? [y/N]: ${RESET}"
    read -r save
    if [[ "$save" =~ ^[Yy]$ ]]; then
        OUTFILE="$LOGS_DIR/${prefix}_$(echo "$TARGET" | tr '/' '_')_$(date +%H%M%S)"
        ok "Output → $OUTFILE"
    else
        OUTFILE=""
    fi
}

press_enter() { echo -e "\n${GREEN_DIM}  Press Enter to return...${RESET}"; read -r; }

# ── NMAP ──────────────────────────────────────────────────────
run_nmap() {
    while true; do
        clear; thick_line
        echo -e "  ${RED}${BOLD}[RECON] NMAP Scanner${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Quick Scan          ${GREEN_DIM}(top 1000 ports, -sV -sC)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Full Port Scan       ${GREEN_DIM}(-p- --min-rate 5000)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} UDP Top 100          ${GREEN_DIM}(-sU --top-ports 100)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} OS + Aggro Detect    ${GREEN_DIM}(-O -A)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Vuln Scripts         ${GREEN_DIM}(--script vuln)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} Stealth SYN Scan     ${GREEN_DIM}(-sS -T2)${RESET}"
        echo -e "  ${GREEN}[7]${RESET} Custom Flags         ${GREEN_DIM}(you type the flags)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}nmap${RESET}${GREEN} > ${RESET}"
        read -r choice

        [[ "$choice" == "0" ]] && break
        get_target || continue
        get_output_file "nmap"

        local cmd=""
        case "$choice" in
            1) cmd="nmap -sV -sC $TARGET" ;;
            2) cmd="nmap -p- --min-rate 5000 -sV $TARGET" ;;
            3) cmd="sudo nmap -sU --top-ports 100 $TARGET" ;;
            4) cmd="sudo nmap -O -A $TARGET" ;;
            5) cmd="nmap --script vuln $TARGET" ;;
            6) cmd="sudo nmap -sS -T2 $TARGET" ;;
            7)
                echo -ne "  ${GREEN}Custom nmap flags${RESET}: nmap "
                read -r custom_flags
                cmd="nmap $custom_flags $TARGET"
                ;;
            *) warn "Invalid option"; sleep 0.8; continue ;;
        esac

        echo ""
        info "Running: ${CYAN}$cmd${RESET}"
        dim_line
        log "CMD: $cmd"

        if [[ -n "$OUTFILE" ]]; then
            eval "$cmd" 2>&1 | tee "${OUTFILE}.txt"
            ok "Saved to ${OUTFILE}.txt"
        else
            eval "$cmd"
        fi
        press_enter
    done
}

# ── GOBUSTER ──────────────────────────────────────────────────
run_gobuster() {
    # Default wordlists
    WL_DIR="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
    WL_DNS="/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
    WL_SMALL="/usr/share/wordlists/dirb/common.txt"

    while true; do
        clear; thick_line
        echo -e "  ${RED}${BOLD}[RECON] Gobuster${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Directory Brute      ${GREEN_DIM}(medium wordlist)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Directory + Ext      ${GREEN_DIM}(php,html,txt,bak)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} DNS Subdomain        ${GREEN_DIM}(subdomains-top1m)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} Quick Dir            ${GREEN_DIM}(dirb/common.txt)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Custom wordlist      ${GREEN_DIM}(you specify path)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}gobuster${RESET}${GREEN} > ${RESET}"
        read -r choice

        [[ "$choice" == "0" ]] && break
        get_target || continue

        # Validate URL for dir mode
        local url="$TARGET"
        if [[ "$choice" != "3" ]]; then
            if [[ ! "$url" =~ ^https?:// ]]; then
                warn "No protocol detected — assuming http://"
                url="http://$TARGET"
            fi
        fi

        get_output_file "gobuster"

        local cmd=""
        case "$choice" in
            1) cmd="gobuster dir -u $url -w $WL_DIR -t 50" ;;
            2) cmd="gobuster dir -u $url -w $WL_DIR -x php,html,txt,bak -t 50" ;;
            3) cmd="gobuster dns -d $TARGET -w $WL_DNS -t 50" ;;
            4) cmd="gobuster dir -u $url -w $WL_SMALL -t 30" ;;
            5)
                echo -ne "  ${GREEN}Wordlist path${RESET}: "
                read -r custom_wl
                if [[ ! -f "$custom_wl" ]]; then
                    err "Wordlist not found: $custom_wl"; sleep 1; continue
                fi
                cmd="gobuster dir -u $url -w $custom_wl -t 50"
                ;;
            *) warn "Invalid option"; sleep 0.8; continue ;;
        esac

        echo ""
        info "Running: ${CYAN}$cmd${RESET}"
        dim_line
        log "CMD: $cmd"

        if [[ -n "$OUTFILE" ]]; then
            eval "$cmd" 2>&1 | tee "${OUTFILE}.txt"
            ok "Saved to ${OUTFILE}.txt"
        else
            eval "$cmd"
        fi
        press_enter
    done
}

# ── FFUF ──────────────────────────────────────────────────────
run_ffuf() {
    WL_BIG="/usr/share/seclists/Discovery/Web-Content/big.txt"
    WL_COMMON="/usr/share/wordlists/dirb/common.txt"
    WL_SUB="/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
    WL_PARAM="/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt"

    while true; do
        clear; thick_line
        echo -e "  ${RED}${BOLD}[RECON] FFUF — Fuzzer${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Directory Fuzz       ${GREEN_DIM}(big.txt)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Subdomain Fuzz       ${GREEN_DIM}(vhost/subdomain)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} GET Parameter Fuzz   ${GREEN_DIM}(param names)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} POST Parameter Fuzz  ${GREEN_DIM}(custom body)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} File Extension Fuzz  ${GREEN_DIM}(find hidden files)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} Custom FUZZ          ${GREEN_DIM}(full manual URL)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}ffuf${RESET}${GREEN} > ${RESET}"
        read -r choice

        [[ "$choice" == "0" ]] && break
        get_target || continue

        local url="$TARGET"
        if [[ ! "$url" =~ ^https?:// ]]; then
            warn "No protocol — assuming http://"
            url="http://$TARGET"
        fi

        get_output_file "ffuf"

        local cmd=""
        case "$choice" in
            1) cmd="ffuf -u $url/FUZZ -w $WL_BIG -t 50" ;;
            2)
                echo -ne "  ${GREEN}Domain${RESET} (e.g. example.com): "
                read -r domain
                cmd="ffuf -u http://FUZZ.$domain -w $WL_SUB -H \"Host: FUZZ.$domain\" -t 50"
                ;;
            3) cmd="ffuf -u $url?FUZZ=test -w $WL_PARAM -t 50" ;;
            4)
                echo -ne "  ${GREEN}POST body${RESET} (e.g. user=FUZZ&pass=test): "
                read -r body
                cmd="ffuf -u $url -X POST -d \"$body\" -w $WL_COMMON -t 50"
                ;;
            5)
                echo -ne "  ${GREEN}Filename base${RESET} (e.g. index): "
                read -r fname
                cmd="ffuf -u $url/${fname}.FUZZ -w /usr/share/seclists/Discovery/Web-Content/web-extensions.txt -t 30"
                ;;
            6)
                echo -ne "  ${GREEN}Full URL with FUZZ keyword${RESET}: "
                read -r custom_url
                echo -ne "  ${GREEN}Wordlist path${RESET}: "
                read -r custom_wl
                cmd="ffuf -u $custom_url -w $custom_wl -t 50"
                ;;
            *) warn "Invalid option"; sleep 0.8; continue ;;
        esac

        # Optional: filter by status code
        echo -ne "  ${GREEN_DIM}Filter out status code? (e.g. 404, leave blank to skip): ${RESET}"
        read -r filter_code
        [[ -n "$filter_code" ]] && cmd="$cmd -fc $filter_code"

        echo ""
        info "Running: ${CYAN}$cmd${RESET}"
        dim_line
        log "CMD: $cmd"

        if [[ -n "$OUTFILE" ]]; then
            eval "$cmd" 2>&1 | tee "${OUTFILE}.txt"
            ok "Saved to ${OUTFILE}.txt"
        else
            eval "$cmd"
        fi
        press_enter
    done
}

# ── RECON MAIN MENU ───────────────────────────────────────────
while true; do
    clear; thick_line
    echo -e "  ${RED}${BOLD}[ RED TEAM → RECON ]${RESET}"
    thick_line
    echo -e "  ${GREEN}[1]${RESET} NMAP Scanner         ${GREEN_DIM}— port scan, OS detect, vulns${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Gobuster             ${GREEN_DIM}— dir/dns brute force${RESET}"
    echo -e "  ${GREEN}[3]${RESET} FFUF                 ${GREEN_DIM}— web fuzzer (dir/subdomain/params)${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back to Dashboard${RESET}"
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@recon${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1) run_nmap ;;
        2) run_gobuster ;;
        3) run_ffuf ;;
        0) exit 0 ;;
        *) warn "Invalid option"; sleep 0.8 ;;
    esac
done
