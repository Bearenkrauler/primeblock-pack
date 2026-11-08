# Dot-sourced aus extras3.ps1: Happy Ghast als riesige Figur (EMF). Der Haarscheitel ist die Sitzflaeche.
# Goldblonde Locken mit Pony, blickdichtes schwarzes Spitzenkleid mit blauer Schleife, Spitzenaermel, Mikrofon.
# Der Ghast wird 4-fach gezeichnet: 16 Texel pro Modelleinheit = 64 Pixel pro Block (Wunsch: so detailliert wie moeglich).
# Texturkoordinaten sind Modelleinheiten; Dot/SetPixel arbeiten in Texeln.
$figK = 16
NewCanvas 128 128 1 $figK
$script:g.SmoothingMode = 'None'
$script:rng = New-Object System.Random 901

$fSkin = '#F5D0B8'; $fSkinD = '#E6B296'; $fBlush = '#F4B6A4'
$fHair = '#F3D57F'; $fHairL = '#FDEDB0'; $fHairD = '#DDB65C'; $fHairDD = '#C2974A'
$fDress = '#1E1B24'; $fDressD = '#100E14'; $fLace = '#45404F'; $fBow = '#2F46C8'
$fSilver = '#C6D1DB'; $fSilverL = '#F4F8FB'

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
    $n = [Math]::Max(1, [int]($f[3] * 4))
    for ($i = 0; $i -lt $n; $i++) {
        $t = if ($n -gt 1) { $i / ($n - 1) } else { 0 }
        Rect $f[0] ($f[1] + $i * $f[3] / $n) $f[2] ($f[3] / $n + 0.125) (Shade $hex ($top + ($bot - $top) * $t))
    }
}
function FigGrain($f, $hexA, $hexB, $count) {
    for ($i = 0; $i -lt ($count * 3); $i++) {
        $px = [int](($f[0] + $script:rng.NextDouble() * $f[2]) * $figK); $py = [int](($f[1] + $script:rng.NextDouble() * $f[3]) * $figK)
        $maxX = [int](($f[0] + $f[2]) * $figK) - 1; $maxY = [int](($f[1] + $f[3]) * $figK) - 1
        Dot ([Math]::Min($px, $maxX)) ([Math]::Min($py, $maxY)) $(if ($i % 2) { $hexA } else { $hexB })
    }
}
# Haarstraehnen: laufen der Laenge nach
function FigStrands($f, $density = 3) {
    FigBand $f $fHair 1.05 0.94
    $count = [int]($f[2] * $density * 3)
    for ($i = 0; $i -lt $count; $i++) {
        $x0 = FigRand $f[0] ($f[0] + $f[2] - 0.25)
        $y0 = FigRand $f[1] ($f[1] + $f[3] * 0.7)
        $len = [Math]::Min((FigRand 1 ($f[3] * 0.8 + 1)), $f[1] + $f[3] - $y0)
        $pick = $script:rng.Next(5)
        $col = if ($pick -le 1) { $fHairD } elseif ($pick -le 3) { $fHairL } else { $fHairDD }
        Rect $x0 $y0 (0.0625 * (1 + $script:rng.Next(3))) $len $col
    }
}
# Locken: geschwungene Wellen laufen die Straehne hinunter, nur innerhalb der Flaeche
function FigCurls($f, $startRow, $count) {
    $old = $script:g.Clip
    $script:g.SetClip((New-Object System.Drawing.RectangleF ([single]$f[0]), ([single]$f[1]), ([single]$f[2]), ([single]$f[3])))
    for ($i = 0; $i -lt ($count * 2); $i++) {
        $hex = if ($i % 3 -eq 0) { $fHairL } elseif ($i % 3 -eq 1) { $fHairDD } else { $fHairD }
        $pen = New-Object System.Drawing.Pen (C $hex), (FigRand 0.0625 0.1875)
        $x0 = FigRand $f[0] ($f[0] + $f[2]); $y0 = FigRand ($f[1] + $startRow) ($f[1] + $f[3])
        $amp = FigRand 0.2 0.5; $per = FigRand 1.2 2.2; $ph = FigRand 0 6.28; $len = FigRand 2 5
        $pts = for ($k0 = 0; $k0 -le 12; $k0++) { $yy = $y0 + $len * $k0 / 12; New-Object System.Drawing.PointF ([single]($x0 + $amp * [Math]::Sin($ph + ($yy - $y0) * 6.28 / $per))), ([single]$yy) }
        $script:g.DrawLines($pen, [System.Drawing.PointF[]]$pts)
    }
    $script:g.Clip = $old
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
function FigFlower($x, $y, $r0) {
    $script:g.FillEllipse((Br $fLace), [single]($x - $r0), [single]($y - $r0 * 0.6), [single]($r0 * 2), [single]($r0 * 1.2))
    $script:g.FillEllipse((Br $fLace), [single]($x - $r0 * 0.6), [single]($y - $r0), [single]($r0 * 1.2), [single]($r0 * 2))
    Rect ($x - 0.0625) ($y - 0.0625) 0.125 0.125 (Shade $fLace 1.5)
}
# Schwarzer Spitzenstoff: dichtes Blumenmuster, Ranken, wenige Glitzerpunkte. Immer blickdicht.
function FigLace($f, $r0, $sparkle = 0.4) {
    FigBand $f $fDress 1.15 0.95
    $rowN = 0
    $old = $script:g.Clip
    $script:g.SetClip((New-Object System.Drawing.RectangleF ([single]$f[0]), ([single]$f[1]), ([single]$f[2]), ([single]$f[3])))
    # Ranken als feine Boegen, darueber Blueten im Versatz
    $vinePen = New-Object System.Drawing.Pen (C (Shade $fLace 0.8)), 0.0625
    for ($i = 0; $i -lt [int]($f[2] * $f[3] * 1.6 + 2); $i++) {
        $d0 = FigRand 0.6 1.6
        $script:g.DrawArc($vinePen, [single](FigRand ($f[0] - 0.5) ($f[0] + $f[2])), [single](FigRand ($f[1] - 0.5) ($f[1] + $f[3])), [single]$d0, [single]$d0, [single](FigRand 0 360), 170)
    }
    for ($fy0 = 0.5; $fy0 -lt $f[3]; $fy0 += 1.3) {
        for ($fx0 = 0.5 + ($rowN % 2) * 0.7; $fx0 -lt $f[2]; $fx0 += 1.4) { FigFlower ($f[0] + $fx0 + (FigRand (-0.08) 0.08)) ($f[1] + $fy0 + (FigRand (-0.08) 0.08)) ($r0 * 1.5) }
        $rowN++
    }
    $script:g.Clip = $old
    FigGrain $f $fSilverL $fSilver ([int]($f[2] * $sparkle))
}
function FigDressBox($F0, $r0, $scallop) {
    foreach ($kk in $figSides) {
        FigLace $F0[$kk] $r0
        if ($scallop) { $f = $F0[$kk]; Rect $f[0] ($f[1] + $f[3] - 0.25) $f[2] 0.25 $fLace; FigScallop $f 1.25 0.45 }
    }
    FigBand $F0.top $fDress 1.1 1.0
    FigBand $F0.bottom $fDressD 1 1
}

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
    $g2.FillEllipse((Br '#8CA8C2'), [single]($lx + 0.5), [single]($ly + 0.1), 1.5, 1.7) # graublaue Iris
    $g2.FillEllipse((Br '#34485C'), [single]($lx + 0.75), [single]($ly + 0.4), 1.0, 1.1)
    $irisPen = New-Object System.Drawing.Pen (C '#5C7A96'), 0.0625
    $g2.DrawEllipse($irisPen, [single]($lx + 0.5), [single]($ly + 0.1), 1.5, 1.7)       # Irisrand
    $g2.FillEllipse((Br '#B4C8DA'), [single]($lx + 0.95), [single]($ly + 1.15), 0.7, 0.5) # helle Iris unten
    $g2.FillEllipse((Br '#141A22'), [single]($lx + 0.97), [single]($ly + 0.6), 0.56, 0.62) # Pupille
    Rect ($lx + 0.75) ($ly + 0.375) 0.375 0.375 '#FFFFFF'                               # Glanzpunkt
    Rect ($lx + 1.5) ($ly + 1.2) 0.1875 0.1875 '#FFFFFF'
    Rect $lx ($ly + 1.8) 2.4 0.0625 $fSkinD                                             # Unterlid
    Rect $lx ($ly - 0.125) 2.4 0.3125 '#3A2A1E'                                         # Oberlid
    for ($lash = 0; $lash -lt 2.4; $lash += 0.25) { Rect ($lx + $lash) ($ly - 0.3125) 0.0625 0.1875 '#3A2A1E' }   # einzelne Wimpern
    Rect ($lx - 0.25) ($ly + 0.125) 0.375 0.1875 '#3A2A1E'; Rect ($lx + 2.3) ($ly + 0.125) 0.375 0.1875 '#3A2A1E'
    Rect $lx ($ly - 0.5) 2.4 0.125 (Shade $fSkin 0.9)                                   # Lidfalte
    for ($br0 = 0.25; $br0 -lt 2.1; $br0 += 0.125) { Rect ($lx + $br0) ($ly - 0.8125 + [Math]::Abs($br0 - 1.2) * 0.06) 0.0625 0.25 $(if (($br0 * 8) % 2) { '#B08A55' } else { '#C9A46A' }) }   # Augenbraue, Haar fuer Haar
}
Rect ($fx + 6.75) ($fy + 6.5) 0.5 0.625 $fSkinD; Rect ($fx + 6.5) ($fy + 7.0) 1 0.125 (Shade $fSkinD 0.9)   # Nase
$g2.FillPie((Br '#C9475F'), [single]($fx + 5.2), [single]($fy + 7.0), 3.6, 2.0, 0, 180)                       # singender Mund
Rect ($fx + 5.5) ($fy + 8.0) 3.0 0.3 '#FFFFFF'                                          # Zaehne
$g2.DrawArc((New-Object System.Drawing.Pen (C '#E0657C'), 0.3), [single]($fx + 5.2), [single]($fy + 7.0), 3.6, 2.0, 0, 180)
Rect ($fx + 6.875) ($fy + 5.2) 0.25 1.3 (Shade $fSkin 1.06)                              # Nasenruecken
Rect ($fx + 6.25) ($fy + 7.125) 0.25 0.0625 $fSkinD; Rect ($fx + 7.5) ($fy + 7.125) 0.25 0.0625 $fSkinD   # Nasenfluegel
Rect ($fx + 6.2) ($fy + 7.0) 1.6 0.125 '#E0657C'                                        # Oberlippe
Rect ($fx + 6.4) ($fy + 8.95) 1.2 0.0625 '#F59AAA'                                      # Glanz auf der Unterlippe
FigGrain @(($fx + 1.2), ($fy + 6.6), 2.6, 1.3) '#F0A594' '#F9C6B6' 25
FigGrain @(($fx + 10.2), ($fy + 6.6), 2.6, 1.3) '#F0A594' '#F9C6B6' 25
Rect $fx $fy 14 3 $fHair
foreach ($dx0 in 0, 12.75) { $strandFace = @(($fx + $dx0), ($fy + 3), 1.25, 5); FigStrands $strandFace 5 }

# ===================== Haare: Oberkopf (Sitzflaeche), Pony, Seitenstraehnen, Locken, Ruecken =====================
$fgCap = FigBox 16 3 16
foreach ($kk in $figSides) { FigStrands $fgCap[$kk] 5 }
FigStrands $fgCap.top 4
Rect ($fgCap.top[0] + 7.875) $fgCap.top[1] 0.25 8 $fHairDD                                # Mittelscheitel
FigStrands $fgCap.bottom 2
$fgBang = FigBox 5 1 1
foreach ($kk in $figAll) { FigStrands $fgBang[$kk] 6 }
FigFray $fgBang.front 0.5
$fgLock = FigBox 2 9 6
foreach ($kk in $figSides + 'top') { FigStrands $fgLock[$kk] 5; FigCurls $fgLock[$kk] 3 8 }
FigBand $fgLock.bottom $fHairL 1 1
$fgCurl = FigBox 4 5 8                                                                    # lockige Enden, breiter als die Straehnen
foreach ($kk in $figSides + 'top') { FigStrands $fgCurl[$kk] 4; FigCurls $fgCurl[$kk] 0 16 }
# Unterseite bleibt durchsichtig, sonst steht unter den Fransen eine flache Platte
foreach ($kk in $figSides) { FigFray $fgCurl[$kk] 0.9 }
$fgCurlS = FigBox 2 3 3                                                                   # kleine Einzellocken
foreach ($kk in $figSides + 'top') { FigStrands $fgCurlS[$kk] 5; FigCurls $fgCurlS[$kk] 0 7 }
#
foreach ($kk in $figSides) { FigFray $fgCurlS[$kk] 0.6 }
$fgFront = FigBox 3 6 2
foreach ($kk in $figSides + 'top') { FigStrands $fgFront[$kk] 6; FigCurls $fgFront[$kk] 1 8 }
#
foreach ($kk in $figSides) { FigFray $fgFront[$kk] 0.9 }
$fgBackHair = FigBox 16 12 4
foreach ($kk in $figSides + 'top') { FigStrands $fgBackHair[$kk] 5; FigCurls $fgBackHair[$kk] 4 26 }
$fgBackCurl = FigBox 18 4 3
foreach ($kk in $figSides + 'top') { FigStrands $fgBackCurl[$kk] 4; FigCurls $fgBackCurl[$kk] 0 16 }
foreach ($kk in $figSides) { FigFray $fgBackCurl[$kk] 0.9 }
FigFray $fgBackHair.back 0.8; FigFray $fgBackHair.right 0.8; FigFray $fgBackHair.left 0.8; FigFray $fgBackHair.front 0.8

# ===================== Oberkoerper 12 x 5 x 8: Spitzenkleid =====================
$fgBody = FigBox 12 5 8
foreach ($kk in $figAll) { FigLace $fgBody[$kk] 0.28 }
FigBand $fgBody.top $fSkin 1 1
$f = $fgBody.front
Rect ($f[0] + 1.5) $f[1] 9 1 $fSkin; Rect ($f[0] + 1.5) ($f[1] + 0.9375) 9 0.0625 $fSkinD      # gerader Ausschnitt
foreach ($sx in 2.25, 9.25) { Rect ($f[0] + $sx) $f[1] 0.5 1 $fDressD }                     # Traeger
# Ruesche am Ausschnitt
$fgRuffle = FigBox 12 1 1
foreach ($kk in $figAll) { FigLace $fgRuffle[$kk] 0.2 1 }
foreach ($kk in $figSides) { FigScallop $fgRuffle[$kk] 0.75 0.3 }
# Blaue Schleife
$fgBow = FigBox 4 2 1
foreach ($kk in $figAll) { FigBand $fgBow[$kk] $fBow 1.25 0.85 }
$f = $fgBow.front
Rect ($f[0] + 1.5) $f[1] 1 2 (Shade $fBow 0.65); Rect ($f[0] + 1.75) ($f[1] + 0.5) 0.5 1 (Shade $fBow 1.35)
Rect ($f[0] + 0.25) ($f[1] + 0.5) 1 0.125 (Shade $fBow 1.4); Rect ($f[0] + 2.75) ($f[1] + 0.5) 1 0.125 (Shade $fBow 1.4)

$fgBowTail = FigBox 1 2 1                                                                  # Schleifenbaender
foreach ($kk in $figAll) { FigBand $fgBowTail[$kk] $fBow 1.1 0.8 }

# ===================== Schultern =====================
$fgShoulder = FigBox 4 3 6
foreach ($kk in $figAll) { FigBand $fgShoulder[$kk] $fSkin 1.03 0.94 }

# ===================== Arme: Spitzenaermel, Ruesche, Hand, Mikrofon =====================
$fgUpper = FigBox 4 7 4
foreach ($kk in $figSides) { $f = $fgUpper[$kk]; FigLace $f 0.22; Rect $f[0] $f[1] $f[2] 2.5 $fSkin; Rect $f[0] ($f[1] + 2.375) $f[2] 0.125 $fSkinD }
FigBand $fgUpper.top $fSkin 1 1; FigBand $fgUpper.bottom $fDress 1 1
$fgArmFrill = FigBox 5 1 5
foreach ($kk in $figAll) { FigLace $fgArmFrill[$kk] 0.2 1 }
foreach ($kk in $figSides) { FigScallop $fgArmFrill[$kk] 0.75 0.3 }
$fgFore = FigBox 4 7 4
foreach ($kk in $figAll) { FigLace $fgFore[$kk] 0.22 }
$fgForeShort = FigBox 4 5 4
foreach ($kk in $figAll) { FigLace $fgForeShort[$kk] 0.22 }
$fgHand = FigBox 3 2 3
foreach ($kk in $figAll) { FigBand $fgHand[$kk] $fSkin 1.02 0.92 }
foreach ($kk in 'front', 'back') { foreach ($px in 0.75, 1.5, 2.25) { Rect ($fgHand[$kk][0] + $px) ($fgHand[$kk][1] + 1) 0.125 1 $fSkinD } }
$fgThumb = FigBox 1 2 1
foreach ($kk in $figAll) { FigBand $fgThumb[$kk] $fSkin 1.02 0.92 }
$fgMicRing = FigBox 3 1 3
foreach ($kk in $figAll) { FigBand $fgMicRing[$kk] $fSilverL 1.0 0.8 }
$fgMicHandle = FigBox 2 3 2
foreach ($kk in $figAll) { FigBand $fgMicHandle[$kk] $fSilver 1.1 0.85; FigGrain $fgMicHandle[$kk] '#FFFFFF' '#8F9FAE' 70 }
$fgMicHead = FigBox 3 2 3
foreach ($kk in $figAll) {
    $f = $fgMicHead[$kk]; FigBand $f '#3A3D44' 1.2 0.85
    for ($px = 0.25; $px -lt $f[2]; $px += 0.5) { Rect ($f[0] + $px) $f[1] 0.125 $f[3] '#6E737C' }
    for ($py = 0.25; $py -lt $f[3]; $py += 0.5) { Rect $f[0] ($f[1] + $py) $f[2] 0.125 '#6E737C' }
}

# ===================== Rock: Huefte, enger Rock, Saum =====================
$fgHip = FigBox 14 3 10; FigDressBox $fgHip 0.3 $false
$fgSkirt = FigBox 13 5 9; FigDressBox $fgSkirt 0.3 $false
$fgHem = FigBox 14 1 10; FigDressBox $fgHem 0.22 $true

# ===================== Beine und schwarze Absatzschuhe =====================
$fgCalf = FigBox 4 3 4
foreach ($kk in $figAll) { FigBand $fgCalf[$kk] $fSkin 0.88 1.0 }
$fgShoe = FigBox 5 1 5
foreach ($kk in $figAll) { FigBand $fgShoe[$kk] '#1A181E' 1.3 0.9 }
foreach ($kk in $figSides) { Rect ($fgShoe[$kk][0] + 0.5) ($fgShoe[$kk][1] + 0.25) ($fgShoe[$kk][2] - 1) 0.1875 '#7A7783' }   # Lackglanz
$fgToe = FigBox 5 1 2
foreach ($kk in $figAll) { FigBand $fgToe[$kk] '#1A181E' 1.3 0.9 }
Rect ($fgToe.top[0] + 1) ($fgToe.top[1] + 0.5) 3 0.25 '#7A7783'
$fgHeel = FigBox 2 2 2
foreach ($kk in $figAll) { FigBand $fgHeel[$kk] '#26232B' 1.1 0.8 }

# Unbemalt und damit durchsichtig: fuer die Ghast-Teile, die die Figur nicht braucht
$fgNone = FigBox 1 1 1
SaveCanvas 'textures\entity\primeblock_giant.png'

# ===================== Modell =====================
# Arm-Teile haengen einzeln am Koerper. Der Arm mit dem Mikrofon hat Ober- und Unterarm mit eigenem Drehpunkt.
function FigPart($id, $tr, $rot, $boxes) { [ordered]@{ id = $id; invertAxis = 'xy'; translate = $tr; rotate = $rot; boxes = $boxes } }
$figArms = @(
    (FigPart 'mic_upper' @(8, 7, 0) @(22, 0, 34) @((FigCube $fgUpper -2 -7 -2), (FigCube $fgArmFrill -2.5 -3.5 -2.5))),
    (FigPart 'mic_fore' @(12, 1, -3) @(25, 0, -124) @((FigCube $fgFore -2 -7 -2), (FigCube $fgHand -1.5 -9 -1.5), (FigCube $fgThumb 1.5 -9 -0.5), (FigCube $fgMicHandle -1 -10 -1), (FigCube $fgMicRing -1.5 -10.5 -1.5), (FigCube $fgMicHead -1.5 -12.5 -1.5))),
    (FigPart 'free_arm' @(-8, 7, 0) @(0, 0, -65) @((FigCube $fgUpper -2 -7 -2), (FigCube $fgArmFrill -2.5 -3.5 -2.5), (FigCube $fgForeShort -2 -12 -2), (FigCube $fgHand -1.5 -14 -1.5), (FigCube $fgThumb -2.5 -14 -0.5))))
$figBoxes = @(
    (FigCube $fgHead -7 6 -7),
    (FigCube $fgCap -8 13 -8),
    (FigCube $fgBang -7 12 -8), (FigCube $fgBang 2 12 -8),
    (FigCube $fgLock -8.5 5 -6), (FigCube $fgLock 6.5 5 -6),
    (FigCube $fgCurl -10 0 -6), (FigCube $fgCurl 6 0 -6),
    (FigCube $fgFront -8 3 -8), (FigCube $fgFront 5 3 -8),
    (FigCube $fgCurlS -10.5 3 -4), (FigCube $fgCurlS 8.5 3 -4), (FigCube $fgCurlS -8.5 1 -8.5), (FigCube $fgCurlS 6.5 1 -8.5),
    (FigCube $fgBackCurl -9 0 5),
    (FigCube $fgBackHair -8 1 4),
    (FigCube $fgBody -6 1 -4),
    (FigCube $fgRuffle -6 4 -5),
    (FigCube $fgBow -2 2.5 -5.5), (FigCube $fgBowTail -1.5 0.5 -5.25), (FigCube $fgBowTail 0.5 0.5 -5.25),
    (FigCube $fgShoulder -10 3 -3), (FigCube $fgShoulder 6 3 -3),
    (FigCube $fgHip -7 -2 -5), (FigCube $fgSkirt -6.5 -7 -4.5), (FigCube $fgHem -7 -8 -5),
    (FigCube $fgCalf -5 -10 -2), (FigCube $fgCalf 1 -10 -2),
    (FigCube $fgShoe -5.5 -11 -2.5), (FigCube $fgShoe 0.5 -11 -2.5),
    (FigCube $fgToe -5.5 -12 -4.5), (FigCube $fgToe 0.5 -12 -4.5),
    (FigCube $fgHeel -4 -12 0.5), (FigCube $fgHeel 2 -12 0.5))
$giantParts = New-Object System.Collections.ArrayList
[void]$giantParts.Add([ordered]@{ part = 'body'; id = 'body'; invertAxis = 'xy'; translate = @(0, -8, 0); boxes = $figBoxes; submodels = $figArms })
# Durchsichtiges Mini-Teil im Kopf. tentacle0 bis tentacle9: EMF zaehlt ab 1, sonst bleibt ein Original-Tentakel sichtbar
foreach ($empty in @('inner_body') + (0..9 | % { "tentacle$_" })) { [void]$giantParts.Add([ordered]@{ part = $empty; id = $empty; invertAxis = 'xy'; translate = @(0, 0, 0); boxes = @((FigCube $fgNone 0 10 0)) }) }
WJ 'optifine\cem\happy_ghast.jem' ([ordered]@{ credit = 'PrimeBlock'; texture = 'textures/entity/primeblock_giant.png'; textureSize = @(128, 128); models = $giantParts })
# Geschirr und Brille ausblenden, Reiten funktioniert weiter
$noHarness = New-Object System.Collections.ArrayList
foreach ($empty in 'harness', 'goggles') { [void]$noHarness.Add([ordered]@{ part = $empty; id = $empty; invertAxis = 'xy'; translate = @(0, 0, 0); boxes = @() }) }
WJ 'optifine\cem\happy_ghast_harness.jem' ([ordered]@{ credit = 'PrimeBlock'; textureSize = @(64, 64); models = $noHarness })
