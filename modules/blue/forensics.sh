#!/usr/bin/env bash
# ShadowDeck v2 — Blue Team | Forensics Module
# modules/blue/forensics.sh

RESET='\033[0m'
GREEN='\033[38;5;82m'
GREEN_DIM='\033[38;5;22m'
GREEN_HI='\033[38;5;118m'
RED='\033[38;5;196m'
AMBER='\033[38;5;214m'
CYAN='\033[38;5;51m'
BOLD='\033[1m'

LOGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../logs" && pwd)"
WORK_DIR="$LOGS_DIR/forensics"
mkdir -p "$WORK_DIR"

dim_line()  { echo -e "${GREEN_DIM}$(printf '─%.0s' {1..70})${RESET}"; }
thick_line(){ echo -e "${GREEN}$(printf '═%.0s' {1..70})${RESET}"; }
info()  { echo -e "${CYAN}[*]${RESET} $1"; }
ok()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${AMBER}[!]${RESET} $1"; }
err()   { echo -e "${RED}[✗]${RESET} $1"; }
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FORENSICS] $1" >> "$LOGS_DIR/shadowdeck.log"; }
press_enter() { echo -e "\n${GREEN_DIM}  Press Enter to return...${RESET}"; read -r; }

pick_file() {
    echo -ne "\n  ${GREEN}Target file path${RESET}: "
    read -r TFILE
    if [[ ! -f "$TFILE" ]]; then
        err "File not found: $TFILE"
        return 1
    fi
    ok "File: $TFILE"
    return 0
}

# ── BINWALK ───────────────────────────────────────────────────
run_binwalk() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[FORENSICS] Binwalk — Firmware/File Analyzer${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Analyze file        ${GREEN_DIM}(signatures scan)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Extract embedded    ${GREEN_DIM}(-e automatic extract)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Deep extract        ${GREEN_DIM}(--dd='.*' extract all)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} Entropy analysis    ${GREEN_DIM}(-E detect encryption/compression)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Strings scan        ${GREEN_DIM}(embedded strings)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} Hex dump view       ${GREEN_DIM}(hexdump -C first 256 bytes)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@binwalk${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        pick_file || { press_enter; continue; }

        local outdir="$WORK_DIR/binwalk_$(basename "$TFILE")_$(date +%H%M%S)"
        local cmd=""

        case "$choice" in
            1) cmd="binwalk \"$TFILE\"" ;;
            2)
                mkdir -p "$outdir"
                cmd="binwalk -e \"$TFILE\" --directory=\"$outdir\""
                ;;
            3)
                mkdir -p "$outdir"
                cmd="binwalk --dd='.*' \"$TFILE\" --directory=\"$outdir\""
                ;;
            4) cmd="binwalk -E \"$TFILE\"" ;;
            5) cmd="binwalk --raw-bytes \"$TFILE\" && strings \"$TFILE\" | head -60" ;;
            6) cmd="hexdump -C \"$TFILE\" | head -32" ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac

        echo ""
        info "Running: ${CYAN}$cmd${RESET}"
        dim_line
        log "CMD: $cmd"
        eval "$cmd" 2>&1 | tee "$WORK_DIR/binwalk_$(date +%H%M%S).txt"
        [[ "$choice" =~ ^[23]$ ]] && ok "Extracted to: $outdir"
        press_enter
    done
}

# ── STEGHIDE ──────────────────────────────────────────────────
run_steghide() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[FORENSICS] Steghide — Steganography${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Extract data        ${GREEN_DIM}(extract hidden data)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Extract (no pass)   ${GREEN_DIM}(empty password attempt)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Embed data          ${GREEN_DIM}(hide file inside image)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} File info           ${GREEN_DIM}(steghide info)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Brute force pass    ${GREEN_DIM}(stegcracker + rockyou)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@steghide${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        case "$choice" in
            1)
                pick_file || { press_enter; continue; }
                echo -ne "  ${GREEN}Password${RESET}: "; read -rs PASS; echo ""
                echo -ne "  ${GREEN}Output file${RESET} [extracted_out]: "; read -r OUTF
                OUTF="${OUTF:-extracted_out}"
                local cmd="steghide extract -sf \"$TFILE\" -p \"$PASS\" -xf \"$OUTF\""
                info "Running: ${CYAN}steghide extract ...${RESET}"
                log "CMD: steghide extract -sf $TFILE"
                eval "$cmd"
                ;;
            2)
                pick_file || { press_enter; continue; }
                info "Trying empty password..."
                steghide extract -sf "$TFILE" -p "" && ok "Extracted!" || warn "No data or wrong password"
                ;;
            3)
                echo -ne "  ${GREEN}Cover file (image)${RESET}: "; read -r COVER
                echo -ne "  ${GREEN}Secret file to hide${RESET}: "; read -r SECRET
                echo -ne "  ${GREEN}Password${RESET}: "; read -rs PASS; echo ""
                if [[ ! -f "$COVER" || ! -f "$SECRET" ]]; then
                    err "File not found"; press_enter; continue
                fi
                steghide embed -cf "$COVER" -sf "$SECRET" -p "$PASS"
                ok "Data embedded into $COVER"
                ;;
            4)
                pick_file || { press_enter; continue; }
                steghide info "$TFILE"
                ;;
            5)
                pick_file || { press_enter; continue; }
                if command -v stegcracker &>/dev/null; then
                    local wl="/usr/share/wordlists/rockyou.txt"
                    [[ ! -f "$wl" ]] && { warn "rockyou.txt not found"; press_enter; continue; }
                    info "Running stegcracker..."
                    stegcracker "$TFILE" "$wl"
                else
                    warn "stegcracker not installed. Install: pip3 install stegcracker --break-system-packages"
                    info "Manual brute with steghide:"
                    echo -e "  ${CYAN}while read p; do steghide extract -sf \"$TFILE\" -p \"\$p\" -xf out 2>/dev/null && echo \"PASS: \$p\" && break; done < /usr/share/wordlists/rockyou.txt${RESET}"
                fi
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac
        press_enter
    done
}

# ── EXIFTOOL ──────────────────────────────────────────────────
run_exiftool() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[FORENSICS] ExifTool — Metadata Analyzer${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} View all metadata"
        echo -e "  ${GREEN}[2]${RESET} View GPS coordinates"
        echo -e "  ${GREEN}[3]${RESET} View camera/device info"
        echo -e "  ${GREEN}[4]${RESET} Strip all metadata    ${GREEN_DIM}(OSINT safe export)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Scan all files in dir ${GREEN_DIM}(bulk metadata)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} Check for hidden data  ${GREEN_DIM}(comment fields)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@exiftool${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        case "$choice" in
            5)
                echo -ne "  ${GREEN}Directory path${RESET}: "; read -r DIRPATH
                if [[ ! -d "$DIRPATH" ]]; then err "Not a directory"; press_enter; continue; fi
                local out="$WORK_DIR/exif_bulk_$(date +%H%M%S).txt"
                exiftool "$DIRPATH"/* 2>/dev/null | tee "$out"
                ok "Saved → $out"
                ;;
            *)
                pick_file || { press_enter; continue; }
                case "$choice" in
                    1)
                        local out="$WORK_DIR/exif_$(basename "$TFILE")_$(date +%H%M%S).txt"
                        exiftool "$TFILE" | tee "$out"
                        ok "Saved → $out"
                        ;;
                    2) exiftool -gps:all "$TFILE" ;;
                    3) exiftool -Make -Model -Software -DateTime "$TFILE" ;;
                    4)
                        warn "This will modify the file. Continue? [y/N]: "
                        read -r confirm
                        if [[ "$confirm" =~ ^[Yy]$ ]]; then
                            exiftool -all= "$TFILE"
                            ok "Metadata stripped from $TFILE"
                        fi
                        ;;
                    6) exiftool -Comment -UserComment -ImageDescription "$TFILE" ;;
                    *) warn "Invalid"; sleep 0.8; continue ;;
                esac
                ;;
        esac
        press_enter
    done
}

# ── FOREMOST ──────────────────────────────────────────────────
run_foremost() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[FORENSICS] Foremost — File Carver${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Recover all file types  ${GREEN_DIM}(from disk image/file)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Recover specific types  ${GREEN_DIM}(jpg,png,pdf,zip,doc...)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Recover from /dev/sda   ${GREEN_DIM}(live disk carving)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@foremost${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        local outdir="$WORK_DIR/foremost_$(date +%H%M%S)"
        mkdir -p "$outdir"

        case "$choice" in
            1)
                pick_file || { press_enter; continue; }
                local cmd="foremost -i \"$TFILE\" -o \"$outdir\""
                info "Running: ${CYAN}$cmd${RESET}"
                log "CMD: $cmd"
                eval "$cmd"
                ok "Recovered files → $outdir"
                ;;
            2)
                pick_file || { press_enter; continue; }
                echo -ne "  ${GREEN}File types${RESET} (e.g. jpg,png,pdf,zip): "; read -r FTYPES
                local cmd="foremost -t $FTYPES -i \"$TFILE\" -o \"$outdir\""
                info "Running: ${CYAN}$cmd${RESET}"
                log "CMD: $cmd"
                eval "$cmd"
                ok "Recovered files → $outdir"
                ;;
            3)
                warn "Requires sudo. This carves from a live disk."
                echo -ne "  ${GREEN}Device${RESET} (e.g. /dev/sda): "; read -r DEV
                if [[ ! -b "$DEV" ]]; then err "Not a block device: $DEV"; press_enter; continue; fi
                local cmd="sudo foremost -i $DEV -o \"$outdir\""
                info "Running: ${CYAN}$cmd${RESET}"
                log "CMD: $cmd"
                eval "$cmd"
                ok "Recovered files → $outdir"
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac
        press_enter
    done
}

# ── FILE ANALYZER ─────────────────────────────────────────────
run_fileanalyzer() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[FORENSICS] Quick File Analyzer${RESET}"
    thick_line
    pick_file || { press_enter; return; }

    local out="$WORK_DIR/fileanalysis_$(basename "$TFILE")_$(date +%H%M%S).txt"

    echo "" | tee "$out"
    thick_line | tee -a "$out"
    echo -e "  ${GREEN_HI}FILE TYPE${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    file "$TFILE" | tee -a "$out"

    echo "" | tee -a "$out"
    echo -e "  ${GREEN_HI}STRINGS (first 40)${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    strings "$TFILE" | head -40 | tee -a "$out"

    echo "" | tee -a "$out"
    echo -e "  ${GREEN_HI}HEX HEADER (first 32 bytes)${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    hexdump -C "$TFILE" | head -4 | tee -a "$out"

    echo "" | tee -a "$out"
    echo -e "  ${GREEN_HI}FILE SIZE & HASH${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    ls -lh "$TFILE" | tee -a "$out"
    echo -ne "MD5:    "; md5sum "$TFILE" | tee -a "$out"
    echo -ne "SHA256: "; sha256sum "$TFILE" | tee -a "$out"

    echo "" | tee -a "$out"
    echo -e "  ${GREEN_HI}EXIF QUICK VIEW${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    exiftool "$TFILE" 2>/dev/null | head -20 | tee -a "$out"

    ok "Full report → $out"
    press_enter
}

# ── MAIN MENU ─────────────────────────────────────────────────
while true; do
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[ BLUE TEAM → FORENSICS ]${RESET}"
    thick_line
    echo -e "  ${GREEN}[1]${RESET} Binwalk              ${GREEN_DIM}— firmware/file analysis & extraction${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Steghide             ${GREEN_DIM}— steganography extract/embed/brute${RESET}"
    echo -e "  ${GREEN}[3]${RESET} ExifTool             ${GREEN_DIM}— metadata viewer/stripper${RESET}"
    echo -e "  ${GREEN}[4]${RESET} Foremost             ${GREEN_DIM}— file carving & recovery${RESET}"
    echo -e "  ${GREEN}[5]${RESET} Quick File Analyzer  ${GREEN_DIM}— file/strings/hex/hash all-in-one${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back to Dashboard${RESET}"
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@forensics${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1) run_binwalk ;;
        2) run_steghide ;;
        3) run_exiftool ;;
        4) run_foremost ;;
        5) run_fileanalyzer ;;
        0) exit 0 ;;
        *) warn "Invalid option"; sleep 0.8 ;;
    esac
done
