# Dot-sourced aus build.ps1: Funktionen fuer "Infos auf einen Blick" (alle Texturen 16 Pixel pro Block).
# ACHTUNG: PowerShell-Variablen ignorieren Gross/Kleinschreibung; $g ist die Zeichenflaeche, $s die Skalierung.

function WJ($rel, $obj) {
    $p = Join-Path $AssetDir $rel
    New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
    [System.IO.File]::WriteAllText($p, ($obj | ConvertTo-Json -Depth 24), $utf8)
}
function Mdl($name) { [ordered]@{ model = "minecraft:$name" } }
function PixelSheet($wd, $ht, $seed) {
    NewCanvas $wd $ht 1
    $script:g.SmoothingMode = 'None'; $script:g.PixelOffsetMode = 'None'
    $script:rng = New-Object System.Random $seed
}
# Ziffern 3x5
$digits = @{
    0 = @('###', '#.#', '#.#', '#.#', '###'); 1 = @('.#.', '##.', '.#.', '.#.', '###'); 2 = @('###', '..#', '###', '#..', '###')
    3 = @('###', '..#', '.##', '..#', '###'); 4 = @('#.#', '#.#', '###', '..#', '..#'); 5 = @('###', '#..', '###', '..#', '###')
    6 = @('###', '#..', '###', '#.#', '###'); 7 = @('###', '..#', '.#.', '.#.', '.#.'); 8 = @('###', '#.#', '###', '#.#', '###')
    9 = @('###', '#.#', '###', '..#', '###')
}
function Num($x, $y, $n, $hex) {
    if ($n -ge 10) { Sprite $x $y $digits[[int][Math]::Floor($n / 10)] $hex; Sprite ($x + 4) $y $digits[[int]($n % 10)] $hex }
    else { Sprite ($x + 2) $y $digits[[int]$n] $hex }
}
$arrowUp = @('...#...', '..###..', '.#####.', '#######', '..###..', '..###..', '..###..')

# ===================== Crops: klein bis reif (nutzt die Original-Modelle) =====================
function CropStates($block, $ages, $small, $ripe) {
    $v = [ordered]@{}
    foreach ($a0 in $ages) { $v["age=$a0"] = Mdl "block/${block}_stage$small" }
    foreach ($key in $ripe.Keys) { $v["age=$key"] = Mdl "block/${block}_stage$($ripe[$key])" }
    WJ "blockstates\$block.json" ([ordered]@{ variants = $v })
}
CropStates 'wheat' (0..6) 0 @{ 7 = 7 }
CropStates 'carrots' (0..6) 0 @{ 7 = 3 }
CropStates 'potatoes' (0..6) 0 @{ 7 = 3 }
CropStates 'beetroots' (0..2) 0 @{ 3 = 3 }
CropStates 'nether_wart' (0..2) 0 @{ 3 = 2 }
CropStates 'sweet_berry_bush' (0..1) 0 @{ 2 = 2; 3 = 3 }
CropStates 'torchflower_crop' (0..1) 0 @{}
CropStates 'melon_stem' (0..7) 0 @{}
CropStates 'pumpkin_stem' (0..7) 0 @{}
$cv = [ordered]@{}
foreach ($fc in @(@('east', 270), @('north', 180), @('south', 0), @('west', 90))) {
    foreach ($a0 in 0, 1, 2) {
        $st = if ($a0 -eq 2) { 2 } else { 0 }
        $e = [ordered]@{ model = "minecraft:block/cocoa_stage$st" }
        if ($fc[1]) { $e.y = $fc[1] }
        $cv["age=$a0,facing=$($fc[0])"] = $e
    }
}
WJ 'blockstates\cocoa.json' ([ordered]@{ variants = $cv })
$pv = [ordered]@{}
foreach ($a0 in 0..4) {
    $st = if ($a0 -eq 4) { 4 } else { 0 }
    $pv["age=$a0,half=lower"] = Mdl "block/pitcher_crop_bottom_stage_$st"
    $pv["age=$a0,half=upper"] = Mdl "block/pitcher_crop_top_stage_$st"
}
WJ 'blockstates\pitcher_crop.json' ([ordered]@{ variants = $pv })

# ===================== Notenblock: Note oben als Zahl, Farbe wie das Noten-Partikel =====================
PixelSheet 80 80 301
foreach ($n in 0..24) {
    $tx = ($n % 5) * 16; $ty = [int][Math]::Floor($n / 5) * 16
    Cloth $tx $ty 16 16 '#6B4A32' 0.8
    HL $tx $ty 16 '#3D2A1C'; HL $tx ($ty + 15) 16 '#3D2A1C'; VL $tx $ty 16 '#3D2A1C'; VL ($tx + 15) $ty 16 '#3D2A1C'
    $p0 = $n / 24.0 * 2 * [Math]::PI
    $rr = [int](255 * [Math]::Max(0, [Math]::Sin($p0 + 0) * 0.65 + 0.35)); $gg = [int](255 * [Math]::Max(0, [Math]::Sin($p0 + 2.094) * 0.65 + 0.35)); $bb = [int](255 * [Math]::Max(0, [Math]::Sin($p0 + 4.189) * 0.65 + 0.35))
    $hex = '#{0:X2}{1:X2}{2:X2}' -f [Math]::Min(255, $rr + 60), [Math]::Min(255, $gg + 60), [Math]::Min(255, $bb + 60)
    HL ($tx + 3) ($ty + 3) 10 $hex; HL ($tx + 3) ($ty + 12) 10 $hex
    Num ($tx + 4) ($ty + 5) $n '#FFFFFF'
}
SaveCanvas 'textures\block\primeblock_note_numbers.png'
$mp2 = New-Object System.Collections.ArrayList
foreach ($n in 0..24) {
    $u0 = ($n % 5) * 3.2; $v0 = [Math]::Floor($n / 5) * 3.2
    $sideF = { param($cull) [ordered]@{ uv = @(0, 0, 16, 16); texture = '#side'; cullface = $cull } }
    WJ "models\block\primeblock_note_$n.json" ([ordered]@{
        parent = 'minecraft:block/block'
        textures = [ordered]@{ particle = 'minecraft:block/note_block'; side = 'minecraft:block/note_block'; top = 'minecraft:block/primeblock_note_numbers' }
        elements = @([ordered]@{ from = @(0, 0, 0); to = @(16, 16, 16); faces = [ordered]@{
            down = (& $sideF 'down'); north = (& $sideF 'north'); south = (& $sideF 'south'); west = (& $sideF 'west'); east = (& $sideF 'east')
            up = [ordered]@{ uv = @($u0, $v0, ($u0 + 3.2), ($v0 + 3.2)); texture = '#top'; cullface = 'up' } } })
    })
    [void]$mp2.Add([ordered]@{ when = [ordered]@{ note = "$n" }; apply = (Mdl "block/primeblock_note_$n") })
}
WJ 'blockstates\note_block.json' ([ordered]@{ multipart = $mp2 })

# ===================== Redstone: Signalstaerke als Zahl auf dem Staub =====================
PixelSheet 64 64 302
foreach ($n in 0..15) {
    $tx = ($n % 4) * 16; $ty = [int][Math]::Floor($n / 4) * 16
    # Dunkler Umriss, damit die Zahl auf rotem Staub lesbar bleibt
    foreach ($o in @(@(-1, 0), @(1, 0), @(0, -1), @(0, 1), @(-1, -1), @(1, 1), @(-1, 1), @(1, -1))) { Num ($tx + 4 + $o[0]) ($ty + 5 + $o[1]) $n '#141414' }
    $col = if ($n -eq 0) { '#9A9A9A' } else { '#FFFFFF' }
    Num ($tx + 4) ($ty + 5) $n $col
}
SaveCanvas 'textures\block\primeblock_redstone_numbers.png'
$rw = New-Object System.Collections.ArrayList
$sides = 'north', 'east', 'south', 'west'
[void]$rw.Add([ordered]@{ apply = (Mdl 'block/redstone_dust_dot'); when = [ordered]@{ OR = @(
    [ordered]@{ east = 'none'; north = 'none'; south = 'none'; west = 'none' }, [ordered]@{ east = 'side|up'; north = 'side|up' }, [ordered]@{ east = 'side|up'; south = 'side|up' },
    [ordered]@{ south = 'side|up'; west = 'side|up' }, [ordered]@{ north = 'side|up'; west = 'side|up' }) } })
[void]$rw.Add([ordered]@{ apply = (Mdl 'block/redstone_dust_side0'); when = [ordered]@{ north = 'side|up' } })
[void]$rw.Add([ordered]@{ apply = (Mdl 'block/redstone_dust_side_alt0'); when = [ordered]@{ south = 'side|up' } })
[void]$rw.Add([ordered]@{ apply = [ordered]@{ model = 'minecraft:block/redstone_dust_side_alt1'; y = 270 }; when = [ordered]@{ east = 'side|up' } })
[void]$rw.Add([ordered]@{ apply = [ordered]@{ model = 'minecraft:block/redstone_dust_side1'; y = 270 }; when = [ordered]@{ west = 'side|up' } })
[void]$rw.Add([ordered]@{ apply = (Mdl 'block/redstone_dust_up'); when = [ordered]@{ north = 'up' } })
[void]$rw.Add([ordered]@{ apply = [ordered]@{ model = 'minecraft:block/redstone_dust_up'; y = 90 }; when = [ordered]@{ east = 'up' } })
[void]$rw.Add([ordered]@{ apply = [ordered]@{ model = 'minecraft:block/redstone_dust_up'; y = 180 }; when = [ordered]@{ south = 'up' } })
[void]$rw.Add([ordered]@{ apply = [ordered]@{ model = 'minecraft:block/redstone_dust_up'; y = 270 }; when = [ordered]@{ west = 'up' } })
foreach ($n in 0..15) {
    $u0 = ($n % 4) * 4; $v0 = [Math]::Floor($n / 4) * 4
    WJ "models\block\primeblock_redstone_$n.json" ([ordered]@{
        ambientocclusion = $false
        textures = [ordered]@{ particle = 'minecraft:block/redstone_dust_dot'; n = 'minecraft:block/primeblock_redstone_numbers' }
        elements = @([ordered]@{ from = @(3, 0.4, 3); to = @(13, 0.4, 13); shade = $false; faces = [ordered]@{ up = [ordered]@{ uv = @($u0, $v0, ($u0 + 4), ($v0 + 4)); texture = '#n' } } })
    })
    [void]$rw.Add([ordered]@{ apply = (Mdl "block/primeblock_redstone_$n"); when = [ordered]@{ power = "$n" } })
}
WJ 'blockstates\redstone_wire.json' ([ordered]@{ multipart = $rw })

# ===================== Bienennest / Bienenstock voll: tropfender Honig =====================
function HoneyFront($rel, $base, $seed) {
    PixelSheet 16 16 $seed
    Cloth 0 0 16 16 $base 0.9
    Cloth 3 5 10 7 '#2B1A0E' 0.6                                                     # Einflugloch
    Cloth 0 0 16 4 '#F7B21B' 0.7; HL 0 0 16 '#FFD95A'; HL 0 4 16 '#E08E0B'           # Honig oben
    foreach ($dr in @(@(1, 5), @(4, 3), @(7, 8), @(10, 4), @(13, 6))) { VL $dr[0] 4 $dr[1] '#F7B21B'; VL ($dr[0] + 1) 4 ($dr[1] - 1) '#FFD95A'; Dot $dr[0] (4 + $dr[1]) '#E08E0B' }
    SaveCanvas $rel
}
HoneyFront 'textures\block\bee_nest_front_honey.png' '#B68342' 311
HoneyFront 'textures\block\beehive_front_honey.png' '#B9935A' 312

# ===================== Komposter voll: hell leuchtendes Knochenmehl =====================
PixelSheet 16 16 320
Cloth 0 0 16 16 '#EFE6C4' 0.9
foreach ($px in @(@(3, 2), @(9, 4), @(13, 2), @(5, 8), @(11, 10), @(2, 12), @(7, 13), @(14, 7))) { Dot $px[0] $px[1] '#7BD63F'; Dot ($px[0] + 1) $px[1] '#FFFFFF' }
SaveCanvas 'textures\block\composter_ready.png'

# ===================== Ackerboden: trocken hell und rissig, nass dunkel mit Wasserglanz =====================
PixelSheet 16 16 330
Cloth 0 0 16 16 '#A98A64' 0.8
foreach ($ry in 3, 7, 11, 15) { HL 0 $ry 16 '#7D6244' }
foreach ($px in @(@(2, 1), @(3, 2), @(9, 5), @(10, 6), @(5, 9), @(4, 10), @(12, 13), @(13, 14), @(14, 1))) { Dot $px[0] $px[1] '#5C4630' }
SaveCanvas 'textures\block\farmland.png'
PixelSheet 16 16 331
Cloth 0 0 16 16 '#3A2717' 0.7
foreach ($ry in 3, 7, 11, 15) { HL 0 $ry 16 '#22150B' }
foreach ($px in @(@(2, 2), @(7, 1), @(12, 2), @(4, 6), @(10, 5), @(1, 10), @(8, 9), @(14, 10), @(5, 14), @(11, 13))) { Dot $px[0] $px[1] '#5E86B8'; Dot ($px[0] + 1) $px[1] '#3F5F87' }
SaveCanvas 'textures\block\farmland_moist.png'

# ===================== Amethyst-Cluster: gross und hell, hebt sich von den Knospen ab =====================
PixelSheet 16 16 340
foreach ($c0 in @(@(7, 0, 2, 16, '#E7B8FF'), @(3, 5, 2, 11, '#C78BF0'), @(11, 3, 2, 13, '#D7A3FA'), @(5, 9, 2, 7, '#A968E0'), @(9, 8, 2, 8, '#B878EA'), @(1, 11, 2, 5, '#9958CF'), @(13, 10, 2, 6, '#A968E0'))) {
    Cloth $c0[0] $c0[1] $c0[2] $c0[3] $c0[4] 0.4
    Dot $c0[0] $c0[1] '#FFFFFF'
}
foreach ($px in @(@(7, 3), @(8, 7), @(12, 6), @(3, 8))) { Dot $px[0] $px[1] '#FFFFFF' }
SaveCanvas 'textures\block\amethyst_cluster.png'

# ===================== Richtungspfeile =====================
function ArrowTex($rel, $base, $col, $seed) {
    PixelSheet 16 16 $seed
    Cloth 0 0 16 16 $base 0.8
    HL 0 0 16 (Shade $base 0.7); HL 0 15 16 (Shade $base 0.7); VL 0 0 16 (Shade $base 0.7); VL 15 0 16 (Shade $base 0.7)
    Sprite 4 4 $arrowUp $col
    SaveCanvas $rel
}
ArrowTex 'textures\block\primeblock_machine_arrow.png' '#7A7A7A' '#FFB000' 350
ArrowTex 'textures\block\primeblock_observer_side.png' '#6A6A6A' '#E53935' 351
ArrowTex 'textures\block\primeblock_hopper_inside.png' '#3A3A3D' '#FFB000' 352

function MachineModels($block) {
    # Pfeile zeigen zur Auswurfseite (Vorderseite im Modell = Norden)
    WJ "models\block\$block.json" ([ordered]@{
        parent = 'minecraft:block/block'
        textures = [ordered]@{ particle = "minecraft:block/${block}_front"; front = "minecraft:block/${block}_front"; arrow = 'minecraft:block/primeblock_machine_arrow'; plain = 'minecraft:block/furnace_side'; bottom = 'minecraft:block/furnace_top' }
        elements = @([ordered]@{ from = @(0, 0, 0); to = @(16, 16, 16); faces = [ordered]@{
            down = [ordered]@{ texture = '#bottom'; cullface = 'down' }
            up = [ordered]@{ texture = '#arrow'; cullface = 'up' }
            north = [ordered]@{ texture = '#front'; cullface = 'north' }
            south = [ordered]@{ texture = '#plain'; cullface = 'south' }
            east = [ordered]@{ texture = '#arrow'; rotation = 90; cullface = 'east' }
            west = [ordered]@{ texture = '#arrow'; rotation = 270; cullface = 'west' } } })
    })
    WJ "models\block\${block}_vertical.json" ([ordered]@{
        parent = 'minecraft:block/cube'
        textures = [ordered]@{ particle = 'minecraft:block/furnace_top'; down = 'minecraft:block/furnace_top'; up = "minecraft:block/${block}_front_vertical"
            north = 'minecraft:block/primeblock_machine_arrow'; east = 'minecraft:block/primeblock_machine_arrow'; south = 'minecraft:block/primeblock_machine_arrow'; west = 'minecraft:block/primeblock_machine_arrow' }
    })
}
MachineModels 'dispenser'; MachineModels 'dropper'
WJ 'models\block\observer.json' ([ordered]@{
    parent = 'block/block'
    textures = [ordered]@{ bottom = 'block/observer_back'; side = 'block/primeblock_observer_side'; top = 'block/observer_top'; front = 'block/observer_front'; particle = 'block/observer_front' }
    elements = @([ordered]@{ from = @(0, 0, 0); to = @(16, 16, 16); faces = [ordered]@{
        down = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#top'; cullface = 'down' }
        up = [ordered]@{ uv = @(0, 16, 16, 0); texture = '#top'; cullface = 'up' }
        north = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#front'; cullface = 'north' }
        south = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#bottom'; cullface = 'south' }
        west = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#side'; rotation = 90; cullface = 'west' }
        east = [ordered]@{ uv = @(0, 0, 16, 16); texture = '#side'; rotation = 270; cullface = 'east' } } })
})
WJ 'models\block\primeblock_hopper_side.json' ([ordered]@{ parent = 'minecraft:block/hopper_side'; textures = [ordered]@{ inside = 'minecraft:block/primeblock_hopper_inside' } })
WJ 'blockstates\hopper.json' ([ordered]@{ variants = [ordered]@{
    'facing=down' = (Mdl 'block/hopper')
    'facing=east' = [ordered]@{ model = 'minecraft:block/primeblock_hopper_side'; y = 90 }
    'facing=north' = (Mdl 'block/primeblock_hopper_side')
    'facing=south' = [ordered]@{ model = 'minecraft:block/primeblock_hopper_side'; y = 180 }
    'facing=west' = [ordered]@{ model = 'minecraft:block/primeblock_hopper_side'; y = 270 } } })

# ===================== Werkzeuge: unter 20 % Haltbarkeit sichtbar beschaedigt =====================
PixelSheet 16 16 360
foreach ($px in @(@(11, 2), @(10, 3), @(11, 4), @(9, 5), @(8, 6), @(9, 7), @(7, 8), @(6, 9), @(7, 10), @(5, 11), @(13, 5), @(12, 6), @(4, 7), @(3, 8))) { Dot $px[0] $px[1] '#1A1A1A' }
foreach ($px in @(@(14, 1), @(14, 2), @(14, 3), @(14, 5))) { Dot $px[0] $px[1] '#E53935' }                    # rotes Warnzeichen
SaveCanvas 'textures\item\primeblock_crack.png'
function WornItem($id, $worn) {
    WJ "items\$id.json" ([ordered]@{ model = [ordered]@{
        type = 'minecraft:range_dispatch'; property = 'minecraft:damage'; normalize = $true
        entries = @([ordered]@{ threshold = 0.8; model = [ordered]@{ type = 'minecraft:model'; model = "minecraft:item/$worn" } })
        fallback = [ordered]@{ type = 'minecraft:model'; model = "minecraft:item/$id" } } })
}
foreach ($mat in 'wooden', 'stone', 'copper', 'iron', 'golden', 'diamond', 'netherite') {
    foreach ($kind in 'pickaxe', 'axe', 'shovel', 'hoe', 'sword') {
        $id = "${mat}_$kind"
        if ($id -eq 'diamond_sword') { continue }
        WJ "models\item\primeblock_worn_$id.json" ([ordered]@{ parent = 'minecraft:item/handheld'; textures = [ordered]@{ layer0 = "minecraft:item/$id"; layer1 = 'minecraft:item/primeblock_crack' } })
        WornItem $id "primeblock_worn_$id"
    }
}
# Klebebandabroller (Diamantschwert) mit eigener beschaedigter Textur
$tapeSrc = [System.Drawing.Image]::FromFile((Join-Path $AssetDir 'textures\item\primeblock_tape_gun.png'))
$tapeBmp = New-Object System.Drawing.Bitmap $tapeSrc.Width, $tapeSrc.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$tg2 = [System.Drawing.Graphics]::FromImage($tapeBmp)
# Abdunkeln ueber eine Farbmatrix, transparente Stellen bleiben dabei transparent
$tapeAttr = New-Object System.Drawing.Imaging.ImageAttributes
$tapeMatrix = New-Object System.Drawing.Imaging.ColorMatrix
$tapeMatrix.Matrix00 = 0.72; $tapeMatrix.Matrix11 = 0.68; $tapeMatrix.Matrix22 = 0.66
$tapeAttr.SetColorMatrix($tapeMatrix)
$tg2.DrawImage($tapeSrc, (New-Object System.Drawing.Rectangle 0, 0, $tapeSrc.Width, $tapeSrc.Height), 0, 0, $tapeSrc.Width, $tapeSrc.Height, 'Pixel', $tapeAttr); $tapeSrc.Dispose()
$crackPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230, 20, 20, 20)), 2
foreach ($ln in @(@(84, 34, 96, 60, 88, 88), @(4, 66, 30, 76, 62, 68), @(4, 84, 18, 100, 12, 116), @(110, 40, 118, 60, 108, 76))) { $tg2.DrawLines($crackPen, [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF $ln[0], $ln[1]), (New-Object System.Drawing.PointF $ln[2], $ln[3]), (New-Object System.Drawing.PointF $ln[4], $ln[5]))) }
$tg2.Dispose()
$tapeBmp.Save((Join-Path $AssetDir 'textures\item\primeblock_tape_gun_worn.png'), [System.Drawing.Imaging.ImageFormat]::Png); $tapeBmp.Dispose()
WJ 'models\item\primeblock_tape_gun_worn.json' ([ordered]@{ parent = 'minecraft:item/diamond_sword'; textures = [ordered]@{ '0' = 'minecraft:item/primeblock_tape_gun_worn'; particle = 'minecraft:item/primeblock_tape_gun_worn' } })
WornItem 'diamond_sword' 'primeblock_tape_gun_worn'

# ===================== Uhr: digitale Stundenanzeige =====================
function ClockFace($rel, $hour) {
    PixelSheet 16 16 (400 + $hour)
    $night = $hour -ge 0 -and ($hour -lt 6 -or $hour -ge 20)
    Cloth 1 3 14 10 '#3A3F45' 0.5
    HL 1 3 14 '#6E757D'; HL 1 12 14 '#23262B'
    Cloth 2 4 12 8 '#12261A' 0.3
    $col = if ($night) { '#7FB6FF' } else { '#5CFF7A' }
    if ($hour -ge 0) { Sprite 4 5 $digits[[int][Math]::Floor($hour / 10)] $col; Sprite 9 5 $digits[[int]($hour % 10)] $col }
    else { HL 4 7 3 $col; HL 9 7 3 $col }
    $mark = if ($night) { '#DDE6FF' } else { '#FFC83A' }
    Dot 13 4 $mark
    SaveCanvas $rel
}
$clockEntries = New-Object System.Collections.ArrayList
$hours = foreach ($h0 in 0..23) {
    $ticks = (($h0 - 6 + 24) % 24) * 1000
    $d0 = ($ticks / 24000.0 - 0.25); $d0 = $d0 - [Math]::Floor($d0)
    # Im Test belegt: Der Zeitwert laeuft linear (Tick 6000 = 0, Tick 18000 = 0.5)
    [pscustomobject]@{ H = $h0; V = $d0 }
}
foreach ($hr in ($hours | Sort-Object V)) {
    $name = 'primeblock_clock_{0:00}' -f $hr.H
    ClockFace "textures\item\$name.png" $hr.H
    WJ "models\item\$name.json" ([ordered]@{ parent = 'minecraft:item/generated'; textures = [ordered]@{ layer0 = "minecraft:item/$name" } })
    [void]$clockEntries.Add([ordered]@{ threshold = [Math]::Round($hr.V, 5); model = [ordered]@{ type = 'minecraft:model'; model = "minecraft:item/$name" } })
}
ClockFace 'textures\item\primeblock_clock_none.png' -1
WJ 'models\item\primeblock_clock_none.json' ([ordered]@{ parent = 'minecraft:item/generated'; textures = [ordered]@{ layer0 = 'minecraft:item/primeblock_clock_none' } })
WJ 'items\clock.json' ([ordered]@{ model = [ordered]@{
    type = 'minecraft:select'; property = 'minecraft:context_dimension'
    cases = @([ordered]@{ when = 'minecraft:overworld'; model = [ordered]@{ type = 'minecraft:range_dispatch'; property = 'minecraft:time'; source = 'daytime'; wobble = $false; entries = $clockEntries } })
    fallback = [ordered]@{ type = 'minecraft:model'; model = 'minecraft:item/primeblock_clock_none' } } })

# ===================== Bundle: Paket waechst mit dem Fuellstand =====================
function ParcelIcon($rel, $x0, $y0, $wd, $ht, $seed, $full) {
    PixelSheet 16 16 $seed
    Cloth $x0 $y0 $wd $ht '#C79A62' 0.6
    HL $x0 $y0 $wd '#E2C38F'; HL $x0 ($y0 + $ht - 1) $wd '#7D5A30'; VL $x0 $y0 $ht '#7D5A30'; VL ($x0 + $wd - 1) $y0 $ht '#7D5A30'
    VL ($x0 + [int][Math]::Floor($wd / 2)) $y0 $ht '#EBD3A8'
    if ($full) { HL $x0 ($y0 + [int][Math]::Floor($ht / 2)) $wd '#EBD3A8'; Dot ($x0 + 1) ($y0 + 1) '#FFFFFF'; Dot ($x0 + 2) ($y0 + 1) '#FFFFFF'; Dot ($x0 + $wd - 3) ($y0 + $ht - 2) '#FF9900'; Dot ($x0 + $wd - 2) ($y0 + $ht - 3) '#FF9900' }
    SaveCanvas $rel
}
ParcelIcon 'textures\item\bundle.png' 3 11 10 3 500 $false                         # leer: flach zusammengefaltet
ParcelIcon 'textures\item\primeblock_bundle_1.png' 4 8 8 6 501 $false
ParcelIcon 'textures\item\primeblock_bundle_2.png' 3 6 10 8 502 $false
ParcelIcon 'textures\item\primeblock_bundle_3.png' 2 4 12 10 503 $true
ParcelIcon 'textures\item\primeblock_bundle_4.png' 1 2 14 13 504 $true
$bundleEntries = New-Object System.Collections.ArrayList
foreach ($st in @(@(0.01, 1), @(0.34, 2), @(0.67, 3), @(1.0, 4))) {
    WJ "models\item\primeblock_bundle_$($st[1]).json" ([ordered]@{ parent = 'minecraft:item/generated'; textures = [ordered]@{ layer0 = "minecraft:item/primeblock_bundle_$($st[1])" } })
    [void]$bundleEntries.Add([ordered]@{ threshold = $st[0]; model = [ordered]@{ type = 'minecraft:model'; model = "minecraft:item/primeblock_bundle_$($st[1])" } })
}
$bundleModel = [ordered]@{ type = 'minecraft:range_dispatch'; property = 'minecraft:bundle/fullness'; entries = $bundleEntries; fallback = [ordered]@{ type = 'minecraft:model'; model = 'minecraft:item/bundle' } }
WJ 'items\bundle.json' ([ordered]@{ model = [ordered]@{
    type = 'minecraft:select'; property = 'minecraft:display_context'
    cases = @([ordered]@{ when = 'gui'; model = [ordered]@{ type = 'minecraft:condition'; property = 'minecraft:bundle/has_selected_item'; on_false = $bundleModel
        on_true = [ordered]@{ type = 'minecraft:composite'; models = @([ordered]@{ type = 'minecraft:model'; model = 'minecraft:item/bundle_open_back' }, [ordered]@{ type = 'minecraft:bundle/selected_item' }, [ordered]@{ type = 'minecraft:model'; model = 'minecraft:item/bundle_open_front' }) } } })
    fallback = $bundleModel } })
