#!/bin/bash
###############################################################################
# Desktop Tuning Manager v1.1 - Dark Edition
# Autor: Diego Costa (@diegocostaroot) - 2026
# Rollback + HTML diff report
# Autor: Diego Costa (@diegocostaroot) / Projeto Root (youtube.com/projetoroot)
# Versão: 1.1
# Veja o link: https://wiki.projetoroot.com.br
# 2026
###############################################################################

trap 'echo "ERRO na linha $LINENO"' ERR

# Cores
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'
echo_status() { echo -e "${GREEN}[✓]${NC} $1"; }
echo_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
echo_error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# Verificações
[[ $(id -u) != 0 ]] && echo_error "Use: sudo $0"
command -v sysctl >/dev/null 2>&1 || echo_error "sysctl não encontrado"

DATE=$(date +%F_%H-%M-%S)
BACKUP_DIR="/var/backups/sysctl-tuning"
SYSCTL_DIR="/etc/sysctl.d"

echo "=============================================="
echo "    DESKTOP TUNING MANAGER v1.1 - TEMA ESCURO "
echo "=============================================="

# 1. ESCOLHER PASTA
echo -n "📁 Pasta relatórios [/home/diegocosta]: "
read PASTA
PASTA=${PASTA:-/home/diegocosta}
PASTA=${PASTA%/}
mkdir -p "$PASTA" 2>/dev/null || PASTA=/root

USER=$(stat -c '%U' "$PASTA" 2>/dev/null | grep -v root || echo root)
echo "👤 Usuário: $USER | 📁 $PASTA"
mkdir -p "$BACKUP_DIR"

# 2. DETECTAR PERFIL ATUAL
detect_profile() {
    for f in "$SYSCTL_DIR"/99-desktop-{gaming,laptop,dev,streaming,powersave}.conf; do
        [[ -f "$f" ]] && {
            name=$(basename "$f" | sed 's/99-desktop-//;s/\.conf//;s/-/ /g')
            num=$(echo "$f" | grep -o '[0-9]' | head -1 || echo 1)
            echo "$num $name"
            return
        }
    done
    echo "1 Desktop Geral"
}
CUR=$(detect_profile)
echo "🎯 Perfil atual: $CUR"

# 3. MENU COMPLETO
cat << EOF

📋 ESCOLHA O PERFIL:

 1) 🖥️  DESKTOP GERAL (CIS Baseline)
 2) 🎮 GAMING (baixo latency)  
 3) 💻 LAPTOP ECONOMIA
 4) 💻 DEV WORKSTATION
 5) 📹 STREAMING OBS
 6) 🔋 ECONOMIA MÁXIMA
 7) 🔄 RESTAURAR BACKUP

EOF

echo -n "Opção (1-7): "
read OPCAO

# 4. VALIDAR OPCAO E MAPEAR NOME
case $OPCAO in
    7)
        BACKUPS=($(find "$BACKUP_DIR" -name "sysctl_backup_*.conf" | sort -r | head -5))
        [[ ${#BACKUPS[@]} -eq 0 ]] && { echo_warning "Sem backups"; exit 0; }
        echo "Backups disponíveis:"
        for i in "${!BACKUPS[@]}"; do
            echo "  $((i+1))) $(basename "${BACKUPS[i]}")"
        done
        echo -n "Escolha: "
        read NUM
        [[ $NUM -le ${#BACKUPS[@]} && $NUM -ge 1 ]] 2>/dev/null || { echo_warning "Inválido"; exit 1; }
        sysctl -p "${BACKUPS[$((NUM-1))]}" && echo_status "Rollback OK"
        exit 0
        ;;
    1|2|3|4|5|6)
        CUR_NUM=$(echo "$CUR" | cut -d' ' -f1)
        [[ $OPCAO == $CUR_NUM ]] && { echo_warning "Perfil já ativo!"; exit 0; }
        ;;
    *) echo_error "Digite 1-7";;
esac

# 5. DEFINIR NOME DO PERFIL
PERFIL_NOME=""
case $OPCAO in
    1) PERFIL_NOME="Desktop Geral" ;;
    2) PERFIL_NOME="Gaming" ;;
    3) PERFIL_NOME="Laptop Economia" ;;
    4) PERFIL_NOME="Dev Workstation" ;;
    5) PERFIL_NOME="Streaming OBS" ;;
    6) PERFIL_NOME="Economia Máxima" ;;
esac

# 6. BACKUP + SNAPSHOTS
BACKUP_FILE="$BACKUP_DIR/sysctl_backup_$DATE.conf"
sysctl -a 2>/dev/null | grep -E '^(net|vm|fs|kernel)\.' | sort > "$BACKUP_FILE"
echo_status "Backup criado: $(basename "$BACKUP_FILE")"

BEFORE="$PASTA/sysctl_before_$DATE.txt"
AFTER="$PASTA/sysctl_after_$DATE.txt"
HTML="$PASTA/sysctl_diff_$DATE.html"

sysctl -a 2>/dev/null | grep -E '^(net|vm|fs|kernel)\.' | sort > "$BEFORE"
echo_status "Snapshot ANTES OK"

# IPV6 DETECT AUTO:
HAS_IPV6=$(ping6 -c1 8.8.8.8 >/dev/null 2>&1 && echo "true" || echo "false")

if [[ "$HAS_IPV6" == "false" ]]; then
    echo "IPv6 não disponível - desabilitando (CIS)"
    cat >> "$SYSCTL_DIR/99-desktop-baseline.conf" << EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF
else
    echo "IPv6 detectado - hardening apenas"
    cat >> "$SYSCTL_DIR/99-desktop-baseline.conf" << EOF
net.ipv6.conf.all.forwarding=0
net.ipv6.conf.default.forwarding=0
net.ipv6.conf.all.accept_ra=0
EOF
fi

# 7. CIS BASELINE (SEMPRE)
cat > "$SYSCTL_DIR/99-desktop-baseline.conf" << 'EOF'
# CIS Ubuntu 22.04 Level 1 + Desktop
fs.protected_hardlinks=1
fs.protected_symlinks=1
fs.protected_fifos=1
fs.protected_regular=2
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
kernel.unprivileged_bpf_disabled=1
kernel.printk=3 4 1 3
fs.suid_dumpable=0
kernel.yama.ptrace_scope=1
kernel.core_uses_pid=1
kernel.kexec_load_disabled=1
kernel.randomize_va_space=2
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
vm.swappiness=10
fs.file-max=1048576
EOF

# 8. PERFIS OTIMIZADOS
case $OPCAO in
    1) # Desktop Geral - só baseline
        ;;
    2) # GAMING
        cat > "$SYSCTL_DIR/99-desktop-gaming.conf" << 'EOF'
vm.swappiness=1
vm.vfs_cache_pressure=50
vm.dirty_ratio=20
vm.dirty_background_ratio=10
kernel.sched_autogroup_enabled=0
net.core.somaxconn=4096
net.core.netdev_max_backlog=5000
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1
EOF
        ;;
    3) # LAPTOP
        cat > "$SYSCTL_DIR/99-desktop-laptop.conf" << 'EOF'
vm.swappiness=60
vm.vfs_cache_pressure=200
vm.dirty_ratio=10
vm.dirty_background_ratio=5
kernel.sched_autogroup_enabled=1
EOF
        echo -n "💡 Power saving extra? (s/N): "
        read PS
        [[ $PS =~ [sS] ]] && systemctl mask systemd-rfkill.service 2>/dev/null && echo_status "Power saving OK"
        ;;
    4) # DEV WORKSTATION
        cat > "$SYSCTL_DIR/99-desktop-dev.conf" << 'EOF'
fs.file-max=2097152
vm.max_map_count=1048576
kernel.pid_max=4194304
vm.swappiness=5
vm.overcommit_memory=1
EOF
        ;;
    5) # STREAMING OBS
        cat > "$SYSCTL_DIR/99-desktop-streaming.conf" << 'EOF'
vm.swappiness=1
net.core.somaxconn=8192
net.core.netdev_max_backlog=10000
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
EOF
        ;;
    6) # ECONOMIA MÁXIMA
        cat > "$SYSCTL_DIR/99-desktop-powersave.conf" << 'EOF'
vm.swappiness=80
vm.vfs_cache_pressure=300
vm.dirty_ratio=5
vm.dirty_background_ratio=2
kernel.sched_autogroup_enabled=1
EOF
        ;;
esac

sysctl --system &>/dev/null && echo_status "✅ PERFIS APLICADOS!"
sysctl -a 2>/dev/null | grep -E '^(net|vm|fs|kernel)\.' | sort > "$AFTER"
echo_status "Snapshot DEPOIS OK"

# 9. HTML REPORT - CORES DARK PERFEITAS
ATIVOS=$(grep -c '=' "$AFTER" 2>/dev/null || echo 0)
REMOVIDOS=$(comm -23 <(sort "$BEFORE") <(sort "$AFTER") 2>/dev/null | wc -l)

cat > "$HTML" << EOF
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <title>Sysctl Tuning Report - $DATE</title>
    <meta charset="UTF-8">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'JetBrains Mono', 'Courier New', monospace; 
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 100%); 
            color: #e0e0e0; 
            padding: 30px; 
            min-height: 100vh;
        }
        .container { max-width: 1400px; margin: 0 auto; }
        .header { 
            background: linear-gradient(90deg, #333 0%, #444 100%); 
            padding: 25px; 
            border-radius: 15px; 
            margin-bottom: 30px; 
            box-shadow: 0 8px 32px rgba(0,0,0,0.5);
            border: 1px solid #555;
            text-align: center;
        }
        h1 { 
            color: #00ff88; 
            text-shadow: 0 0 20px #00ff88; 
            margin-bottom: 10px;
            font-size: 2.2em;
        }
        .stats { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); 
            gap: 20px; 
            margin: 25px 0;
        }
        .stat { 
            background: rgba(0,0,0,0.4); 
            padding: 25px; 
            border-radius: 15px; 
            text-align: center; 
            box-shadow: 0 10px 40px rgba(0,0,0,0.6);
            border: 2px solid transparent;
            transition: all 0.3s ease;
        }
        .stat:hover { transform: translateY(-5px); }
        .active { 
            background: rgba(0,255,136,0.15) !important; 
            border-color: #00ff88 !important; 
            color: #00ff88 !important;
        }
        .removed { 
            background: rgba(255,85,85,0.15) !important; 
            border-color: #ff5555 !important; 
            color: #ff5555 !important;
        }
        .diff-container { 
            background: #2a2a2a; 
            padding: 30px; 
            border-radius: 20px; 
            box-shadow: inset 0 0 30px rgba(0,0,0,0.7), 0 10px 40px rgba(0,0,0,0.5);
            border: 2px solid #444;
            margin: 30px 0;
        }
        .diff-title { 
            color: #ffaa00; 
            font-size: 1.5em; 
            margin-bottom: 20px; 
            text-align: center;
            text-shadow: 0 0 10px #ffaa00;
        }
        pre { 
            background: #1e1e1e; 
            padding: 25px; 
            border-radius: 12px; 
            overflow-x: auto; 
            white-space: pre-wrap; 
            line-height: 1.6;
            font-size: 13px;
            border-left: 5px solid #555;
            box-shadow: inset 0 0 20px rgba(0,0,0,0.5);
        }
        .active-line { 
            background: rgba(0,255,136,0.3) !important; 
            color: #00ff88 !important; 
            padding: 6px 10px !important; 
            border-radius: 6px !important;
            border-left: 4px solid #00ff88 !important;
            display: block !important;
            margin: 2px 0;
            font-weight: 500;
        }
        .removed-line { 
            background: rgba(255,85,85,0.3) !important; 
            color: #ff5555 !important; 
            padding: 6px 10px !important; 
            border-radius: 6px !important;
            border-left: 4px solid #ff5555 !important;
            text-decoration: line-through;
            display: block !important;
            margin: 2px 0;
            font-weight: 500;
        }
        .footer { 
            text-align: center; 
            color: #888; 
            padding: 25px;
            background: rgba(0,0,0,0.4);
            border-radius: 15px;
            margin-top: 30px;
            font-size: 0.95em;
            border: 1px solid #444;
        }
        @media (max-width: 768px) {
            body { padding: 20px 15px; }
            h1 { font-size: 1.8em; }
            pre { font-size: 12px; padding: 20px; }
            .stats { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🖥️ Sysctl Tuning Report</h1>
            <p><strong>Perfil:</strong> $PERFIL_NOME | <strong>Data:</strong> $DATE</p>
        </div>
        
        <div class="stats">
            <div class="stat active">
                <h2>✅ ATIVOS</h2>
                <h1>$ATIVOS</h1>
            </div>
            <div class="stat removed">
                <h2>❌ REMOVIDOS</h2>
                <h1>$REMOVIDOS</h1>
            </div>
        </div>

        <div class="diff-container">
            <div class="diff-title">📊 DIFERENÇAS DETECTADAS</div>
            <pre>
🟢 === ATIVOS ($ATIVOS itens) ===
$(grep '=' "$AFTER" | head -30 | sort | sed 's/^/  <span class="active-line">&<\/span>/')
                
🔴 === REMOVIDOS ($REMOVIDOS itens) ===
$(comm -23 <(sort "$BEFORE") <(sort "$AFTER") | head -20 | sed 's/^/  <span class="removed-line">&<\/span>/')
            </pre>
        </div>

        <div class="footer">
            <strong>📁 Arquivos gerados:</strong><br>
            🔙 Backup: <code>$(basename "$BACKUP_FILE")</code> | 
            📋 Antes: <code>$(basename "$BEFORE")</code> | 
            ✅ Depois: <code>$(basename "$AFTER")</code><br><br>
            ✨ <strong>Desktop Tuning Manager v1.1 - Dark Edition</strong><br>
            👨‍💻 Diego Costa (@diegocostaroot) - youtube.com/projetoroot
        </div>
    </div>
</body></html>
EOF

echo_status "📊 HTML Dark criado: $(basename "$HTML")"

# 10. CHOWN AUTOMÁTICO - SEMPRE para usuário /home/
HOME_USER=$(ls /home/ 2>/dev/null | head -1)  # Primeiro usuário em /home/

if [[ -n "$HOME_USER" && "$HOME_USER" != "lost+found" ]]; then
    chown -R "$HOME_USER":"$HOME_USER" "$PASTA"
    echo_status "✅ Chown $HOME_USER OK (detectado em /home/)"
else
    echo_warning "Nenhum usuário em /home/, mantendo root"
fi

echo -e "\n${GREEN}🎉 SUCESSO TOTAL!${NC}"
echo "📁 Backup: $BACKUP_FILE"
echo "📊 HTML: $HTML" 
echo "🔍 Abra o HTML no navegador!"
