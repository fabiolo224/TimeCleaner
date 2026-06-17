# TimeCleaner

App macOS per la menu bar che analizza applicazioni e file inutilizzati, mostra la dimensione e la data di ultimo utilizzo, e permette di eliminarli.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)

## Funzionalità

- Scansione app installate con dimensione e ultimo utilizzo
- Scansione file (Download, Documenti, Desktop, Cache, ecc.)
- Suggerimento di eliminazione basato su dimensione e inattività
- Eliminazione nel Cestino (recuperabile)
- Apertura cartelle in Finder
- Icona sempre presente nella menu bar (si riavvia automaticamente)

## Requisiti

- macOS 13 (Ventura) o superiore
- Xcode Command Line Tools (`xcode-select --install`)

## Installazione

```bash
git clone https://github.com/tuousername/TimeCleaner.git
cd TimeCleaner
chmod +x install.sh
./install.sh
```

Lo script compila il codice, installa l'app in `/Applications` e configura il riavvio automatico. L'icona del cestino apparirà nella menu bar.

## Disinstallazione

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## Build manuale

Se vuoi solo compilare senza installare:

```bash
chmod +x build.sh
./build.sh
open TimeCleaner.app
```

## Nota su Gatekeeper

Poiché l'app non è firmata con un certificato Apple, al primo avvio macOS potrebbe avvisarti. Per aprirla:

1. Tasto destro su `TimeCleaner.app` → **Apri**
2. Clicca **Apri** nella finestra di dialogo

Oppure da terminale:
```bash
xattr -cr /Applications/TimeCleaner.app
```

## Struttura del progetto

```
TimeCleaner/
├── Sources/
│   ├── main.swift          # Entry point
│   ├── AppDelegate.swift   # Menu bar, popover, onboarding
│   ├── AppInfo.swift       # Scanner app e file
│   ├── ContentView.swift   # UI principale
│   └── Onboarding.swift    # Schermata di benvenuto
├── AppIcon.iconset/        # Icone app
├── menubar_template@2x.png # Icona menu bar
├── build.sh                # Compila l'app
├── install.sh              # Installa e configura
└── uninstall.sh            # Rimuove tutto
```

## Licenza

MIT
