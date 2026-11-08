# Dot-sourced from build.ps1 (uses $root, $utf8, C, Br, Pn, Text, Smile, $navy, ...)
$AssetDir = Join-Path $root 'assets\minecraft'
$s = 8   # HD scale for entity / armor textures

$skin = '#BD8B67'; $skinD = '#A8775A'; $hair = '#3B2A20'; $pants = '#3E434A'; $pantsD = '#33373D'
$boots = '#1A1A1A'; $hivis = '#DCEB2A'; $hivisD = '#B9C71C'; $refl = '#D9DDE0'

# $k = Qualitaetsfaktor: Bild wird $k-mal groesser gerendert, alle Zeichenbefehle bleiben gleich (ScaleTransform)
function NewCanvas($w, $h, $scale, $k = 1) {
    $script:cs = $scale; $script:ck = $k
    $script:cv = New-Object System.Drawing.Bitmap ($w * $scale * $k), ($h * $scale * $k), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $script:g = [System.Drawing.Graphics]::FromImage($script:cv)
    $script:g.SmoothingMode = 'AntiAlias'; $script:g.TextRenderingHint = 'AntiAliasGridFit'
    $script:g.PixelOffsetMode = 'Half'
    $script:g.Clear([System.Drawing.Color]::Transparent)
    if ($k -ne 1) { $script:g.ScaleTransform([single]$k, [single]$k) }
}
function SaveCanvas($rel) {
    $p = Join-Path $AssetDir $rel
    New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
    $script:g.Dispose(); $script:cv.Save($p, [System.Drawing.Imaging.ImageFormat]::Png); $script:cv.Dispose()
}
function Rect($u, $v, $w, $h, $hex) { $script:g.FillRectangle((Br $hex), [single]($u * $cs), [single]($v * $cs), [single]($w * $cs), [single]($h * $cs)) }
function Faces($u, $v, $w, $h, $d) {
    @{
        top = @(($u + $d), $v, $w, $d); bottom = @(($u + $d + $w), $v, $w, $d)
        right = @($u, ($v + $d), $d, $h); front = @(($u + $d), ($v + $d), $w, $h)
        left = @(($u + $d + $w), ($v + $d), $d, $h); back = @(($u + 2 * $d + $w), ($v + $d), $w, $h)
    }
}
function FillFace($f, $hex) { Rect $f[0] $f[1] $f[2] $f[3] $hex }
function Rows($f, $r0, $r1, $hex) { Rect $f[0] ($f[1] + $r0) $f[2] ($r1 - $r0) $hex }
function SideRows($F, $r0, $r1, $hex) { foreach ($k in 'right', 'front', 'left', 'back') { Rows $F[$k] $r0 $r1 $hex } }
function FillAll($F, $hex, $skip = @()) { foreach ($k in $F.Keys) { if ($skip -notcontains $k) { FillFace $F[$k] $hex } } }
function Mid($f) { @((($f[0] + $f[2] / 2) * $cs), (($f[1]) * $cs)) }   # x centre / top y in canvas px

. (Join-Path $PSScriptRoot 'villagers.ps1')

# =============== Diamond armor -> work clothes ===============
function Layer1 {
    NewCanvas 64 32 $s
    # cap
    $H = Faces 0 0 8 8 8
    FillFace $H.top $navy
    SideRows $H 0 2.5 $navy; SideRows $H 2.5 3 $navyD
    $m = Mid $H.front; Smile $m[0] ($m[1] + 1.3 * $s) (4 * $s) (0.45 * $s)
    # hi-vis vest over navy shirt
    $B = Faces 16 16 8 12 4
    FillAll $B $hivis @('bottom')
    foreach ($k in 'right', 'front', 'left', 'back') { Rows $B[$k] 7 8 $refl; Rows $B[$k] 9.5 10.5 $refl }
    Rect ($B.front[0] + 3) ($B.front[1]) 2 4 $navy
    Rect ($B.front[0] + 3.9) ($B.front[1] + 4) 0.2 8 '#6B6F45'
    $m = Mid $B.front; Smile ($m[0] + 2 * $s) ($m[1] + 5.2 * $s) (2.2 * $s) (0.3 * $s)
    $m = Mid $B.back
    Text 'Prime' 17 '#1B1B1B' $m[0] ($m[1] + 2 * $s)
    Text 'Block' 17 '#1B1B1B' $m[0] ($m[1] + 4.3 * $s)
    Rect ($B.top[0] + 2) ($B.top[1] + 1) 4 2 $navy
    # short navy sleeves
    $Ar = Faces 40 16 4 12 4
    FillFace $Ar.top $navy; SideRows $Ar 0 4 $navy; SideRows $Ar 4 4.5 $navyD
    # work boots
    $L = Faces 0 16 4 12 4
    SideRows $L 8 9 '#4A3426'; SideRows $L 9 11.3 $boots; SideRows $L 11.3 12 '#0B0B0B'
    FillFace $L.bottom '#0B0B0B'
    Rect ($L.front[0] + 1) ($L.front[1] + 9.3) 2 0.3 '#8A8A8A'; Rect ($L.front[0] + 1) ($L.front[1] + 10) 2 0.3 '#8A8A8A'
}
function Layer2 {
    NewCanvas 64 32 $s
    $B = Faces 16 16 8 12 4
    SideRows $B 8 12 $pants; SideRows $B 8 9 $boots
    Rect ($B.front[0] + 3.5) ($B.front[1] + 8) 1 1 '#C9CDD2'
    $L = Faces 0 16 4 12 4
    FillAll $L $pants @('bottom')
    foreach ($k in 'right', 'left') { $f = $L[$k]; Rect ($f[0] + 0.5) ($f[1] + 3) 3 3.5 $pantsD; Rect ($f[0] + 0.5) ($f[1] + 3) 3 0.6 '#2A2D32' }
    SideRows $L 8 8.6 $orange; SideRows $L 8.6 9.2 $refl
}
Layer1; SaveCanvas 'textures\models\armor\diamond_layer_1.png'
Layer2; SaveCanvas 'textures\models\armor\diamond_layer_2.png'
Layer1; SaveCanvas 'textures\entity\equipment\humanoid\diamond.png'          # 1.21.2+
Layer2; SaveCanvas 'textures\entity\equipment\humanoid_leggings\diamond.png' # 1.21.2+

# =============== Item icons (32x32 pixel art) ===============
function ItemCanvas { NewCanvas 32 32 1; $script:g.SmoothingMode = 'None'; $script:g.PixelOffsetMode = 'None' }
function P($pts, $hex) {
    $arr = foreach ($p in $pts) { New-Object System.Drawing.PointF ([single]$p[0]), ([single]$p[1]) }
    $script:g.FillPolygon((Br $hex), [System.Drawing.PointF[]]$arr)
}
function Px($list, $hex) { foreach ($p in $list) { Rect $p[0] $p[1] 1 1 $hex } }

# Work cap
ItemCanvas
Rect 9 9 12 1 '#0F1620'; Rect 7 10 16 1 '#0F1620'; Rect 6 11 1 9 '#0F1620'; Rect 23 11 1 8 '#0F1620'
Rect 9 10 12 2 $navy; Rect 7 11 16 3 $navy; Rect 6 13 18 6 $navy
Rect 9 11 5 1 $navyL; Rect 7 13 2 4 $navyL
Rect 14 8 2 2 $navyD
Rect 5 19 19 2 $navyD; Rect 20 19 9 2 '#101722'; Rect 22 21 7 1 '#0B1018'
Px @(@(10, 15), @(11, 16), @(12, 16), @(13, 16), @(14, 16), @(15, 15), @(16, 14), @(15, 14), @(16, 15)) $orange
SaveCanvas 'textures\item\diamond_helmet.png'

# Safety vest
ItemCanvas
Rect 7 4 6 4 $hivis; Rect 19 4 6 4 $hivis
Rect 5 8 22 19 $hivis
Rect 13 4 6 8 $navy; Rect 14 12 4 2 $navy
Rect 15 14 2 13 '#8E9641'
Rect 5 17 22 2 $refl; Rect 5 21 22 2 $refl
Rect 5 8 1 19 $hivisD; Rect 26 8 1 19 $hivisD; Rect 5 26 22 1 $hivisD
Rect 7 3 6 1 $hivisD; Rect 19 3 6 1 $hivisD
Px @(@(19, 11), @(20, 12), @(21, 12), @(22, 12), @(23, 11), @(23, 10)) $orange
SaveCanvas 'textures\item\diamond_chestplate.png'

# Work trousers
ItemCanvas
Rect 8 4 16 3 $boots; Rect 15 4 2 3 '#C9CDD2'
Rect 8 7 16 6 $pants; Rect 8 13 7 15 $pants; Rect 17 13 7 15 $pants
Rect 15 13 2 1 $pantsD
Rect 9 9 4 4 $pantsD; Rect 19 9 4 4 $pantsD
Rect 8 20 7 1 $orange; Rect 17 20 7 1 $orange; Rect 8 21 7 1 $refl; Rect 17 21 7 1 $refl
Rect 8 7 1 21 $pantsD; Rect 23 7 1 21 $pantsD
SaveCanvas 'textures\item\diamond_leggings.png'

# Work boots
ItemCanvas
foreach ($ox in 3, 17) {
    Rect $ox 11 7 2 '#4A3426'
    Rect $ox 13 7 9 $boots; Rect $ox 22 11 5 $boots; Rect ($ox + 1) 22 2 1 '#2E2E2E'
    Rect $ox 27 11 2 '#5A5A5A'
    Px @(@(($ox + 2), 15), @(($ox + 4), 15), @(($ox + 2), 17), @(($ox + 4), 17), @(($ox + 2), 19), @(($ox + 4), 19)) '#9A9A9A'
}
SaveCanvas 'textures\item\diamond_boots.png'

# Totem -> PrimeBlock package
ItemCanvas
P @(@(16, 3), @(29, 9.5), @(16, 16), @(3, 9.5)) '#D9AE76'
P @(@(3, 9.5), @(16, 16), @(16, 29), @(3, 22.5)) '#C08A50'
P @(@(16, 16), @(29, 9.5), @(29, 22.5), @(16, 29)) '#A26E3E'
P @(@(8.5, 6), @(11, 4.8), @(24, 11.3), @(21.5, 12.6)) '#EBD3A8'                 # tape on top
P @(@(21.5, 12.6), @(24, 11.3), @(24, 24.8), @(21.5, 26.1)) '#C9A57A'           # tape down the side
P @(@(17.5, 20), @(20.5, 18.5), @(20.5, 22), @(17.5, 23.5)) '#F4F4F4'          # label
Px @(@(5, 16), @(6, 17), @(7, 18), @(8, 18), @(9, 19), @(10, 19), @(11, 19), @(12, 19), @(13, 18), @(13, 17), @(12, 17)) '#2B2B2B'
$script:g.DrawPolygon((Pn '#5E3F1F' 1), [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point 16, 3), (New-Object System.Drawing.Point 29, 9), (New-Object System.Drawing.Point 29, 22),
    (New-Object System.Drawing.Point 16, 29), (New-Object System.Drawing.Point 3, 22), (New-Object System.Drawing.Point 3, 9)))
SaveCanvas 'textures\item\totem_of_undying.png'

# =============== Diamond sword -> PrimeBlock tape gun (3D item model) ===============
NewCanvas 16 16 8          # 128x128, Rect works in model-UV units (0..16)
$tg = $script:g
# A: tape roll face (disc, transparent corners)            uv 0,0,8,8
$tg.FillEllipse((Br '#A8743F'), 0, 0, 64, 64)
foreach ($r in 8, 15, 21) { $tg.DrawEllipse((Pn '#8E5E30' 1.5), $r, $r, 64 - 2 * $r, 64 - 2 * $r) }
$tg.DrawArc((Pn '#C9965E' 3), 4, 4, 56, 56, 200, 70)
# B: tape rim                                              uv 8,0,10,8
Rect 8 0 2 8 '#A06C3A'; Rect 8.7 0 0.4 8 '#B98249'
# C: white hub disc                                        uv 10,0,13,3
$tg.FillEllipse((Br '#E8E8E8'), 80, 0, 24, 24); $tg.DrawEllipse((Pn '#9A9A9A' 2), 82, 2, 20, 20)
foreach ($k in 0..2) { $a = $k * 120 * [Math]::PI / 180; $tg.FillEllipse((Br '#B5B5B5'), [single](92 + 7 * [Math]::Cos($a) - 2), [single](12 + 7 * [Math]::Sin($a) - 2), 4, 4) }
# D: yellow hub disc                                       uv 13,0,16,3
$tg.FillEllipse((Br '#F5C400'), 104, 0, 24, 24); $tg.DrawEllipse((Pn '#C99E00' 2), 107, 3, 18, 18)
$tg.FillEllipse((Br '#8A8A8A'), 112, 8, 8, 8)
# swatches E..J                                            uv 10..16, 3..4
$i = 0; foreach ($c in '#E8E8E8', '#BFC4C9', $navy, '#15191F', '#F5C400', $orange) { Rect (10 + $i) 3 1 1 $c; $i++ }
# K: grip side                                             uv 10,4,13,12
Rect 10 4 3 8 $navy
$tg.FillRectangle((Br '#5B6B7A'), 84, 40, 16, 50)
for ($y = 44; $y -lt 88; $y += 6) { $tg.DrawLine((Pn '#45525E' 2), 85, $y, 99, $y) }
Rect 10 4 3 0.4 $orange
# L: clear guard                                           uv 13,4,16,10
Rect 13 4 3 6 '#CFE9F2'; $tg.DrawRectangle((Pn '#9CC7D6' 2), 105, 33, 22, 46)
Smile 116 64 16 2
# M: frame side with name                                  uv 0,8,11,10
Rect 0 8 11 2 $navy; Rect 0 9.7 11 0.3 $orange
Text 'PrimeBlock' 12 $white 44 71
# N: nose side                                             uv 0,10,3,15
Rect 0 10 3 5 $navy
$tg.FillPolygon((Br $orange), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF 0, 104), (New-Object System.Drawing.PointF 24, 92), (New-Object System.Drawing.PointF 24, 96), (New-Object System.Drawing.PointF 0, 108)))
Smile 12 86 14 2
# O: serrated blade                                        uv 3,10,4,11
Rect 3 10 1 1 '#BFC4C9'
for ($x = 24; $x -lt 32; $x += 2) { $tg.FillPolygon((Br '#7E848A'), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF $x, 88), (New-Object System.Drawing.PointF ($x + 1), 84), (New-Object System.Drawing.PointF ($x + 2), 88))) }
SaveCanvas 'textures\item\primeblock_tape_gun.png'

$UV = @{
    disc = @(0, 0, 8, 8); rim = @(8, 0, 10, 8); hub = @(10, 0, 13, 3); yel = @(13, 0, 16, 3)
    white = @(10, 3, 11, 4); silver = @(11, 3, 12, 4); navy = @(12, 3, 13, 4); dark = @(13, 3, 14, 4); orange = @(15, 3, 16, 4)
    grip = @(10, 4, 13, 12); guard = @(13, 4, 16, 10); frame = @(0, 8, 11, 10); nose = @(0, 10, 3, 15); blade = @(3, 10, 4, 11)
}
$els = New-Object System.Collections.ArrayList
function El($from, $to, $faces, $rot = $null) {
    $fo = [ordered]@{}
    foreach ($k in $faces.Keys) { $fo[$k] = [ordered]@{ uv = $UV[$faces[$k]]; texture = '#0' } }
    $e = [ordered]@{ from = $from; to = $to }
    if ($rot) { $e.rotation = $rot }
    $e.faces = $fo
    [void]$script:els.Add($e)
}
function All6($m) { @{ north = $m; south = $m; east = $m; west = $m; up = $m; down = $m } }
# tape roll: centre (9, 14.5), radius 5, z 5.5..10.5 — 8 planks form a 16-sided rim
$c = @(9, 14.5, 8)
foreach ($a in 0, 22.5, 45, -22.5, -45) { El @(8, 9.5, 5.5) @(10, 19.5, 10.5) @{ up = 'rim'; down = 'rim' } ([ordered]@{ angle = $a; axis = 'z'; origin = $c }) }
foreach ($a in 0, 22.5, -22.5) { El @(4, 13.5, 5.5) @(14, 15.5, 10.5) @{ east = 'rim'; west = 'rim' } ([ordered]@{ angle = $a; axis = 'z'; origin = $c }) }
El @(4, 9.5, 5.45) @(14, 19.5, 5.45) @{ north = 'disc' }
El @(4, 9.5, 10.55) @(14, 19.5, 10.55) @{ south = 'disc' }
El @(6.5, 12, 5.3) @(11.5, 17, 5.3) @{ north = 'hub' }
El @(6.5, 12, 10.7) @(11.5, 17, 10.7) @{ south = 'hub' }
El @(7.75, 13.25, 5.1) @(10.25, 15.75, 5.1) @{ north = 'yel' }
El @(7.75, 13.25, 10.9) @(10.25, 15.75, 10.9) @{ south = 'yel' }
El @(8.5, 14, 4.8) @(9.5, 15, 11.2) (All6 'silver')                                        # axle bolt
# body
El @(4, 8, 6) @(15, 10, 10) @{ north = 'frame'; south = 'frame'; east = 'navy'; west = 'navy'; up = 'navy'; down = 'navy' }
El @(3, 7, 6.5) @(5, 13, 9.5) (All6 'navy')                                               # rear bracket
El @(5.5, 8.5, 5) @(12.5, 9.5, 6) (All6 'navy'); El @(5.5, 8.5, 10) @(12.5, 9.5, 11) (All6 'navy')  # roll arms
El @(6, 0, 6.5) @(9, 8, 9.5) @{ north = 'grip'; south = 'grip'; east = 'navy'; west = 'navy'; up = 'navy'; down = 'dark' } ([ordered]@{ angle = -22.5; axis = 'z'; origin = @(7.5, 8, 8) })
El @(9, 5, 7.25) @(12, 6, 8.75) (All6 'white')                                            # trigger lever
El @(14, 7, 5.5) @(17, 12, 10.5) @{ north = 'nose'; south = 'nose'; east = 'navy'; west = 'navy'; up = 'navy'; down = 'dark' }
El @(16.5, 6, 6) @(18, 7.5, 10) (All6 'dark')                                             # press roller
El @(12, 12, 6) @(17.6, 12.3, 10) (All6 'rim')                                            # tape strip
El @(17.6, 9.5, 5.5) @(18.6, 10.2, 10.5) (All6 'blade')                                   # cutter blade
El @(17.6, 10.2, 5.5) @(18.1, 16, 10.5) (All6 'guard') ([ordered]@{ angle = 22.5; axis = 'z'; origin = @(17.85, 10.2, 8) })  # guard

$model = [ordered]@{
    credit   = 'PrimeBlock'
    textures = [ordered]@{ '0' = 'minecraft:item/primeblock_tape_gun'; particle = 'minecraft:item/primeblock_tape_gun' }
    elements = $els
    display  = [ordered]@{
        thirdperson_righthand = [ordered]@{ rotation = @(0, -90, 0); translation = @(0, 3, 1); scale = @(0.55, 0.55, 0.55) }
        thirdperson_lefthand  = [ordered]@{ rotation = @(0, 90, 0); translation = @(0, 3, 1); scale = @(0.55, 0.55, 0.55) }
        firstperson_righthand = [ordered]@{ rotation = @(0, -90, 5); translation = @(1.13, 4, 1.13); scale = @(0.6, 0.6, 0.6) }
        firstperson_lefthand  = [ordered]@{ rotation = @(0, 90, -5); translation = @(1.13, 4, 1.13); scale = @(0.6, 0.6, 0.6) }
        gui                   = [ordered]@{ rotation = @(15, -25, 0); translation = @(-2.5, -1.5, 0); scale = @(0.75, 0.75, 0.75) }
        ground                = [ordered]@{ rotation = @(0, 0, 0); translation = @(0, 2, 0); scale = @(0.4, 0.4, 0.4) }
        fixed                 = [ordered]@{ rotation = @(0, 180, 0); translation = @(2.5, -1.5, 0); scale = @(0.7, 0.7, 0.7) }
        head                  = [ordered]@{ rotation = @(0, -90, 0); translation = @(0, 10, 0); scale = @(0.8, 0.8, 0.8) }
    }
}
$mp = Join-Path $AssetDir 'models\item'
New-Item -ItemType Directory -Force $mp | Out-Null
[System.IO.File]::WriteAllText((Join-Path $mp 'diamond_sword.json'), ($model | ConvertTo-Json -Depth 12), $utf8)

# =============== Totem -> 3D PrimeBlock package ===============
NewCanvas 16 16 8          # 128x128, 8 px per UV unit
$card = '#C79A62'; $cardD = '#9A6F3C'; $tape = '#E2C38F'
# A: front/back (10x8) with logo                           uv 0,0,10,8
Rect 0 0 10 8 $card; $script:g.DrawRectangle((Pn $cardD 2), 1, 1, 78, 62)
Rect 4.25 0 1.5 8 $tape
Text 'PrimeBlock' 13 '#2B2B2B' 40 30
Smile 40 44 34 3
# B: left/right (10x8) with shipping label                 uv 0,8,10,16
Rect 0 8 10 8 $card; $script:g.DrawRectangle((Pn $cardD 2), 1, 65, 78, 62)
Rect 1.5 9.5 4.5 3 '#F4F4F4'
for ($k = 0; $k -lt 3; $k++) { Rect 2 (10 + $k * 0.7) 3 0.25 '#7A7A7A' }
Rect 7 10 2 2 '#2B2B2B'; Rect 7.3 10.3 0.6 0.6 '#F4F4F4'; Rect 8.1 11.1 0.6 0.6 '#F4F4F4'   # QR-ish code
Text 'PrimeBlock' 9 '#2B2B2B' 40 112
# top (stretched onto 10x10)                               uv 10,0,16,6
Rect 10 0 6 6 $card; Rect 12.4 0 1.2 6 $tape
Rect 10.6 0.6 1.4 1.1 '#F4F4F4'
# bottom                                                   uv 10,6,16,12
Rect 10 6 6 6 $cardD
# tape swatch                                              uv 10,12,12,14
Rect 10 12 2 2 $tape; Rect 10 12 2 0.3 '#F0D8AE'
SaveCanvas 'textures\item\primeblock_package.png'

$UV = @{ front = @(0, 0, 10, 8); side = @(0, 8, 10, 16); top = @(10, 0, 16, 6); bottom = @(10, 6, 16, 12); tape = @(10, 12, 12, 14) }
$els = New-Object System.Collections.ArrayList
El @(3, 4, 3) @(13, 12, 13) @{ north = 'front'; south = 'front'; east = 'side'; west = 'side'; up = 'top'; down = 'bottom' }
El @(7.25, 12, 2.9) @(8.75, 12.15, 13.1) (All6 'tape')                         # tape over the lid
El @(7.25, 6.5, 2.9) @(8.75, 12, 3) (All6 'tape')                              # tape down the front
El @(7.25, 6.5, 13) @(8.75, 12, 13.1) (All6 'tape')                            # tape down the back
$model = [ordered]@{
    credit   = 'PrimeBlock'
    textures = [ordered]@{ '0' = 'minecraft:item/primeblock_package'; particle = 'minecraft:item/primeblock_package' }
    elements = $els
    display  = [ordered]@{
        gui                   = [ordered]@{ rotation = @(30, 225, 0); translation = @(0, 0, 0); scale = @(0.9, 0.9, 0.9) }
        ground                = [ordered]@{ rotation = @(0, 0, 0); translation = @(0, 2, 0); scale = @(0.5, 0.5, 0.5) }
        fixed                 = [ordered]@{ rotation = @(0, 0, 0); translation = @(0, 0, 0); scale = @(0.9, 0.9, 0.9) }
        thirdperson_righthand = [ordered]@{ rotation = @(75, 45, 0); translation = @(0, 2.5, 0); scale = @(0.5, 0.5, 0.5) }
        thirdperson_lefthand  = [ordered]@{ rotation = @(75, 45, 0); translation = @(0, 2.5, 0); scale = @(0.5, 0.5, 0.5) }
        firstperson_righthand = [ordered]@{ rotation = @(0, 45, 0); translation = @(0, 2, 0); scale = @(0.55, 0.55, 0.55) }
        firstperson_lefthand  = [ordered]@{ rotation = @(0, 225, 0); translation = @(0, 2, 0); scale = @(0.55, 0.55, 0.55) }
        head                  = [ordered]@{ rotation = @(0, 0, 0); translation = @(0, 0, 0); scale = @(1.2, 1.2, 1.2) }
    }
}
[System.IO.File]::WriteAllText((Join-Path $mp 'totem_of_undying.json'), ($model | ConvertTo-Json -Depth 12), $utf8)

# =============== Names ===============
$langDir = Join-Path $AssetDir 'lang'
New-Item -ItemType Directory -Force $langDir | Out-Null
$de = @'
{
  "item.minecraft.totem_of_undying": "PrimeBlock Paket",
  "item.minecraft.diamond_sword": "PrimeBlock Klebebandabroller",
  "item.minecraft.diamond_helmet": "PrimeBlock Arbeitsm#ue#tze",
  "item.minecraft.diamond_chestplate": "PrimeBlock Warnweste",
  "item.minecraft.diamond_leggings": "PrimeBlock Arbeitshose",
  "item.minecraft.diamond_boots": "PrimeBlock Arbeitsschuhe",
  "entity.minecraft.villager": "PrimeBlock Mitarbeiter",
  "entity.minecraft.boat": "PrimeBlock Lieferwagen"
}
'@
$en = @'
{
  "item.minecraft.totem_of_undying": "PrimeBlock Package",
  "item.minecraft.diamond_sword": "PrimeBlock Tape Gun",
  "item.minecraft.diamond_helmet": "PrimeBlock Work Cap",
  "item.minecraft.diamond_chestplate": "PrimeBlock Safety Vest",
  "item.minecraft.diamond_leggings": "PrimeBlock Work Trousers",
  "item.minecraft.diamond_boots": "PrimeBlock Work Boots",
  "entity.minecraft.villager": "PrimeBlock Employee",
  "entity.minecraft.boat": "PrimeBlock Delivery Van"
}
'@
$de = $de.Replace('#ue#', [string][char]0xFC)
[System.IO.File]::WriteAllText((Join-Path $langDir 'de_de.json'), $de, $utf8)
[System.IO.File]::WriteAllText((Join-Path $langDir 'en_us.json'), $en, $utf8)
