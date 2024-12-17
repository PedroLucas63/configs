# Update
alias apt-update 'sudo apt update && sudo apt dist-upgrade -y && sudo apt autoremove -y'
alias brew-update 'brew update && brew upgrade'
alias flatpak-update 'flatpak update -y'
alias updated 'apt-update; brew-update; flatpak-update'
