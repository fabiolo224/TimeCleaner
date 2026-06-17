# TimeCleaner

🇮🇹 App macOS per la menu bar che analizza applicazioni e file inutilizzati, mostra la dimensione e la data di ultimo utilizzo, e permette di eliminarli.

🇬🇧 macOS menu bar app that analyses unused applications and files, shows their size and last used date, and lets you delete them.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)

---

## Funzionalità / Features

- 🇮🇹 Scansione app installate con dimensione e ultimo utilizzo  
  🇬🇧 Scan installed apps with size and last used date
- 🇮🇹 Scansione file (Download, Documenti, Desktop, Cache, ecc.)  
  🇬🇧 Scan files (Downloads, Documents, Desktop, Cache, etc.)
- 🇮🇹 Eliminazione nel Cestino (recuperabile)  
  🇬🇧 Move to Trash (recoverable)
- 🇮🇹 Icona sempre presente nella menu bar  
  🇬🇧 Icon always present in the menu bar

## Requisiti / Requirements

- macOS 13 (Ventura) o superiore / or higher

## Gatekeeper

🇮🇹 Poiché l'app non è firmata, al primo avvio macOS potrebbe bloccarla. Vai in Impostazioni di Sistema → Privacy e Sicurezza → Apri comunque. Oppure da terminale:  
🇬🇧 Since the app is not signed, macOS may block it on first launch. Go to System Settings → Privacy & Security → Open Anyway. Or from terminal:

```bash
xattr -cr /Applications/TimeCleaner.app
```

## Licenza / License

MIT
