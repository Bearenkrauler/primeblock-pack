# Dot-sourced from build.ps1 after extras.ps1 (uses NewCanvas, SaveCanvas, Rect, Faces, FillFace, Rows, SideRows,
# FillAll, Mid, Smile, Text, FitText, P, Px, ItemCanvas, $AssetDir, $utf8 and the colour variables).
# ACHTUNG: PowerShell-Variablen ignorieren Gross/Kleinschreibung - keine Namen wie $s/$S, $a/$A wiederverwenden.

$cardC = '#C79A62'; $cardDk = '#9A6F3C'; $tapeC = '#E2C38F'; $suit = '#2B2F36'; $suitD = '#1F2227'

function PU($pts, $hex) {   # Polygon in Textur-Einheiten (wird mit $cs skaliert)
    $scaled = foreach ($pt in $pts) { , @(($pt[0] * $cs), ($pt[1] * $cs)) }
    P $scaled $hex
}
function Outline($f, $hex, $w = 0.25) {
    $script:g.DrawRectangle((Pn $hex ($w * $cs)), [single](($f[0] + $w / 2) * $cs), [single](($f[1] + $w / 2) * $cs), [single](($f[2] - $w) * $cs), [single](($f[3] - $w) * $cs))
}
function Logo($f, $txt = '#2B2B2B', $big = 1.0) {
    $m = Mid $f
    $hgt = $f[3]
    FitText 'PrimeBlock' $txt $m[0] ($m[1] + $hgt * 0.36 * $cs) ($f[2] * 0.82 * $cs) (11 * $big)
    Smile $m[0] ($m[1] + $hgt * 0.6 * $cs) ($f[2] * 0.45 * $cs) (0.5 * $cs * $big)
}

# =============== Kiste -> PrimeBlock-Lagerbox (Karton) ===============
# Minecraft rendert das Kistenmodell ohne die bei Mobs uebliche Spiegelung. Deshalb wird alles so gezeichnet,
# wie man es in der Welt sehen soll, und danach umgerechnet (FixChest):
#   lange Seiten (N/S) 180 Grad gedreht, kurze Seiten (O/W) vertikal gespiegelt, Deckel-/Bodenflaeche getauscht + gespiegelt.
# Vorderseite (mit Schloss) = Slot "back". Doppelkiste: Modell "left" hat die Naht bei +x und steht vom Spieler aus RECHTS.
function PxRect($f) { $u = $script:cs * $script:ck; New-Object System.Drawing.Rectangle ([int]($f[0] * $u)), ([int]($f[1] * $u)), ([int]($f[2] * $u)), ([int]($f[3] * $u)) }
function Crop($bmp, $f) { $bmp.Clone((PxRect $f), $bmp.PixelFormat) }
function Paste($gr, $img, $f) { $gr.DrawImage($img, (PxRect $f)); $img.Dispose() }
function RawGraphics($bmp) {
    $gr = [System.Drawing.Graphics]::FromImage($bmp)
    $gr.CompositingMode = 'SourceCopy'; $gr.InterpolationMode = 'NearestNeighbor'; $gr.PixelOffsetMode = 'Half'
    $gr
}
function FixChest($gr, $bmp, $F) {
    foreach ($k in 'front', 'back') { $img = Crop $bmp $F[$k]; $img.RotateFlip('Rotate180FlipNone'); Paste $gr $img $F[$k] }
    foreach ($k in 'right', 'left') { $img = Crop $bmp $F[$k]; $img.RotateFlip('RotateNoneFlipY'); Paste $gr $img $F[$k] }
    $tp = Crop $bmp $F.top; $bt = Crop $bmp $F.bottom
    $tp.RotateFlip('RotateNoneFlipX'); $bt.RotateFlip('RotateNoneFlipX')
    Paste $gr $tp $F.bottom; Paste $gr $bt $F.top
}
function ShippingLabel($f) {
    Rect ($f[0] + $f[2] / 2 - 1.25) $f[1] 2.5 2.5 $tapeC                          # Klebeband vom Deckel
    Rect ($f[0] + 2) ($f[1] + 3.5) ($f[2] - 4) 4.5 '#F4F4F4'                        # Versandetikett
    for ($k2 = 0; $k2 -lt 3; $k2++) { Rect ($f[0] + 2.6) ($f[1] + 4.3 + $k2 * 1.2) ($f[2] - 7.5) 0.45 '#7A7A7A' }
    Rect ($f[0] + $f[2] - 4.4) ($f[1] + 4.2) 1.8 1.8 '#2B2B2B'
}
# Zeichnet alles ausser den langen Seiten. Blick wie in der Welt: L.top = Deckel aussen, B.top = Innenboden.
function ChestCommon($w, $lockW) {
    $L = Faces 0 0 $w 5 14; $B = Faces 0 19 $w 10 14; $Latch = Faces 0 0 $lockW 4 1
    FillAll $L $cardC; FillAll $B $cardC
    FillFace $L.bottom $cardDk; FillFace $B.top '#3B2A1A'; FillFace $B.bottom $cardDk
    $t = $L.top; Rect $t[0] ($t[1] + $t[3] / 2 - 1.25) $t[2] 2.5 $tapeC              # Klebeband laengs ueber den Deckel
    foreach ($k in 'right', 'left') {
        $f = $L[$k]; Outline $f $cardDk; Rect ($f[0] + $f[2] / 2 - 1.25) $f[1] 2.5 $f[3] $tapeC
        $f = $B[$k]; Outline $f $cardDk; ShippingLabel $f
    }
    FillAll $Latch $silver; FillFace $Latch.front '#7E848A'                         # Verschluss
    @{ L = $L; B = $B }
}
$q = 2   # Qualitaetsfaktor der Kisten-Texturen

# Einzelkiste
NewCanvas 64 64 4 $q
$cf = ChestCommon 14 2
$t = $cf.L.top; Rect ($t[0] + 1) ($t[1] + 1) 3.5 2.5 '#F4F4F4'                     # Etikett auf dem Deckel
foreach ($k in 'front', 'back') {
    Outline $cf.L[$k] $cardDk
    $f = $cf.B[$k]; Outline $f $cardDk; Logo @($f[0], ($f[1] + 1), $f[2], ($f[3] - 1))
}
$script:g.Dispose(); $gr = RawGraphics $script:cv
FixChest $gr $script:cv $cf.L; FixChest $gr $script:cv $cf.B
$gr.Dispose()
$p = Join-Path $AssetDir 'textures\entity\chest\normal.png'; New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
$script:cv.Save($p, [System.Drawing.Imaging.ImageFormat]::Png); $script:cv.Dispose()

# Doppelkiste: eine durchgehende Vorderseite (30 breit) mit einem grossen Logo, auf beide Haelften verteilt
NewCanvas 30 15 4 $q
Rect 0 0 30 15 $cardC; Outline @(0, 0, 30, 5) $cardDk; Outline @(0, 5, 30, 10) $cardDk
FitText 'PrimeBlock' '#2B2B2B' (15 * 4) ((5 + 3.6) * 4) (22 * 4) 26
Smile (15 * 4) ((5 + 6.9) * 4) (11 * 4) (0.7 * 4)
$script:g.Dispose(); $comp = $script:cv
foreach ($half in 'left', 'right') {
    NewCanvas 64 64 4 $q
    $cf = ChestCommon 15 1
    $script:g.Dispose(); $gr = RawGraphics $script:cv
    $viewLeft = @{ lid = (Crop $comp @(0, 0, 15, 5)); base = (Crop $comp @(0, 5, 15, 10)) }
    $viewRight = @{ lid = (Crop $comp @(15, 0, 15, 5)); base = (Crop $comp @(15, 5, 15, 10)) }
    # Vorderseite (Slot "back"): Modell "left" steht vom Spieler aus rechts. Rueckseite (Slot "front"): umgekehrt.
    if ($half -eq 'left') { $fr = $viewRight; $bk = $viewLeft } else { $fr = $viewLeft; $bk = $viewRight }
    Paste $gr $fr.lid $cf.L.back; Paste $gr $fr.base $cf.B.back
    Paste $gr $bk.lid $cf.L.front; Paste $gr $bk.base $cf.B.front
    FixChest $gr $script:cv $cf.L; FixChest $gr $script:cv $cf.B
    $gr.Dispose()
    $script:cv.Save((Join-Path $AssetDir "textures\entity\chest\normal_$half.png"), [System.Drawing.Imaging.ImageFormat]::Png); $script:cv.Dispose()
}
$comp.Dispose()

# =============== Fass -> Paketstapel ===============
NewCanvas 16 16 4 2
$shades = @('#C79A62', '#BB8E57', '#D2A56E')
$bands = @(@(0, 5), @(5, 10.5), @(10.5, 16))
for ($k = 0; $k -lt 3; $k++) {
    $y0 = $bands[$k][0]; $hh = $bands[$k][1] - $y0
    $x0 = @(0.5, 2, 1)[$k]; $ww = @(15, 13, 14)[$k]
    Rect 0 $y0 16 $hh '#5E4127'
    Rect $x0 ($y0 + 0.3) $ww ($hh - 0.6) $shades[$k]
    Rect ($x0 + $ww / 2 - 0.8) ($y0 + 0.3) 1.6 ($hh - 0.6) $tapeC
    Rect ($x0 + 1) ($y0 + 1.2) 3 1.8 '#F4F4F4'
}
Smile (11 * 4) (8.6 * 4) 16 2
SaveCanvas 'textures\block\barrel_side.png'
NewCanvas 16 16 4 2
Rect 0 0 16 16 $cardC; Outline @(0, 0, 16, 16) $cardDk 0.5
Rect 7 0 2 16 $tapeC; Rect 0 7 16 2 $tapeC
Rect 1.5 1.5 4 3 '#F4F4F4'; Rect 2 2.2 3 0.4 '#7A7A7A'; Rect 2 3.2 2 0.4 '#7A7A7A'
Smile (12 * 4) (12.5 * 4) 14 2
SaveCanvas 'textures\block\barrel_top.png'
NewCanvas 16 16 4 2
Rect 0 0 16 16 $cardC; Rect 1.5 1.5 13 13 '#3B2A1A'                             # offener Karton
Rect 2.5 2.5 5 4 $cardC; Rect 4.5 2.5 1 4 $tapeC
Rect 8.5 3 5 5 '#BB8E57'; Rect 8.5 5 5 1 $tapeC
Rect 3 8.5 6 5 '#D2A56E'; Rect 3 10.5 6 0.8 $tapeC
Rect 10 9.5 3.5 4 $cardC
SaveCanvas 'textures\block\barrel_top_open.png'
NewCanvas 16 16 4 2
Rect 0 0 16 16 $cardDk; Rect 7 0 2 16 '#B08A5A'
SaveCanvas 'textures\block\barrel_bottom.png'

# =============== Shulker-Kisten -> PrimeBlock-Versandboxen ===============
function Shade($hex, $f) {
    $c = C $hex
    $r = [int][Math]::Max(0, [Math]::Min(255, $c.R * $f)); $gg = [int][Math]::Max(0, [Math]::Min(255, $c.G * $f)); $bb = [int][Math]::Max(0, [Math]::Min(255, $c.B * $f))
    '#{0:X2}{1:X2}{2:X2}' -f $r, $gg, $bb
}
$shulkerColors = [ordered]@{
    '' = '#8C6A97'; 'white' = '#E4E7E8'; 'orange' = '#F07613'; 'magenta' = '#BD44B3'; 'light_blue' = '#3AAFD9'
    'yellow' = '#F8C627'; 'lime' = '#70B919'; 'pink' = '#ED8DAC'; 'gray' = '#3E4447'; 'light_gray' = '#8E8E86'
    'cyan' = '#158991'; 'purple' = '#792AAC'; 'blue' = '#35399D'; 'brown' = '#724728'; 'green' = '#546D1B'
    'red' = '#A12722'; 'black' = '#1D1D21'
}
foreach ($name in $shulkerColors.Keys) {
    $col = $shulkerColors[$name]; $colD = Shade $col 0.75
    $txt = if ($name -in 'white', 'yellow', 'light_gray', 'pink', 'lime', 'light_blue') { $navy } else { '#FFFFFF' }
    NewCanvas 64 64 4 2
    $L = Faces 0 0 16 12 16; $B = Faces 0 28 16 8 16; $Hd = Faces 0 52 6 6 6
    FillAll $L $col; FillAll $B $colD
    foreach ($k in 'right', 'front', 'left', 'back') {
        $f = $L[$k]; Outline $f $colD 0.4
        Rect $f[0] ($f[1] + 4.5) $f[2] 3 $txt                                       # Schriftband
        $m = Mid $f; FitText 'PrimeBlock' $col $m[0] ($m[1] + 6 * 4) (13 * 4) 13
        Rect $f[0] ($f[1] + 11) $f[2] 1 $colD
        $f = $B[$k]; Outline $f (Shade $col 0.55) 0.4
        Rect ($f[0] + 5) ($f[1] + 2.5) 6 2 (Shade $col 0.45)                        # Griffmulde
    }
    $t = $L.top; Outline $t $colD 0.5
    Rect ($t[0] + 3) ($t[1] + 3) 10 10 (Shade $col 0.88)
    $m = Mid $t; Smile $m[0] ($m[1] + 8 * 4) (8 * 4) 3
    FillFace $L.bottom (Shade $col 0.5); FillFace $B.top (Shade $col 0.5)
    FillAll $Hd $navy                                                              # Kopf des Shulker-Mobs
    $f = $Hd.front; Rect ($f[0] + 1.5) ($f[1] + 2) 1 1 $white; Rect ($f[0] + 3.5) ($f[1] + 2) 1 1 $white
    $m = Mid $f; Smile $m[0] ($m[1] + 4.2 * 4) (3 * 4) 1.5
    $file = if ($name) { "shulker_$name.png" } else { 'shulker.png' }
    SaveCanvas "textures\entity\shulker\$file"
}

# =============== Karte -> Routenplan ===============
function Clipboard($withHeader = $true) {
    Rect 6 3 20 27 '#6D4C2F'; Rect 7 4 18 25 '#8A6440'                            # Brett
    Rect 8 6 16 22 '#F6F1E4'                                                       # Papier
    if ($withHeader) { Rect 8 6 16 3 $navy; Px @(@(19, 7), @(20, 8), @(21, 8), @(22, 7)) $orange }
    Rect 12 2 8 3 '#9EA4AA'; Rect 13 1 6 2 '#C9CDD2'; Rect 15 2 2 1 '#6E757D'      # Klemme
}
ItemCanvas; Clipboard
Rect 10 11 12 0.8 '#D7D0BE'; Rect 10 14 12 0.8 '#D7D0BE'; Rect 10 17 12 0.8 '#D7D0BE'; Rect 10 20 9 0.8 '#D7D0BE'
SaveCanvas 'textures\item\map.png'
ItemCanvas; Clipboard
Rect 9 10 14 17 '#DDE8D2'                                                          # Kartenausschnitt
Rect 9 15 14 1 '#B8B8B8'; Rect 15 10 1 17 '#B8B8B8'; Rect 9 22 14 1 '#B8B8B8'; Rect 20 10 1 17 '#B8B8B8'
Rect 11 12 3 2 '#A7C79A'; Rect 17 18 2 3 '#A7C79A'; Rect 10 24 4 2 '#9CC3E6'
Px @(@(11, 25), @(12, 24), @(13, 23), @(14, 22), @(15, 21), @(15, 20), @(15, 19), @(16, 18), @(17, 17), @(18, 16), @(19, 15), @(20, 14)) $orange
Px @(@(12, 25), @(14, 23), @(16, 19), @(18, 17), @(20, 15)) $orange
Rect 19 11 3 3 '#D32F2F'; Rect 20 14 1 1 '#D32F2F'; Rect 20 12 1 1 '#FFFFFF'          # Ziel-Pin
Rect 10 25 2 2 $navy                                                               # Start (Depot)
SaveCanvas 'textures\item\filled_map.png'
# Papierrand, wenn man die Karte in der Hand haelt
NewCanvas 64 64 1
Rect 0 0 64 64 '#F3EAD3'; Rect 0 0 64 3 $navy; Rect 0 61 64 3 $navy; Rect 0 0 3 64 $navy; Rect 61 0 3 64 $navy
Rect 3 3 58 1 $orange; Rect 3 60 58 1 $orange; Rect 3 3 1 58 $orange; Rect 60 3 1 58 $orange
SaveCanvas 'textures\map\map_background.png'

# =============== Buch und Feder -> Klemmbrett / Lieferliste ===============
ItemCanvas; Clipboard
for ($k = 0; $k -lt 5; $k++) { Rect 10 (11 + $k * 3.2) 12 0.8 '#C9D3E0' }
P @(@(24, 15), @(27, 12), @(29, 14), @(26, 17)) $navy                                # Stift
P @(@(24, 15), @(26, 17), @(23, 19)) '#E8C9A0'; Rect 22.5 18.5 1 1 '#2B2B2B'
P @(@(27, 12), @(28, 11), @(30, 13), @(29, 14)) $orange
SaveCanvas 'textures\item\writable_book.png'
ItemCanvas; Clipboard
for ($k = 0; $k -lt 5; $k++) {
    $yy = 11 + $k * 3.2
    Px @(@(10, ($yy + 0.5)), @(11, ($yy + 1.2)), @(12, ($yy)), @(13, ($yy - 0.8))) '#2E9E44'   # Haken
    Rect 15 ($yy + 0.2) (7 - ($k % 2) * 2) 0.8 '#7E8794'
}
SaveCanvas 'textures\item\written_book.png'

# =============== Elytra -> Liefer-Drohnenfluegel ===============
function WingTex {
    NewCanvas 64 32 8
    $W = Faces 22 0 10 20 2
    FillAll $W $orange
    foreach ($k in 'front', 'back') {
        $f = $W[$k]
        Rect $f[0] $f[1] $f[2] $f[3] $navy
        $script:g.SetClip((New-Object System.Drawing.RectangleF ([single]($f[0] * $cs)), ([single]($f[1] * $cs)), ([single]($f[2] * $cs)), ([single]($f[3] * $cs))))
        for ($q = -20; $q -lt 30; $q += 2) { $script:g.DrawLine((Pn $navyL 3), [single](($f[0] + $q) * $cs), [single]($f[1] * $cs), [single](($f[0] + $q + 20) * $cs), [single](($f[1] + 20) * $cs)) }
        $script:g.ResetClip()
        Rect $f[0] $f[1] $f[2] 1 $orange; Rect $f[0] $f[1] 1 $f[3] $orange               # Vorderkante
        # Rotor mit Propeller
        $cx = ($f[0] + 5.5) * $cs; $cy = ($f[1] + 5.5) * $cs; $rr = 3.6 * $cs
        $script:g.DrawEllipse((Pn '#C9CDD2' (0.5 * $cs)), [single]($cx - $rr), [single]($cy - $rr), [single](2 * $rr), [single](2 * $rr))
        $script:g.FillRectangle((Br '#9EA4AA'), [single]($cx - $rr * 0.9), [single]($cy - 0.35 * $cs), [single](1.8 * $rr), [single](0.7 * $cs))
        $script:g.FillEllipse((Br $silver), [single]($cx - 0.8 * $cs), [single]($cy - 0.8 * $cs), [single](1.6 * $cs), [single](1.6 * $cs))
        $m = Mid $f
        FitText 'PrimeBlock' $white $m[0] ($m[1] + 12.5 * $cs) (8.5 * $cs) 13
        Smile $m[0] ($m[1] + 14.5 * $cs) (5 * $cs) (0.5 * $cs)
        Rect ($f[0] + 2) ($f[1] + 17.5) 6 0.6 $orange
    }
}
WingTex; SaveCanvas 'textures\entity\equipment\wings\elytra.png'
ItemCanvas
foreach ($side in -1, 1) {
    $bx = if ($side -lt 0) { 3 } else { 17 }
    Rect $bx 8 12 18 $navy; Rect $bx 8 12 2 $orange
    if ($side -lt 0) { Rect $bx 8 2 18 $orange } else { Rect ($bx + 10) 8 2 18 $orange }
    Rect ($bx + 3) 12 6 6 '#9EA4AA'; Rect ($bx + 1) 14.5 10 1 '#C9CDD2'; Rect ($bx + 5) 14 2 2 $silver
    Px @(@(($bx + 4), 22), @(($bx + 5), 23), @(($bx + 6), 23), @(($bx + 7), 23), @(($bx + 8), 22)) $orange
}
Rect 15 10 2 6 '#2B2F36'
SaveCanvas 'textures\item\elytra.png'
ItemCanvas
foreach ($side in -1, 1) {
    $bx = if ($side -lt 0) { 3 } else { 17 }
    Rect $bx 10 12 16 '#4A5262'; Rect $bx 10 12 2 '#9C6A2E'
    Rect ($bx + 3) 14 6 6 '#6E757D'
}
Px @(@(21, 12), @(22, 13), @(22, 14), @(23, 15), @(22, 16), @(23, 17), @(24, 18)) '#1B1B1B'
Px @(@(8, 13), @(9, 14), @(8, 15), @(9, 16), @(10, 17)) '#1B1B1B'
SaveCanvas 'textures\item\elytra_broken.png'

# =============== Netherit-Ruestung -> Manager-Outfit ===============
function ManagerLayer1 {
    NewCanvas 64 32 8
    # Headset: Buegel ueber den Kopf, Ohrmuscheln, Mikrofon
    $H = Faces 0 0 8 8 8
    Rect $H.top[0] ($H.top[1] + 3.5) 8 1 '#1B1B1B'
    foreach ($k in 'right', 'left') {
        $f = $H[$k]
        Rect ($f[0] + 3.5) $f[1] 1 3 '#1B1B1B'
        Rect ($f[0] + 2) ($f[1] + 2.5) 4 3.5 '#2B2F36'; Rect ($f[0] + 2.5) ($f[1] + 3) 3 2.5 $orange
    }
    $f = $H.right; Rect ($f[0] + 0) ($f[1] + 5.5) 3 0.6 '#1B1B1B'                    # Mikrofonarm
    $f = $H.front; Rect ($f[0] + 0) ($f[1] + 5.3) 1.4 1 '#1B1B1B'; Rect ($f[0] + 6.6) ($f[1] + 5.3) 1.4 1 '#1B1B1B'
    # Sakko mit Hemd und Krawatte
    $B = Faces 16 16 8 12 4
    FillAll $B $suit @('bottom')
    $f = $B.front; $fx = $f[0]; $fy = $f[1]
    PU @(@(($fx + 2.6), $fy), @(($fx + 5.4), $fy), @(($fx + 4), ($fy + 6))) '#F2F2F2'
    Rect ($fx + 3.6) ($fy + 0.4) 0.8 6.5 '#C62828'; Rect ($fx + 3.4) ($fy + 0.3) 1.2 0.8 '#9E1F1F'
    PU @(@(($fx + 2.6), $fy), @(($fx + 4), ($fy + 6)), @(($fx + 2), ($fy + 3))) $suitD
    PU @(@(($fx + 5.4), $fy), @(($fx + 4), ($fy + 6)), @(($fx + 6), ($fy + 3))) $suitD
    Rect ($f[0] + 3.85) ($f[1] + 7.5) 0.4 0.4 '#8A8F96'; Rect ($f[0] + 3.85) ($f[1] + 9.5) 0.4 0.4 '#8A8F96'
    Rect ($f[0] + 5.8) ($f[1] + 1.5) 0.8 0.8 $orange                                  # PrimeBlock-Anstecker
    Rect ($f[0] + 0.8) ($f[1] + 8) 1.8 0.3 $suitD; Rect ($f[0] + 5.4) ($f[1] + 8) 1.8 0.3 $suitD
    $m = Mid $B.back; Smile $m[0] ($m[1] + 2 * $cs) (3 * $cs) (0.35 * $cs)
    Rect ($B.top[0] + 2.5) ($B.top[1] + 1) 3 2 '#F2F2F2'
    $Ar = Faces 40 16 4 12 4
    FillFace $Ar.top $suit; SideRows $Ar 0 10.5 $suit; SideRows $Ar 10.5 11.5 '#F2F2F2'
    # Lederschuhe
    $Lg = Faces 0 16 4 12 4
    SideRows $Lg 8.6 9.2 '#2B2B2B'; SideRows $Lg 9.2 12 '#141414'; FillFace $Lg.bottom '#0B0B0B'
    Rect ($Lg.front[0] + 0.6) ($Lg.front[1] + 9.6) 1 0.4 '#5A5F66'
}
function ManagerLayer2 {
    NewCanvas 64 32 8
    $B = Faces 16 16 8 12 4
    SideRows $B 8 12 $suit; SideRows $B 8 9 '#111111'
    Rect ($B.front[0] + 3.5) ($B.front[1] + 8) 1 1 $silver
    $Lg = Faces 0 16 4 12 4
    FillAll $Lg $suit @('bottom')
    Rect ($Lg.front[0] + 1.85) $Lg.front[1] 0.3 12 '#3A3F47'                          # Buegelfalte
}
ManagerLayer1; SaveCanvas 'textures\models\armor\netherite_layer_1.png'
ManagerLayer2; SaveCanvas 'textures\models\armor\netherite_layer_2.png'
ManagerLayer1; SaveCanvas 'textures\entity\equipment\humanoid\netherite.png'
ManagerLayer2; SaveCanvas 'textures\entity\equipment\humanoid_leggings\netherite.png'

ItemCanvas                                                                          # Headset
$script:g.DrawArc((Pn '#1B1B1B' 3), 6, 4, 20, 22, 180, 180)
Rect 3 13 6 9 '#2B2F36'; Rect 4 14 4 7 $orange; Rect 23 13 6 9 '#2B2F36'; Rect 24 14 4 7 $orange
P @(@(6, 22), @(8, 22), @(15, 27), @(14, 28)) '#1B1B1B'; Rect 14 26 4 3 '#2B2B2B'
SaveCanvas 'textures\item\netherite_helmet.png'
ItemCanvas                                                                          # Sakko
Rect 6 5 20 22 $suit; Rect 3 7 4 17 $suit; Rect 25 7 4 17 $suit
P @(@(12, 5), @(20, 5), @(16, 15)) '#F2F2F2'; Rect 15 6 2 12 '#C62828'; Rect 14.5 5 3 2 '#9E1F1F'
P @(@(12, 5), @(16, 15), @(10, 10)) $suitD; P @(@(20, 5), @(16, 15), @(22, 10)) $suitD
Rect 20 8 2 2 $orange; Rect 15.5 19 1 1 '#8A8F96'; Rect 15.5 22 1 1 '#8A8F96'
Rect 3 23 4 2 '#F2F2F2'; Rect 25 23 4 2 '#F2F2F2'
SaveCanvas 'textures\item\netherite_chestplate.png'
ItemCanvas                                                                          # Anzughose
Rect 8 4 16 3 '#111111'; Rect 15 4 2 3 $silver
Rect 8 7 16 6 $suit; Rect 8 13 7 15 $suit; Rect 17 13 7 15 $suit
Rect 11 9 1 19 '#3A3F47'; Rect 20 9 1 19 '#3A3F47'
SaveCanvas 'textures\item\netherite_leggings.png'
ItemCanvas                                                                          # Lederschuhe
foreach ($ox in 2, 17) {
    Rect $ox 16 7 6 '#141414'; Rect $ox 21 13 5 '#141414'; Rect ($ox + 9) 22 4 3 '#1E1E1E'
    Rect $ox 26 13 1.5 '#3A2A1E'; Rect ($ox + 2) 18 4 1 '#5A5F66'; Rect ($ox + 8) 22 2 1 '#5A5F66'
}
SaveCanvas 'textures\item\netherite_boots.png'

# =============== Werkbank -> Packstation ===============
$bench = '#C9A46E'; $benchD = '#A9844F'
NewCanvas 16 16 4 2                                                                   # Arbeitsplatte
Rect 0 0 16 16 $bench; Outline @(0, 0, 16, 16) $benchD 0.6
Rect 1 1 8.5 8.5 '#2E7D5B'                                                          # Schneidematte
for ($k = 1; $k -lt 4; $k++) { Rect (1 + $k * 2.1) 1 0.15 8.5 '#4F9F7C'; Rect 1 (1 + $k * 2.1) 8.5 0.15 '#4F9F7C' }
Rect 2.5 3 5 4.5 $cardC; Rect 4.6 3 0.8 4.5 $tapeC                                  # Karton auf der Matte
Rect 10.5 1.5 4.5 3.5 $navy; $script:g.FillEllipse((Br '#A06C3A'), 44, 6, 14, 14); $script:g.FillEllipse((Br '#F5C400'), 49, 11, 4, 4)   # Abroller
Rect 10.5 7 4 1 '#9EA4AA'; Rect 10.5 8.2 4 1 '#9EA4AA'                              # Schere
$script:g.DrawEllipse((Pn $orange 2), 56, 26, 6, 6); $script:g.DrawEllipse((Pn $orange 2), 56, 34, 6, 6)
Rect 1 11 9 4 '#F4F4F4'; Rect 1.6 11.8 6 0.5 '#7A7A7A'; Rect 1.6 13 4 0.5 '#7A7A7A'   # Lieferschein
Smile (13 * 4) (13.2 * 4) 14 2
SaveCanvas 'textures\block\crafting_table_top.png'
NewCanvas 16 16 4 2                                                                   # Front
Rect 0 0 16 16 $navy; Rect 0 0 16 2 $bench; Outline @(0, 2, 16, 14) $navyD 0.5
FitText 'PACKSTATION' $white 32 18 58 10
Smile 32 28 30 3
Rect 1.5 9 6 6 $navyL; Rect 8.5 9 6 6 $navyL
Rect 3.5 11.5 2 0.6 $silver; Rect 10.5 11.5 2 0.6 $silver
SaveCanvas 'textures\block\crafting_table_front.png'
NewCanvas 16 16 4 2                                                                   # Seite: Regal mit Material
Rect 0 0 16 16 $navy; Rect 0 0 16 2 $bench
Rect 1 3 14 5.5 '#141C28'; Rect 1 9.5 14 5.5 '#141C28'; Rect 1 8.5 14 1 $navyL
Rect 1.5 4.5 4 4 $cardC; Rect 6 5.5 3.5 3 '#BB8E57'
$script:g.FillEllipse((Br '#A06C3A'), 42, 20, 13, 13); $script:g.FillEllipse((Br $navyD), 46, 24, 5, 5)
Rect 1.5 11 6 4 '#F2F2F2'; Rect 1.5 12.5 6 0.4 '#CFCFCF'
Rect 8.5 11.5 5 3.5 $cardC; Rect 10.6 11.5 0.8 3.5 $tapeC
SaveCanvas 'textures\block\crafting_table_side.png'

# =============== Amboss -> Paketwaage (neues 3D-Modell) ===============
NewCanvas 16 16 4 2                                                                   # Gehaeuse-Textur
Rect 0 0 16 8 '#4A4F55'; Rect 0 0 16 0.5 '#6A7178'
for ($k = 0; $k -lt 5; $k++) { Rect (2 + $k * 2.6) 3 1.4 0.5 '#33373D'; Rect (2 + $k * 2.6) 4.5 1.4 0.5 '#33373D' }
Rect 0 7.5 16 0.5 $orange
Rect 0 8 8 4 '#0E1410'; Rect 0.3 8.3 7.4 3.4 '#16241A'                              # Display
FitText '2.40 kg' '#5CFF7A' 16 40 28 11
Rect 8 8 8 4 $navy; Smile 48 42 18 2
Rect 0 12 16 4 '#2A2D32'
SaveCanvas 'textures\block\anvil.png'
function ScaleTop($rel, $wear) {
    NewCanvas 16 16 4 2
    Rect 0 0 16 16 '#B9BEC4'
    for ($k = 1; $k -lt 8; $k++) { Rect ($k * 2) 0 0.15 16 '#A3A9AF'; Rect 0 ($k * 2) 16 0.15 '#A3A9AF' }
    Outline @(0, 0, 16, 16) $orange 0.8
    Smile 32 34 22 3
    FitText 'max 50 kg' '#4A4F55' 32 50 40 9
    if ($wear -ge 1) { $script:g.DrawLine((Pn '#7E848A' 1.5), 8, 12, 26, 20); $script:g.DrawLine((Pn '#7E848A' 1.5), 40, 46, 56, 40); $script:g.DrawLine((Pn '#7E848A' 1), 12, 50, 20, 56) }
    if ($wear -ge 2) {
        $script:g.FillEllipse((Br '#8F959B'), 10, 34, 9, 7); $script:g.FillEllipse((Br '#8F959B'), 44, 12, 8, 6)
        $script:g.DrawLines((Pn '#3A3F45' 1.5), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF 50, 26), (New-Object System.Drawing.PointF 44, 32), (New-Object System.Drawing.PointF 47, 38), (New-Object System.Drawing.PointF 40, 46)))
    }
    SaveCanvas $rel
}
ScaleTop 'textures\block\anvil_top.png' 0
ScaleTop 'textures\block\chipped_anvil_top.png' 1
ScaleTop 'textures\block\damaged_anvil_top.png' 2

function Face($uv, $tex, $extra = @{}) { $o = [ordered]@{ uv = $uv; texture = $tex }; foreach ($k in $extra.Keys) { $o[$k] = $extra[$k] }; $o }
$hull = @(0, 0, 16, 3)
$scaleEls = @(
    [ordered]@{ __comment = 'Sockel'; from = @(1, 0, 1); to = @(15, 3, 15); faces = [ordered]@{
        down = (Face @(0, 12, 16, 16) '#body' @{ cullface = 'down' }); north = (Face $hull '#body'); south = (Face $hull '#body'); east = (Face $hull '#body'); west = (Face $hull '#body') } }
    [ordered]@{ __comment = 'Wiegeplatte'; from = @(0, 3, 0); to = @(16, 4.5, 16); faces = [ordered]@{
        up = (Face @(0, 0, 16, 16) '#top'); down = (Face @(0, 12, 16, 16) '#body')
        north = (Face @(0, 6, 16, 7.5) '#body'); south = (Face @(0, 6, 16, 7.5) '#body'); east = (Face @(0, 6, 16, 7.5) '#body'); west = (Face @(0, 6, 16, 7.5) '#body') } }
    [ordered]@{ __comment = 'Saeule'; from = @(7, 4.5, 13.5); to = @(9, 10, 15); faces = [ordered]@{
        north = (Face @(6, 0, 8, 5.5) '#body'); south = (Face @(6, 0, 8, 5.5) '#body'); east = (Face @(6, 0, 7.5, 5.5) '#body'); west = (Face @(6, 0, 7.5, 5.5) '#body') } }
    [ordered]@{ __comment = 'Display'; from = @(3, 10, 12.5); to = @(13, 15, 15.5); faces = [ordered]@{
        north = (Face @(0, 8, 8, 12) '#body'); south = (Face @(8, 8, 16, 12) '#body')
        east = (Face @(0, 0, 3, 5) '#body'); west = (Face @(0, 0, 3, 5) '#body'); up = (Face @(0, 0, 10, 3) '#body'); down = (Face @(0, 0, 10, 3) '#body') } }
)
$anvilModel = [ordered]@{
    parent   = 'block/block'
    textures = [ordered]@{ particle = 'block/anvil'; body = 'block/anvil' }
    display  = [ordered]@{
        fixed    = [ordered]@{ rotation = @(0, 90, 0); translation = @(0, 0, 0); scale = @(0.5, 0.5, 0.5) }
        on_shelf = [ordered]@{ rotation = @(0, 90, 0); translation = @(0, 0, 0); scale = @(1, 1, 1) }
    }
    elements = $scaleEls
}
$bm = Join-Path $AssetDir 'models\block'
New-Item -ItemType Directory -Force $bm | Out-Null
[System.IO.File]::WriteAllText((Join-Path $bm 'template_anvil.json'), ($anvilModel | ConvertTo-Json -Depth 12), $utf8)

# =============== Lesepult -> Kundenservice-Schalter ===============
# UV-Bereiche wie im Vanilla-Modell: base (Bodenplatte), front (Saeule vorne/hinten), sides (Pult + Saeulenseiten), top (Pultflaeche)
NewCanvas 16 16 4 2
Rect 0 0 16 16 $navy; Outline @(0.5, 0.5, 15, 15) $orange 0.5
Rect 0 6 16 2 $navyD; Rect 0 7.5 16 0.5 $orange; Rect 0 14 16 2 $navyD; Rect 0 15.5 16 0.5 $orange
SaveCanvas 'textures\block\lectern_base.png'
NewCanvas 16 16 4 2
Rect 0 0 8 13 $navy; Outline @(0, 0, 8, 13) $navyL 0.4
$script:g.FillEllipse((Br $prime), 8, 6, 16, 16); Rect 3.75 2.6 0.5 0.5 $white; Rect 3.75 3.4 0.5 1.8 $white   # Info-Symbol
FitText 'SERVICE' $white 16 30 28 9
Smile 16 42 18 2
Rect 8 3 8 13 $navy; Outline @(8, 3, 8, 13) $navyL 0.4; Smile 48 36 16 2
SaveCanvas 'textures\block\lectern_front.png'
NewCanvas 16 16 4 2
Rect 0 0 16 4 $orange; FitText 'KUNDENSERVICE' $navy 32 8 60 9
Rect 0 4 16 4 $navy; Rect 0 7.5 16 0.5 $orange
Rect 0 8 16 8 $navy; Rect 2 8 0.6 8 $navyL; Rect 13.4 8 0.6 8 $navyL
SaveCanvas 'textures\block\lectern_sides.png'
NewCanvas 16 16 4 2
Rect 0 0 16 16 '#D7DBDF'; Outline @(0, 0, 16, 16) '#9EA4AA' 0.6
Rect 1.5 1.5 13 0.4 '#C2C7CC'
Smile 52 50 14 2
SaveCanvas 'textures\block\lectern_top.png'

# =============== Namen ergaenzen ===============
function AddLang($file, $entries) {
    $p = Join-Path $AssetDir "lang\$file"
    $obj = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    foreach ($k in $entries.Keys) { $obj | Add-Member -NotePropertyName $k -NotePropertyValue $entries[$k] -Force }
    $json = ($obj | ConvertTo-Json -Depth 3).Replace('#ue#', [string][char]0xFC).Replace('#ae#', [string][char]0xE4).Replace('#oe#', [string][char]0xF6).Replace('#ss#', [string][char]0xDF)
    [System.IO.File]::WriteAllText($p, $json, $utf8)
}
$deColors = [ordered]@{ white = 'Wei#ss#e'; orange = 'Orange'; magenta = 'Magenta'; light_blue = 'Hellblaue'; yellow = 'Gelbe'; lime = 'Hellgr#ue#ne'; pink = 'Rosa'; gray = 'Graue'; light_gray = 'Hellgraue'; cyan = 'T#ue#rkise'; purple = 'Violette'; blue = 'Blaue'; brown = 'Braune'; green = 'Gr#ue#ne'; red = 'Rote'; black = 'Schwarze' }
$enColors = [ordered]@{ white = 'White'; orange = 'Orange'; magenta = 'Magenta'; light_blue = 'Light Blue'; yellow = 'Yellow'; lime = 'Lime'; pink = 'Pink'; gray = 'Gray'; light_gray = 'Light Gray'; cyan = 'Cyan'; purple = 'Purple'; blue = 'Blue'; brown = 'Brown'; green = 'Green'; red = 'Red'; black = 'Black' }
$de = [ordered]@{
    'block.minecraft.chest' = 'PrimeBlock Lagerbox'; 'container.chest' = 'PrimeBlock Lagerbox'; 'container.chestDouble' = 'Gro#ss#e PrimeBlock Lagerbox'
    'block.minecraft.barrel' = 'PrimeBlock Paketstapel'; 'container.barrel' = 'PrimeBlock Paketstapel'
    'block.minecraft.shulker_box' = 'PrimeBlock Versandbox'; 'container.shulkerBox' = 'PrimeBlock Versandbox'
    'item.minecraft.map' = 'PrimeBlock Routenplan (leer)'; 'item.minecraft.filled_map' = 'PrimeBlock Routenplan'
    'item.minecraft.writable_book' = 'PrimeBlock Klemmbrett'; 'item.minecraft.written_book' = 'PrimeBlock Lieferliste'
    'item.minecraft.elytra' = 'PrimeBlock Drohnenfl#ue#gel'
    'item.minecraft.netherite_helmet' = 'PrimeBlock Manager-Headset'; 'item.minecraft.netherite_chestplate' = 'PrimeBlock Manager-Sakko'
    'item.minecraft.netherite_leggings' = 'PrimeBlock Anzughose'; 'item.minecraft.netherite_boots' = 'PrimeBlock Lederschuhe'
    'block.minecraft.crafting_table' = 'PrimeBlock Packstation'
    'block.minecraft.anvil' = 'PrimeBlock Paketwaage'; 'block.minecraft.chipped_anvil' = 'Zerkratzte PrimeBlock Paketwaage'; 'block.minecraft.damaged_anvil' = 'Besch#ae#digte PrimeBlock Paketwaage'
    'block.minecraft.lectern' = 'PrimeBlock Kundenservice-Schalter'
}
$en = [ordered]@{
    'block.minecraft.chest' = 'PrimeBlock Storage Box'; 'container.chest' = 'PrimeBlock Storage Box'; 'container.chestDouble' = 'Large PrimeBlock Storage Box'
    'block.minecraft.barrel' = 'PrimeBlock Parcel Stack'; 'container.barrel' = 'PrimeBlock Parcel Stack'
    'block.minecraft.shulker_box' = 'PrimeBlock Shipping Box'; 'container.shulkerBox' = 'PrimeBlock Shipping Box'
    'item.minecraft.map' = 'PrimeBlock Route Plan (empty)'; 'item.minecraft.filled_map' = 'PrimeBlock Route Plan'
    'item.minecraft.writable_book' = 'PrimeBlock Clipboard'; 'item.minecraft.written_book' = 'PrimeBlock Delivery List'
    'item.minecraft.elytra' = 'PrimeBlock Drone Wings'
    'item.minecraft.netherite_helmet' = 'PrimeBlock Manager Headset'; 'item.minecraft.netherite_chestplate' = 'PrimeBlock Manager Jacket'
    'item.minecraft.netherite_leggings' = 'PrimeBlock Suit Trousers'; 'item.minecraft.netherite_boots' = 'PrimeBlock Dress Shoes'
    'block.minecraft.crafting_table' = 'PrimeBlock Packing Station'
    'block.minecraft.anvil' = 'PrimeBlock Parcel Scale'; 'block.minecraft.chipped_anvil' = 'Scratched PrimeBlock Parcel Scale'; 'block.minecraft.damaged_anvil' = 'Damaged PrimeBlock Parcel Scale'
    'block.minecraft.lectern' = 'PrimeBlock Service Counter'
}
foreach ($k in $deColors.Keys) { $de["block.minecraft.${k}_shulker_box"] = "$($deColors[$k]) PrimeBlock Versandbox"; $en["block.minecraft.${k}_shulker_box"] = "$($enColors[$k]) PrimeBlock Shipping Box" }
AddLang 'de_de.json' $de
AddLang 'en_us.json' $en
