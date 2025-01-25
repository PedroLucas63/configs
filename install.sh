#!/bin/bash

# Script de configuração para ambientes baseados em Debian
# Autor: Pedro Lucas
# Data: $(date +%Y-%m-%d)

# Definindo cores para mensagens
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

print_message() {
	echo -e "${GREEN}[INFO]${RESET} $1"
}

print_warning() {
	echo -e "${YELLOW}[INFO]${RESET} $1"
}

print_error() {
	echo -e "${RED}[INFO]${RESET} $1"
}

# Atualizando pacotes e instalando pacotes essenciais
print_message "Atualizando pacotes do sistema..."
sudo apt update && sudo apt upgrade -y


print_message "Instalando pacotes essenciais..."
sudo apt install -y git curl wget build-essential software-properties-common

# Instalando homebrew
print_message "Instalando o Homebrew..."
if ! command -v brew &> /dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_message "Homebrew instalado com sucesso."
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
    print_warning "Homebrew já está instalado. Pulando instalação."
fi

# Instalação e configuração do Flatpak
print_message "Instalando o Flatpak..."
if ! command -v flatpak &> /dev/null; then
    sudo apt install -y flatpak
    print_message "Flatpak instalado com sucesso."
else
    print_warning "Flatpak já está instalado. Pulando instalação."
fi

print_message "Adicionando repositório Flathub ao Flatpak..."
if ! flatpak remotes | grep -q "flathub"; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    print_message "Repositório Flathub adicionado com sucesso."
else
    print_warning "Repositório Flathub já está configurado. Pulando adição."
fi

# Instalação de pacotes adicionais via APT
print_message "Instalando pacotes adicionais via APT..."
sudo apt install -y docker.io postgresql ufw gufw rclone

# Instalação de pacotes via Homebrew
print_message "Instalando pacotes via Homebrew..."
if command -v brew &> /dev/null; then
    brew install htop
    brew install fish fisher
    brew install oh-my-posh lf zoxide
    brew install llvm 
    brew install openjdk 
    brew install python 
    brew install nvm doxygen
    brew install mednafen
else
    print_error "Homebrew não encontrado. Pulando instalação via Homebrew."
fi

# Configurando o Node.js LTS, nvm e pnpm
print_message "Instalando Node.js LTS, NVM e PNPM..."
nvm install lts
nvm use lts
npm install -g pnpm

# Configurando pacotes Flatpak
print_message "Instalando aplicativos via Flatpak..."
FLATPAK_APPS=(
    "it.mijorus.gearlever"      	     # GearLever
    "com.github.sdv43.whaler"                # Whaler
    "com.usebottles.bottles"                 # Bottles
    "org.gnome.Boxes"                        # Boxes
    "io.dbeaver.DBeaverCommunity"            # DBeaver
    "org.onlyoffice.desktopeditors"          # OnlyOffice
    "com.heroicgameslauncher.hgl"            # Heroic Games Launcher
    "com.valvesoftware.Steam"                # Steam
    "net.pcsx2.PCSX2"                        # PCSX2
    "com.github.AmatCoder.mednaffe"      	 # Mednaffe
)

for app in "${FLATPAK_APPS[@]}"; do
    if ! flatpak list | grep -q "$(echo "$app" | cut -d. -f3)"; then
        flatpak install -y flathub "$app"
        print_message "Flatpak $app instalado com sucesso."
    else
        print_warning "Flatpak $app já está instalado. Pulando."
    fi
done

# Configuração do UFW
print_message "Configurando UFW..."
sudo ufw enable
sudo ufw allow ssh
print_message "UFW configurado com sucesso."

# Configuração inicial do Docker
print_message "Configurando Docker..."
sudo systemctl enable docker
sudo systemctl start docker

# Adicionando o usuário ao grupo docker
if groups | grep -q '\bdocker\b'; then
    print_message "Usuário já pertence ao grupo docker."
else
    sudo usermod -aG docker "$USER"
    print_message "Usuário adicionado ao grupo docker. Será necessário reiniciar a sessão para aplicar as permissões."
fi

# Testando acesso ao docker.sock
if [ -S /var/run/docker.sock ]; then
    print_message "Docker.sock detectado. Whaler deve funcionar corretamente."
else
    print_error "Docker.sock não encontrado. Verifique se o Docker está funcionando."
fi

# Configuração inicial do PostgreSQL
print_message "Configurando PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Configurando acesso ao PostgreSQL
print_message "Configurando permissões do PostgreSQL para facilitar conexão via DBeaver..."
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf
sudo sed -i "s/peer/trust/g" /etc/postgresql/*/main/pg_hba.conf
sudo sed -i "s/md5/trust/g" /etc/postgresql/*/main/pg_hba.conf

# Reiniciando o PostgreSQL para aplicar configurações
sudo systemctl restart postgresql
print_message "PostgreSQL configurado. Credenciais padrão: usuário 'postgres', senha 'postgres'."

if command -v fish &> /dev/null; then
    # Adicionando Fish ao arquivo de shells válidos (se necessário)
    if ! grep -q "$(command -v fish)" /etc/shells; then
        echo "$(command -v fish)" | sudo tee -a /etc/shells
    fi

    # Alterando shell padrão para Fish
    chsh -s "$(command -v fish)" "$USER"
    print_message "Fish configurado como shell padrão. Faça logout para aplicar a mudança."
else
    print_error "Fish não encontrado. Certifique-se de que ele está instalado."
fi

# Diretório de fontes
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Função para baixar e instalar uma fonte
install_font() {
    local url=$1
    local zip_name=$2
    local dest_dir=$3

    curl -L -o "$FONT_DIR/$zip_name" "$url"
    unzip -o "$FONT_DIR/$zip_name" -d "$FONT_DIR/$dest_dir"
    rm "$FONT_DIR/$zip_name"
}

# Cascadia Code (todas as variantes)
install_font \
    "https://github.com/microsoft/cascadia-code/releases/latest/download/CascadiaCode-ttf.zip" \
    "CascadiaCode-ttf.zip" \
    "CascadiaCode"

# FiraCode (todas as variantes)
install_font \
    "https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip" \
    "FiraCode.zip" \
    "FiraCode"

# Hack Nerd Font (todas as variantes)
install_font \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip" \
    "HackNerdFont.zip" \
    "HackNerdFont"

# Atualizando cache de fontes
fc-cache -fv
echo "Todas as versões das fontes foram instaladas e o cache foi atualizado."

# Definindo diretórios
REPO_DIR="$HOME/configs"
FISH_CONFIG_DIR="$HOME/.config/fish"
THEMES_DIR="$HOME/.themes/oh-my-posh"
CLANG_DIR="$HOME/.config/clang"
LF_CONFIG_DIR="$HOME/.config/lf"

# Criando pastas necessárias
mkdir -p "$THEMES_DIR" "$FISH_CONFIG_DIR" "$CLANG_DIR" "$LF_CONFIG_DIR" "$FISH_CONFIG_DIR/functions" "$FISH_CONFIG_DIR/completions"

# Copiando o tema do Oh My Posh
echo "Copiando tema do Oh My Posh..."
cp "$REPO_DIR/oh-my-posh/theme.omp.json" "$THEMES_DIR"

# Configurações do Fish
echo "Configurando o Fish..."
cat << 'EOF' >> "$FISH_CONFIG_DIR/config.fish"
# Homebrew
eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)

# Oh My Posh
oh-my-posh init fish --config ~/.themes/oh-my-posh/theme.omp.json | source

# Zoxide
zoxide init fish | source

# Aliases
source ~/.config/fish/aliases.fish

# Variables
set -x CLANG_FORMAT_FILE ~/.config/clang/.clang-format
EOF

fisher install jorgebucaran/nvm.fish

# Copiando arquivos de configuração
echo "Copiando arquivos de configuração do Fish..."
cp "$REPO_DIR/fish/aliases.fish" "$FISH_CONFIG_DIR/"
cp "$REPO_DIR/fish/functions/lfcd.fish" "$FISH_CONFIG_DIR/functions/"
cp "$REPO_DIR/fish/completions/lf.fish" "$FISH_CONFIG_DIR/completions/"

# Copiando arquivo .clang-format
echo "Copiando arquivo .clang-format..."
cp "$REPO_DIR/clang/.clang-format" "$CLANG_DIR/"

# Copiando arquivos do lf
echo "Copiando arquivos de configuração do lf..."
cp -r "$REPO_DIR/lf/"* "$LF_CONFIG_DIR/"

echo "Configurações e cópias concluídas!"

# Definindo utilização do fish
echo "Configurações adicionais do fish..."
chsh -s $(which fish)
fish

# Finalização
print_message "Instalação e configuração concluídas com sucesso!"
