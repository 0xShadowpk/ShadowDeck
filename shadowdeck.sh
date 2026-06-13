#!/usr/bin/env bash
# ============================================================
#  ShadowDeck v2 — Ultimate Purple Team Toolkit
#  Author : 0xShadowpk
#  Target : Kali WSL2 | HP EliteBook 840 G3
#  Repo   : git@github.com:0xShadowpk/ShadowDeck.git
# ============================================================

# ── Paths ────────────────────────────────────────────────────
SHADOWDECK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SHADOWDECK_DIR/modules"
LOGS_DIR="$SHADOWDECK_DIR/logs"
mkdir -p "$LOGS_DIR"

# ── CRT Color Palette ─────────────────────────────────────────
RESET='\033[0m'
GREEN='\033[38;5;82m'       # phosphor green — primary text
GREEN_DIM='\033[38;5;22m'   # dim green — borders / inactive
GREEN_HI='\033[38;5;118m'   # bright green — highlights / titles
RED='\033[38;5;196m'        # alert / danger
AMBER='\033[38;5;214m'      # warnings / blue-team accent
CYAN='\033[38;5;51m'        # info / links
BOLD='\033[1m'
DIM='\033[2m'
BLINK='\033[5m'

# ── Helpers ───────────────────────────────────────────────────
crt_clear() { clear; printf '\033[?25l'; }   # hide cursor on clear
crt_show_cursor() { printf '\033[?25h'; }
trap crt_show_cursor EXIT

dim_line()  { echo -e "${GREEN_DIM}$(printf '─%.0s' {1..70})${RESET}"; }
thick_line(){ echo -e "${GREEN}$(printf '═%.0s' {1..70})${RESET}"; }

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGS_DIR/shadowdeck.log"
}

require_module() {
    local mod="$MODULES_DIR/$1"
    if [[ ! -f "$mod" ]]; then
        echo -e "${RED}[!] Module not found: $1${RESET}"
        echo -e "${AMBER}[*] Run: git pull to update ShadowDeck${RESET}"
        sleep 2; return 1
    fi
    bash "$mod"
}

confirm() {
    echo -e "${AMBER}[?] $1 [y/N]: ${RESET}"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# ── ASCII Banner ──────────────────────────────────────────────
print_banner() {
    echo -e "${GREEN_HI}${BOLD}"
    cat << 'BANNER'
  ██████╗ ██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗
  ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║
  ███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║
  ╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║
  ███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝
BANNER
    echo -e "${RESET}"
    echo -e "${GREEN}          ██████╗ ███████╗ ██████╗██╗  ██╗    ██╗   ██╗██████╗ ${RESET}"
    echo -e "${GREEN}          ██╔══██╗██╔════╝██╔════╝██║ ██╔╝    ██║   ██║╚════██╗${RESET}"
    echo -e "${GREEN_HI}          ██║  ██║█████╗  ██║     █████╔╝     ██║   ██║ █████╔╝${RESET}"
    echo -e "${GREEN}          ██║  ██║██╔══╝  ██║     ██╔═██╗     ╚██╗ ██╔╝██╔═══╝ ${RESET}"
    echo -e "${GREEN_DIM}          ██████╔╝███████╗╚██████╗██║  ██╗     ╚████╔╝ ███████╗${RESET}"
    echo -e "${GREEN_DIM}          ╚═════╝ ╚══════╝ ╚═════╝╚═╝  ╚═╝      ╚═══╝  ╚══════╝${RESET}"
}

# ── Status Bar ────────────────────────────────────────────────
print_statusbar() {
    local ip_local vpn_status
    ip_local=$(hostname -I 2>/dev/null | awk '{print $1}')
    if ip a 2>/dev/null | grep -q "tun0"; then
        vpn_status="${GREEN}[VPN:ON]${RESET}"
    else
        vpn_status="${RED}[VPN:OFF]${RESET}"
    fi

    thick_line
    echo -e " ${GREEN_DIM}USER${RESET}: ${GREEN}${BOLD}$(whoami)${RESET}  ${GREEN_DIM}HOST${RESET}: ${GREEN}$(hostname)${RESET}  ${GREEN_DIM}IP${RESET}: ${GREEN}${ip_local}${RESET}  ${vpn_status}  ${GREEN_DIM}$(date '+%H:%M %Z')${RESET}"
    thick_line
}

# ── Main Menu ─────────────────────────────────────────────────
print_menu() {
    echo ""
    echo -e "${GREEN_HI}${BOLD}  ╔══ RED TEAM ══════════════╗   ╔══ BLUE TEAM ═════════════╗${RESET}"
    echo -e "${GREEN}  ║  ${RED}[1]${GREEN} Recon              ║   ║  ${AMBER}[5]${GREEN} Forensics           ║${RESET}"
    echo -e "${GREEN}  ║  ${RED}[2]${GREEN} Brute Force        ║   ║  ${AMBER}[6]${GREEN} Hash Cracking       ║${RESET}"
    echo -e "${GREEN}  ║  ${RED}[3]${GREEN} Web Attacks        ║   ║  ${AMBER}[7]${GREEN} Traffic Analysis    ║${RESET}"
    echo -e "${GREEN}  ║  ${RED}[4]${GREEN} Reverse Shells     ║   ║  ${AMBER}[8]${GREEN} Log Analyzer        ║${RESET}"
    echo -e "${GREEN}  ╚════════════════════════╝   ╚═════════════════════════╝${RESET}"
    echo ""
    echo -e "${GREEN_HI}${BOLD}  ╔══ CORE ═══════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}  ║  ${CYAN}[9]${GREEN} ShadowScan (WebUI)    ${CYAN}[10]${GREEN} tmux Workspace        ║${RESET}"
    echo -e "${GREEN}  ║  ${CYAN}[11]${GREEN} GitHub Push           ${CYAN}[12]${GREEN} Cheatsheet/Help       ║${RESET}"
    echo -e "${GREEN}  ╚═══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    dim_line
    echo -e "  ${GREEN_DIM}[0] Exit${RESET}                                        ${DIM}ShadowDeck v2.0${RESET}"
    dim_line
    echo ""
    echo -ne "  ${GREEN_HI}${BOLD}shadow@deck${RESET}${GREEN} > ${RESET}"
}

# ── Module Dispatchers ────────────────────────────────────────
run_recon()         { log_action "Recon module launched";        require_module "red/recon.sh"; }
run_bruteforce()    { log_action "BruteForce module launched";   require_module "red/bruteforce.sh"; }
run_webattacks()    { log_action "WebAttacks module launched";   require_module "red/webattacks.sh"; }
run_revshells()     { log_action "RevShells module launched";    require_module "red/revshells.sh"; }
run_forensics()     { log_action "Forensics module launched";    require_module "blue/forensics.sh"; }
run_hashcrack()     { log_action "HashCrack module launched";    require_module "blue/hashcrack.sh"; }
run_traffic()       { log_action "Traffic module launched";      require_module "blue/traffic.sh"; }
run_loganalyzer()   { log_action "LogAnalyzer module launched";  require_module "blue/loganalyzer.sh"; }

run_shadowscan() {
    log_action "ShadowScan launched"
    echo -e "\n${GREEN}[*] Starting ShadowScan...${RESET}"
    # Try to open in background; works if ShadowScan is already cloned alongside
    local scan_dir
    scan_dir=$(find "$HOME" -maxdepth 3 -name "app.py" -path "*/ShadowScan/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
    if [[ -n "$scan_dir" ]]; then
        echo -e "${GREEN}[+] Found ShadowScan at: $scan_dir${RESET}"
        cd "$scan_dir" || return
        nohup python3 app.py &>/dev/null &
        sleep 1
        echo -e "${GREEN}[+] ShadowScan running at ${CYAN}http://127.0.0.1:5000${RESET}"
        echo -e "${GREEN_DIM}    Open in browser: http://127.0.0.1:5000${RESET}"
    else
        echo -e "${AMBER}[!] ShadowScan not found. Clone it alongside ShadowDeck:${RESET}"
        echo -e "${CYAN}    git clone git@github.com:0xShadowpk/ShadowScan.git${RESET}"
    fi
    echo -e "\n${GREEN_DIM}Press Enter to return...${RESET}"; read -r
}

run_tmux_workspace() {
    log_action "tmux workspace launched"
    local session="ShadowDeck"
    if tmux has-session -t "$session" 2>/dev/null; then
        echo -e "${AMBER}[*] Session '$session' already running. Attaching...${RESET}"
        sleep 1
        tmux attach-session -t "$session"
        return
    fi
    echo -e "${GREEN}[*] Launching tmux workspace...${RESET}"
    tmux new-session  -d -s "$session" -n "Dashboard" -x 220 -y 50
    tmux new-window   -t "$session"    -n "ShadowScan"
    tmux new-window   -t "$session"    -n "NetHunter"
    tmux new-window   -t "$session"    -n "Git"
    tmux new-window   -t "$session"    -n "ShadowDeck"
    tmux send-keys    -t "$session:ShadowScan"  "cd ~/ShadowScan && python3 app.py" ""
    tmux send-keys    -t "$session:Dashboard"   "bash $SHADOWDECK_DIR/shadowdeck.sh" ""
    tmux select-window -t "$session:Dashboard"
    tmux attach-session -t "$session"
}

run_github_push() {
    log_action "GitHub push initiated"
    echo -e "\n${GREEN}[*] GitHub Push — ShadowDeck${RESET}"
    dim_line
    cd "$SHADOWDECK_DIR" || { echo -e "${RED}[!] Cannot cd to ShadowDeck dir${RESET}"; return; }
    echo -e "${GREEN_DIM}Staged changes:${RESET}"
    git status --short
    echo ""
    echo -ne "${GREEN}[?] Commit message: ${RESET}"
    read -r commit_msg
    [[ -z "$commit_msg" ]] && commit_msg="chore: update ShadowDeck v2"
    git add -A
    git commit -m "$commit_msg"
    git push origin main
    echo -e "\n${GREEN}[+] Pushed to git@github.com:0xShadowpk/ShadowDeck.git${RESET}"
    echo -e "${GREEN_DIM}Press Enter to return...${RESET}"; read -r
}

run_cheatsheet() {
    require_module "core/cheatsheet.sh"
}

# ── Main Loop ─────────────────────────────────────────────────
main() {
    while true; do
        crt_clear
        print_banner
        print_statusbar
        print_menu

        read -r choice
        case "$choice" in
            1)  run_recon ;;
            2)  run_bruteforce ;;
            3)  run_webattacks ;;
            4)  run_revshells ;;
            5)  run_forensics ;;
            6)  run_hashcrack ;;
            7)  run_traffic ;;
            8)  run_loganalyzer ;;
            9)  run_shadowscan ;;
            10) run_tmux_workspace ;;
            11) run_github_push ;;
            12) run_cheatsheet ;;
            0)
                crt_clear
                echo -e "\n${GREEN_HI}${BOLD}  [ShadowDeck] Session terminated. Stay in the shadows. 🕶${RESET}\n"
                crt_show_cursor
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid option${RESET}"
                sleep 0.8
                ;;
        esac
    done
}

main
