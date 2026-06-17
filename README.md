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
- 🇮🇹 Icona sempre presente nella menu bar, si avvia automaticamente al login  
  🇬🇧 Icon always in the menu bar, launches automatically at login
- 🇮🇹 Aggiornamenti automatici dall'app  
  🇬🇧 Automatic in-app updates
- 🇮🇹 Interfaccia in italiano o inglese in base alla lingua del Mac  
  🇬🇧 Interface in Italian or English based on your Mac's language
- 🇮🇹 Disinstallazione in un click dal menu dell'app  
  🇬🇧 One-click uninstall from the app menu

## Requisiti / Requirements

- macOS 13 (Ventura) o superiore / or higher

## Installazione / Installation

🇮🇹 Scarica il `.dmg` dalla pagina [Releases](../../releases), aprilo e trascina TimeCleaner in `/Applications`.

🇬🇧 Download the `.dmg` from the [Releases](../../releases) page, open it and drag TimeCleaner to `/Applications`.

## Disinstallazione / Uninstall

🇮🇹 Apri TimeCleaner → clicca l'icona ⚙️ in alto a destra → **Disinstalla TimeCleaner**.

🇬🇧 Open TimeCleaner → click the ⚙️ icon in the top right → **Uninstall TimeCleaner**.

## Gatekeeper

🇮🇹 Poiché l'app non è firmata, al primo avvio macOS potrebbe bloccarla. Vai in Impostazioni di Sistema → Privacy e Sicurezza → Apri comunque. Oppure da terminale:

```bash
xattr -cr /Applications/TimeCleaner.app
```

🇬🇧 Since the app is not signed, macOS may block it on first launch. Go to System Settings → Privacy & Security → Open Anyway. Or from terminal:

```bash
xattr -cr /Applications/TimeCleaner.app
```

## Licenza / License

MIT
