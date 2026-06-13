#!/usr/bin/env bash
# ShadowDeck v2 — Install & Setup Script
# Run this ONCE after copying all files to ~/ShadowDeck
# Usage: bash install.sh

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
ok()   { echo -e "${GREEN}[+]${RESET} $1"; }
info() { echo -e "${CYAN}[*]${RESET} $1"; }
warn() { echo -e "${AMBER}[!]${RESET} $1"; }
err()  { echo -e "${RED}[✗]${RESET} $1"; }
pass() { echo -e "  ${GREEN}✔${RESET}  $1"; }
fail() { echo -e "  ${RED}✘${RESET}  $1 ${RED}(missing)${RESET}"; }

SHADOWDECK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
thick_line
echo -e "  ${GREEN_HI}${BOLD}ShadowDeck v2 — Installer & Verifier${RESET}"
thick_line
echo ""

# ── STEP 1: chmod all modules ─────────────────────────────────
info "Step 1: Setting permissions..."
dim_line

FILES=(
    "shadowdeck.sh"
    "modules/core/cheatsheet.sh"
    "modules/red/recon.sh"
    "modules/red/bruteforce.sh"
    "modules/red/webattacks.sh"
    "modules/red/revshells.sh"
    "modules/blue/forensics.sh"
    "modules/blue/hashcrack.sh"
    "modules/blue/traffic.sh"
    "modules/blue/loganalyzer.sh"
    "install.sh"
)

all_ok=true
for f in "${FILES[@]}"; do
    fp="$SHADOWDECK_DIR/$f"
    if [[ -f "$fp" ]]; then
        chmod +x "$fp"
        pass "$f"
    else
        fail "$f"
        all_ok=false
    fi
done

echo ""
if $all_ok; then
    ok "All files found and permissions set."
else
    warn "Some files are missing — paste them in and re-run install.sh"
fi

# ── STEP 2: Create directory structure ───────────────────────
echo ""
info "Step 2: Creating directories..."
dim_line
mkdir -p "$SHADOWDECK_DIR/logs/forensics"
mkdir -p "$SHADOWDECK_DIR/logs/hashcrack"
mkdir -p "$SHADOWDECK_DIR/logs/traffic"
mkdir -p "$SHADOWDECK_DIR/logs/loganalyzer"
mkdir -p "$SHADOWDECK_DIR/modules/core"
mkdir -p "$SHADOWDECK_DIR/modules/red"
mkdir -p "$SHADOWDECK_DIR/modules/blue"
pass "logs/ structure created"
pass "modules/ structure created"

# ── STEP 3: Verify tools ──────────────────────────────────────
echo ""
info "Step 3: Checking installed tools..."
dim_line

TOOLS=(
    "nmap" "gobuster" "ffuf"
    "hydra"
    "sqlmap" "nikto"
    "nc" "rlwrap"
    "binwalk" "steghide" "exiftool" "foremost"
    "john" "hashcat"
    "tshark" "tcpdump"
    "git" "tmux" "python3"
)

missing_tools=()
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        pass "$tool"
    else
        fail "$tool"
        missing_tools+=("$tool")
    fi
done

echo ""
if [[ ${#missing_tools[@]} -eq 0 ]]; then
    ok "All tools present."
else
    warn "Missing tools: ${missing_tools[*]}"
    echo -e "  ${CYAN}Install: sudo apt install ${missing_tools[*]}${RESET}"
fi

# ── STEP 4: shadow alias ──────────────────────────────────────
echo ""
info "Step 4: Checking 'shadow' alias..."
dim_line

ALIAS_LINE="alias shadow='bash $SHADOWDECK_DIR/shadowdeck.sh'"
if grep -q "alias shadow=" "$HOME/.bashrc" 2>/dev/null; then
    pass "shadow alias already in ~/.bashrc"
else
    echo "$ALIAS_LINE" >> "$HOME/.bashrc"
    pass "shadow alias added to ~/.bashrc"
    info "Run: source ~/.bashrc  (or restart terminal)"
fi

# ── STEP 5: Git remote check ──────────────────────────────────
echo ""
info "Step 5: Git remote check..."
dim_line

cd "$SHADOWDECK_DIR" || exit 1
if git remote -v 2>/dev/null | grep -q "ShadowDeck"; then
    pass "Git remote: $(git remote get-url origin 2>/dev/null)"
else
    warn "No git remote found."
    info "Setting up remote..."
    git init -q
    git remote add origin git@github.com:0xShadowpk/ShadowDeck.git 2>/dev/null || \
        git remote set-url origin git@github.com:0xShadowpk/ShadowDeck.git
    pass "Remote set: git@github.com:0xShadowpk/ShadowDeck.git"
fi

# ── STEP 6: Initial commit & push ────────────────────────────
echo ""
info "Step 6: Git push..."
dim_line
echo -ne "  ${GREEN}Push ShadowDeck v2 to GitHub now? [y/N]: ${RESET}"
read -r dopush

if [[ "$dopush" =~ ^[Yy]$ ]]; then
    git add -A
    git commit -m "feat: ShadowDeck v2 — Ultimate Purple Team Toolkit

Modules:
- Red Team: Recon (nmap/gobuster/ffuf), BruteForce (hydra),
  WebAttacks (sqlmap/burp/nikto/payloads), RevShells (13 shells/listener/msfvenom)
- Blue Team: Forensics (binwalk/steghide/exiftool/foremost),
  HashCrack (john/hashcat/auto-id), Traffic (wireshark/tshark/tcpdump),
  LogAnalyzer (auth/web/IOC/live monitor)
- Core: Dashboard, Cheatsheet, tmux workspace, GitHub push"

    git push origin main
    echo ""
    ok "Pushed to git@github.com:0xShadowpk/ShadowDeck.git"
else
    info "Skipped. Push manually later: git push origin main"
fi

# ── DONE ──────────────────────────────────────────────────────
echo ""
thick_line
echo -e "  ${GREEN_HI}${BOLD}ShadowDeck v2 — READY${RESET}"
thick_line
echo ""
echo -e "  ${GREEN}Launch:${RESET}  ${CYAN}shadow${RESET}  (after source ~/.bashrc)"
echo -e "  ${GREEN}Or:${RESET}      ${CYAN}bash ~/ShadowDeck/shadowdeck.sh${RESET}"
echo ""
echo -e "  ${GREEN_DIM}Stay in the shadows. — 0xShadowpk${RESET}"
echo ""
thick_line
