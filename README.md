# PrimeBlock Texture Pack

Wird vom **Primeblock**-Server-Plugin automatisch an alle Spieler verteilt: Das Plugin prueft regelmaessig
das neueste Release dieses Repos und schickt die ZIP als Server-Resource-Pack. Spieler laden es nur neu,
wenn sich das Pack geaendert hat.

## Inhalt
- Boote -> PrimeBlock-Lieferwagen (3D-Modell, braucht **Entity Model Features + Entity Texture Features** oder OptiFine)
- Villager -> PrimeBlock-Mitarbeiter, jeder Beruf mit eigener Arbeitskleidung
- Diamantruestung -> Arbeitskleidung (Kappe, Warnweste, Arbeitshose, Arbeitsschuhe)
- Diamantschwert -> 3D-Klebebandabroller
- Totem der Unsterblichkeit -> 3D-PrimeBlock-Paket

## Pack neu bauen
Windows PowerShell 5.1:
```
powershell -ExecutionPolicy Bypass -File build.ps1
```
Erzeugt `PrimeBlock/` und `PrimeBlock.zip` neben den Skripten.

## Update veroeffentlichen
Neues Release mit hoeherer Versionsnummer und der ZIP als Anhang, z. B.:
```
powershell -ExecutionPolicy Bypass -File publish.ps1 -Tag v2 -Notes "Was neu ist"
```
Der Server erkennt es innerhalb von 10 Minuten (sofort mit `/primeblock pack`).