# Dot-sourced aus extras.ps1: Villager als Pixel-Art in Vanilla-Aufloesung (64x64, 16 Pixel pro Block).
# Abwechslung entsteht aus Farbstufen pro Pixel statt aus hoher Aufloesung.
# ACHTUNG: PowerShell-Variablen ignorieren Gross/Kleinschreibung.

function Shade($hex, $f) {
    $c0 = C $hex
    '#{0:X2}{1:X2}{2:X2}' -f [int][Math]::Min(255, $c0.R * $f), [int][Math]::Min(255, $c0.G * $f), [int][Math]::Min(255, $c0.B * $f)
}
function FitText($str, $hex, $cx, $cy, $maxW, $maxSize) {
    $size = $maxSize
    do {
        $fnt = New-Object System.Drawing.Font 'Arial', ([single]$size), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
        $tw = $script:g.MeasureString($str, $fnt).Width; $size -= 0.5
    } while ($tw -gt $maxW -and $size -gt 4)
    $sz = $script:g.MeasureString($str, $fnt)
    $script:g.DrawString($str, $fnt, (Br $hex), [single]($cx - $sz.Width / 2), [single]($cy - $sz.Height / 2))
}

# --- Pixel-Werkzeuge ---
function PixelCanvas($seed) {
    NewCanvas 64 64 1
    $script:g.SmoothingMode = 'None'; $script:g.PixelOffsetMode = 'None'
    $script:rng = New-Object System.Random $seed
}
function Dot($x, $y, $hex) { $script:cv.SetPixel([int]$x, [int]$y, (C $hex)) }
function HL($x, $y, $len, $hex) { for ($i = 0; $i -lt $len; $i++) { Dot ($x + $i) $y $hex } }
function VL($x, $y, $len, $hex) { for ($i = 0; $i -lt $len; $i++) { Dot $x ($y + $i) $hex } }
function Ramp($hex) { @((Shade $hex 0.66), (Shade $hex 0.82), $hex, (Shade $hex 1.13), (Shade $hex 1.26)) }
# Fuellt ein Rechteck mit Farbstufen: oben heller, unten dunkler, Rand dunkler, dazu zufaellige Flecken
function Cloth($x0, $y0, $wd, $ht, $hex, $grain = 0.85) {
    $r = Ramp $hex
    for ($yy = 0; $yy -lt $ht; $yy++) {
        $vert = if ($ht -gt 1) { 0.6 - 1.2 * $yy / ($ht - 1) } else { 0 }
        for ($xx = 0; $xx -lt $wd; $xx++) {
            $edge = if ($xx -eq 0 -or $xx -eq $wd - 1) { -0.6 } else { 0 }
            $n = ($script:rng.NextDouble() * 2 - 1) * $grain
            $idx = [int][Math]::Round(2 + $vert + $edge + $n)
            Dot ($x0 + $xx) ($y0 + $yy) $r[[Math]::Max(0, [Math]::Min(4, $idx))]
        }
    }
}
function ClothF($f, $hex, $grain = 0.85) { Cloth $f[0] $f[1] $f[2] $f[3] $hex $grain }
function ClothRows($f, $r0, $r1, $hex, $grain = 0.85) { Cloth $f[0] ($f[1] + $r0) $f[2] ($r1 - $r0) $hex $grain }
function ClothSides($Fb, $r0, $r1, $hex, $grain = 0.85) { foreach ($kk in 'right', 'front', 'left', 'back') { ClothRows $Fb[$kk] $r0 $r1 $hex $grain } }
# Pixelbild aus Zeichenketten, '#' = Farbe
function Sprite($x, $y, $rows, $hex) {
    for ($ry = 0; $ry -lt $rows.Count; $ry++) { for ($rx = 0; $rx -lt $rows[$ry].Length; $rx++) { if ($rows[$ry][$rx] -eq '#') { Dot ($x + $rx) ($y + $ry) $hex } } }
}

$pxSkin = '#BD8B67'; $pxHair = '#3B2A20'; $pxNavy = '#25344A'; $pxPants = '#454A52'; $pxLeather = '#4A3426'; $pxShoe = '#232326'
$logoSmile = @('#...#', '.###.')

# ===================== Grunduniform =====================
PixelCanvas 4711
$Hh = Faces 0 0 8 10 8
foreach ($kk in 'right', 'front', 'left', 'back') { ClothF $Hh[$kk] $pxSkin 0.7 }
ClothF $Hh.bottom (Shade $pxSkin 0.75) 0.5
ClothF $Hh.top $pxNavy 0.8
ClothSides $Hh 0 3 $pxNavy 0.8
foreach ($kk in 'right', 'front', 'left', 'back') { HL $Hh[$kk][0] ($Hh[$kk][1] + 2) 8 '#141C28' }   # Kappenband
$ct = $Hh.top; Dot ($ct[0] + 3) ($ct[1] + 3) '#3D5273'; Dot ($ct[0] + 4) ($ct[1] + 4) '#3D5273'; Dot ($ct[0] + 3) ($ct[1] + 4) '#141C28'
# Gesicht
$fx = $Hh.front[0]; $fy = $Hh.front[1]
HL $fx ($fy + 3) 8 '#8E5F45'                                                     # Schatten der Kappe
HL ($fx + 1) ($fy + 4) 2 $pxHair; HL ($fx + 5) ($fy + 4) 2 $pxHair; HL ($fx + 3) ($fy + 4) 2 '#5A4030'   # Augenbrauen
Dot ($fx + 1) ($fy + 5) '#F4F1E8'; Dot ($fx + 2) ($fy + 5) '#2E7D32'; Dot ($fx + 5) ($fy + 5) '#2E7D32'; Dot ($fx + 6) ($fy + 5) '#F4F1E8'
Dot ($fx + 1) ($fy + 6) '#C77F68'; Dot ($fx + 6) ($fy + 6) '#C77F68'; Dot ($fx + 0) ($fy + 6) '#B8846A'; Dot ($fx + 7) ($fy + 6) '#B8846A'   # Wangen
Dot ($fx + 2) ($fy + 8) '#6E3B2C'; Dot ($fx + 5) ($fy + 8) '#6E3B2C'             # Mund neben der Nase
HL ($fx + 1) ($fy + 9) 6 '#94674D'                                               # Kinn
Sprite ($fx + 2) ($fy + 0) $logoSmile '#FF9900'
# Haare
$hb = $Hh.back; Cloth $hb[0] ($hb[1] + 3) 8 4 $pxHair 1.0; HL $hb[0] ($hb[1] + 7) 8 '#8E5F45'
$hr = $Hh.right; Cloth $hr[0] ($hr[1] + 3) 5 2 $pxHair 1.0; VL ($hr[0] + 5) ($hr[1] + 4) 2 '#94674D'
$hl2 = $Hh.left; Cloth ($hl2[0] + 3) ($hl2[1] + 3) 5 2 $pxHair 1.0; VL ($hl2[0] + 2) ($hl2[1] + 4) 2 '#94674D'
# Nase
$Nn = Faces 24 0 2 4 2
foreach ($kk in 'right', 'front', 'left', 'back', 'top') { ClothF $Nn[$kk] '#C69473' 0.6 }
ClothF $Nn.bottom '#8E5F45' 0.3
$nf = $Nn.front; Dot $nf[0] ($nf[1] + 3) '#7C5038'; Dot ($nf[0] + 1) ($nf[1] + 3) '#7C5038'

# Hemd + Hose (Jacket-Layer)
$Jj = Faces 0 38 8 20 6
ClothSides $Jj 0 11 $pxNavy; ClothF $Jj.top $pxNavy
ClothSides $Jj 11 12 $pxLeather 0.5
ClothSides $Jj 12 20 $pxPants; ClothF $Jj.bottom (Shade $pxPants 0.8) 0.5
ClothF (Faces 16 20 8 12 6).front '#141C28' 0.4
$jx = $Jj.front[0]; $jy = $Jj.front[1]
# Kragen, Knopfleiste, Tasche, Namensschild
HL ($jx + 3) $jy 2 $pxSkin; Dot ($jx + 2) $jy '#3D5273'; Dot ($jx + 5) $jy '#3D5273'; Dot ($jx + 3) ($jy + 1) '#3D5273'; Dot ($jx + 4) ($jy + 1) '#3D5273'
VL ($jx + 3) ($jy + 2) 9 '#141C28'
foreach ($by in 2, 4, 6, 8, 10) { Dot ($jx + 4) ($jy + $by) '#9EA4AA' }
HL ($jx + 5) ($jy + 2) 2 '#3D5273'; Dot ($jx + 5) ($jy + 3) '#141C28'; Dot ($jx + 6) ($jy + 3) '#FF9900'; HL ($jx + 5) ($jy + 4) 2 '#141C28'
HL ($jx + 1) ($jy + 2) 2 '#E8E8E8'
Dot ($jx + 1) ($jy + 9) '#141C28'; Dot ($jx + 2) ($jy + 8) '#141C28'; Dot ($jx + 6) ($jy + 9) '#141C28'; Dot ($jx + 5) ($jy + 8) '#141C28'   # Falten
# Guertel
foreach ($kk in 'right', 'left', 'back') { Dot ($Jj[$kk][0] + 1) ($Jj[$kk][1] + 11) $pxPants; Dot ($Jj[$kk][0] + $Jj[$kk][2] - 2) ($Jj[$kk][1] + 11) $pxPants }
HL ($jx + 3) ($jy + 11) 2 '#C9CDD2'; Dot ($jx + 1) ($jy + 11) $pxPants; Dot ($jx + 6) ($jy + 11) $pxPants
# Hose vorne
VL ($jx + 3) ($jy + 12) 8 '#23262B'; VL ($jx + 4) ($jy + 14) 6 '#2F3339'
Dot ($jx + 0) ($jy + 13) '#2F3339'; Dot ($jx + 1) ($jy + 14) '#2F3339'; Dot ($jx + 7) ($jy + 13) '#2F3339'; Dot ($jx + 6) ($jy + 14) '#2F3339'
HL ($jx + 1) ($jy + 16) 2 '#5A6069'; HL ($jx + 5) ($jy + 17) 2 '#5A6069'
HL $jx ($jy + 19) 8 '#2A2D32'
# Seiten
foreach ($kk in 'right', 'left') {
    $sf = $Jj[$kk]
    VL ($sf[0] + 3) ($sf[1] + 1) 9 '#141C28'
    HL ($sf[0] + 1) ($sf[1] + 14) 4 '#5A6069'; HL ($sf[0] + 1) ($sf[1] + 17) 4 '#2A2D32'; VL ($sf[0] + 1) ($sf[1] + 15) 2 '#2A2D32'; VL ($sf[0] + 4) ($sf[1] + 15) 2 '#2A2D32'   # Cargotasche
    HL $sf[0] ($sf[1] + 19) 6 '#2A2D32'
}
# Ruecken: Passe, PB-Logo, Smile, Gesaesstaschen
$bx0 = $Jj.back[0]; $by0 = $Jj.back[1]
HL $bx0 ($by0 + 1) 8 '#141C28'
Sprite ($bx0 + 0) ($by0 + 3) @('###.###', '#.#.#.#', '###.##.', '#...#.#', '#...###') '#F2F2F2'
Sprite ($bx0 + 1) ($by0 + 9) $logoSmile '#FF9900'
VL ($bx0 + 3) ($by0 + 12) 8 '#23262B'
foreach ($px0 in 1, 5) { HL ($bx0 + $px0) ($by0 + 13) 2 '#5A6069'; HL ($bx0 + $px0) ($by0 + 15) 2 '#2A2D32' }
HL $bx0 ($by0 + 19) 8 '#2A2D32'

# Arme
$Aa = Faces 44 22 4 8 4
foreach ($kk in 'right', 'front', 'left', 'back', 'top') { ClothF $Aa[$kk] $pxNavy }
ClothF $Aa.bottom '#141C28' 0.4
foreach ($kk in 'right', 'front', 'left', 'back') { $af = $Aa[$kk]; HL $af[0] ($af[1] + 1) 4 '#1A2433'; Dot ($af[0] + 1) ($af[1] + 5) '#141C28'; Dot ($af[0] + 2) ($af[1] + 6) '#141C28' }
$Bb = Faces 40 38 8 4 4
foreach ($kk in 'right', 'front', 'left', 'back', 'top') { ClothF $Bb[$kk] $pxNavy }
ClothF $Bb.bottom '#141C28' 0.4
$bfr = $Bb.front
foreach ($hx in 0, 6) {
    Cloth ($bfr[0] + $hx) $bfr[1] 2 4 $pxSkin 0.5
    foreach ($fy2 in 1, 3) { Dot ($bfr[0] + $hx) ($bfr[1] + $fy2) '#8E5F45'; Dot ($bfr[0] + $hx + 1) ($bfr[1] + $fy2) '#8E5F45' }     # Finger
}
VL ($bfr[0] + 2) $bfr[1] 4 '#141C28'; VL ($bfr[0] + 5) $bfr[1] 4 '#141C28'           # Manschetten
Dot ($bfr[0] + 3) ($bfr[1] + 1) '#141C28'; Dot ($bfr[0] + 4) ($bfr[1] + 2) '#141C28'  # Arm ueber Arm

# Beine und Schuhe
$Ll = Faces 0 22 4 12 4
ClothSides $Ll 0 10 $pxPants; ClothF $Ll.top $pxPants
ClothSides $Ll 10 12 $pxShoe 0.5
ClothF $Ll.bottom '#101012' 0.3
foreach ($kk in 'right', 'front', 'left', 'back') { HL $Ll[$kk][0] ($Ll[$kk][1] + 11) 4 '#5C4230'; HL $Ll[$kk][0] ($Ll[$kk][1] + 9) 4 '#2A2D32' }
$lf = $Ll.front; HL ($lf[0] + 1) ($lf[1] + 10) 2 '#4A4A4F'; Dot ($lf[0] + 1) ($lf[1] + 9) '#9A9A9A'; Dot ($lf[0] + 2) ($lf[1] + 9) '#9A9A9A'   # Kappe, Schnuersenkel
SaveCanvas 'textures\entity\villager\villager.png'

# Biom-Overlays bleiben leer, damit jeder Villager die Uniform traegt
foreach ($tn in 'desert', 'jungle', 'plains', 'savanna', 'snow', 'swamp', 'taiga') { NewCanvas 64 64 1; SaveCanvas "textures\entity\villager\type\$tn.png" }

# ===================== Berufe (Schrift passt bei 8 Pixeln nicht, daher Farbe + Symbol auf dem Ruecken) =====================
$icons = @{
    truck  = @('.###.', '.###.', '####.', '#####', '.#.#.')
    anchor = @('..#..', '.###.', '..#..', '#.#.#', '.###.')
    back   = @('..#..', '.##..', '#####', '.##.#', '..###')
    parcel = @('#####', '#.#.#', '#####', '#.#.#', '#####')
    info   = @('..#..', '.....', '.##..', '..#..', '.###.')
    pin    = @('.###.', '#...#', '#...#', '.#.#.', '..#..')
    cross  = @('.###.', '.###.', '#####', '.###.', '.###.')
    shield = @('#####', '#####', '#####', '.###.', '..#..')
    star   = @('..#..', '#####', '.###.', '.###.', '#...#')
    wrench = @('#...#', '#####', '.###.', '..#..', '..#..')
    boxes  = @('.###.', '.###.', '.....', '##.##', '##.##')
    tape   = @('.###.', '#...#', '#.#.#', '#...#', '.####')
    fork   = @('#.#.#', '#.#.#', '#####', '..#..', '..#..')
    learn  = @('#....', '#....', '#....', '#....', '#####')
}
$jobs = @(
    @{ p = 'farmer';        cap = '#F08A00'; vest = '#F07F00'; mark = '#2A1600'; icon = 'truck';  hivis = $true }
    @{ p = 'fisherman';     cap = '#0E7C86'; vest = '#14A3B0'; mark = '#EAF8FA'; icon = 'anchor'; whistle = $true }
    @{ p = 'shepherd';      cap = '#D45D9E'; vest = '#E87BB6'; mark = '#FFFFFF'; icon = 'back' }
    @{ p = 'fletcher';      cap = '#1AA7EC'; vest = '#4FC3F7'; mark = '#0D2A3A'; icon = 'parcel' }
    @{ p = 'librarian';     cap = '#6A3FA0'; vest = '#8E5CC9'; mark = '#FFFFFF'; icon = 'info'; glasses = $true }
    @{ p = 'cartographer';  cap = '#2E7D32'; vest = '#43A047'; mark = '#FFFFFF'; icon = 'pin'; clipboard = $true }
    @{ p = 'cleric';        cap = '#E6E6E6'; vest = '#E6E6E6'; mark = '#C62828'; icon = 'cross'; medic = $true }
    @{ p = 'armorer';       cap = '#242424'; vest = '#2E2E2E'; mark = '#FFD54F'; icon = 'shield'; guard = $true }
    @{ p = 'weaponsmith';   cap = $null;     vest = '#2B2F36'; mark = '#F2F2F2'; icon = 'star'; suit = $true }
    @{ p = 'toolsmith';     cap = '#E89F1E'; vest = '#F2BC2B'; mark = '#2A1F00'; icon = 'wrench'; belt = $true; hivis = $true }
    @{ p = 'mason';         cap = '#6E6E6E'; vest = '#8D8D8D'; mark = '#F2F2F2'; icon = 'boxes'; hivis = $true }
    @{ p = 'leatherworker'; cap = '#6D4C41'; vest = '#A9743F'; mark = '#F2E2C4'; icon = 'tape'; apron = $true }
    @{ p = 'butcher';       cap = '#E6E6E6'; vest = '#E6E6E6'; mark = '#C62828'; icon = 'fork'; apron = $true; stains = $true }
    @{ p = 'nitwit';        cap = '#7CB342'; vest = '#9CCC65'; mark = '#2B3D12'; icon = 'learn'; trainee = $true }
)
$seedNo = 900
foreach ($job in $jobs) {
    $seedNo += 37
    PixelCanvas $seedNo
    $vc = $job.vest; $vd = Shade $vc 0.62; $vl = Shade $vc 1.2
    $Hh = Faces 0 0 8 10 8; $Jj = Faces 0 38 8 20 6
    $jx = $Jj.front[0]; $jy = $Jj.front[1]; $bx0 = $Jj.back[0]; $by0 = $Jj.back[1]

    # Kappe
    if ($job.cap) {
        $cd = Shade $job.cap 0.6
        ClothF $Hh.top $job.cap 0.8; ClothSides $Hh 0 3 $job.cap 0.8
        foreach ($kk in 'right', 'front', 'left', 'back') { HL $Hh[$kk][0] ($Hh[$kk][1] + 2) 8 $cd }
        $ct = $Hh.top; Dot ($ct[0] + 3) ($ct[1] + 3) (Shade $job.cap 1.25); Dot ($ct[0] + 4) ($ct[1] + 4) (Shade $job.cap 1.25)
        $smileCol = if ($job.p -in 'farmer', 'toolsmith') { '#25344A' } else { '#FF9900' }
        if ($job.medic) { Dot ($Hh.front[0] + 3) $Hh.front[1] '#C62828'; HL ($Hh.front[0] + 2) ($Hh.front[1] + 1) 3 '#C62828' }
        else { Sprite ($Hh.front[0] + 2) $Hh.front[1] $logoSmile $smileCol }
    }
    if ($job.glasses) {
        $gx = $Hh.front[0]; $gy = $Hh.front[1]
        # Nur seitliche Rahmen und Steg: Die Augen bleiben sichtbar, sonst wirkt es wie eine Augenbinde
        foreach ($gfr in 0, 3, 4, 7) { Dot ($gx + $gfr) ($gy + 5) '#2B2B2B' }
        foreach ($gbr in 1, 2, 5, 6) { Dot ($gx + $gbr) ($gy + 6) '#6B6B6B' }
        Dot ($Hh.right[0] + 7) ($Hh.right[1] + 5) '#2B2B2B'; Dot ($Hh.left[0]) ($Hh.left[1] + 5) '#2B2B2B'
    }

    if ($job.apron) {
        Cloth $jx ($jy + 2) 8 15 $vc 0.8
        foreach ($sx in 1, 6) { VL ($jx + $sx) $jy 2 $vc; VL ($bx0 + $sx) $by0 8 $vc }
        foreach ($kk in 'right', 'left') { HL $Jj[$kk][0] ($Jj[$kk][1] + 8) $Jj[$kk][2] $vd }
        HL ($jx + 2) ($jy + 11) 4 $vl; HL ($jx + 2) ($jy + 14) 4 $vd; VL ($jx + 2) ($jy + 12) 2 $vd; VL ($jx + 5) ($jy + 12) 2 $vd   # Tasche
        Dot ($jx + 3) ($jy + 11) '#C62828'; Dot ($jx + 4) ($jy + 10) '#D0D0D0'
        HL $jx ($jy + 16) 8 $vd
        if ($job.stains) { foreach ($st in @(@(1, 12), @(6, 15), @(5, 9), @(2, 16))) { Dot ($jx + $st[0]) ($jy + $st[1]) '#B5504A' } }
        else { VL ($jx + 3) ($jy + 2) 2 '#E2C38F'; VL ($jx + 4) ($jy + 2) 2 '#E2C38F' }
        Cloth ($bx0 + 1) ($by0 + 2) 6 6 $vc 0.6
        HL $bx0 ($by0 + 8) 8 $vd
        Sprite ($bx0 + 1) ($by0 + 2) $icons[$job.icon] $job.mark
    } else {
        # Weste: Seiten, Ruecken und zwei Vorderteile, die Knopfleiste der Uniform bleibt sichtbar
        foreach ($kk in 'right', 'left', 'back') { ClothRows $Jj[$kk] 0 11 $vc }
        Cloth $jx $jy 3 11 $vc; Cloth ($jx + 5) $jy 3 11 $vc
        VL ($jx + 2) $jy 11 $vd; VL ($jx + 5) $jy 11 $vd                               # Saum zur Oeffnung
        HL $jx ($jy + 10) 3 $vd; HL ($jx + 5) ($jy + 10) 3 $vd
        foreach ($px0 in 0, 6) { HL ($jx + $px0) ($jy + 8) 2 $vl; HL ($jx + $px0) ($jy + 9) 2 (Shade $vc 0.8) }   # Taschen
        foreach ($kk in 'right', 'left') { HL $Jj[$kk][0] ($Jj[$kk][1] + 10) $Jj[$kk][2] $vd; VL ($Jj[$kk][0] + 3) ($Jj[$kk][1] + 1) 9 (Shade $vc 0.8) }
        HL $bx0 ($by0 + 1) 8 (Shade $vc 0.72); HL $bx0 ($by0 + 10) 8 $vd
        Sprite ($bx0 + 1) ($by0 + 3) $icons[$job.icon] $job.mark

        if ($job.hivis) {
            foreach ($kk in 'right', 'left', 'back') { HL $Jj[$kk][0] ($Jj[$kk][1] + 9) $Jj[$kk][2] '#D9DDE0' }
            HL $jx ($jy + 9) 2 '#D9DDE0'; HL ($jx + 6) ($jy + 9) 2 '#D9DDE0'
            VL ($jx + 1) $jy 4 '#D9DDE0'; VL ($jx + 6) $jy 4 '#D9DDE0'
            Dot ($bx0 + 1) $by0 '#D9DDE0'; Dot ($bx0 + 6) $by0 '#D9DDE0'
        } elseif (-not $job.suit) {
            HL ($jx + 6) ($jy + 2) 2 '#F4F4F4'; Dot ($jx + 7) ($jy + 1) '#9EA4AA'           # Namensschild
        }
        if ($job.suit) {
            # Anzug: weisses Hemd, Krawatte, Revers, dunkle Hose
            Cloth ($jx + 3) $jy 2 11 '#EDEDED' 0.4
            HL ($jx + 3) $jy 2 '#FFFFFF'; VL ($jx + 3) ($jy + 1) 8 '#B3262B'; VL ($jx + 4) ($jy + 1) 7 '#C62828'
            Dot ($jx + 3) ($jy + 3) '#8E1B1B'; Dot ($jx + 4) ($jy + 5) '#8E1B1B'
            VL ($jx + 2) $jy 6 '#1A1D22'; VL ($jx + 5) $jy 6 '#1A1D22'
            Dot ($jx + 6) ($jy + 2) '#C62828'
            ClothSides $Jj 12 20 '#2A2D33' 0.6; ClothSides $Jj 11 12 '#141416' 0.3
            HL ($jx + 3) ($jy + 11) 2 '#C9CDD2'; VL ($jx + 3) ($jy + 12) 8 '#141416'; VL ($bx0 + 3) ($by0 + 12) 8 '#141416'
        }
        if ($job.guard) {
            HL ($Jj.right[0] + 1) $Jj.right[1] 4 '#D9B23C'; HL ($Jj.left[0] + 1) $Jj.left[1] 4 '#D9B23C'
            HL ($jx + 0) ($jy + 2) 2 '#FFD54F'; Dot ($jx + 0) ($jy + 3) '#D9B23C'; Dot ($jx + 1) ($jy + 3) '#8A6D00'   # Dienstmarke
        }
        if ($job.whistle) { VL ($jx + 1) $jy 3 '#F5C400'; Dot ($jx + 1) ($jy + 3) '#C9CDD2' }
        if ($job.trainee) { HL $jx ($jy + 2) 2 '#FFFFFF'; Dot $jx ($jy + 2) '#C62828'; HL $jx ($jy + 3) 2 '#C62828' }
        if ($job.medic) { Dot ($jx + 1) ($jy + 1) '#C62828'; HL ($jx + 0) ($jy + 2) 2 '#C62828'; VL ($jx + 1) ($jy + 2) 2 '#C62828' }
    }
    if ($job.belt) {
        foreach ($kk in 'right', 'front', 'left', 'back') { ClothRows $Jj[$kk] 11 12 '#6D4C33' 0.4 }
        HL ($jx + 3) ($jy + 11) 2 '#C9CDD2'
        Cloth $jx ($jy + 12) 2 2 '#5D4037' 0.4; Dot ($jx + 0) ($jy + 11) '#9E9E9E'          # Tasche mit Schraubenzieher
        Cloth ($jx + 6) ($jy + 12) 2 2 '#5D4037' 0.4; Dot ($jx + 7) ($jy + 11) '#6E6E6E'; Dot ($jx + 6) ($jy + 11) '#E53935'
    }
    if ($job.clipboard) {
        $mf = (Faces 40 38 8 4 4).front
        Cloth ($mf[0] + 2) $mf[1] 4 4 '#6D4C2F' 0.3; HL ($mf[0] + 3) ($mf[1] + 1) 2 '#F6F1E4'; HL ($mf[0] + 3) ($mf[1] + 2) 2 '#43A047'; HL ($mf[0] + 3) ($mf[1] + 3) 2 '#F6F1E4'
        HL ($mf[0] + 3) $mf[1] 2 '#9EA4AA'
    }
    SaveCanvas "textures\entity\villager\profession\$($job.p).png"
}
