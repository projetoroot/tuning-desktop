#!/usr/bin/env bash
###############################################################################
# Desktop Tuning Manager
# Rollback + HTML diff report
# Autor: Diego Costa (@diegocostaroot) / Projeto Root (youtube.com/projetoroot)
# Versão: 1.0
# Veja o link: https://wiki.projetoroot.com.br
# 2026
###############################################################################


set -Eeuo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SYSCTL_BIN="$(command -v sysctl || true)"

if [[ -z "$SYSCTL_BIN" ]]; then
    echo "Erro crítico: sysctl não encontrado no sistema"
    exit 1
fi


if [ "$EUID" -ne 0 ]; then
    echo "Execute como root"
    exit 1
fi

DATE=$(date +%F-%H-%M-%S)

echo
read -p "Informe o diretório para salvar relatórios (ex: /root ou /home/user): " REPORT_BASE

if [ ! -d "$REPORT_BASE" ]; then
    echo "Diretório não existe"
    exit 1
fi

BACKUP_DIR="/var/backups/sysctl-tuning"
SYSCTL_DIR="/etc/sysctl.d"

mkdir -p "$BACKUP_DIR"
mkdir -p "$SYSCTL_DIR"

BACKUP_FILE="$BACKUP_DIR/sysctl_backup_$DATE.conf"
BEFORE_TXT="$REPORT_BASE/sysctl_before_$DATE.txt"
AFTER_TXT="$REPORT_BASE/sysctl_after_$DATE.txt"
DIFF_HTML="$REPORT_BASE/sysctl_diff_$DATE.html"

#########################################
# Rollback manual sysctl
#########################################

rollback_sysctl_menu() {

    echo
    echo "Backups disponíveis:"
    echo

    mapfile -t BACKUPS < <(find "$BACKUP_DIR" -type f -name "*.conf" -size +0c | sort)

    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo "Nenhum backup válido encontrado"
        return 1
    fi

    for i in "${!BACKUPS[@]}"; do
        printf "%d) %s\n" "$((i+1))" "$(basename "${BACKUPS[$i]}")"
    done

    echo
    read -p "Escolha o número do backup: " CHOICE

    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
        echo "Entrada inválida"
        return 1
    fi

    INDEX=$((CHOICE-1))

    if [ "$INDEX" -lt 0 ] || [ "$INDEX" -ge "${#BACKUPS[@]}" ]; then
        echo "Opção fora da lista"
        return 1
    fi

    SELECTED="${BACKUPS[$INDEX]}"

    echo
    echo "Backup selecionado:"
    echo "$SELECTED"
    echo

    read -p "Confirma restaurar? (s/n): " CONFIRM

    if [[ "$CONFIRM" =~ ^[sS]$ ]]; then

        echo "Aplicando rollback..."
        sysctl -p "$SELECTED"

        cp "$SELECTED" /etc/sysctl.d/99-rollback-manual.conf
        sysctl --system

        echo "Rollback concluído"
    else
        echo "Cancelado"
    fi
}


#########################################
# Backup atual
#########################################

echo "Criando backup atual"
sysctl -a 2>/dev/null | sort > "$BACKUP_FILE"

#########################################
# BEFORE snapshot
#########################################

echo "Capturando estado BEFORE"
sysctl -a 2>/dev/null | sort > "$BEFORE_TXT"


#########################################
# Detectar perfil ativo atual
#########################################

CURRENT_PROFILE="Nenhum"

if ls $SYSCTL_DIR/99-desktop-gaming.conf >/dev/null 2>&1; then
    CURRENT_PROFILE="Gaming"
    CURRENT_PROFILE_ID=2
elif ls $SYSCTL_DIR/99-desktop-laptop.conf >/dev/null 2>&1; then
    CURRENT_PROFILE="Laptop Economia"
    CURRENT_PROFILE_ID=3
elif ls $SYSCTL_DIR/99-desktop-dev.conf >/dev/null 2>&1; then
    CURRENT_PROFILE="Dev Workstation"
    CURRENT_PROFILE_ID=4
elif ls $SYSCTL_DIR/99-desktop-streaming.conf >/dev/null 2>&1; then
    CURRENT_PROFILE="Streaming OBS"
    CURRENT_PROFILE_ID=5
else
    CURRENT_PROFILE_ID=1
    CURRENT_PROFILE="Desktop Geral"
fi


#########################################
# Menu perfil
#########################################

clear
echo "Perfil atualmente ativo: $CURRENT_PROFILE"
echo "Escolha perfil:"
echo "1 Desktop Geral"
echo "2 Gaming"
echo "3 Laptop Economia"
echo "4 Dev Workstation"
echo "5 Streaming OBS"
echo "6 Economia de Energia"
echo "7 Restaurar backup sysctl"
echo
read -p "Opção: " PROFILE

#########################################
# Bloquear reaplicação do mesmo perfil
#########################################

if [[ "$PROFILE" =~ ^[1-5]$ ]]; then
    if [ "$PROFILE" -eq "${CURRENT_PROFILE_ID:-0}" ]; then
        echo
        echo "Perfil $CURRENT_PROFILE já está ativo."
        echo "Nada será alterado."
        exit 0
    fi
fi

case "$PROFILE" in
  1) PROFILE_NAME="Desktop Geral" ;;
  2) PROFILE_NAME="Gaming" ;;
  3) PROFILE_NAME="Laptop Economia" ;;
  4) PROFILE_NAME="Dev Workstation" ;;
  5) PROFILE_NAME="Streaming OBS" ;;
  6) PROFILE_NAME="Economia de Energia" ;;
  7) PROFILE_NAME="Rollback Sysctl"; rollback_sysctl_menu ;;
  *) PROFILE_NAME="Desconhecido" ;;
esac

echo "Selecionado: $PROFILE $PROFILE_NAME"

#########################################
# Limpeza perfis antigos
#########################################

echo "Removendo perfis antigos"

find "$SYSCTL_DIR" -maxdepth 1 -type f -name "99-desktop-*.conf" \
    ! -name "99-desktop-baseline.conf" \
    -exec rm -f {} \;

#########################################
# Baseline
#########################################

cat > $SYSCTL_DIR/99-desktop-baseline.conf <<EOF
fs.protected_hardlinks=1
fs.protected_symlinks=1
fs.protected_fifos=1
fs.protected_regular=1
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
fs.suid_dumpable=0
kernel.yama.ptrace_scope=1
net.ipv4.tcp_syncookies=1
vm.swappiness=10
fs.file-max=1048576
EOF

#########################################
# Perfis extras
#########################################

case $PROFILE in

2)
cat > $SYSCTL_DIR/99-desktop-gaming.conf <<EOF
vm.swappiness=5
net.core.somaxconn=8192
net.core.netdev_max_backlog=25000
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_slow_start_after_idle=0
EOF
;;

3)
PROFILE_NAME="Laptop Economia"

# Configurações básicas
cat > $SYSCTL_DIR/99-desktop-laptop.conf <<EOF
vm.swappiness=20
vm.dirty_ratio=10
vm.dirty_background_ratio=5
kernel.sched_autogroup_enabled=1
EOF

# Pergunta sobre Runtime Power Saving
echo
read -p "Aplicar Runtime Power Saving (CPU, brilho, I/O)? (s/n): " POWER_SAVE
if [[ "$POWER_SAVE" =~ ^[sS]$ ]]; then
    echo "Aplicando ajustes de economia de energia..."
    # exemplo de ajustes
    sysctl -w vm.vfs_cache_pressure=200
    # CPU scaling para modo powersave
    for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "powersave" > "$CPUFREQ"
    done
    # brilho mínimo (opcional, se for laptop)
    if [ -d /sys/class/backlight ]; then
        for BR in /sys/class/backlight/*/brightness; do
            MAX=$(cat $(dirname $BR)/max_brightness)
            MIN=$((MAX / 4))
            echo "$MIN" > "$BR"
        done
    fi
fi
;;

4)
cat > $SYSCTL_DIR/99-desktop-dev.conf <<EOF
fs.file-max=2097152
vm.max_map_count=262144
kernel.pid_max=4194304
vm.swappiness=5
EOF
;;

5)
cat > $SYSCTL_DIR/99-desktop-streaming.conf <<EOF
vm.swappiness=5
net.core.somaxconn=8192
net.core.netdev_max_backlog=30000
net.core.rmem_max=33554432
net.core.wmem_max=33554432
EOF
;;

6)
cat > $SYSCTL_DIR/99-desktop-powersave.conf <<EOF
vm.swappiness=30
vm.dirty_ratio=5
vm.dirty_background_ratio=3
kernel.sched_autogroup_enabled=1
vm.vfs_cache_pressure=200
EOF
;;

esac

#########################################
# Aplicar com rollback
#########################################

echo "Aplicando tuning"

if ! sysctl --system; then

    echo "Erro detectado. Iniciando rollback"

    while read line; do
        KEY=$(echo "$line" | cut -d '=' -f1)
        VAL=$(echo "$line" | cut -d '=' -f2-)
        sysctl -w "$KEY=$VAL" >/dev/null 2>&1
    done < "$BACKUP_FILE"

    echo "Rollback concluído"
    exit 1
fi

#########################################
# AFTER snapshot
#########################################

echo "Capturando estado AFTER"
sysctl -a 2>/dev/null | sort > "$AFTER_TXT"

#########################################
# Gerar HTML Diff
#########################################

echo "Gerando relatório comparativo HTML"

{
echo "<html><head>"
echo "<title>Sysctl Diff Report</title>"
echo "<style>"
echo "body { font-family: monospace; background:#111; color:#eee; }"
echo ".add { color:#00ff88; }"
echo ".rem { color:#ff5555; }"
echo "</style>"
echo "</head><body>"
echo "<h1>Sysctl Antes vs Depois - $DATE</h1>"
echo "###################################################### "
echo "      <h2>Mudancas Realizadas</h2> "
echo "                                                       "
echo "  <h3>Perfil Selecionado: $PROFILE - $PROFILE_NAME</h3>"
echo "                                                       "
echo "<h3><span class='add'>Valores novos</span></h3>"
echo "<h3><span class='rem'>Valores antigos</span></h3>"
echo "                                                       "
echo "###################################################### "
echo "<pre>"

diff "$BEFORE_TXT" "$AFTER_TXT" | while read line; do
    if [[ $line == \<* ]]; then
        echo "<span class='rem'>$line</span>"
    elif [[ $line == \>* ]]; then
        echo "<span class='add'>$line</span>"
    else
        echo "$line"
    fi
done

echo "</pre>"
echo "</body></html>"
} > "$DIFF_HTML"

#########################################
# Final
#########################################

echo
echo "Concluído"
echo
echo "Arquivos gerados:"
echo "$BEFORE_TXT"
echo "$AFTER_TXT"
echo "$DIFF_HTML"
