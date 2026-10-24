#!/bin/bash
clear
echo "========================================================"
echo "         Komorebi Study - Sblocco e Primo Avvio         "
echo "========================================================"
echo ""

APP_NAME="Komorebi Study.app"
DIR="$(cd "$(dirname "$0")" && pwd)"
APP_IN_APPS="/Applications/$APP_NAME"
APP_IN_DIR="$DIR/$APP_NAME"

if [ ! -d "$APP_IN_APPS" ]; then
    if [ -d "$APP_IN_DIR" ]; then
        echo "📦 Copia di $APP_NAME in /Applications..."
        cp -R "$APP_IN_DIR" "/Applications/"
        echo "✅ Installazione completata!"
    else
        echo "❌ Errore: $APP_NAME non trovata."
        echo "Trascina prima l'applicazione nella cartella Applicazioni e riprova."
        read -p "Premi [Invio] per uscire..."
        exit 1
    fi
fi

echo "🔓 Rimozione delle restrizioni di sicurezza macOS (quarantena)..."
xattr -cr "$APP_IN_APPS" 2>/dev/null || xattr -d com.apple.quarantine "$APP_IN_APPS" 2>/dev/null || true

echo "🚀 Avvio di Komorebi Study in corso..."
open "$APP_IN_APPS"

echo ""
echo "========================================================"
echo "    Komorebi Study è stato avviato con successo! 🎉     "
echo "========================================================"
echo ""
echo "Da adesso in poi puoi aprire l'app direttamente da"
echo "Applicazioni, Launchpad o Dock senza alcun blocco."
sleep 2
exit 0
