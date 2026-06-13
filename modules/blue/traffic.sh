#!/usr/bin/env bash
# ShadowDeck v2 — Blue Team | Traffic Analysis Module
# modules/blue/traffic.sh

RESET='\033[0m'
GREEN='\033[38;5;82m'
GREEN_DIM='\033[38;5;22m'
GREEN_HI='\033[38;5;118m'
RED='\033[38;5;196m'
AMBER='\033[38;5;214m'
CYAN='\033[38;5;51m'
BOLD='\033[1m'

LOGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../logs" && pwd)"
WORK_DIR="$LOGS_DIR/traffic"
mkdir -p "$WORK_DIR"

dim_line()  { echo -e "${GREEN_DIM}$(printf '─%.0s' {1..70})${RESET}"; }
thick_line(){ echo -e "${GREEN}$(printf '═%.0s' {1..70})${RESET}"; }
info()  { echo -e "${CYAN}[*]${RESET} $1"; }
ok()    { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${AMBER}[!]${RESET} $1"; }
err()   { echo -e "${RED}[✗]${RESET} $1"; }
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TRAFFIC] $1" >> "$LOGS_DIR/shadowdeck.log"; }
press_enter() { echo -e "\n${GREEN_DIM}  Press Enter to return...${RESET}"; read -r; }

get_interface() {
    echo ""
    echo -e "  ${GREEN_HI}Available interfaces:${RESET}"
    ip -o link show 2>/dev/null | awk '{print "  " NR") " $2}' | tr -d ':'
    echo -ne "\n  ${GREEN}Interface${RESET} [eth0]: "; read -r IFACE
    IFACE="${IFACE:-eth0}"
    ok "Interface: $IFACE"
}

pick_pcap() {
    echo -ne "\n  ${GREEN}PCAP file path${RESET}: "; read -r PCAP
    if [[ ! -f "$PCAP" ]]; then
        err "File not found: $PCAP"; return 1
    fi
    ok "PCAP: $PCAP"
    return 0
}

# ── WIRESHARK ─────────────────────────────────────────────────
run_wireshark() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[TRAFFIC] Wireshark${RESET}"
    thick_line
    echo -e "  ${GREEN}[1]${RESET} Launch Wireshark       ${GREEN_DIM}(Windows GUI via WSL2)${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Open PCAP in Wireshark ${GREEN_DIM}(from file)${RESET}"
    echo -e "  ${GREEN}[3]${RESET} Key display filters    ${GREEN_DIM}(quick reference)${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back${RESET}"
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@wireshark${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1)
            info "Attempting to launch Wireshark..."
            # WSL2: try windows path first
            if command -v wireshark.exe &>/dev/null; then
                nohup wireshark.exe &>/dev/null &
                ok "Wireshark launched (Windows)"
            elif command -v wireshark &>/dev/null; then
                nohup wireshark &>/dev/null &
                ok "Wireshark launched"
            else
                warn "Wireshark not in PATH"
                info "On WSL2 — launch from Windows:"
                echo -e "  ${CYAN}  → Search 'Wireshark' in Windows Start menu${RESET}"
                echo -e "  ${CYAN}  → Or: /mnt/c/Program Files/Wireshark/Wireshark.exe${RESET}"
                echo ""
                info "Install on Kali: ${CYAN}sudo apt install wireshark${RESET}"
            fi
            log "Wireshark launch attempted"
            ;;
        2)
            pick_pcap || { press_enter; return; }
            if command -v wireshark.exe &>/dev/null; then
                local winpath
                winpath=$(wslpath -w "$PCAP" 2>/dev/null)
                nohup wireshark.exe "$winpath" &>/dev/null &
            elif command -v wireshark &>/dev/null; then
                nohup wireshark "$PCAP" &>/dev/null &
            else
                err "Wireshark not found"
            fi
            ;;
        3)
            clear; thick_line
            echo -e "  ${AMBER}${BOLD}Wireshark Display Filters${RESET}"
            thick_line
            cat << 'EOF'

  PROTOCOL FILTERS
  ─────────────────────────────────────────────────────
  http              — all HTTP traffic
  dns               — all DNS queries/responses
  tcp               — all TCP
  udp               — all UDP
  icmp              — ping traffic
  ftp               — FTP
  ssh               — SSH
  ssl || tls        — encrypted traffic

  IP FILTERS
  ─────────────────────────────────────────────────────
  ip.addr == 10.10.10.10          — any traffic to/from IP
  ip.src == 10.10.10.10           — traffic FROM IP
  ip.dst == 10.10.10.10           — traffic TO IP
  ip.addr == 10.10.10.0/24        — entire subnet

  PORT FILTERS
  ─────────────────────────────────────────────────────
  tcp.port == 80                  — TCP port 80
  tcp.port == 443                 — HTTPS
  udp.port == 53                  — DNS

  HTTP SPECIFIC
  ─────────────────────────────────────────────────────
  http.request.method == "GET"
  http.request.method == "POST"
  http.response.code == 200
  http.response.code == 404
  http contains "password"
  http.request.uri contains "admin"

  DNS
  ─────────────────────────────────────────────────────
  dns.flags.response == 0         — queries only
  dns.flags.response == 1         — responses only
  dns.qry.name contains "google"

  TCP FLAGS
  ─────────────────────────────────────────────────────
  tcp.flags.syn == 1              — SYN packets
  tcp.flags.syn==1 && tcp.flags.ack==0  — SYN scan detect
  tcp.flags.reset == 1            — RST packets

  COMBINE FILTERS
  ─────────────────────────────────────────────────────
  ip.addr==10.10.10.10 && http
  tcp.port==80 || tcp.port==443
  !(arp || dns || icmp)           — exclude noise

EOF
            ;;
        0) return ;;
        *) warn "Invalid" ;;
    esac
    press_enter
}

# ── TSHARK ────────────────────────────────────────────────────
run_tshark() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[TRAFFIC] TShark — CLI Packet Analyzer${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Live capture             ${GREEN_DIM}(interface → pcap)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Read PCAP file           ${GREEN_DIM}(display packets)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Filter PCAP              ${GREEN_DIM}(display filter -Y)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} Extract HTTP traffic     ${GREEN_DIM}(urls + methods)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Extract credentials      ${GREEN_DIM}(HTTP POST fields)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} Extract DNS queries      ${GREEN_DIM}(hostnames)${RESET}"
        echo -e "  ${GREEN}[7]${RESET} Top talkers              ${GREEN_DIM}(IP conversation stats)${RESET}"
        echo -e "  ${GREEN}[8]${RESET} Custom fields extract    ${GREEN_DIM}(-T fields -e)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@tshark${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        local cmd="" outfile="$WORK_DIR/tshark_$(date +%H%M%S).txt"

        case "$choice" in
            1)
                get_interface
                echo -ne "  ${GREEN}Packet count${RESET} [100]: "; read -r COUNT
                COUNT="${COUNT:-100}"
                echo -ne "  ${GREEN}Capture filter${RESET} (blank for all, e.g. 'port 80'): "; read -r CFILT
                local pcap_out="$WORK_DIR/capture_$(date +%H%M%S).pcap"
                if [[ -n "$CFILT" ]]; then
                    cmd="sudo tshark -i $IFACE -c $COUNT -f \"$CFILT\" -w \"$pcap_out\""
                else
                    cmd="sudo tshark -i $IFACE -c $COUNT -w \"$pcap_out\""
                fi
                info "Running: ${CYAN}$cmd${RESET}"
                info "Saving to: $pcap_out"
                log "CMD: $cmd"
                eval "$cmd"
                ok "Capture saved → $pcap_out"
                ;;
            2)
                pick_pcap || { press_enter; continue; }
                echo -ne "  ${GREEN}Packet count to show${RESET} [50]: "; read -r COUNT
                COUNT="${COUNT:-50}"
                cmd="tshark -r \"$PCAP\" -c $COUNT"
                info "Running: ${CYAN}$cmd${RESET}"
                log "CMD: $cmd"
                eval "$cmd" 2>&1 | tee "$outfile"
                ok "Output → $outfile"
                ;;
            3)
                pick_pcap || { press_enter; continue; }
                echo -e "  ${GREEN_DIM}Examples: http | dns | tcp.port==80 | ip.addr==10.10.10.10${RESET}"
                echo -ne "  ${GREEN}Display filter${RESET}: "; read -r DFILT
                cmd="tshark -r \"$PCAP\" -Y \"$DFILT\""
                info "Running: ${CYAN}$cmd${RESET}"
                log "CMD: $cmd"
                eval "$cmd" 2>&1 | tee "$outfile"
                ok "Output → $outfile"
                ;;
            4)
                pick_pcap || { press_enter; continue; }
                cmd="tshark -r \"$PCAP\" -Y http.request -T fields -e ip.src -e http.host -e http.request.method -e http.request.uri"
                info "Extracting HTTP requests..."
                log "CMD: $cmd"
                eval "$cmd" 2>&1 | tee "$outfile"
                ok "Output → $outfile"
                ;;
            5)
                pick_pcap || { press_enter; continue; }
                info "Extracting POST data (possible credentials)..."
                cmd="tshark -r \"$PCAP\" -Y 'http.request.method==POST' -T fields -e ip.src -e http.host -e http.request.uri -e http.file_data"
                log "CMD: $cmd"
                eval "$cmd" 2>&1 | tee "$outfile"
                ok "Output → $outfile"
                ;;
            6)
                pick_pcap || { press_enter; continue; }
                cmd="tshark -r \"$PCAP\" -Y 'dns.flags.response==0' -T fields -e frame.time -e ip.src -e dns.qry.name"
                info "Extracting DNS queries..."
                log "CMD: $cmd"
                eval "$cmd" 2>&1 | sort -u | tee "$outfile"
                ok "Output → $outfile"
                ;;
            7)
                pick_pcap || { press_enter; continue; }
                cmd="tshark -r \"$PCAP\" -q -z conv,ip"
                info "Top IP conversations..."
                log "CMD: $cmd"
                eval "$cmd" 2>&1 | tee "$outfile"
                ok "Output → $outfile"
                ;;
            8)
                pick_pcap || { press_enter; continue; }
                echo -e "  ${GREEN_DIM}Fields: ip.src ip.dst tcp.port http.host dns.qry.name frame.time${RESET}"
                echo -ne "  ${GREEN}Fields to extract${RESET} (space separated): "; read -r FIELDS
                local field_flags=""
                for f in $FIELDS; do field_flags="$field_flags -e $f"; done
                cmd="tshark -r \"$PCAP\" -T fields $field_flags"
                info "Running: ${CYAN}$cmd${RESET}"
                log "CMD: $cmd"
                eval "$cmd" 2>&1 | tee "$outfile"
                ok "Output → $outfile"
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac
        press_enter
    done
}

# ── TCPDUMP ───────────────────────────────────────────────────
run_tcpdump() {
    while true; do
        clear; thick_line
        echo -e "  ${AMBER}${BOLD}[TRAFFIC] TCPDump — Packet Capture${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET} Capture all traffic     ${GREEN_DIM}(save to pcap)${RESET}"
        echo -e "  ${GREEN}[2]${RESET} Capture by port         ${GREEN_DIM}(e.g. port 80)${RESET}"
        echo -e "  ${GREEN}[3]${RESET} Capture by host         ${GREEN_DIM}(src/dst IP)${RESET}"
        echo -e "  ${GREEN}[4]${RESET} Capture HTTP only       ${GREEN_DIM}(port 80 or 8080)${RESET}"
        echo -e "  ${GREEN}[5]${RESET} Capture DNS             ${GREEN_DIM}(port 53)${RESET}"
        echo -e "  ${GREEN}[6]${RESET} Read saved PCAP         ${GREEN_DIM}(tcpdump -r)${RESET}"
        echo -e "  ${GREEN}[7]${RESET} Custom filter           ${GREEN_DIM}(manual BPF syntax)${RESET}"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@tcpdump${RESET}${GREEN} > ${RESET}"
        read -r choice
        [[ "$choice" == "0" ]] && break

        local pcap_out="$WORK_DIR/tcpdump_$(date +%H%M%S).pcap"
        local cmd=""

        case "$choice" in
            1)
                get_interface
                echo -ne "  ${GREEN}Packet count${RESET} [200]: "; read -r COUNT
                COUNT="${COUNT:-200}"
                cmd="sudo tcpdump -i $IFACE -c $COUNT -w \"$pcap_out\""
                ;;
            2)
                get_interface
                echo -ne "  ${GREEN}Port${RESET}: "; read -r PORT
                echo -ne "  ${GREEN}Packet count${RESET} [100]: "; read -r COUNT
                COUNT="${COUNT:-100}"
                cmd="sudo tcpdump -i $IFACE port $PORT -c $COUNT -w \"$pcap_out\""
                ;;
            3)
                get_interface
                echo -ne "  ${GREEN}Host IP${RESET}: "; read -r HOST
                echo -ne "  ${GREEN}Packet count${RESET} [100]: "; read -r COUNT
                COUNT="${COUNT:-100}"
                cmd="sudo tcpdump -i $IFACE host $HOST -c $COUNT -w \"$pcap_out\""
                ;;
            4)
                get_interface
                cmd="sudo tcpdump -i $IFACE 'tcp port 80 or tcp port 8080' -c 200 -w \"$pcap_out\""
                ;;
            5)
                get_interface
                cmd="sudo tcpdump -i $IFACE port 53 -c 100 -w \"$pcap_out\""
                ;;
            6)
                pick_pcap || { press_enter; continue; }
                echo -ne "  ${GREEN}Filter${RESET} (blank for all): "; read -r FILT
                if [[ -n "$FILT" ]]; then
                    cmd="tcpdump -r \"$PCAP\" -nn $FILT"
                else
                    cmd="tcpdump -r \"$PCAP\" -nn"
                fi
                info "Running: ${CYAN}$cmd${RESET}"
                log "CMD: $cmd"
                eval "$cmd" 2>&1 | head -100
                press_enter; continue
                ;;
            7)
                get_interface
                echo -e "  ${GREEN_DIM}BPF examples: 'port 443' | 'host 10.10.10.10' | 'tcp and port 22'${RESET}"
                echo -ne "  ${GREEN}Custom filter${RESET}: "; read -r CFILT
                echo -ne "  ${GREEN}Packet count${RESET} [100]: "; read -r COUNT
                COUNT="${COUNT:-100}"
                cmd="sudo tcpdump -i $IFACE $CFILT -c $COUNT -w \"$pcap_out\""
                ;;
            *) warn "Invalid"; sleep 0.8; continue ;;
        esac

        echo ""
        info "Running: ${CYAN}$cmd${RESET}"
        info "Output → $pcap_out"
        warn "Press Ctrl+C to stop capture early"
        dim_line
        log "CMD: $cmd"
        eval "$cmd"
        ok "Saved → $pcap_out"
        info "Open with: tshark -r \"$pcap_out\" or Wireshark"
        press_enter
    done
}

# ── PCAP ANALYZER ─────────────────────────────────────────────
run_pcap_analyzer() {
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[TRAFFIC] PCAP Quick Analyzer${RESET}"
    thick_line
    pick_pcap || { press_enter; return; }

    local out="$WORK_DIR/pcap_analysis_$(date +%H%M%S).txt"
    echo "" | tee "$out"

    thick_line | tee -a "$out"
    echo -e "  ${GREEN_HI}PACKET COUNT${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    tshark -r "$PCAP" 2>/dev/null | wc -l | xargs echo "  Total packets:" | tee -a "$out"

    echo "" | tee -a "$out"
    echo -e "  ${GREEN_HI}TOP 10 SOURCE IPs${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    tshark -r "$PCAP" -T fields -e ip.src 2>/dev/null | sort | uniq -c | sort -rn | head -10 | tee -a "$out"

    echo "" | tee -a "$out"
    echo -e "  ${GREEN_HI}TOP 10 DESTINATION IPs${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    tshark -r "$PCAP" -T fields -e ip.dst 2>/dev/null | sort | uniq -c | sort -rn | head -10 | tee -a "$out"

    echo "" | tee -a "$out"
    echo -e "  ${GREEN_HI}PROTOCOLS DETECTED${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    tshark -r "$PCAP" -q -z io,phs 2>/dev/null | head -30 | tee -a "$out"

    echo "" | tee -a "$out"
    echo -e "  ${GREEN_HI}HTTP REQUESTS (first 20)${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    tshark -r "$PCAP" -Y http.request -T fields -e ip.src -e http.host -e http.request.uri 2>/dev/null | head -20 | tee -a "$out"

    echo "" | tee -a "$out"
    echo -e "  ${GREEN_HI}DNS QUERIES (first 20)${RESET}" | tee -a "$out"
    dim_line | tee -a "$out"
    tshark -r "$PCAP" -Y 'dns.flags.response==0' -T fields -e dns.qry.name 2>/dev/null | sort -u | head -20 | tee -a "$out"

    ok "Full report → $out"
    press_enter
}

# ── MAIN MENU ─────────────────────────────────────────────────
while true; do
    clear; thick_line
    echo -e "  ${AMBER}${BOLD}[ BLUE TEAM → TRAFFIC ANALYSIS ]${RESET}"
    thick_line
    echo -e "  ${GREEN}[1]${RESET} Wireshark             ${GREEN_DIM}— GUI launcher + filter reference${RESET}"
    echo -e "  ${GREEN}[2]${RESET} TShark                ${GREEN_DIM}— CLI capture, filter, extract${RESET}"
    echo -e "  ${GREEN}[3]${RESET} TCPDump               ${GREEN_DIM}— lightweight capture${RESET}"
    echo -e "  ${GREEN}[4]${RESET} PCAP Quick Analyzer   ${GREEN_DIM}— top IPs, protocols, HTTP, DNS${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back to Dashboard${RESET}"
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@traffic${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1) run_wireshark ;;
        2) run_tshark ;;
        3) run_tcpdump ;;
        4) run_pcap_analyzer ;;
        0) exit 0 ;;
        *) warn "Invalid option"; sleep 0.8 ;;
    esac
done


