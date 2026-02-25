#!/bin/bash
###############################################################################
# Desktop Tuning Manager - Instalador com seletor de Tema v1.0
# Autor: Diego Costa (@diegocostaroot) / Projeto Root (youtube.com/projetoroot)
# Veja o link: https://wiki.projetoroot.com.br
# 2026
###############################################################################

clear
echo "=============================================="
echo "    🎨 DESKTOP TUNING MANAGER - TEMA SELETOR"
echo "=============================================="
echo

echo "Escolha o tema do relatório HTML:"
echo
echo " 1) 🌞 TEMA CLARO  - Visual limpo e brilhante"
echo " 2) 🌌 TEMA ESCURO - Fundo escuro, verde neon"
echo

echo -n "Opção (1-2): "
read TEMA

case $TEMA in
    1)
        SCRIPT_URL="https://raw.githubusercontent.com/projetoroot/tuning-desktop/refs/heads/main/desktop-tuning-manager-light.sh"
        SCRIPT_NAME="desktop-tuning-light.sh"
        echo "🌞 Selecionado TEMA CLARO"
        ;;
    2)
        SCRIPT_URL="https://raw.githubusercontent.com/projetoroot/tuning-desktop/refs/heads/main/desktop-tuning-manager-dark.sh"
        SCRIPT_NAME="desktop-tuning-dark.sh"
        echo "🌌 Selecionado TEMA ESCURO"
        ;;
    *)
        echo "❌ Opção inválida! Use 1 ou 2."
        exit 1
        ;;
esac

# Detectar usuário home
USER_HOME=$(getent passwd {1000..6000} | grep -v nologin | head -1 | cut -d: -f6)
[[ -z "$USER_HOME" ]] && USER_HOME="/root"

SCRIPT_PATH="$USER_HOME/$SCRIPT_NAME"

echo "👤 Salvando em: $SCRIPT_PATH"
echo

# Verificar wget
if ! command -v wget >/dev/null 2>&1; then
    echo "📦 Instalando wget..."
    apt update && apt install -y wget || { echo "❌ Falha na instalação"; exit 1; }
fi

# Verificar se já existe
if [[ -f "$SCRIPT_PATH" ]]; then
    echo "⚠️  $SCRIPT_NAME já existe. Sobrescrever? (s/N): "
    read SOBRESCREVER
    [[ "$SOBRESCREVER" != [sS]* ]] && { echo "❌ Cancelado"; exit 0; }
fi

# Baixar script
echo "📥 Baixando $SCRIPT_NAME..."
if wget -q "$SCRIPT_URL" -O "$SCRIPT_PATH"; then
    echo "✅ Download concluído!"
    
    # Verificar se é executável bash
    if head -n1 "$SCRIPT_PATH" | grep -q "#!/bin/bash"; then
        echo "🔧 Configurando..."
        chmod +x "$SCRIPT_PATH"
        chown "$USER_HOME"/* 2>/dev/null || true
        
        echo
        echo "🎉 $SCRIPT_NAME salvo em: $SCRIPT_PATH"
        echo "🚀 Executando pela primeira vez..."
        echo "=============================================="
        echo
        
        # Executar
        sudo "$SCRIPT_PATH"
        
        echo
        echo "✅ Instalação completa!"
        echo
        echo "🔄 Para reexecutar futuramente:"
        echo "   cd ~"
        echo "   sudo ./$SCRIPT_NAME"
        echo
        cat << "EOF"
   ╔══════════════════════════════════════╗
   ║           ✅ PRONTO! ✅              ║
   ║                                      ║
   ║  Script salvo permanentemente em:   ║
   ║  ~/desktop-tuning-[claro|dark].sh    ║
   ║                                      ║
   ║  sudo ./desktop-tuning-dark.sh       ║
   ╚══════════════════════════════════════╝
EOF
        
    else
        echo "❌ Arquivo inválido! Não é script bash."
        rm -f "$SCRIPT_PATH"
        exit 1
    fi
else
    echo "❌ Falha no download!"
    echo "URL: $SCRIPT_URL"
    exit 1
fi

echo "👋 Até logo! (@diegocostaroot)"
