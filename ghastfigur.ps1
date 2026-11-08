# Dot-sourced aus extras3.ps1: Happy Ghast als riesige Figur (EMF). Der Haarscheitel ist die Sitzflaeche.
# Blonde Haare mit Pony, offene weiss-blaue Jacke, glitzerndes hellblaues Kleid mit Spitze, weisse Plateaustiefel.
# Der Ghast wird 4-fach gezeichnet: 8 Texel pro Modelleinheit = 32 Pixel pro Block (auf Wunsch feiner als 16x).
# Texturkoordinaten sind Modelleinheiten; Dot/SetPixel arbeiten in Texeln.
$figK = 8
NewCanvas 128 128 1 $figK
$script:g.SmoothingMode = 'None'
$script:rng = New-Object System.Random 900

$fSkin = '#F5D0B8'; $fSkinD = '#E6B296'; $fBlush = '#F4B6A4'
$fHair = '#F1D9A2'; $fHairL = '#FBF0CC'; $fHairD = '#DDBC82'; $fHairDD = '#C9A46A'
$fWhite = '#F5F2E9'; $fWhiteD = '#D6D2C5'; $fBlue = '#A6D2F0'; $fBlueD = '#78B2DC'; $fInk = '#26303C'
$fDress = '#BCE0F6'; $fDressD = '#8CC3E8'; $fLace = '#FAFDFF'
$fSilver = '#C6D1DB'; $fSilverL = '#F4F8FB'; $fGold = '#EDCB70'

# Einfacher Regal-Packer: jede Box bekommt automatisch ihren Platz auf dem Atlas
$script:figX = 0; $script:figY = 0; $script:figRow = 0
function FigBox($wd, $ht, $dp) {
    $tw = 2 * ($wd + $dp); $th = $ht + $dp
    if ($script:figX + $tw -gt 128) { $script:figX = 0; $script:figY += $script:figRow; $script:figRow = 0 }
    if ($script:figY + $th -gt 128) { throw "Figur-Atlas ist voll ($wd x $ht x $dp)" }
    $f = Faces $script:figX $script:figY $wd $ht $dp
    $f.uv = @($script:figX, $script:figY); $f.size = @($wd, $ht, $dp)
    $script:figX += $tw; $script:figRow = [Math]::Max($script:figRow, $th)
    $f
}
function FigCube($f, $x, $y, $z) { [ordered]@{ coordinates = @($x, $y, $z, $f.size[0], $f.size[1], $f.size[2]); textureOffset = $f.uv } }
$figSides = 'right', 'front', 'left', 'back'
$figAll = 'right', 'front', 'left', 'back', 'top', 'bottom'

function FigRand($a, $b) { $a + $script:rng.NextDouble() * ($b - $a) }
# Weicher Verlauf von oben nach unten in sichtbaren Pixel-Stufen
function FigBand($f, $hex, $top = 1.06, $bot = 0.88) {
    $n = [Math]::Max(1, [int]($f[3] * 2))
    for ($i = 0; $i -lt $n; $i++) {
        $t = if ($n -gt 1) { $i / ($n - 1) } else { 0 }
        Rect $f[0] ($f[1] + $i * $f[3] / $n) $f[2] ($f[3] / $n + 0.125) (Shade $hex ($top + ($bot - $top) * $t))
    }
}
function FigGrain($f, $hexA, $hexB, $count) {
    for ($i = 0; $i -lt $count; $i++) {
        $px = [int](($f[0] + $script:rng.NextDouble() * $f[2]) * $figK); $py = [int](($f[1] + $script:rng.NextDouble() * $f[3]) * $figK)
        $maxX = [int](($f[0] + $f[2]) * $figK) - 1; $maxY = [int](($f[1] + $f[3]) * $figK) - 1
        Dot ([Math]::Min($px, $maxX)) ([Math]::Min($py, $maxY)) $(if ($i % 2) { $hexA } else { $hexB })
    }
}
# Haarstraehnen: laufen der Laenge nach
function FigStrands($f, $density = 3) {
    FigBand $f $fHair 1.05 0.92
    $count = [int]($f[2] * $density)
    for ($i = 0; $i -lt $count; $i++) {
        $x0 = FigRand $f[0] ($f[0] + $f[2] - 0.25)
        $y0 = FigRand $f[1] ($f[1] + $f[3] * 0.7)
        $len = [Math]::Min((FigRand 1 ($f[3] * 0.8 + 1)), $f[1] + $f[3] - $y0)
        $pick = $script:rng.Next(5)
        $col = if ($pick -le 1) { $fHairD } elseif ($pick -le 3) { $fHairL } else { $fHairDD }
        Rect $x0 $y0 (0.125 * (1 + $script:rng.Next(2))) $len $col
    }
}
# Macht Texel transparent: ausgefranste Haarspitzen und Spitzensaum
function FigClear($x, $y) { $script:cv.SetPixel([int]$x, [int]$y, [System.Drawing.Color]::Transparent) }
function FigFray($f, $depth) {
    $x0 = [int]($f[0] * $figK); $xw = [int]($f[2] * $figK); $yEnd = [int](($f[1] + $f[3]) * $figK)
    $col = 0
    while ($col -lt $xw) {
        $w0 = 3 + $script:rng.Next(5); $d0 = 2 + $script:rng.Next([int]($depth * $figK))
        for ($c = $col; $c -lt [Math]::Min($col + $w0, $xw); $c++) { for ($k0 = 1; $k0 -le $d0; $k0++) { FigClear ($x0 + $c) ($yEnd - $k0) } }
        $col += $w0
    }
}
# Bogen-Saum: wie Spitze unten am Rock
function FigScallop($f, $wave, $depth) {
    $x0 = [int]($f[0] * $figK); $xw = [int]($f[2] * $figK); $yEnd = [int](($f[1] + $f[3]) * $figK)
    $period = [int]($wave * $figK)
    for ($c = 0; $c -lt $xw; $c++) {
        $t = (($c % $period) / $period) * 2 - 1
        $cut = [int]($depth * $figK * $t * $t)
        for ($k0 = 1; $k0 -le $cut; $k0++) { FigClear ($x0 + $c) ($yEnd - $k0) }
    }
}
$figHeart = @('.##.##.', '#######', '#######', '.#####.', '..###..', '...#...')
$figStar = @('..#..', '..#..', '#####', '.###.', '.#.#.')
# Pailletten: Herzen, Sterne, Glitzerpunkte
function FigSequins($f, $count, $seedHearts = $true) {
    for ($i = 0; $i -lt $count; $i++) {
        $tx = [int](FigRand ($f[0] * $figK + 1) (($f[0] + $f[2]) * $figK - 9))
        $ty = [int](FigRand ($f[1] * $figK + 1) (($f[1] + $f[3]) * $figK - 8))
        $kind = $script:rng.Next(3)
        if ($kind -eq 0 -and $seedHearts) { Sprite $tx $ty $figHeart $fGold; Dot ($tx + 1) ($ty + 1) $fSilverL }
        elseif ($kind -eq 1) { Sprite $tx $ty $figStar $fSilverL; Dot ($tx + 2) ($ty + 2) $fGold }
        else { Dot $tx $ty $fSilverL; Dot ($tx + 1) $ty $fSilver; Dot $tx ($ty + 1) $fSilver }
    }
}
function FigFlower($x, $y, $r0) {
    $script:g.FillEllipse((Br $fLace), [single]($x - $r0), [single]($y - $r0 * 0.6), [single]($r0 * 2), [single]($r0 * 1.2))
    $script:g.FillEllipse((Br $fLace), [single]($x - $r0 * 0.6), [single]($y - $r0), [single]($r0 * 1.2), [single]($r0 * 2))
    Rect ($x - 0.125) ($y - 0.125) 0.25 0.25 $fDressD
}
# Rockstufe: Falten, Spitzenblueten, Glitzer
function FigSkirt($F0, $flowers, $scallop) {
    foreach ($kk in $figSides) {
        $f = $F0[$kk]
        FigBand $f $fDress 1.06 0.92
        for ($px = 0.5; $px -lt $f[2]; $px += 1) { Rect ($f[0] + $px) $f[1] 0.125 $f[3] (Shade $fDress 0.93) }
        $rowN = 0; for ($fy0 = 0.55; $fy0 -lt $f[3]; $fy0 += 0.9) { for ($fx0 = 0.5 + ($rowN % 2) * 0.5; $fx0 -lt $f[2]; $fx0 += 1) { FigFlower ($f[0] + $fx0) ($f[1] + $fy0) $flowers }; $rowN++ }
        FigGrain $f $fSilverL $fSilver ([int]($f[2] * 6))
        Rect $f[0] ($f[1] + $f[3] - 0.25) $f[2] 0.25 $fLace
        if ($scallop) { FigScallop $f 1.5 0.5 }
    }
    FigBand $F0.top $fDress 1.05 0.98
    FigBand $F0.bottom (Shade $fDressD 0.82) 1 1
    FigGrain $F0.bottom $fDress $fLace 80
}
# Lederflaeche der Jacke
function FigLeather($f, $hex) { FigBand $f $hex 1.04 0.93; FigGrain $f (Shade $hex 0.93) (Shade $hex 1.05) ([int]($f[2] * $f[3] * 3)) }

# ===================== Kopf 14 x 10 x 14 =====================
$fgHead = FigBox 14 10 14
foreach ($kk in 'right', 'left', 'back') { FigStrands $fgHead[$kk] 4 }
FigStrands $fgHead.top 3; FigBand $fgHead.bottom $fSkin 1 1
$ff = $fgHead.front; $fx = $ff[0]; $fy = $ff[1]
FigBand $ff $fSkin 1.03 0.97
Rect $fx ($fy + 8.75) 14 1.25 (Shade $fSkin 0.93)
Rect ($fx + 2) ($fy + 9.5) 10 0.5 $fSkinD                                         # Kinnschatten
$g2 = $script:g
$g2.FillEllipse((Br $fBlush), [single]($fx + 1.2), [single]($fy + 6.6), 2.6, 1.3)     # Wangen
$g2.FillEllipse((Br $fBlush), [single]($fx + 10.2), [single]($fy + 6.6), 2.6, 1.3)
foreach ($ex in 3.0, 8.6) {
    $lx = $fx + $ex; $ly = $fy + 4.7
    $g2.FillEllipse((Br '#FFFFFF'), [single]$lx, [single]$ly, 2.4, 1.9)                # Augapfel
    $g2.FillEllipse((Br '#5B93C4'), [single]($lx + 0.5), [single]($ly + 0.1), 1.5, 1.7) # Iris
    $g2.FillEllipse((Br '#2C4A68'), [single]($lx + 0.75), [single]($ly + 0.4), 1.0, 1.1)
    Rect ($lx + 0.75) ($ly + 0.375) 0.375 0.375 '#FFFFFF'                               # Glanzpunkt
    Rect $lx ($ly - 0.125) 2.4 0.375 '#4A3322'                                          # Oberlid mit Wimpern
    Rect ($lx - 0.125) ($ly + 0.125) 0.25 0.25 '#4A3322'; Rect ($lx + 2.3) ($ly + 0.125) 0.25 0.25 '#4A3322'
    Rect ($lx + 0.25) ($ly - 0.75) 1.9 0.25 '#B08A55'                                   # Augenbraue
}
Rect ($fx + 6.75) ($fy + 6.5) 0.5 0.625 $fSkinD; Rect ($fx + 6.5) ($fy + 7.0) 1 0.125 (Shade $fSkinD 0.9)   # Nase
$g2.FillPie((Br '#B5495A'), [single]($fx + 4.7), [single]($fy + 6.9), 4.6, 2.3, 0, 180)                       # Lachen
Rect ($fx + 5.1) ($fy + 8.05) 3.8 0.375 '#FFFFFF'                                       # Zaehne
$g2.DrawArc((New-Object System.Drawing.Pen (C '#D87784'), 0.25), [single]($fx + 4.7), [single]($fy + 6.9), 4.6, 2.3, 0, 180)
# Haare, die seitlich ins Gesicht fallen (nur Textur)
Rect $fx $fy 14 3 $fHair
foreach ($dx0 in 0, 12.75) { $strandFace = @(($fx + $dx0), ($fy + 3), 1.25, 5); FigStrands $strandFace 5 }

# ===================== Haare: Oberkopf (Sitzflaeche), Pony, Seitenstraehnen, Ruecken =====================
$fgCap = FigBox 16 3 16
foreach ($kk in $figSides) { FigStrands $fgCap[$kk] 5 }
FigStrands $fgCap.top 4
Rect ($fgCap.top[0] + 7.875) $fgCap.top[1] 0.25 8 $fHairDD                                # Mittelscheitel
FigStrands $fgCap.bottom 2
$fgBang = FigBox 5 1 1
foreach ($kk in $figAll) { FigStrands $fgBang[$kk] 6 }
FigFray $fgBang.front 0.5
$fgLock = FigBox 2 12 6
foreach ($kk in $figSides + 'top') { FigStrands $fgLock[$kk] 5; }
FigBand $fgLock.bottom $fHairL 1 1
foreach ($kk in $figSides) { FigFray $fgLock[$kk] 1.2 }
$fgFront = FigBox 3 8 2
foreach ($kk in $figSides + 'top') { FigStrands $fgFront[$kk] 6 }
FigBand $fgFront.bottom $fHairL 1 1
foreach ($kk in $figSides) { FigFray $fgFront[$kk] 1.2 }
$fgBackHair = FigBox 16 12 4
foreach ($kk in $figSides + 'top') { FigStrands $fgBackHair[$kk] 5 }
FigBand $fgBackHair.bottom $fHairL 1 1
FigFray $fgBackHair.back 0.8; FigFray $fgBackHair.right 0.8; FigFray $fgBackHair.left 0.8; FigFray $fgBackHair.front 0.8

# ===================== Oberkoerper 12 x 5 x 8: Jacke und Kleid =====================
$fgBody = FigBox 12 5 8
foreach ($kk in 'right', 'left', 'back') {
    $f = $fgBody[$kk]; FigLeather $f $fWhite
    Rect $f[0] $f[1] $f[2] 1.25 $fBlue; Rect $f[0] ($f[1] + 1.25) $f[2] 0.125 $fBlueD
    Rect $f[0] ($f[1] + 4) $f[2] 1 $fDress; Rect $f[0] ($f[1] + 3.875) $f[2] 0.125 $fInk      # kurze Jacke, darunter das Kleid
}
FigBand $fgBody.top $fBlue 1 1; FigBand $fgBody.bottom $fDressD 1 1
$f = $fgBody.front; FigBand $f $fDress 1.08 0.95
for ($i = 0; $i -lt 5; $i++) { Rect ($f[0] + 4) ($f[1] + $i) 4 0.125 (Shade $fDress 0.94) }
FigSequins $f 20; FigSequins @(($f[0] + 4), $f[1], 4, 4) 16
Rect $f[0] ($f[1] + 4) $f[2] 1 $fSilver; FigGrain @($f[0], ($f[1] + 4), $f[2], 1) $fSilverL '#9FB0BE' 220   # Glitzergurt
Rect ($f[0] + 4) $f[1] 4 0.375 $fBlueD                                                    # Ausschnitt
# Jackenvorderteile als eigene Boxen, stehen eine Einheit vor
$fgPanel = FigBox 4 4 1
foreach ($kk in $figAll) { FigLeather $fgPanel[$kk] $fWhite }
$f = $fgPanel.front
Rect $f[0] $f[1] 4 1.25 $fBlue; Rect $f[0] ($f[1] + 1.25) 4 0.125 $fBlueD                  # blaue Passe
Rect ($f[0] + 0.25) ($f[1] + 2.5) 1.5 0.125 $fWhiteD; Rect ($f[0] + 0.25) ($f[1] + 3) 1.5 0.125 $fWhiteD  # Tasche
Rect ($f[0] + 3.625) $f[1] 0.375 4 $fInk                                                  # schwarze Paspel
Rect $f[0] ($f[1] + 3.75) 4 0.25 $fInk
for ($zy = 0; $zy -lt 4; $zy += 0.375) { Rect ($f[0] + 3.375) ($f[1] + $zy) 0.25 0.125 $fSilver } # Reissverschluss
Sprite ([int](($f[0] + 1.5) * $figK)) ([int](($f[1] + 0.3) * $figK)) $figHeart $fInk       # Herzknopf
FigBand $fgPanel.top $fBlue 1 1

# ===================== Schulter 4 x 3 x 6 =====================
$fgShoulder = FigBox 4 3 6
foreach ($kk in $figAll) {
    $f = $fgShoulder[$kk]; FigLeather $f $fBlue
    Rect $f[0] ($f[1] + $f[3] - 0.5) $f[2] 0.5 $fWhite
}
for ($px = 0.5; $px -lt 4; $px += 1) { Rect ($fgShoulder.top[0] + $px) $fgShoulder.top[1] 0.125 6 $fBlueD }

# ===================== Arm: Aermel, breite Manschette, Hand =====================
$fgSleeve = FigBox 4 9 4
foreach ($kk in $figAll) { FigLeather $fgSleeve[$kk] $fWhite }
foreach ($kk in $figSides) {
    $f = $fgSleeve[$kk]
    Rect ($f[0] + 0.25) ($f[1] + 3.5) ($f[2] - 0.5) 0.125 $fWhiteD; Rect ($f[0] + 0.25) ($f[1] + 3.75) ($f[2] - 0.5) 0.125 $fWhiteD  # Ellenbogen-Naehte
    Rect ($f[0] + 0.25) ($f[1] + 4.0) ($f[2] - 0.5) 0.125 $fWhiteD
}
foreach ($kk in 'right', 'left') {
    $f = $fgSleeve[$kk]; Rect ($f[0] + 1) $f[1] 2 $f[3] $fBlue; Rect ($f[0] + 1) $f[1] 0.125 $f[3] $fBlueD; Rect ($f[0] + 2.875) $f[1] 0.125 $f[3] $fBlueD
}
$fgCuff = FigBox 5 2 5
foreach ($kk in $figAll) { FigLeather $fgCuff[$kk] $fWhite }
foreach ($kk in $figSides) {
    $f = $fgCuff[$kk]
    Rect $f[0] ($f[1] + 0.75) $f[2] 0.5 $fBlue; Rect $f[0] ($f[1] + 1.75) $f[2] 0.25 $fInk; Rect $f[0] $f[1] $f[2] 0.25 $fWhiteD
}
FigBand $fgCuff.bottom (Shade $fBlueD 0.8) 1 1
$fgHand = FigBox 3 2 3
foreach ($kk in $figAll) { FigBand $fgHand[$kk] $fSkin 1.02 0.92 }
foreach ($kk in 'front', 'back') { foreach ($px in 0.75, 1.5, 2.25) { Rect ($fgHand[$kk][0] + $px) ($fgHand[$kk][1] + 1) 0.125 1 $fSkinD } }

# ===================== Rock in drei Stufen =====================
$fgSk1 = FigBox 14 2 10; FigSkirt $fgSk1 0.2 $false
$fgSk2 = FigBox 16 2 12; FigSkirt $fgSk2 0.26 $false
$fgSk3 = FigBox 18 2 14; FigSkirt $fgSk3 0.32 $true

# ===================== Beine und Plateaustiefel =====================
$fgThigh = FigBox 4 2 4
foreach ($kk in $figAll) { FigBand $fgThigh[$kk] $fSkin 0.86 1.0 }                         # Schatten unter dem Rock
$fgBoot = FigBox 5 5 5
foreach ($kk in $figAll) { FigLeather $fgBoot[$kk] '#F7F5EF' }
foreach ($kk in $figSides) {
    $f = $fgBoot[$kk]
    Rect $f[0] $f[1] $f[2] 0.375 $fWhiteD; Rect $f[0] ($f[1] + 0.375) $f[2] 0.125 '#B8B4A8'     # Schaftrand
    Rect ($f[0] + 1) ($f[1] + 0.75) 0.5 3.5 '#FFFFFF'                                       # Lackglanz
    Rect $f[0] ($f[1] + 4.25) $f[2] 0.75 $fWhiteD
}
$fgToe = FigBox 5 2 2
foreach ($kk in $figAll) { FigLeather $fgToe[$kk] '#F7F5EF' }
Rect ($fgToe.front[0] + 1) ($fgToe.front[1] + 0.25) 3 0.375 '#FFFFFF'
Rect $fgToe.front[0] ($fgToe.front[1] + 1.5) 5 0.5 $fWhiteD
$fgSole = FigBox 6 1 8
foreach ($kk in $figAll) { FigBand $fgSole[$kk] $fSilver 1.1 0.82; FigGrain $fgSole[$kk] $fSilverL '#8F9FAE' ([int]($fgSole[$kk][2] * 22)) }

# Unbemalt und damit durchsichtig: fuer die Ghast-Teile, die die Figur nicht braucht
$fgNone = FigBox 1 1 1
SaveCanvas 'textures\entity\primeblock_giant.png'

# ===================== Modell =====================
$figArmAngle = 52
function FigArm($id, $sign) {
    [ordered]@{
        id = $id; invertAxis = 'xy'; translate = @((8 * $sign), 7, 0); rotate = @(0, 0, ($figArmAngle * $sign))
        boxes = @(
            (FigCube $fgSleeve -2 -9 -2),
            (FigCube $fgCuff -2.5 -11 -2.5),
            (FigCube $fgHand -1.5 -13 -1.5))
    }
}
$figBoxes = @(
    (FigCube $fgHead -7 6 -7),
    (FigCube $fgCap -8 13 -8),
    (FigCube $fgBang -7 12 -8), (FigCube $fgBang 2 12 -8),
    (FigCube $fgLock -8.5 1 -6), (FigCube $fgLock 6.5 1 -6),
    (FigCube $fgFront -8 1 -8), (FigCube $fgFront 5 1 -8),
    (FigCube $fgBackHair -8 1 4),
    (FigCube $fgBody -6 1 -4),
    (FigCube $fgPanel -6 2 -5), (FigCube $fgPanel 2 2 -5),
    (FigCube $fgShoulder -10 3 -3), (FigCube $fgShoulder 6 3 -3),
    (FigCube $fgSk1 -7 -1 -5), (FigCube $fgSk2 -8 -3 -6), (FigCube $fgSk3 -9 -5 -7),
    (FigCube $fgThigh -5 -7 -2), (FigCube $fgThigh 1 -7 -2),
    (FigCube $fgBoot -5.5 -11 -2.5), (FigCube $fgBoot 0.5 -11 -2.5),
    (FigCube $fgToe -5.5 -11 -4.5), (FigCube $fgToe 0.5 -11 -4.5),
    (FigCube $fgSole -6 -12 -4.5), (FigCube $fgSole 0 -12 -4.5))
$giantParts = New-Object System.Collections.ArrayList
[void]$giantParts.Add([ordered]@{ part = 'body'; id = 'body'; invertAxis = 'xy'; translate = @(0, -8, 0); boxes = $figBoxes
    submodels = @((FigArm 'arm_a' 1), (FigArm 'arm_b' -1)) })
# Durchsichtiges Mini-Teil im Kopf. tentacle0 bis tentacle9: EMF zaehlt ab 1, sonst bleibt ein Original-Tentakel sichtbar
foreach ($empty in @('inner_body') + (0..9 | % { "tentacle$_" })) { [void]$giantParts.Add([ordered]@{ part = $empty; id = $empty; invertAxis = 'xy'; translate = @(0, 0, 0); boxes = @((FigCube $fgNone 0 10 0)) }) }
WJ 'optifine\cem\happy_ghast.jem' ([ordered]@{ credit = 'PrimeBlock'; texture = 'textures/entity/primeblock_giant.png'; textureSize = @(128, 128); models = $giantParts })
# Geschirr und Brille ausblenden, Reiten funktioniert weiter
$noHarness = New-Object System.Collections.ArrayList
foreach ($empty in 'harness', 'goggles') { [void]$noHarness.Add([ordered]@{ part = $empty; id = $empty; invertAxis = 'xy'; translate = @(0, 0, 0); boxes = @() }) }
WJ 'optifine\cem\happy_ghast_harness.jem' ([ordered]@{ credit = 'PrimeBlock'; textureSize = @(64, 64); models = $noHarness })
