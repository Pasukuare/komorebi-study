#!/bin/bash
# Installs the adjacent, verified bundle. Never changes the user's study archive.
set -euo pipefail
APP_NAME="Komorebi Study.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP="$SCRIPT_DIR/$APP_NAME"
TARGET_APP="/Applications/$APP_NAME"
WORK_DIR=""
OLD_MOVED=0
INSTALLED=0
fail() { printf '\nErrore: %s\n' "$1" >&2; exit 1; }
verify_bundle() {
    [ -d "$1" ] && [ ! -L "$1" ] || fail "Applicazione non trovata o collegamento non valido: $1"
    local bundle_id
    bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1/Contents/Info.plist") || fail "Info.plist non leggibile."
    [ "$bundle_id" = "com.komorebi.study" ] || fail "Questo file non è Komorebi Study."
    /usr/bin/codesign --verify --deep --strict "$1" || fail "Firma o integrità dell'app non valide. Scarica nuovamente il DMG."
}
# Read-only packaging check; does not install, remove attributes or launch the app.
if [ "${1:-}" = "--verifica" ]; then
    verify_bundle "${2:-$SOURCE_APP}"
    printf 'Integrità di Komorebi Study verificata. Nessuna modifica eseguita.\n'
    exit 0
fi
[ "$#" -eq 0 ] || fail "Opzione non riconosciuta."
printf 'Komorebi Study — installazione e primo avvio\n\n'
printf 'Esegui questo file solo dal DMG scaricato dalla fonte ufficiale.\n'
verify_bundle "$SOURCE_APP"
[ ! -L "$TARGET_APP" ] || fail "L'app in Applicazioni è un collegamento: installa manualmente con Finder."
[ -w /Applications ] || fail "Applicazioni non è scrivibile. Trascina l'app con Finder e usa le opzioni di apertura di macOS."
if /usr/bin/pgrep -f '^/Applications/Komorebi Study.app/Contents/MacOS/Komorebi Study($| )' >/dev/null; then
    fail "Komorebi è aperta. Chiudila dal menu Komorebi Study > Esci, poi riapri questo file. Il timer verrà recuperato in pausa."
fi
if [ -e "$TARGET_APP" ]; then
    printf '\nÈ già presente una versione di Komorebi.\n'
    printf 'Verrà sostituita con quella di questo DMG. I dati di studio restano intatti.\n'
    read -r -p 'Installare questa versione? [s/N] ' answer
    case "$answer" in s|S|si|Si|sì|Sì|y|Y|yes) ;; *) printf 'Installazione annullata.\n'; exit 0 ;; esac
fi
cleanup() {
    if [ "$OLD_MOVED" -eq 1 ] && [ "$INSTALLED" -eq 0 ] && [ ! -e "$TARGET_APP" ] && [ -d "$WORK_DIR/previous.app" ]; then
        /bin/mv "$WORK_DIR/previous.app" "$TARGET_APP" || printf 'Ripristina la copia precedente da %s\n' "$WORK_DIR/previous.app" >&2
    fi
    if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
        # Remove only this script's uniquely created staging directory.
        if [ "$OLD_MOVED" -eq 1 ] && [ "$INSTALLED" -eq 0 ] && [ -d "$WORK_DIR/previous.app" ]; then return; fi
        /bin/rm -rf "$WORK_DIR"
    fi
}
WORK_DIR=$(/usr/bin/mktemp -d /Applications/.komorebi-install.XXXXXX) || fail "Impossibile preparare l'installazione."
trap cleanup EXIT
trap 'exit 130' INT TERM
/usr/bin/ditto "$SOURCE_APP" "$WORK_DIR/new.app" || fail "Copia dell'app non riuscita."
verify_bundle "$WORK_DIR/new.app"
# Remove only quarantine from this bundle, preserving all other extended attributes.
attributes=$(/usr/bin/xattr -r "$WORK_DIR/new.app") || fail "Impossibile leggere gli attributi dell'app."
if [[ "$attributes" == *com.apple.quarantine* ]]; then
    /usr/bin/xattr -dr com.apple.quarantine "$WORK_DIR/new.app" || fail "Impossibile rimuovere la quarantena dalla copia dell'app."
fi
if [ -e "$TARGET_APP" ]; then
    /bin/mv "$TARGET_APP" "$WORK_DIR/previous.app" || fail "Impossibile spostare la versione precedente."
    OLD_MOVED=1
fi
/bin/mv "$WORK_DIR/new.app" "$TARGET_APP" || fail "Installazione non riuscita."
INSTALLED=1
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$TARGET_APP" || printf 'Registrazione icona non aggiornata: riapri l’app da Finder.\n'
/usr/bin/open "$TARGET_APP" || fail "App installata, ma apertura non riuscita. Aprila da Finder."
printf '\nInstallazione completata; richiesta di apertura inviata a macOS.\n'
printf 'Questo script non equivale alla notarizzazione Apple.\n'
