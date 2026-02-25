# 🖥️ Desktop Tuning Manager

**Autor:** Diego Costa (@diegocostaroot)  
**Canal no youtube:** Projeto Root ([youtube.com/projetoroot](https://www.youtube.com/projetoroot))
**Wiki:** ([wiki.projetoroot.com.br](https://wiki.projetoroot.com.br))
**Versão:** 1.1 | **Ano:** 2026  

Gerenciador de perfis de tuning para Linux Desktop com backup, rollback e relatório HTML de diferenças.

---

## 🔧 Compatibilidade

O script foi testado e é compatível com as seguintes distribuições e versões Linux Desktop:

| Sistema | Versão Testada | Observações |
|---------|----------------|------------|
| Debian | 12 / 13 | Requer `sysctl` instalado, executado como root |
| Ubuntu | 22.04 / 24.04 | Funciona com desktops GNOME/KDE/CLI |
| Fedora | 38 / 39 | Necessário ajustar `sysctl.d` para SELinux permissivo |
| Pop!_OS | 22.04 / 24.04 | Mesmos requisitos do Ubuntu |
| Linux Mint | 21 / 22 | Testado com Cinnamon e Mate |
| Outros | Qualquer distro Linux moderna | Requer `sysctl` e diretórios padrão `/etc/sysctl.d` e `/var/backups/sysctl-tuning` |

> ⚠️ **Nota:** Sistemas que não possuem `/etc/sysctl.d` ou `sysctl` não são compatíveis. Sempre execute como root.

---

## 🎛️ Perfis Disponíveis

| Opção | Perfil | Arquivo Criado | Efeito Principal |
|-------|--------|----------------|-----------------|
| 1️⃣ | **Desktop Geral** | `99-desktop-baseline.conf` | ⚡ Baseline básico do sysctl, sem ajustes extras |
| 2️⃣ | **Gaming** | `99-desktop-gaming.conf` | 🎮 Otimizações TCP e memória para jogos, conexões e backlog aumentados |
| 3️⃣ | **Laptop Economia** | `99-desktop-laptop.conf` | 💡 Economia de energia, swappiness médio, opcional runtime power saving (CPU, brilho, I/O) |
| 4️⃣ | **Dev Workstation** | `99-desktop-dev.conf` | 💻 Limites altos de arquivos, processos e swappiness baixo para desenvolvimento |
| 5️⃣ | **Streaming OBS** | `99-desktop-streaming.conf` | 📹 Buffers de rede maiores, swappiness baixo, otimização para streaming |
| 6️⃣ | **Economia de Energia** | `99-desktop-powersave.conf` | 🌱 Swappiness alto, cache pressure e scheduling para economia geral de energia |
| 7️⃣ | **Restaurar Backup** | `99-rollback-manual.conf` | 🔄 Restaura qualquer backup válido do sysctl (runtime + permanente) |

> ⚠️ **Nota:** Opção 7 lista todos os backups disponíveis em `/var/backups/sysctl-tuning` e pede confirmação antes de restaurar.

---

## 📋 Fluxo de Execução

1. 💾 Cria backup atual do sysctl em `/var/backups/sysctl-tuning`  
2. 📝 Captura snapshot **Antes**  
3. 🔍 Detecta perfil ativo  
4. 🖱️ Menu para escolher perfil  
5. 🚫 Bloqueia reaplicação do mesmo perfil  
6. 🗑️ Remove perfis antigos e aplica **baseline**  
7. ⚙️ Aplica perfil escolhido  
8. 🔧 Aplica `sysctl --system` e faz rollback automático em caso de erro  
9. 📝 Captura snapshot **Depois**  
10. 🌐 Gera relatório HTML comparando antes/depois  

---

## 📄 Relatórios Gerados

| Arquivo | Conteúdo |
|---------|----------|
| `sysctl_before_YYYY-MM-DD-HH-MM-SS.txt` | Estado do sysctl **antes** do tuning |
| `sysctl_after_YYYY-MM-DD-HH-MM-SS.txt` | Estado do sysctl **após** o tuning |
| `sysctl_diff_YYYY-MM-DD-HH-MM-SS.html` | 💻 Relatório visual comparando antes e depois, com cores para valores adicionados/removidos |

---

## ⚙️ Requisitos

- Linux com `sysctl`
- Executar o script como **root**
- Diretório para salvar relatórios existente

---

## 🏃‍♂️ Uso

```bash
wget https://raw.githubusercontent.com/projetoroot/tuning-desktop/refs/heads/main/install.sh
sudo bash install.sh
