$ErrorActionPreference = 'Stop'
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Join-Path $PSScriptRoot 'PrimeBlock'
if (Test-Path $root) { Remove-Item $root -Recurse -Force }
$cem = Join-Path $root 'assets\minecraft\optifine\cem'
$tex = Join-Path $root 'assets\minecraft\textures\entity'
New-Item -ItemType Directory -Force $cem | Out-Null
New-Item -ItemType Directory -Force $tex | Out-Null

# ---------------- Texture ----------------
$S = 512
$bmp = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'AntiAliasGridFit'
$g.Clear([System.Drawing.Color]::Transparent)

function C($hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Br($hex) { New-Object System.Drawing.SolidBrush (C $hex) }
function Pn($hex, $w) { New-Object System.Drawing.Pen (C $hex), $w }

$navy = '#1E2A3B'; $navyD = '#141C28'; $navyL = '#2C3B52'
$orange = '#FF9900'; $prime = '#1AA7EC'; $white = '#FFFFFF'
$lgray = '#C8CCD1'; $dgray = '#3A3F45'; $black = '#131313'
$interior = '#2A2D32'; $red = '#C4232B'; $amber = '#FFB000'; $head = '#FFF6D8'; $silver = '#B9BEC4'

$uv = @{}
function Region($name, $x, $y, $w, $h) { $script:uv[$name] = @($x, $y, ($x + $w), ($y + $h)) }

function Smile($cx, $cy, $w, $thick) {
    $h = $w * 0.45
    $pen = Pn $orange $thick
    $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
    $g.DrawArc($pen, [single]($cx - $w / 2), [single]($cy - $h / 2), [single]$w, [single]$h, 25, 130)
    $a = 25 * [Math]::PI / 180
    $ex = $cx + ($w / 2) * [Math]::Cos($a); $ey = $cy + ($h / 2) * [Math]::Sin($a)
    $s = $thick * 1.8
    $pts = @(
        (New-Object System.Drawing.PointF ([single]($ex + $s * 0.9), [single]($ey - $s * 0.9))),
        (New-Object System.Drawing.PointF ([single]($ex - $s * 1.1), [single]($ey - $s * 0.2))),
        (New-Object System.Drawing.PointF ([single]($ex + $s * 0.3), [single]($ey + $s * 1.0)))
    )
    $g.FillPolygon((Br $orange), $pts)
}
function Text($str, $size, $hex, $cx, $cy, $style = 'Bold') {
    $f = New-Object System.Drawing.Font 'Arial', ([single]$size), ([System.Drawing.FontStyle]$style), ([System.Drawing.GraphicsUnit]::Pixel)
    $sz = $g.MeasureString($str, $f)
    $g.DrawString($str, $f, (Br $hex), [single]($cx - $sz.Width / 2), [single]($cy - $sz.Height / 2))
}
function Panel($x, $y, $w, $h, $fill, $edge, $ew = 3) {
    $g.FillRectangle((Br $fill), $x, $y, $w, $h)
    if ($edge) { $g.DrawRectangle((Pn $edge $ew), $x + $ew / 2, $y + $ew / 2, $w - $ew, $h - $ew) }
}

# Cargo side (15 x 20 model px -> 150 x 200)
Panel 0 0 150 200 $navy $navyD
$g.FillRectangle((Br $navyL), 3, 3, 144, 6)               # roof edge highlight
$g.FillRectangle((Br $dgray), 0, 178, 150, 22)            # lower trim
$g.DrawLine((Pn $navyD 2), 0, 150, 150, 150)              # body crease
Text 'PrimeBlock' 23 $white 75 72
Smile 72 98 92 7
Text 'prime' 22 $prime 75 132 'Italic, Bold'
Region 'cargoSide' 0 0 150 200

# Rear doors (20 x 20 -> 200 x 200)
Panel 150 0 200 200 $navy $navyD
$g.DrawLine((Pn $navyD 3), 250, 4, 250, 178)
$g.DrawRectangle((Pn $navyD 2), 158, 8, 88, 168); $g.DrawRectangle((Pn $navyD 2), 254, 8, 88, 168)
$g.FillRectangle((Br $silver), 238, 96, 8, 22); $g.FillRectangle((Br $silver), 254, 96, 8, 22)
Text 'PrimeBlock' 22 $white 250 40
Smile 248 60 66 5
$g.FillRectangle((Br $red), 154, 104, 14, 52); $g.FillRectangle((Br $amber), 154, 156, 14, 12)
$g.FillRectangle((Br $red), 332, 104, 14, 52); $g.FillRectangle((Br $amber), 332, 156, 14, 12)
$g.FillRectangle((Br $red), 200, 4, 100, 5)               # 3rd brake light
$g.FillRectangle((Br $dgray), 150, 178, 200, 22)
Panel 215 150 70 24 '#F2F2F2' $black 2
Text 'PR1-ME' 15 $black 250 162
Region 'rear' 150 0 200 200

# Hood front (20 x 7 -> 200 x 70)
Panel 350 0 160 56 $navy $navyD 2
$g.FillRectangle((Br '#EAF6FF'), 356, 4, 148, 5)          # LED light bar
$g.FillRectangle((Br $black), 400, 18, 60, 24)            # grille
for ($i = 0; $i -lt 5; $i++) { $g.DrawLine((Pn $dgray 1), 402, 22 + $i * 4, 458, 22 + $i * 4) }
$g.FillEllipse((Br $head), 360, 14, 28, 18); $g.FillEllipse((Br $head), 472, 14, 28, 18)
$g.DrawEllipse((Pn $silver 2), 360, 14, 28, 18); $g.DrawEllipse((Pn $silver 2), 472, 14, 28, 18)
$g.FillRectangle((Br $amber), 362, 34, 14, 4); $g.FillRectangle((Br $amber), 484, 34, 14, 4)
$g.FillRectangle((Br $dgray), 350, 46, 160, 10)
Smile 430 32 22 2
Region 'hoodFront' 350 0 160 56

# Cab door (15 x 8 -> 150 x 80)
Panel 350 60 150 80 $navy $navyD
$g.DrawLine((Pn $navyD 3), 380, 60, 380, 128); $g.DrawLine((Pn $navyD 3), 470, 60, 470, 128)
$g.FillRectangle((Br $dgray), 350, 128, 150, 12)
Text 'prime' 26 $prime 425 88 'Italic, Bold'
Smile 425 108 52 4
Region 'cabSide' 350 60 150 80

# Hood top (9 x 20 -> 72 x 160)
Panel 0 210 72 160 $navy $navyD 2
$g.DrawLine((Pn $navyL 2), 6, 260, 66, 260); $g.DrawLine((Pn $navyL 2), 6, 320, 66, 320)
Region 'hoodTop' 0 210 72 160

# Cargo roof (15 x 20 -> 150 x 200)
Panel 80 210 150 200 $lgray '#9EA3A9'
for ($i = 1; $i -lt 6; $i++) { $g.DrawLine((Pn '#A9AEB4' 3), 80 + $i * 25, 214, 80 + $i * 25, 406) }
Region 'roof' 80 210 150 200

# Wheel (7 x 7 -> 70 x 70)
$g.FillEllipse((Br $black), 240, 210, 70, 70)
$g.FillEllipse((Br '#262626'), 248, 218, 54, 54)
$g.FillEllipse((Br $silver), 256, 226, 38, 38)
$g.FillEllipse((Br '#7D838A'), 266, 236, 18, 18)
for ($k = 0; $k -lt 5; $k++) {
    $a = $k * 72 * [Math]::PI / 180
    $g.FillEllipse((Br $dgray), [single](275 + 12 * [Math]::Cos($a) - 2), [single](245 + 12 * [Math]::Sin($a) - 2), 4, 4)
}
Region 'wheel' 240 210 70 70

# Solid colour swatches
$sw = @{ navy = $navy; dark = $dgray; black = $black; light = $lgray; interior = $interior; silver = $silver }
$sx = 240
foreach ($k in $sw.Keys) {
    $g.FillRectangle((Br $sw[$k]), $sx, 420, 16, 16)
    Region $k ($sx + 4) 424 8 8
    $sx += 20
}
# Dashboard top with a little screen
Panel 240 450 40 20 $interior $null
$g.FillRectangle((Br '#0E5A8A'), 250, 454, 20, 10)
Region 'dash' 240 450 40 20

# Package side (64 x 64)
Panel 330 150 64 64 '#C79A62' '#9A6F3C' 2
$g.FillRectangle((Br '#D8B484'), 356, 150, 12, 64)              # tape
Text 'PrimeBlock' 9 '#2B2B2B' 362 176
Smile 361 186 26 2
Region 'package' 330 150 64 64
# Package top (64 x 64)
Panel 400 150 64 64 '#C79A62' '#9A6F3C' 2
$g.FillRectangle((Br '#D8B484'), 426, 150, 12, 64)
$g.FillRectangle((Br '#D8B484'), 400, 176, 64, 12)
$g.FillRectangle((Br $white), 406, 156, 16, 12); $g.DrawRectangle((Pn '#555555' 1), 406, 156, 16, 12)   # label
Region 'packageTop' 400 150 64 64
# Cargo floor (64 x 64)
Panel 330 220 64 64 '#4A4F55' $null
$g.SetClip((New-Object System.Drawing.Rectangle 330, 220, 64, 64))
for ($i = -64; $i -lt 64; $i += 8) { $g.DrawLine((Pn '#5A6067' 2), 330 + $i, 220, 394 + $i, 284) }
$g.ResetClip()
Region 'floor' 330 220 64 64
# Seat fabric (32 x 32)
Panel 400 220 32 32 '#25282D' '#1A1C20' 2
$g.DrawLine((Pn '#3A3E45' 2), 400, 236, 432, 236)
Region 'seat' 400 220 32 32
# Light cargo wall + shelf metal
$g.FillRectangle((Br '#9AA0A6'), 440, 220, 16, 16); Region 'wall' 444 224 8 8
$g.FillRectangle((Br '#6E757D'), 460, 220, 16, 16); Region 'shelf' 464 224 8 8

$g.Dispose()
$bmp.Save((Join-Path $tex 'primeblock_van.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# ---------------- Model ----------------
function Box($x1, $y1, $z1, $x2, $y2, $z2, $def, $faces = @{}) {
    $m = @{ uvNorth = $def; uvSouth = $def; uvEast = $def; uvWest = $def; uvUp = $def; uvDown = $def }
    foreach ($k in $faces.Keys) { $m[$k] = $faces[$k] }
    # Transform: mirror front/back (in-game front is +X), centre cab on driver seat, scale up
    $k = 1.5; $sh = 3
    $ax = -$k * ([double]$x1 + $sh); $bx = -$k * ([double]$x2 + $sh)
    $nx1 = [Math]::Min($ax, $bx); $nx2 = [Math]::Max($ax, $bx)
    $y1 = $k * $y1; $y2 = $k * $y2; $z1 = $k * $z1; $z2 = $k * $z2
    $parts = @()
    $parts += ('"coordinates": [{0}, {1}, {2}, {3}, {4}, {5}]' -f $nx1, $y1, $z1, ($nx2 - $nx1), ($y2 - $y1), ($z2 - $z1))
    foreach ($k in 'uvNorth', 'uvEast', 'uvSouth', 'uvWest', 'uvUp', 'uvDown') {
        $r = $script:uv[$m[$k]]
        $parts += ('"{0}": [{1}, {2}, {3}, {4}]' -f $k, $r[0], $r[1], $r[2], $r[3])
    }
    '        { ' + ($parts -join ', ') + ' }'
}
$sides = { param($mat) @{ uvNorth = $mat; uvSouth = $mat } }
$ends = { param($mat) @{ uvEast = $mat; uvWest = $mat } }

$boxes = @()
# jem space: +Y up, -X = driving direction (front), Z = sideways
$boxes += Box -19 -4 -10 20 -1 10 'dark'                                       # chassis
$boxes += Box -21 -4 -10.5 -19 0 10.5 'black'                                  # front bumper
$boxes += Box 20 -4 -10.5 21.5 0 10.5 'black'                                  # rear bumper
$f = @{ uvEast = 'hoodFront'; uvWest = 'hoodFront'; uvUp = 'hoodTop'; uvDown = 'dark' }
$boxes += Box -19 -1 -10 -10 6 10 'navy' $f                                    # hood / engine
# (coordinates below are the original layout: front = -X, cab x -10..5, cargo x 5..20)
# --- Cab: door panels (outer face = livery, inner face = interior) ---
$boxes += Box -10 -1 9 5 7 10 'interior' @{ uvSouth = 'cabSide'; uvDown = 'dark'; uvUp = 'navy' }
$boxes += Box -10 -1 -10 5 7 -9 'interior' @{ uvNorth = 'cabSide'; uvDown = 'dark'; uvUp = 'navy' }
$boxes += Box -10 -1 -9 -7 9 9 'interior' @{ uvUp = 'dash'; uvWest = 'navy'; uvEast = 'interior' }  # dashboard
# Driver seat (centre, where the rider sits) and passenger seat (right)
foreach ($sz in @(@(-3, 3), @(4.5, 8.5))) {
    $z1 = $sz[0]; $z2 = $sz[1]
    $boxes += Box -5.5 -1 $z1 -1.5 0.5 $z2 'seat'                              # cushion
    $boxes += Box -1.5 -1 $z1 0 10 $z2 'seat'                                  # backrest
    $boxes += Box -1.25 10 ($z1 + 1) -0.25 12.5 ($z2 - 1) 'seat'               # headrest
}
$boxes += Box -8 9 -0.5 -7.5 12 0.5 'black'                                    # steering column
$boxes += Box -8.5 11 -2.5 -7.5 15 2.5 'black'                                 # steering wheel
$boxes += Box -10 7 9 -9 17 10 'navy'                                          # A-pillar R
$boxes += Box -10 7 -10 -9 17 -9 'navy'                                        # A-pillar L
$boxes += Box 4 7 9 5 17 10 'navy'                                             # B-pillar
$boxes += Box 4 7 -10 5 17 -9 'navy'                                           # B-pillar
$boxes += Box -10 17 -10 5 19 10 'navy' @{ uvUp = 'light'; uvDown = 'interior' } # cab roof
# --- Partition with walk-through doorway (z -3.5..3.5) ---
$boxes += Box 4 -1 3.5 5 17 9 'wall'
$boxes += Box 4 -1 -9 5 17 -3.5 'wall'
$boxes += Box 4 14 -3.5 5 17 3.5 'wall'                                        # door header
$boxes += Box 3.75 -1 3.25 5.25 14 3.75 'shelf'                                # door frame
$boxes += Box 3.75 -1 -3.75 5.25 14 -3.25 'shelf'
# --- Hollow cargo area ---
$boxes += Box 5 -1 -9 19 0 9 'floor' @{ uvDown = 'dark' }                      # floor
$boxes += Box 5 18 -10 20 19 10 'navy' @{ uvUp = 'roof'; uvDown = 'wall' }     # roof
$boxes += Box 5 -1 9 20 18 10 'wall' @{ uvSouth = 'cargoSide'; uvUp = 'navy'; uvDown = 'dark' }    # side wall +Z
$boxes += Box 5 -1 -10 20 18 -9 'wall' @{ uvNorth = 'cargoSide'; uvUp = 'navy'; uvDown = 'dark' }  # side wall -Z
$boxes += Box 19 -1 -9 20 18 9 'rear' @{ uvNorth = 'navy'; uvSouth = 'navy'; uvUp = 'navy'; uvDown = 'dark' } # rear doors
$boxes += Box 12 17.5 -1 13 18 1 'light'                                       # ceiling light
# --- Shelves with packages on both sides, aisle in the middle ---
$pkgMat = @{ uvUp = 'packageTop'; uvDown = 'packageTop' }
foreach ($side in 1, -1) {
    $zi = 3.5 * $side; $zo = 8.75 * $side
    $za = [Math]::Min($zi, $zo); $zb = [Math]::Max($zi, $zo)
    foreach ($px in 6, 18) {                                                   # posts (nur Enden)
        $boxes += Box $px 0 ([Math]::Min($zi, $zi + 0.5 * $side)) ($px + 0.5) 17.5 ([Math]::Max($zi, $zi + 0.5 * $side)) 'shelf'
    }
    foreach ($by in 5.5, 11.5) { $boxes += Box 6 $by $za 18.5 ($by + 0.5) $zb 'shelf' }   # boards
    # packages: per level [x1, x2, height, depth]
    $levels = @(
        @{ y = 0;  p = @(@(6.75, 11.75, 4, 4.5), @(12.5, 18, 4.5, 4.75)) },
        @{ y = 6;  p = @(@(6.75, 12, 4, 4.5), @(13, 17.75, 3, 4)) },
        @{ y = 12; p = @(@(7, 12.5, 3.5, 4), @(13, 18, 5, 4.5)) }
    )
    if ($side -lt 0) { $levels = @($levels[1], $levels[2], $levels[0]); $levels[0].y = 0; $levels[1].y = 6; $levels[2].y = 12 }
    foreach ($lv in $levels) {
        foreach ($p in $lv.p) {
            $d = $p[3]; $zw = 8.75 * $side; $zf = $zw - $d * $side
            $boxes += Box $p[0] $lv.y ([Math]::Min($zw, $zf)) $p[1] ($lv.y + $p[2]) ([Math]::Max($zw, $zf)) 'package' $pkgMat
        }
    }
}
# loose packages in the aisle near the rear doors
$boxes += Box 15.5 0 -2.5 18.5 3 0.5 'package' $pkgMat
$boxes += Box -10 11 10 -8 14 12.5 'black'                                     # mirror R
$boxes += Box -10 11 -12.5 -8 14 -10 'black'                                   # mirror L
foreach ($wx in -12, 12) {
    foreach ($wz in @(@(10, 12), @(-12, -10))) {
        $boxes += Box ($wx - 3.5) -7 $wz[0] ($wx + 3.5) 0 $wz[1] 'black' @{ uvNorth = 'wheel'; uvSouth = 'wheel' }
    }
}

function Part($name, $withBoxes) {
    $b = if ($withBoxes) { "`n" + ($boxes -join ",`n") + "`n      " } else { '' }
    "    {`n      ""part"": ""$name"", ""id"": ""$name"", ""invertAxis"": ""xy"", ""translate"": [0, 0, 0], ""rotate"": [0, 0, 0],`n      ""boxes"": [$b]`n    }"
}
# $geo = part that carries the van. For boats this is "right" (the only vanilla boat part with no built-in rotation).
function Jem($geo, $partNames) {
    $models = @(Part $geo $true)
    foreach ($p in $partNames) { $models += Part $p $false }
    "{`n  ""credit"": ""PrimeBlock"",`n  ""texture"": ""textures/entity/primeblock_van.png"",`n  ""textureSize"": [512, 512],`n  ""models"": [`n" + ($models -join ",`n") + "`n  ]`n}`n"
}
$boatParts = 'bottom', 'back', 'front', 'left', 'paddle_left', 'paddle_right'
$chest = 'chest_bottom', 'chest_lid', 'chest_lock'
$raftParts = 'paddle_left', 'paddle_right'

$utf8 = New-Object System.Text.UTF8Encoding $false
function Save($name, $content) { [System.IO.File]::WriteAllText((Join-Path $cem $name), $content, $utf8) }

$jBoat = Jem 'right' $boatParts; $jChest = Jem 'right' ($boatParts + $chest)
$jRaft = Jem 'bottom' $raftParts; $jChestRaft = Jem 'bottom' ($raftParts + $chest)
Save 'boat.jem' $jBoat; Save 'chest_boat.jem' $jChest
Save 'raft.jem' $jRaft; Save 'chest_raft.jem' $jChestRaft
foreach ($w in 'oak', 'spruce', 'birch', 'jungle', 'acacia', 'dark_oak', 'mangrove', 'cherry', 'pale_oak') {
    Save "${w}_boat.jem" $jBoat; Save "${w}_chest_boat.jem" $jChest
}
Save 'bamboo_raft.jem' $jRaft; Save 'bamboo_chest_raft.jem' $jChestRaft

# ---------------- pack.mcmeta + icon ----------------
$meta = @'
{
  "pack": {
    "pack_format": 34,
    "supported_formats": { "min_inclusive": 34, "max_inclusive": 99 },
    "min_format": 34,
    "max_format": 99,
    "description": "SECT6PrimeBlock\nSECT7Lieferwagen, Mitarbeiter, Arbeitskleidung & Pakete"
  }
}
'@
$meta = $meta.Replace('SECT', '\u00' + 'a7')
[System.IO.File]::WriteAllText((Join-Path $root 'pack.mcmeta'), $meta, $utf8)

$icon = New-Object System.Drawing.Bitmap 128, 128
$g = [System.Drawing.Graphics]::FromImage($icon)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
$g.Clear((C $navy))
$g.FillRectangle((Br $lgray), 0, 104, 128, 24)
$g.FillRectangle((Br $navyL), 14, 34, 100, 58)
$g.FillRectangle((Br '#9FD3F0'), 18, 40, 16, 22)
$g.FillEllipse((Br $black), 22, 82, 24, 24); $g.FillEllipse((Br $silver), 29, 89, 10, 10)
$g.FillEllipse((Br $black), 84, 82, 24, 24); $g.FillEllipse((Br $silver), 91, 89, 10, 10)
Text 'PrimeBlock' 14 $white 76 52
Smile 76 66 46 4
Text 'VAN' 22 $orange 64 16
$g.Dispose()
$icon.Save((Join-Path $root 'pack.png'), [System.Drawing.Imaging.ImageFormat]::Png); $icon.Dispose()

# ---------------- Zip (forward slashes) ----------------
. (Join-Path $PSScriptRoot 'extras.ps1')
. (Join-Path $PSScriptRoot 'extras2.ps1')

# ---------------- Performance: HD-Entity-Texturen halbieren (2x2-Mittelung, 75 % weniger Grafikspeicher) ----------------
function Halve($path) {
    $src = [System.Drawing.Image]::FromFile($path)
    $dst = New-Object System.Drawing.Bitmap ([int]($src.Width / 2)), ([int]($src.Height / 2)), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gr = [System.Drawing.Graphics]::FromImage($dst)
    $gr.InterpolationMode = 'HighQualityBilinear'; $gr.PixelOffsetMode = 'Half'; $gr.CompositingMode = 'SourceCopy'
    $attr = New-Object System.Drawing.Imaging.ImageAttributes; $attr.SetWrapMode('TileFlipXY')
    $gr.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $dst.Width, $dst.Height), 0, 0, $src.Width, $src.Height, 'Pixel', $attr)
    $gr.Dispose(); $src.Dispose()
    $dst.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $dst.Dispose()
}
# Halbieren ist abgeschaltet (volle Qualitaet gewuenscht). Bei FPS-Problemen wieder einschalten:
$halveTextures = $false
if ($halveTextures) {
    $halve = @(Get-ChildItem (Join-Path $root 'assets\minecraft\textures\entity\villager') -Recurse -Filter *.png) +
             @(Get-ChildItem (Join-Path $root 'assets\minecraft\textures\models\armor') -Filter *.png) +
             @(Get-ChildItem (Join-Path $root 'assets\minecraft\textures\entity\equipment') -Recurse -Filter *.png)
    foreach ($f in $halve) {
        $img = [System.Drawing.Image]::FromFile($f.FullName); $w = $img.Width; $img.Dispose()
        if ($w -gt 64) { Halve $f.FullName }   # leere 64x64-Overlays bleiben
    }
}

$zip = Join-Path $PSScriptRoot 'PrimeBlock.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
$z = [System.IO.Compression.ZipFile]::Open($zip, 'Create')
Get-ChildItem $root -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z, $_.FullName, $rel) | Out-Null
}
$z.Dispose()
"OK: $zip"
