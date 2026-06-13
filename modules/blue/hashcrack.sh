#!/usr/bin/env bash
# ShadowDeck v2 — Blue Team | Hash Cracking Module
# modules/blue/hashcrack.sh

RESET='\033[0m'
GREEN='\033[38;5;82m'
GREEN_DIM='\033[38;5;22m'
GREEN_HI='\033[38;5;118m'
RED='\033[38;5;196m'
AMBER='\033[38;5;214m'
CYAN='\033[38;5;51m'
BOLD='\033[1m'

LOGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../logs" && pwd)"
WORK_DIR="$LOGS_DIR/hashcrack"
mkdir -p "$WORK_DIR"

dim_line()  { echo -e "${GREEN_DIM}$(printf '─%.0s' {1..70})${RESET}"; }
thick_line(){ echo -e "${GREEN}$(printf '═%.0s' {1..70})${RESET}"; }
info()  { echo -e "${CYAN}[*]${RESET} $1"; }
ok()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${AMBER}[!]${RESET} $1"; }
err()   { echo -e "${RED}[✗]${RESET} $1"; }
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HASHCRACK] $1" >> "$LOGS_DIR/shadowdeck.log"; }
press_enter() { echo -e "\n${GREEN_DIM}  Press Enter to return...${RESET}"; read -r; }

# ── Wordlist picker ───────────────────────────────────────────
pick_wordlist() {
    local WL_ROCK="/usr/share/wordlists/rockyou.txt"
    local WL_ROCK_GZ="/usr/share/wordlists/rockyou.txt.gz"
    local WL_10K="/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt"

    echo ""
    echo -e "  ${GREEN_HI}Wordlist:${RESET}"
    echo -e "  ${GREEN}[1]${RESET} rockyou.txt         ${GREEN_DIM}(~14M passwords)${RESET}"
    echo -e "  ${GREEN}[2]${RESET} 10k-most-common     ${GREEN_DIM}(fast, seclists)${RESET}"
    echo -e "  ${GREEN}[3]${RESET} Custom path"
    echo -ne "\n  ${GREEN_HI}wl${RESET}${GREEN} > ${RESET}"
    read -r wl_choice

    case "$wl_choice" in
        1)
            if [[ -f "$WL_ROCK" ]]; then
                WORDLIST="$WL_ROCK"
            elif [[ -f "$WL_ROCK_GZ" ]]; then
                warn "Extracting rockyou.txt.gz..."
                sudo gunzip "$WL_ROCK_GZ"
                WORDLIST="$WL_ROCK"
            else
                err "rockyou.txt not found"; return 1
            fi
            ;;
        2)
            [[ -f "$WL_10K" ]] && WORDLIST="$WL_10K" || { err "seclists not installed: sudo apt install seclists"; return 1; }
            ;;
        3)
            echo -ne "  ${GREEN}Path${RESET}: "; read -r WORDLIST
            [[ ! -f "$WORDLIST" ]] && { err "Not found: $WORDLIST"; return 1; }
            ;;
        *) err "Invalid"; return 1 ;;
    esac
    ok "Wordlist: $WORDLIST"
    return 0
}

# ── Auto Hash Identifier ──────────────────────────────────────
identify_hash() {
    local hash="$1"
    local len=${#hash}

    # Pattern-based identification
    if [[ "$hash" =~ ^\$2[aby]\$ ]]; then
        echo "bcrypt [hashcat: 3200] [john: bcrypt]"
    elif [[ "$hash" =~ ^\$6\$ ]]; then
        echo "SHA-512 crypt [hashcat: 1800] [john: sha512crypt]"
    elif [[ "$hash" =~ ^\$5\$ ]]; then
        echo "SHA-256 crypt [hashcat: 7400] [john: sha256crypt]"
    elif [[ "$hash" =~ ^\$1\$ ]]; then
        echo "MD5 crypt [hashcat: 500] [john: md5crypt]"
    elif [[ "$hash" =~ ^\$apr1\$ ]]; then
        echo "Apache MD5 [hashcat: 1600] [john: md5crypt]"
    elif [[ "$hash" =~ ^[0-9a-fA-F]{32}$ ]]; then
        echo "MD5 (32 hex) [hashcat: 0] [john: raw-md5]"
    elif [[ "$hash" =~ ^[0-9a-fA-F]{40}$ ]]; then
        echo "SHA-1 (40 hex) [hashcat: 100] [john: raw-sha1]"
    elif [[ "$hash" =~ ^[0-9a-fA-F]{64}$ ]]; then
        echo "SHA-256 (64 hex) [hashcat: 1400] [john: raw-sha256]"
    elif [[ "$hash" =~ ^[0-9a-fA-F]{128}$ ]]; then
        echo "SHA-512 (128 hex) [hashcat: 1700] [john: raw-sha512]"
    elif [[ "$hash" =~ ^[0-9a-fA-F]{56}$ ]]; then
        echo "SHA-224 (56 hex) [hashcat: 1300]"
    elif [[ "$hash" =~ ^[0-9a-fA-F]{96}$ ]]; then
        echo "SHA-384 (96 hex) [hashcat: 10800]"
    elif [[ "$hash" =~ ^[A-Za-z0-9+/]{22}==$ ]]; then
        echo "Possibly MD5 Base64"
    elif [[ "$hash" =~ ^[A-Z0-9]{32}$ ]]; then
        echo "Possibly NTLM [hashcat: 1000] [john: nt]"
    elif [[ "$hash" =~ ^[0-9a-fA-F]{16}$ ]]; then
        echo "MySQL 3.x (16 hex) [hashcat: 200]"
    elif [[ "$hash" =~ ^\*[0-9a-fA-F]{40}$ ]]; then
        echo "MySQL 4.1+ [hashcat: 300] [john: mysql-sha1]"
    else
        echo "Unknown — try: hashid, hash-identifier, or name-that-hash"
    fi
}

# ── Hash ID Tool ──────────────────────────────────────────────
run_hashid() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[HASH CRACKING] Hash Identifier${RESET}"
    thick_line
    echo -ne "  ${GREEN}Paste hash${RESET}: "; read -r HASH
    [[ -z "$HASH" ]] && { err "No hash entered"; press_enter; return; }

    echo ""
    dim_line
    echo -e "  ${GREEN_HI}ShadowDeck Detection:${RESET}"
    echo -e "  ${CYAN}$(identify_hash "$HASH")${RESET}"
    echo ""

    # Use hashid if available
    if command -v hashid &>/dev/null; then
        echo -e "  ${GREEN_HI}hashid output:${RESET}"
        dim_line
        hashid "$HASH"
    fi

    # Use hash-identifier if available
    if command -v hash-identifier &>/dev/null; then
        echo -e "\n  ${GREEN_HI}hash-identifier output:${RESET}"
        dim_line
        echo "$HASH" | hash-identifier 2>/dev/null | grep -v "^#\|HASH\|Possible\|--" | head -10
    fi

    press_enter
}

# ── JOHN THE RIPPER ───────────────────────────────────────────
run_john() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[HASH CRACKING] John The Ripper${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Crack hash file         ${GREEN_DIM}(auto-detect format)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Crack with format       ${GREEN_DIM}(specify --format)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Show cracked hashes     ${GREEN_DIM}(--show)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} Crack /etc/shadow       ${GREEN_DIM}(unshadow + john)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Crack ZIP password      ${GREEN_DIM}(zip2john)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} Crack RAR password      ${GREEN_DIM}(rar2john)${RESET}"
        echo -e "  ${GREEN}[7]${RESET} Crack SSH key           ${GREEN_DIM}(ssh2john)${RESET}"
        echo -e "  ${GREEN}[8]${RESET} Crack PDF password      ${GREEN_DIM}(pdf2john)${RESET}"
        echo -e "  ${GREEN}[9]${RESET} Wordlist + Rules        ${GREEN_DIM}(best64 rule)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@john${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        local cmd=""
        local hashfile=""

        case "$choice" in
            1)
                echo -ne "  ${GREEN}Hash file path${RESET}: "; read -r hashfile
                [[ ! -f "$hashfile" ]] && { err "File not found"; press_enter; continue; }
                pick_wordlist || { press_enter; continue; }
                cmd="john --wordlist=\"$WORDLIST\" \"$hashfile\""
                ;;
            2)
                echo -ne "  ${GREEN}Hash file path${RESET}: "; read -r hashfile
                [[ ! -f "$hashfile" ]] && { err "File not found"; press_enter; continue; }
                echo -e "  ${GREEN_DIM}Formats: raw-md5, raw-sha1, raw-sha256, sha512crypt, bcrypt, nt, md5crypt${RESET}"
                echo -ne "  ${GREEN}Format${RESET}: "; read -r FMT
                pick_wordlist || { press_enter; continue; }
                cmd="john --format=$FMT --wordlist=\"$WORDLIST\" \"$hashfile\""
                ;;
            3)
                echo -ne "  ${GREEN}Hash file path${RESET}: "; read -r hashfile
                [[ ! -f "$hashfile" ]] && { err "File not found"; press_enter; continue; }
                john --show "$hashfile"
                press_enter; continue
                ;;
            4)
                echo -ne "  ${GREEN}/etc/passwd path${RESET} [/etc/passwd]: "; read -r PFILE
                PFILE="${PFILE:-/etc/passwd}"
                echo -ne "  ${GREEN}/etc/shadow path${RESET} [/etc/shadow]: "; read -r SFILE
                SFILE="${SFILE:-/etc/shadow}"
                local combined="$WORK_DIR/unshadowed_$(date +%H%M%S).txt"
                unshadow "$PFILE" "$SFILE" > "$combined"
                ok "Unshadowed → $combined"
                pick_wordlist || { press_enter; continue; }
                cmd="john --wordlist=\"$WORDLIST\" \"$combined\""
                ;;
            5)
                echo -ne "  ${GREEN}ZIP file path${RESET}: "; read -r ZIPF
                [[ ! -f "$ZIPF" ]] && { err "File not found"; press_enter; continue; }
                hashfile="$WORK_DIR/zip_hash_$(date +%H%M%S).txt"
                zip2john "$ZIPF" > "$hashfile"
                ok "Hash extracted → $hashfile"
                pick_wordlist || { press_enter; continue; }
                cmd="john --wordlist=\"$WORDLIST\" \"$hashfile\""
                ;;
            6)
                echo -ne "  ${GREEN}RAR file path${RESET}: "; read -r RARF
                [[ ! -f "$RARF" ]] && { err "File not found"; press_enter; continue; }
                hashfile="$WORK_DIR/rar_hash_$(date +%H%M%S).txt"
                rar2john "$RARF" > "$hashfile"
                ok "Hash extracted → $hashfile"
                pick_wordlist || { press_enter; continue; }
                cmd="john --wordlist=\"$WORDLIST\" \"$hashfile\""
                ;;
            7)
                echo -ne "  ${GREEN}SSH private key path${RESET}: "; read -r SSHK
                [[ ! -f "$SSHK" ]] && { err "File not found"; press_enter; continue; }
                hashfile="$WORK_DIR/ssh_hash_$(date +%H%M%S).txt"
                ssh2john "$SSHK" > "$hashfile"
                ok "Hash extracted → $hashfile"
                pick_wordlist || { press_enter; continue; }
                cmd="john --wordlist=\"$WORDLIST\" \"$hashfile\""
                ;;
            8)
                echo -ne "  ${GREEN}PDF file path${RESET}: "; read -r PDFF
                [[ ! -f "$PDFF" ]] && { err "File not found"; press_enter; continue; }
                hashfile="$WORK_DIR/pdf_hash_$(date +%H%M%S).txt"
                pdf2john "$PDFF" > "$hashfile" 2>/dev/null || \
                python3 /usr/share/john/pdf2john.py "$PDFF" > "$hashfile"
                ok "Hash extracted → $hashfile"
                pick_wordlist || { press_enter; continue; }
                cmd="john --wordlist=\"$WORDLIST\" \"$hashfile\""
                ;;
            9)
                echo -ne "  ${GREEN}Hash file path${RESET}: "; read -r hashfile
                [[ ! -f "$hashfile" ]] && { err "File not found"; press_enter; continue; }
                pick_wordlist || { press_enter; continue; }
                cmd="john --wordlist=\"$WORDLIST\" --rules=best64 \"$hashfile\""
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac

        echo ""
        info "Running: ${CYAN}$cmd${RESET}"
        dim_line
        log "CMD: $cmd"
        eval "$cmd" 2>&1 | tee "$WORK_DIR/john_$(date +%H%M%S).txt"
        press_enter
    done
}

# ── HASHCAT ───────────────────────────────────────────────────
run_hashcat() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[HASH CRACKING] Hashcat${RESET}"
        thick_line
        echo -e "  ${GREEN_DIM}Attack modes: 0=dict  1=combo  3=brute  6=dict+mask  7=mask+dict${RESET}"
        dim_line
        echo -e "  ${GREEN}[1]${RESET} Dictionary attack    ${GREEN_DIM}(-a 0)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Brute force mask     ${GREEN_DIM}(-a 3 ?a?a?a?a?a?a)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Rule-based attack    ${GREEN_DIM}(-a 0 -r best64.rule)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} Common hash presets  ${GREEN_DIM}(pick -m mode)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Show cracked         ${GREEN_DIM}(--show)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} Custom command       ${GREEN_DIM}(full manual flags)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@hashcat${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        local cmd=""

        case "$choice" in
            1)
                echo -ne "  ${GREEN}Hash file or single hash${RESET}: "; read -r HASHVAL
                echo -ne "  ${GREEN}Hash mode (-m)${RESET} ${GREEN_DIM}[0=MD5, 100=SHA1, 1400=SHA256, 1000=NTLM]${RESET}: "; read -r MODE
                MODE="${MODE:-0}"
                pick_wordlist || { press_enter; continue; }
                cmd="hashcat -m $MODE -a 0 \"$HASHVAL\" \"$WORDLIST\" --force"
                ;;
            2)
                echo -ne "  ${GREEN}Hash file or single hash${RESET}: "; read -r HASHVAL
                echo -ne "  ${GREEN}Hash mode (-m)${RESET}: "; read -r MODE
                MODE="${MODE:-0}"
                echo -e "  ${GREEN_DIM}Mask chars: ?l=lower ?u=upper ?d=digit ?s=special ?a=all${RESET}"
                echo -ne "  ${GREEN}Mask${RESET} (e.g. ?a?a?a?a?a?a for 6-char): "; read -r MASK
                MASK="${MASK:-?a?a?a?a?a?a}"
                cmd="hashcat -m $MODE -a 3 \"$HASHVAL\" \"$MASK\" --force"
                ;;
            3)
                echo -ne "  ${GREEN}Hash file or single hash${RESET}: "; read -r HASHVAL
                echo -ne "  ${GREEN}Hash mode (-m)${RESET}: "; read -r MODE
                MODE="${MODE:-0}"
                pick_wordlist || { press_enter; continue; }
                local rules_path="/usr/share/hashcat/rules/best64.rule"
                if [[ ! -f "$rules_path" ]]; then
                    rules_path="/usr/share/doc/hashcat/rules/best64.rule"
                fi
                cmd="hashcat -m $MODE -a 0 \"$HASHVAL\" \"$WORDLIST\" -r \"$rules_path\" --force"
                ;;
            4)
                clear; thick_line
                echo -e "  ${AMBER}${BOLD}Common Hash Modes${RESET}"
                thick_line
                printf "  %-10s %-30s\n" "Mode" "Type"
                dim_line
                printf "  ${CYAN}%-10s${RESET} %s\n" "0"    "MD5"
                printf "  ${CYAN}%-10s${RESET} %s\n" "100"  "SHA-1"
                printf "  ${CYAN}%-10s${RESET} %s\n" "1400" "SHA-256"
                printf "  ${CYAN}%-10s${RESET} %s\n" "1700" "SHA-512"
                printf "  ${CYAN}%-10s${RESET} %s\n" "1000" "NTLM"
                printf "  ${CYAN}%-10s${RESET} %s\n" "3200" "bcrypt"
                printf "  ${CYAN}%-10s${RESET} %s\n" "500"  "MD5 crypt (\$1\$)"
                printf "  ${CYAN}%-10s${RESET} %s\n" "1800" "SHA-512 crypt (\$6\$)"
                printf "  ${CYAN}%-10s${RESET} %s\n" "7400" "SHA-256 crypt (\$5\$)"
                printf "  ${CYAN}%-10s${RESET} %s\n" "1600" "Apache MD5"
                printf "  ${CYAN}%-10s${RESET} %s\n" "300"  "MySQL 4.1+"
                printf "  ${CYAN}%-10s${RESET} %s\n" "1500" "DES crypt"
                printf "  ${CYAN}%-10s${RESET} %s\n" "13100" "Kerberos TGS (AS-REP)"
                printf "  ${CYAN}%-10s${RESET} %s\n" "22000" "WPA2 (PMKID/EAPOL)"
                press_enter; continue
                ;;
            5)
                echo -ne "  ${GREEN}Hash file${RESET}: "; read -r HASHVAL
                echo -ne "  ${GREEN}Hash mode (-m)${RESET}: "; read -r MODE
                MODE="${MODE:-0}"
                hashcat -m "$MODE" --show "$HASHVAL" 2>/dev/null || \
                    warn "No cracked hashes found in potfile for this mode"
                press_enter; continue
                ;;
            6)
                echo -ne "  ${GREEN}Full hashcat flags${RESET}: hashcat "; read -r custom
                cmd="hashcat $custom --force"
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac

        echo ""
        info "Running: ${CYAN}$cmd${RESET}"
        warn "Note: WSL2 GPU passthrough is limited — CPU mode will be used (--force)"
        dim_line
        log "CMD: $cmd"
        eval "$cmd" 2>&1 | tee "$WORK_DIR/hashcat_$(date +%H%M%S).txt"
        press_enter
    done
}

# ── ONLINE LOOKUP ─────────────────────────────────────────────
run_online_lookup() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[HASH CRACKING] Online Hash Lookup${RESET}"
    thick_line
    echo -e "  ${GREEN_DIM}These sites have massive pre-computed rainbow tables:${RESET}"
    echo ""
    echo -e "  ${CYAN}https://crackstation.net${RESET}         — MD5, SHA1, SHA256, NTLM, LM"
    echo -e "  ${CYAN}https://hashes.com/en/decrypt/hash${RESET}  — multi-format"
    echo -e "  ${CYAN}https://www.onlinehashcrack.com${RESET}  — WPA, MD5, SHA"
    echo -e "  ${CYAN}https://md5decrypt.net${RESET}           — MD5 reverse"
    echo ""
    echo -ne "  ${GREEN}Paste hash to lookup${RESET}: "; read -r HASH
    [[ -z "$HASH" ]] && { press_enter; return; }

    echo ""
    echo -e "  ${GREEN_HI}Hash:${RESET} ${CYAN}$HASH${RESET}"
    echo -e "  ${GREEN_HI}Type:${RESET} $(identify_hash "$HASH")"
    echo ""
    info "Copy the hash and paste it at crackstation.net for fastest lookup"
    echo -e "  ${GREEN_DIM}(Browser-based lookup — open from Windows/browser)${RESET}"
    press_enter
}

# ── MAIN MENU ─────────────────────────────────────────────────
while true; do
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[ BLUE TEAM → HASH CRACKING ]${RESET}"
    thick_line
    echo -e "  ${GREEN}[1]${RESET} Hash Identifier      ${GREEN_DIM}— auto-detect hash type${RESET}"
    echo -e "  ${GREEN}[2]${RESET} John The Ripper      ${GREEN_DIM}— dict/rules/zip/rar/ssh/pdf${RESET}"
    echo -e "  ${GREEN}[3]${RESET} Hashcat              ${GREEN_DIM}— dict/brute/rules/presets${RESET}"
    echo -e "  ${GREEN}[4]${RESET} Online Lookup        ${GREEN_DIM}— crackstation/hashes.com refs${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back to Dashboard${RESET}"
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@hashcrack${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1) run_hashid ;;
        2) run_john ;;
        3) run_hashcat ;;
        4) run_online_lookup ;;
        0) exit 0 ;;
        *) warn "Invalid option"; sleep 0.8 ;;
    esac
done
