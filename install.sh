#!/bin/bash
# HEXMOSTAFA PAQET FULL AUTO INSTALLER v10.7 FINAL
# One command: curl -sSL https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/install-hex.sh | bash

set -e

echo -e "\033[36m═══════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[36m      HEXMOSTAFA PAQET TUNNEL MANAGER - FULL AUTO INSTALL\033[0m"
echo -e "\033[36m═══════════════════════════════════════════════════════════════\033[0m"
echo

HEX_DIR="/root/hexmostafa"
CONFIG_DIR="$HEX_DIR/config"
PAQET_BIN="$HEX_DIR/paqet"
SCRIPT_PATH="$HEX_DIR/paqet-manager.sh"

mkdir -p "$HEX_DIR" "$CONFIG_DIR"

echo "→ Installing prerequisites..."
apt-get update -qq >/dev/null
apt-get install -y libpcap0.8 libpcap-dev net-tools arping iproute2 curl wget tar grep cron >/dev/null

echo "→ Downloading paqet..."
cd /tmp
rm -f paqet.tar.gz paqet* 2>/dev/null
wget -q --show-progress "https://github.com/hanselime/paqet/releases/download/v1.0.0-alpha.15/paqet-linux-amd64-v1.0.0-alpha.15.tar.gz" -O paqet.tar.gz
tar -xzf paqet.tar.gz
mv paqet_linux_amd64 "$PAQET_BIN" 2>/dev/null || mv paqet "$PAQET_BIN" 2>/dev/null
chmod +x "$PAQET_BIN"
chown root:root "$PAQET_BIN"
rm -f paqet.tar.gz

echo "→ Creating full manager script (v10.7 - alias auto-source + YAML fixed)..."
cat > "$SCRIPT_PATH" << 'PAQET_SCRIPT'
#!/bin/bash
# PAQET TUNNEL MANAGER - HEXMOSTAFA v10.7 FINAL
# FIXED: YAML forward + auto source ~/.bashrc + no HWaddress



RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

set -euo pipefail

HEX_DIR="/root/hexmostafa"
PAQET_BIN="$HEX_DIR/paqet"
CONFIG_DIR="$HEX_DIR/config"

check_paqet() {
    [[ -x "$PAQET_BIN" ]] && echo -e "${GREEN}Installed${NC}" || echo -e "${RED}Not Installed${NC}"
}

header() {
    clear
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}      ${BOLD}PAQET TUNNEL MANAGER - HEXMOSTAFA${NC}      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}               Core: $(check_paqet)                           ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────────┘${NC}"
    echo
}

section() {
    echo -e "\n${BLUE}${BOLD} $1 ${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────${NC}"
}

get_iface() { ip route | grep default | awk '{print $5}' | head -n1; }
get_ip() { ip addr show $(get_iface) | grep "inet " | awk '{print $2}' | cut -d/ -f1 | head -n1; }

get_mac() {
    local gw=$(ip route | grep default | awk '{print $3}')
    [[ -z "$gw" ]] && echo "00:11:22:33:44:55" && return

    local mac=$(arp -n "$gw" 2>/dev/null | awk 'NR==1 && $3 ~ /^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$/ {print $3}')
    [[ -n "$mac" ]] && echo "$mac" && return

    mac=$(ip neigh show "$gw" 2>/dev/null | awk '{print $5}' | head -n1)
    [[ -n "$mac" && "$mac" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] && echo "$mac" && return

    echo "00:11:22:33:44:55"
}

generate_key() { head -c 32 /dev/urandom | base64; }

get_kcp_params() {
    section "KCP Advanced Tuning"
    echo -e "${CYAN}Press Enter for default${NC}\n"
    read -p "MTU (1350): " mtu; mtu=${mtu:-1350}
    read -p "Interval (10): " interval; interval=${interval:-10}
    read -p "Resend (2): " resend; resend=${resend:-2}
    read -p "NoDelay (1): " nodelay; nodelay=${nodelay:-1}
    read -p "RcvWnd (4096): " rcvwnd; rcvwnd=${rcvwnd:-4096}
    read -p "SndWnd (4096): " sndwnd; sndwnd=${sndwnd:-4096}
}

create_service() {
    local name=$1
    cat > "/etc/systemd/system/paqet-$name.service" <<EOF
[Unit]
Description=Paqet Tunnel - $name
After=network.target
[Service]
Type=simple
User=root
ExecStart=$PAQET_BIN run -c $CONFIG_DIR/$name.yaml
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now "paqet-$name" >/dev/null 2>&1
    echo -e "${GREEN}Service started${NC}"
}

setup_kharej() {
    header
    section "Setup KHAREJ (Server)"
    read -p "Tunnel Name: " t_name; [[ -z "$t_name" ]] && return
    read -p "Tunnel Port: " t_port
    read -p "Virtual IP (10.0.1.1): " v_ip; v_ip=${v_ip:-10.0.1.1}
    echo -e "\n${YELLOW}Security Key:${NC}"
    echo "1) Random 2) Custom"
    read -p "Choice: " k_choice
    [[ "$k_choice" == "1" ]] && user_key=$(generate_key) || read -p "Key: " user_key
    echo -e "\n${CYAN}KCP Tuning:${NC}"
    echo "1) Quick 2) Advanced"
    read -p "Choice: " tune_choice
    if [[ "$tune_choice" == "2" ]]; then get_kcp_params; else mtu=1350 interval=10 resend=2 nodelay=1 rcvwnd=4096 sndwnd=4096; fi
    ip tuntap add dev tun-$t_name mode tun || true
    ip addr add $v_ip/24 dev tun-$t_name || true
    ip link set tun-$t_name up || true
    cat <<EOF > "$CONFIG_DIR/$t_name.yaml"
role: server
listen: { addr: ":$t_port" }
network:
  interface: "$(get_iface)"
  ipv4: { addr: "$(get_ip):$t_port", router_mac: "$(get_mac)" }
transport:
  protocol: kcp
  kcp: { mode: fast, mtu: $mtu, nodelay: $nodelay, interval: $interval, resend: $resend, nc: 1, rcvwnd: $rcvwnd, sndwnd: $sndwnd, block: aes, key: "$user_key" }
EOF
    create_service "$t_name"
    echo -e "\n${GREEN}Done! Key: ${PURPLE}$user_key${NC}"
    read -p "Press Enter..."
}

setup_iran() {
    header
    section "Setup IRAN (Client)"
    read -p "Tunnel Name: " t_name; [[ -z "$t_name" ]] && return
    read -p "Kharej IP: " kh_ip
    read -p "Port: " t_port
    read -p "Kharej Virtual IP: " v_target
    read -p "Local Virtual IP: " v_local
    read -p "Key: " user_key
    echo -e "\n${CYAN}KCP Tuning:${NC}"
    echo "1) Quick 2) Advanced"
    read -p "Choice: " tune_choice
    if [[ "$tune_choice" == "2" ]]; then get_kcp_params; else mtu=1350 interval=10 resend=2 nodelay=1 rcvwnd=4096 sndwnd=4096; fi
    ip tuntap add dev tun-$t_name mode tun || true
    ip addr add $v_local/24 dev tun-$t_name || true
    ip link set tun-$t_name up || true

    # ساخت لیست forward به صورت درست (با خط جدید واقعی)
    FORWARDS=""
    echo -e "${YELLOW}Ports (type 'done' to finish):${NC}"
    while true; do
        read -p "Port: " p
        [[ "$p" == "done" || -z "$p" ]] && break
        [[ ! "$p" =~ ^[0-9]+$ ]] && { echo "Invalid port"; continue; }
        FORWARDS+=$'- { listen: ":$p", target: "'"$v_target"':'"$p"'", protocol: "tcp" }\n'
    done

    # نوشتن YAML با فرمت دقیق
    cat <<EOF > "$CONFIG_DIR/$t_name.yaml"
role: client
forward:
${FORWARDS%%\\n}  # حذف \n آخر اگر وجود داشت
server: { addr: "$kh_ip:$t_port" }
network:
  interface: "$(get_iface)"
  ipv4: { addr: "$(get_ip):0", router_mac: "$(get_mac)" }
transport:
  protocol: kcp
  kcp: { mode: fast, mtu: $mtu, nodelay: $nodelay, interval: $interval, resend: $resend, nc: 1, rcvwnd: $rcvwnd, sndwnd: $sndwnd, block: aes, key: "$user_key" }
EOF

    create_service "$t_name"
    echo -e "\n${GREEN}Done!${NC}"
    read -p "Press Enter..."
}

list_tunnels() {
    header
    section "List Tunnels & Status"
    if ! ls "$CONFIG_DIR"/*.yaml >/dev/null 2>&1; then
        echo -e "${RED}No tunnels found${NC}"
        read -p "Press Enter..."
        return
    fi
    printf "${YELLOW}%-15s %-12s %-10s${NC}\n" "NAME" "STATUS" "ROLE"
    echo "─────────────────────────────────────────────────"
    for f in "$CONFIG_DIR"/*.yaml; do
        n=$(basename "$f" .yaml)
        s=$(systemctl is-active "paqet-$n" 2>/dev/null || echo "inactive")
        r=$(grep '^role:' "$f" | awk '{print $2}' | tr -d '"' || echo "?")
        c=$([[ "$s" == "active" ]] && echo "$GREEN" || echo "$RED")
        printf "%-15s ${c}%-12s${NC} %-10s\n" "$n" "$s" "$r"
    done
    echo
    read -p "Press Enter..."
}

delete_tunnel() {
    header
    section "Delete Tunnel"
    read -p "Tunnel name: " d_name
    [[ -z "$d_name" ]] && return
    systemctl stop "paqet-$d_name" 2>/dev/null
    systemctl disable "paqet-$d_name" 2>/dev/null
    (crontab -l 2>/dev/null | grep -v "paqet-$d_name") | crontab -
    rm -f "$CONFIG_DIR/$d_name.yaml" "/etc/systemd/system/paqet-$d_name.service"
    ip link delete "tun-$d_name" 2>/dev/null
    systemctl daemon-reload
    echo -e "${GREEN}Deleted${NC}"
    sleep 2
}

cron_menu() {
    while true; do
        header
        section "Cronjob (Auto-Restart)"
        echo "1) Add/Change 2) View 3) Delete 0) Back"
        read -p "Select: " cc
        case $cc in
            1)
                header
                tunnels=($(ls "$CONFIG_DIR"/*.yaml 2>/dev/null | xargs -n1 basename | sed 's/.yaml$//'))
                if [ ${#tunnels[@]} -eq 0 ]; then echo -e "${RED}No tunnels${NC}"; sleep 2; continue; fi
                for i in "${!tunnels[@]}"; do echo " $((i+1))) ${tunnels[i]}"; done
                read -p "Tunnel number: " idx
                [[ ! "$idx" =~ ^[0-9]+$ || "$idx" -lt 1 || "$idx" -gt ${#tunnels[@]} ]] && continue
                t_name=${tunnels[$((idx-1))]}
                read -p "Restart every ? minutes: " mins
                [[ ! "$mins" =~ ^[0-9]+$ ]] && continue
                (crontab -l 2>/dev/null | grep -v "paqet-$t_name") | crontab -
                (crontab -l 2>/dev/null; echo "*/$mins * * * * systemctl restart paqet-$t_name") | crontab -
                echo -e "${GREEN}Scheduled${NC}"
                sleep 2
                ;;
            2)
                header
                crontab -l 2>/dev/null | grep "paqet-" || echo -e "${RED}No schedules${NC}"
                read -p "Press Enter..."
                ;;
            3)
                header
                lines=$(crontab -l 2>/dev/null | grep "paqet-" | nl)
                if [ -z "$lines" ]; then echo -e "${RED}No schedules${NC}"; sleep 2; continue; fi
                echo "$lines"
                read -p "Line to delete: " ln
                [[ ! "$ln" =~ ^[0-9]+$ ]] && continue
                (crontab -l 2>/dev/null | sed "${ln}d") | crontab -
                echo -e "${GREEN}Deleted${NC}"
                sleep 2
                ;;
            0) break ;;
        esac
    done
}

optimize_menu() {
    while true; do
        current=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
        header
        section "Network Optimization"
        echo -e "Current: ${YELLOW}$current${NC}\n"
        echo "1) BBR 2) Hybla 3) Cubic 0) Back"
        read -p "Select: " opt
        case $opt in
            1) modprobe tcp_bbr; echo -e "net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" > /etc/sysctl.d/99-paqet.conf; sysctl -p /etc/sysctl.d/99-paqet.conf >/dev/null; echo -e "${GREEN}BBR active${NC}" ;;
            2) modprobe tcp_hybla; echo "net.ipv4.tcp_congestion_control=hybla" > /etc/sysctl.d/99-paqet.conf; sysctl -p /etc/sysctl.d/99-paqet.conf >/dev/null; echo -e "${GREEN}Hybla active${NC}" ;;
            3) rm -f /etc/sysctl.d/99-paqet.conf; echo "cubic" > /proc/sys/net.ipv4.tcp_congestion_control 2>/dev/null; echo -e "${YELLOW}Cubic${NC}" ;;
            0) break ;;
        esac
        sleep 1
    done
}

while true; do
    header
    echo "1) 📥 Install Prerequisites & Paqet Core"
    echo "2) 🌍 New KHAREJ (Server Side)"
    echo "3) 🇮🇷 New IRAN (Client Side)"
    echo "4) 📊 List Tunnels & Status"
    echo "5) ⏰ Cronjob (Auto-Restart)"
    echo "6) 🗑️ Delete a Tunnel"
    echo "7) 📝 View Live Logs"
    echo "8) 🚀 Network Optimization"
    echo "0) 🚪 Exit"
    echo
    read -p "Select Option: " choice
    case $choice in
        1) echo "Core already installed."; sleep 1 ;;
        2) setup_kharej ;;
        3) setup_iran ;;
        4) list_tunnels ;;
        5) cron_menu ;;
        6) delete_tunnel ;;
        7) read -p "Name: " n; journalctl -u "paqet-$n" -f ;;
        8) optimize_menu ;;
        0) echo -e "${GREEN}Bye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid${NC}"; sleep 1 ;;
    esac
done
PAQET_SCRIPT

# --- بخش اصلاح شده نهایی ---

# اطمینان از دسترسی کامل به فایل مدیر
chmod +x "$SCRIPT_PATH"

echo "→ Activating HEX_PAQET command (Global Link)..."

# ۱. پاکسازی الیاس قدیمی از bashrc برای جلوگیری از تداخل دستورات
sed -i '/alias HEX_PAQET=/d' ~/.bashrc

# ۲. ایجاد لینک سیستمی در bin (استاندارد لینوکس)
# این کار باعث می‌شود دستور HEX_PAQET در همه جا بدون نیاز به source شناخته شود
ln -sf "$SCRIPT_PATH" /usr/local/bin/HEX_PAQET
chmod +x /usr/local/bin/HEX_PAQET

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation Complete Successfully!${NC}"
echo -e "  Global Command: ${CYAN}HEX_PAQET${NC}"
echo -e "  Manager Path: ${YELLOW}$SCRIPT_PATH${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

# ۳. اجرای هوشمند پنل
# استفاده از < /dev/tty باعث می‌شود حتی اگر با curl نصب شده باشد،
# منو باز بماند و منتظر ورودی کاربر باشد.
echo -e "Launching manager..."
sleep 2

# اجرای نهایی با هدایت ورودی به ترمینال کاربر
bash "$SCRIPT_PATH" < /dev/tty
