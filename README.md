# TimeCleaner

🇮🇹 App macOS per la menu bar che analizza applicazioni e file inutilizzati, mostra la dimensione e la data di ultimo utilizzo, e permette di eliminarli.

🇬🇧 macOS menu bar app that analyses unused applications and files, shows their size and last used date, and lets you delete them.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)

---

## Funzionalità / Features

- 🇮🇹 Scansione app installate con dimensione e ultimo utilizzo
- 🇬🇧 Scan installed apps with size and last used date

<<<<<<< HEAD
- macOS 13 (Ventura) o superiore

## Nota su Gatekeeper

Poiché l'app non è firmata con un certificato Apple, al primo avvio macOS potrebbe avvisarti. Per aprirla:

1. Vai nelle impostazioni di sistema - privacy e sicurezza - apri comunque

Oppure da terminale:
```bash
xattr -cr /Applications/TimeCleaner.app
```
## Licenza
=======
- 🇮🇹 Scansione file (Download, Documenti, Desktop, Cache, ecc.)
- 🇬🇧 Scan files (Downloads, Documents, Desktop, Cache, etc.)

- 🇮🇹 Suggerimento di eliminazione basato su dimensione e inattività
- 🇬🇧 Deletion suggestion based on size and inactivity

- 🇮🇹 Eliminazione nel Cestino (recuperabile)
- 🇬🇧 Move to Trash (recoverable)

- 🇮🇹 Icona sempre presente nella menu bar (si riavvia automaticamente)
- 🇬🇧 Icon always present in the menu bar (auto-restarts)

- 🇮🇹 Interfaccia in italiano o inglese in base alla lingua del Mac
- 🇬🇧 Interface in Italian or English based on your Mac's language

## Requisiti / Requirements

- macOS 13 (Ventura) or higher
- Xcode Command Line Tools (`xcode-select --install`)

## Installazione / Installation

🇮🇹 Scarica il `.dmg` dalla pagina [Releases](../../releases), aprilo e trascina TimeCleaner in `/Applications`.

🇬🇧 Download the `.dmg` from the [Releases](../../releases) page, open it and drag TimeCleaner to `/Applications`.

## Build dal sorgente / Build from source

```bash
git clone https://github.com/tuousername/TimeCleaner.git
cd TimeCleaner
chmod +x install.sh
./install.sh
```

## Nota su Gatekeeper / Gatekeeper note

🇮🇹 Poiché l'app non è firmata, al primo avvio macOS potrebbe bloccarla. Per aprirla: tasto destro su `TimeCleaner.app` → **Apri**, oppure da terminale:

🇬🇧 Since the app is not signed, macOS may block it on first launch. To open it: right-click `TimeCleaner.app` → **Open**, or from terminal:

```bash
xattr -cr /Applications/TimeCleaner.app
```

## Licenza / License
>>>>>>> 9d282e9 (Add English translations to README)

MIT
