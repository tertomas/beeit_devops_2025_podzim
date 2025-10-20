#!/bin/sh

echo "=== Akutální shell ==="
echo "$SHELL"

echo ""
echo "=== Uživatel ==="
whoami

echo ""
echo "=== Verze linuxu ==="
if [ -f /etc/os-release ]; then
    cat /etc/os-release
else
    echo "/etc/os-release not found."
fi

echo ""
echo "=== Environmentální proměnné ==="
printenv


# ukol 5
#logovaci funkce
log() { echo "[INFO] $1"; }
logError() { echo "[ERROR] $1" >&2; }

#vytvareni linku
create_link() { [[ $3 == "soft" ]] && ln -s "$1" "$2" || ln "$1" "$2"; }

#vypis aktualizaci
list_updates() { git update-git-for-windows; echo $?; }

#provedeni aktualizaci
update_packages() { git update-git-for-windows}

# === Hledání souborů s 'b','e','a','e' v pořadí ===
najdi_pismena() { find "${1:-.}" -type f -name "*b*e*e*" 2>/dev/null; }



#ukol 6 - fce a volání s parametry
#!/bin/bash

# --- NASTAVENÍ ---
LOG_FILE="" 
RETURN_CODE=0


# Logování - INFO
log() {
    local msg="[INFO] $1"
    if [[ -n "$LOG_FILE" ]]; then
        echo "$msg" >> "$LOG_FILE"
    else
        echo -e "\e[32m$msg\e[0m"
    fi
}

# Logování - CHYBA a nastavení návratového kódu
logError() {
    local msg="[ERROR] $1"
    RETURN_CODE=1 # Nastaví chybu pro konec skriptu
    if [[ -n "$LOG_FILE" ]]; then
        echo "$msg" >> "$LOG_FILE"
    else
        echo -e "\e[31m$msg\e[0m" >&2
    fi
}

# Nápověda
show_help() {
    echo "Použití: $0 [FLAGY] [ARGUMENTY]"
    echo "Lze zadat více flag najednou, např. ./$0 -a -u"
    echo ""
    echo "FLAGY:"
    echo "  -h                  Zobrazí tuto nápovědu."
    echo "  -f <soubor>         Loguje do daného souboru."
    echo "  -a                  Vypíše balíčky s aktualizací."
    echo "  -u                  Provede upgrade balíčků (sudo)."
    echo "  -s                  Vytvoří soft link na skript do /usr/local/bin/linux_cli (sudo)."
    echo "  -b                  Najde soubory s 'b...e...e' v názvu (sudo)."
    echo "  -l <zdroj> <cíl> [typ] Vytvoří link ('soft' nebo 'hard')."
}

# Vytvoření linku 
create_link() {
    local SOURCE="$1"
    local TARGET="$2"
    local TYPE="${3:-soft}"

    if [[ -z "$SOURCE" || -z "$TARGET" ]]; then
        logError "Chyba -l: Chybí zdroj nebo cíl."
        return 1
    fi
    
    if [[ -e "$TARGET" || -L "$TARGET" ]]; then
        logError "Cíl linku '$TARGET' již existuje. Přerušuji."
        return 1
    fi

    if [[ "$TYPE" == "soft" ]]; then
        ln -s "$SOURCE" "$TARGET" && log "Soft link OK: $TARGET." || logError "Chyba soft linku."
    elif [[ "$TYPE" == "hard" ]]; then
        ln "$SOURCE" "$TARGET" && log "Hard link OK: $TARGET." || logError "Chyba hard linku."
    else
        logError "Neplatný typ linku: $TYPE."
        return 1
    fi
}

# Vylistování aktualizací (-a)
list_updates() {
    log "Vypisuji balíčky k aktualizaci..."
    # Zkontroluje apt nebo yum/dnf
    if command -v apt &> /dev/null; then
        sudo apt update >/dev/null 2>&1 && apt list --upgradable
    elif command -v yum &> /dev/null; then
        sudo yum check-update
    else
        logError "Nenalezen správce balíčků (apt/yum)."
    fi
    [[ $? -ne 0 ]] && logError "Chyba při listování aktualizací."
}

# Upgrade balíčků (-u)
upgrade_packages() {
    log "Spouštím upgrade balíčků (sudo)..."
    if command -v apt &> /dev/null; then
        sudo apt-get update && sudo apt-get upgrade -y
    elif command -v yum &> /dev/null; then
        sudo yum update -y
    else
        logError "Nenalezen správce balíčků pro upgrade."
    fi
    [[ $? -ne 0 ]] && logError "Upgrade selhal."
}

# Linu na skript (-s)
install_cli_link() {
    local SCRIPT_PATH=$(realpath "$0")
    local LINK_TARGET="/usr/local/bin/linux_cli"
    
    if [[ -e "$LINK_TARGET" && ! -L "$LINK_TARGET" ]]; then
        logError "Cíl linku '$LINK_TARGET' již existuje a není to soft link. Přerušuji."
        return 1
    fi
    
    log "Vytvářím soft link: $LINK_TARGET"
    sudo ln -sf "$SCRIPT_PATH" "$LINK_TARGET" && log "Link na skript OK." || logError "Chyba při tvorbě linku na skript (zkuste sudo)."
}

# Hledání souborů (-b)
find_bee_files() {
    log "Hledám soubory s 'b...e...e' (sudo)..."
    # Regulární výraz: '.*b.*e.*e.*'
    sudo find / -regextype posix-extended -regex '.*b.*e.*e.*' 2>/dev/null
    [[ $? -ne 0 ]] && logError "Chyba při hledání (zkuste sudo)."
}

ACTIONS=()
DO_CREATE_LINK=false

while getopts "hf:aulsb" OPT; do
    case "$OPT" in
        h) show_help; exit 0 ;;
        f) LOG_FILE="$OPTARG"; log "Logování nastaveno na soubor: $LOG_FILE.";;
        a) ACTIONS+=("list_updates");;
        u) ACTIONS+=("upgrade_packages");;
        s) ACTIONS+=("install_cli_link");;
        b) ACTIONS+=("find_bee_files");;
        l) DO_CREATE_LINK=true;;
        \?) logError "Neplatný flag: -$OPTARG"; show_help; exit 1 ;;
    esac
done

#posunuti
shift $((OPTIND-1))


# 1. Vytvoření linku (-l)
if $DO_CREATE_LINK; then
    log "Vykonávám: Vytvoření linku."
    create_link "$1" "$2" "$3"
fi

# 2. Vykonávání zbytku
for action in "${ACTIONS[@]}"; do
    log "Vykonávám: $action"
    # Spuštění funkce
    "$action"
done

log "Skript dokončen."
exit $RETURN_CODE
