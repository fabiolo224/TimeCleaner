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

## Nota su Gatekeeper

Poiché l'app non è firmata con un certificato Apple, al primo avvio macOS potrebbe avvisarti. Per aprirla:

1. Vai nelle impostazioni di sistema - privacy e sicurezza - apri comunque

Oppure da terminale:
```bash
xattr -cr /Applications/TimeCleaner.app
```
## Licenza

MIT
