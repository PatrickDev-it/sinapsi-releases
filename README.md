# Sinapsi — installer

Questa repository distribuisce **solo i binari** di Sinapsi: la CLI globale (`sinapsi`) e l'app
desktop, per macOS e Windows 10/11. Il sorgente è proprietario e non è qui; l'uso dei binari è
regolato da [LICENSE-BINARY.md](LICENSE-BINARY.md).

Scarica dalla pagina [Releases](../../releases) il file per il tuo sistema:

| Sistema | CLI globale | App desktop |
|---|---|---|
| Windows 10 / 11 (x64) | `sinapsi-cli-windows-x64-installer.zip` | `sinapsi-desktop-windows-x64-installer.zip` (contiene anche la CLI) |
| Mac Apple Silicon (M1…) | `sinapsi-cli-macos-aarch64-installer.sh` | `sinapsi-desktop-macos-universal.dmg` |
| Mac Intel | `sinapsi-cli-macos-x86_64-installer.sh` | `sinapsi-desktop-macos-universal.dmg` |

Prima di installare, confronta l'hash del file con `SHA256SUMS.txt` della stessa release.

## Windows

Estrai lo zip e fai doppio clic su **Installa Sinapsi.bat**; il file `LEGGIMI.txt` nello zip
descrive aggiornamento, ripristino della versione precedente e disinstallazione. Da PowerShell:

```powershell
& '.\Installa Sinapsi.ps1' -VerifyOnly   # controlla il payload senza installare
& '.\Installa Sinapsi.ps1'               # installa o aggiorna
```

L'app desktop usa WebView2, già presente su Windows 11 e sui Windows 10 aggiornati; se manca,
l'installer lo dice e non lo scarica. Il pacchetto non è firmato: SmartScreen può chiedere
conferma («Ulteriori informazioni» → «Esegui comunque»).

## macOS

CLI (installa in `~/.local/bin`, nessun `sudo`):

```sh
sh sinapsi-cli-macos-aarch64-installer.sh --verify-only   # controlla il payload
sh sinapsi-cli-macos-aarch64-installer.sh                 # installa o aggiorna
sh sinapsi-cli-macos-aarch64-installer.sh --rollback      # torna alla versione precedente
sh sinapsi-cli-macos-aarch64-installer.sh --uninstall
```

App desktop: apri il `.dmg` e trascina **Sinapsi** in Applicazioni. L'app è firmata solo ad hoc,
non notarizzata: al primo avvio macOS la blocca. Aprila con clic destro → **Apri**, oppure:

```sh
xattr -dr com.apple.quarantine /Applications/Sinapsi.app
```

L'app porta con sé la propria copia di `sinapsi` e non richiede la CLI installata.

## Come sono costruiti

Il workflow [`build`](.github/workflows/build.yml) gira solo su avvio manuale del maintainer: un
job per sistema operativo builda dal sorgente privato con gli installer del sorgente stesso, li
prova (installazione, aggiornamento, ripristino, disinstallazione) su Windows Server 2022 e 2025 e
su macOS 15, e pubblica la release con il commit sorgente da cui viene.
