# Dot-sourced aus extras.ps1: Villager-Grunduniform und 14 Berufe mit Stoffstruktur, Schatten und Details.
# ACHTUNG: PowerShell-Variablen ignorieren Gross/Kleinschreibung ($s ist die Skalierung, $g die Zeichenflaeche).

if (-not ('PbTex' -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class PbTex {
    static byte[] Open(Bitmap b, out BitmapData d) {
        d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        byte[] a = new byte[d.Stride * b.Height];
        Marshal.Copy(d.Scan0, a, 0, a.Length);
        return a;
    }
    static void Close(Bitmap b, BitmapData d, byte[] a) { Marshal.Copy(a, 0, d.Scan0, a.Length); b.UnlockBits(d); }
    static byte Clamp(double v) { return (byte)(v < 0 ? 0 : (v > 255 ? 255 : v)); }
    static void Mul(byte[] a, int i, double f) {
        a[i] = Clamp(a[i] * f); a[i + 1] = Clamp(a[i + 1] * f); a[i + 2] = Clamp(a[i + 2] * f);
    }
    static double Hash(int x, int y, int s) {
        unchecked {
            int n = x * 374761393 + y * 668265263 + s * 1274126177;
            n = (n ^ (n >> 13)) * 1274126177;
            n = n ^ (n >> 16);
            return ((n & 0xFFFF) / 65535.0) * 2.0 - 1.0;
        }
    }
    // Stoffkorn (fein) und Flecken (grob) auf allen sichtbaren Pixeln
    public static void Noise(Bitmap b, int fine, double fineAmp, int coarse, double coarseAmp, int seed) {
        BitmapData d; byte[] a = Open(b, out d);
        for (int y = 0; y < b.Height; y++) for (int x = 0; x < b.Width; x++) {
            int i = y * d.Stride + x * 4;
            if (a[i + 3] == 0) continue;
            double f = 1.0 + Hash(x / fine, y / fine, seed) * fineAmp + Hash(x / coarse, y / coarse, seed + 7) * coarseAmp;
            Mul(a, i, f);
        }
        Close(b, d, a);
    }
    // Licht von oben: Helligkeit laeuft von top nach bottom
    public static void Gradient(Bitmap b, int rx, int ry, int rw, int rh, double top, double bottom) {
        BitmapData d; byte[] a = Open(b, out d);
        for (int y = ry; y < ry + rh && y < b.Height; y++) {
            double f = top + (bottom - top) * (y - ry) / Math.Max(1, rh - 1);
            for (int x = rx; x < rx + rw && x < b.Width; x++) {
                int i = y * d.Stride + x * 4;
                if (a[i + 3] != 0) Mul(a, i, f);
            }
        }
        Close(b, d, a);
    }
    // Abdunkeln zu den Kanten hin (Rundung des Koerpers)
    public static void Edges(Bitmap b, int rx, int ry, int rw, int rh, int width, double factor) {
        BitmapData d; byte[] a = Open(b, out d);
        for (int y = ry; y < ry + rh && y < b.Height; y++) for (int x = rx; x < rx + rw && x < b.Width; x++) {
            int dist = Math.Min(x - rx, rx + rw - 1 - x);
            if (dist >= width) continue;
            int i = y * d.Stride + x * 4;
            if (a[i + 3] != 0) Mul(a, i, factor + (1.0 - factor) * dist / (double)width);
        }
        Close(b, d, a);
    }
}
'@
}

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
# Linie in Textur-Einheiten; $al = Deckkraft 0-255, $dash = Naht (gestrichelt)
function Line($x1, $y1, $x2, $y2, $hex, $wid = 0.15, $al = 255, $dash = $false) {
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb($al, (C $hex))), ([single]($wid * $cs))
    if ($dash) { $pen.DashPattern = [single[]]@(2.5, 2) }
    $script:g.DrawLine($pen, [single]($x1 * $cs), [single]($y1 * $cs), [single]($x2 * $cs), [single]($y2 * $cs))
    $pen.Dispose()
}
function RectA($u, $v, $wd, $ht, $hex, $al) {
    $br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($al, (C $hex)))
    $script:g.FillRectangle($br, [single]($u * $cs), [single]($v * $cs), [single]($wd * $cs), [single]($ht * $cs))
    $br.Dispose()
}
function Stitch($x1, $y1, $x2, $y2, $hex) { Line $x1 $y1 $x2 $y2 $hex 0.09 170 $true }
function Pocket($u, $v, $wd, $ht, $hex) {
    # Aufgesetzte Tasche mit Klappe und Naht
    RectA $u $v $wd $ht '#000000' 28
    Line $u $v ($u + $wd) $v '#000000' 0.12 90; Line $u ($v + $ht) ($u + $wd) ($v + $ht) '#000000' 0.14 110
    Line $u $v $u ($v + $ht) '#000000' 0.12 90; Line ($u + $wd) $v ($u + $wd) ($v + $ht) '#000000' 0.12 90
    Rect $u $v $wd ($ht * 0.32) (Shade $hex 1.1)
    Line $u ($v + $ht * 0.32) ($u + $wd) ($v + $ht * 0.32) '#000000' 0.12 120
    Stitch ($u + 0.15) ($v + $ht - 0.2) ($u + $wd - 0.15) ($v + $ht - 0.2) (Shade $hex 1.6)
}
function Wrinkle($x1, $y1, $x2, $y2) {
    Line $x1 $y1 $x2 $y2 '#000000' 0.2 42
    Line ($x1 + 0.12) ($y1 + 0.14) ($x2 + 0.12) ($y2 + 0.14) '#FFFFFF' 0.1 18
}
function ShadeFace($f, $top = 1.08, $bottom = 0.88, $edge = 0.78) {
    $u = $cs * $ck
    $px = [int]($f[0] * $u); $py = [int]($f[1] * $u); $pw = [int]($f[2] * $u); $ph = [int]($f[3] * $u)
    [PbTex]::Gradient($script:cv, $px, $py, $pw, $ph, $top, $bottom)
    [PbTex]::Edges($script:cv, $px, $py, $pw, $ph, [int]($u * 0.9), $edge)
}
function ShadeBox($Fb, $keys = @('right', 'front', 'left', 'back'), $top = 1.08, $bottom = 0.88, $edge = 0.78) {
    $script:g.Flush()
    foreach ($kk in $keys) { ShadeFace $Fb[$kk] $top $bottom $edge }
}
function Grain($seed, $fineAmp = 0.04, $coarseAmp = 0.035) {
    $script:g.Flush()
    [PbTex]::Noise($script:cv, 4, $fineAmp, 16, $coarseAmp, $seed)
}

# ===================== Grunduniform =====================
$skinL = '#CC9B77'; $skinS = '#9C6C50'; $shoe = '#1B1B1D'; $leather = '#3A2A1E'
NewCanvas 64 64 $s

# --- Kopf ---
$Hh = Faces 0 0 8 10 8
FillAll $Hh $skin
FillFace $Hh.bottom $skinS
FillFace $Hh.top $navy
SideRows $Hh 0 3 $navy; SideRows $Hh 2.6 3 $navyD
$hb = $Hh.back; Rect $hb[0] ($hb[1] + 3) 8 3.6 $hair
$hr = $Hh.right; Rect $hr[0] ($hr[1] + 3) 5 2.4 $hair; Rect $hr[0] ($hr[1] + 5.4) 3 1 $hair
$hl = $Hh.left; Rect ($hl[0] + 3) ($hl[1] + 3) 5 2.4 $hair; Rect ($hl[0] + 5) ($hl[1] + 5.4) 3 1 $hair
Rect ($hr[0] + 3.4) ($hr[1] + 4.6) 1.4 2 $skinS; Rect ($hl[0] + 3.2) ($hl[1] + 4.6) 1.4 2 $skinS   # Ohren
FillAll (Faces 24 0 2 4 2) $skinL
$Nn = Faces 24 0 2 4 2
ShadeBox $Nn @('right', 'left', 'back') 1.0 0.8 0.85
ShadeBox $Hh @('right', 'left', 'back', 'front') 1.05 0.9 0.82
Grain 11 0.04 0.05

# Gesicht
$fx = $Hh.front[0]; $fy = $Hh.front[1]
RectA $fx ($fy + 3) 8 0.7 '#000000' 55                                             # Schatten der Kappe
Rect ($fx + 0.8) ($fy + 4.1) 2.5 0.55 $hair; Rect ($fx + 4.7) ($fy + 4.1) 2.5 0.55 $hair   # Augenbrauen
Rect ($fx + 3.1) ($fy + 4.35) 1.8 0.4 (Shade $hair 1.2)
foreach ($ex in 1, 5) {
    Rect ($fx + $ex) ($fy + 5) 2 1 '#F4F1E8'                                        # Augenweiss
    $ix = if ($ex -eq 1) { $fx + 2 } else { $fx + 5 }
    Rect $ix ($fy + 5) 1 1 '#2E7D32'; Rect ($ix + 0.25) ($fy + 5.25) 0.5 0.5 '#0D2B12'  # Iris + Pupille
    Rect ($ix + 0.1) ($fy + 5.1) 0.22 0.22 '#FFFFFF'                                # Glanzpunkt
    Line ($fx + $ex) ($fy + 5) ($fx + $ex + 2) ($fy + 5) '#3B2A20' 0.18                # Oberlid
    RectA ($fx + $ex) ($fy + 6) 2 0.35 '#000000' 40                                 # Schatten unterm Auge
}
RectA ($fx + 0.5) ($fy + 6.8) 2 1.2 '#C4453A' 45; RectA ($fx + 5.5) ($fy + 6.8) 2 1.2 '#C4453A' 45   # Wangen
Rect ($fx + 2) ($fy + 8.2) 1 0.4 '#6E3B2C'; Rect ($fx + 5) ($fy + 8.2) 1 0.4 '#6E3B2C'            # Mund neben der Nase
RectA ($fx + 1.4) ($fy + 8.7) 5.2 1.3 '#2B1B12' 40                                  # Bartschatten
RectA $fx ($fy + 9.5) 8 0.5 '#000000' 40
for ($k = 0; $k -lt 14; $k++) { Line ($hb[0] + 0.4 + $k * 0.55) ($hb[1] + 3.1) ($hb[0] + 0.3 + $k * 0.55) ($hb[1] + 6.4 - ($k % 3) * 0.4) '#000000' 0.1 70 }  # Haarstraehnen
RectA $hb[0] ($hb[1] + 3) 8 0.6 '#000000' 50
# Nase: Nasenloecher und Schatten
$nf = $Nn.front; Rect $nf[0] ($nf[1] + 3.2) 0.6 0.5 $skinS; Rect ($nf[0] + 1.4) ($nf[1] + 3.2) 0.6 0.5 $skinS
RectA $nf[0] $nf[1] 2 0.5 '#FFFFFF' 26; FillFace $Nn.bottom $skinS

# Kappe: Stoffbahnen, Knopf, Schirmband, Logo
$ct = $Hh.top
Line ($ct[0] + 4) $ct[1] ($ct[0] + 4) ($ct[1] + 8) '#000000' 0.12 90; Line $ct[0] ($ct[1] + 4) ($ct[0] + 8) ($ct[1] + 4) '#000000' 0.12 90
Line $ct[0] $ct[1] ($ct[0] + 8) ($ct[1] + 8) '#000000' 0.12 70; Line ($ct[0] + 8) $ct[1] $ct[0] ($ct[1] + 8) '#000000' 0.12 70
Rect ($ct[0] + 3.5) ($ct[1] + 3.5) 1 1 $navyL; RectA ($ct[0] + 1) ($ct[1] + 1) 2.5 2.5 '#FFFFFF' 14
foreach ($kk in 'right', 'front', 'left', 'back') {
    $cf = $Hh[$kk]
    Line ($cf[0] + 2.7) $cf[1] ($cf[0] + 2.7) ($cf[1] + 2.6) '#000000' 0.1 80; Line ($cf[0] + 5.3) $cf[1] ($cf[0] + 5.3) ($cf[1] + 2.6) '#000000' 0.1 80
    Stitch $cf[0] ($cf[1] + 2.45) ($cf[0] + 8) ($cf[1] + 2.45) (Shade $navy 2.2)
}
$m = Mid $Hh.front; Smile $m[0] ($m[1] + 1.4 * $s) (4 * $s) (0.42 * $s)

# --- Hemd + Hose (Jacket-Layer) ---
$Jj = Faces 0 38 8 20 6
FillAll $Jj $navy
SideRows $Jj 11 12 $leather; SideRows $Jj 12 20 $pants
FillFace $Jj.bottom $pants; FillFace $Jj.top (Shade $navy 1.15)
FillAll (Faces 16 20 8 12 6) $navyD
ShadeBox $Jj @('right', 'front', 'left', 'back') 1.14 0.8 0.74
Grain 23 0.045 0.04

$jx = $Jj.front[0]; $jy = $Jj.front[1]
# Kragen und Knopfleiste
$script:g.FillPolygon((Br $skin), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF ([single](($jx + 3) * $s)), ([single]($jy * $s))), (New-Object System.Drawing.PointF ([single](($jx + 5) * $s)), ([single]($jy * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4) * $s)), ([single](($jy + 1.6) * $s)))))
foreach ($sd in -1, 1) {
    $script:g.FillPolygon((Br $navyL), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 1) * $s)), ([single]($jy * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 2.6) * $s)), ([single]($jy * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 2.2) * $s)), ([single](($jy + 1.5) * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 0.15) * $s)), ([single](($jy + 1.75) * $s)))))
    Line ($jx + 4 + $sd * 0.15) ($jy + 1.75) ($jx + 4 + $sd * 2.2) ($jy + 1.5) '#000000' 0.12 130
}
Rect ($jx + 3.55) ($jy + 1.6) 0.9 9.4 (Shade $navy 1.18)
Line ($jx + 3.55) ($jy + 1.6) ($jx + 3.55) ($jy + 11) '#000000' 0.08 110; Line ($jx + 4.45) ($jy + 1.6) ($jx + 4.45) ($jy + 11) '#000000' 0.08 110
foreach ($by in 2.4, 4.4, 6.4, 8.4, 10.2) { Rect ($jx + 3.82) ($jy + $by) 0.36 0.36 '#C9CDD2' }
# Brusttaschen, Namensschild, Falten
Pocket ($jx + 5.1) ($jy + 2.6) 2.2 2.6 $navy
$script:g.FillRectangle((Br $orange), [single](($jx + 5.5) * $s), [single](($jy + 3.7) * $s), [single](1.4 * $s), [single](0.18 * $s))
Rect ($jx + 0.8) ($jy + 2.8) 2.1 1 '#F4F4F4'; Rect ($jx + 1) ($jy + 3.05) 1.7 0.2 '#7A7A7A'; Rect ($jx + 1) ($jy + 3.4) 1.1 0.15 '#A8A8A8'
Wrinkle ($jx + 0.8) ($jy + 10.6) ($jx + 2.4) ($jy + 7.8); Wrinkle ($jx + 7.2) ($jy + 10.6) ($jx + 5.6) ($jy + 8)
Wrinkle ($jx + 1.8) ($jy + 10.7) ($jx + 3) ($jy + 8.9); Wrinkle ($jx + 6.2) ($jy + 10.7) ($jx + 5) ($jy + 9.2)
Wrinkle ($jx + 0.5) ($jy + 6) ($jx + 2.6) ($jy + 5.2)
# Guertel
foreach ($kk in 'right', 'front', 'left', 'back') {
    $bf = $Jj[$kk]
    Line $bf[0] ($bf[1] + 11.05) ($bf[0] + $bf[2]) ($bf[1] + 11.05) '#6A4E38' 0.1
    Stitch $bf[0] ($bf[1] + 11.85) ($bf[0] + $bf[2]) ($bf[1] + 11.85) '#8A6B50'
    Line ($bf[0] + 1.4) ($bf[1] + 10.9) ($bf[0] + 1.4) ($bf[1] + 12.1) $pants 0.4
    Line ($bf[0] + $bf[2] - 1.4) ($bf[1] + 10.9) ($bf[0] + $bf[2] - 1.4) ($bf[1] + 12.1) $pants 0.4
}
Rect ($jx + 3.45) ($jy + 11) 1.1 1 '#C9CDD2'; Rect ($jx + 3.7) ($jy + 11.25) 0.6 0.5 $leather
# Hose vorne
Line ($jx + 4) ($jy + 12) ($jx + 4) ($jy + 20) '#000000' 0.2 110                    # Beine trennen
Stitch ($jx + 4.45) ($jy + 12.1) ($jx + 4.45) ($jy + 14.4) (Shade $pants 1.8)
Line ($jx + 0.3) ($jy + 12.1) ($jx + 2) ($jy + 13.7) '#000000' 0.13 110; Line ($jx + 7.7) ($jy + 12.1) ($jx + 6) ($jy + 13.7) '#000000' 0.13 110  # Taschen
Line ($jx + 2) ($jy + 12.5) ($jx + 2) ($jy + 19.8) '#FFFFFF' 0.08 28; Line ($jx + 6) ($jy + 12.5) ($jx + 6) ($jy + 19.8) '#FFFFFF' 0.08 28     # Buegelfalte
Wrinkle ($jx + 0.6) ($jy + 16.4) ($jx + 3.2) ($jy + 15.8); Wrinkle ($jx + 4.8) ($jy + 15.8) ($jx + 7.4) ($jy + 16.4)
Wrinkle ($jx + 0.9) ($jy + 17.5) ($jx + 3) ($jy + 17.2); Wrinkle ($jx + 5) ($jy + 17.2) ($jx + 7.1) ($jy + 17.5)
Stitch $jx ($jy + 19.6) ($jx + 8) ($jy + 19.6) (Shade $pants 1.8)
# Seiten: Naht und Cargotasche
foreach ($kk in 'right', 'left') {
    $sf = $Jj[$kk]
    Line ($sf[0] + 3) ($sf[1] + 0.3) ($sf[0] + 3) ($sf[1] + 11) '#000000' 0.12 90
    Line ($sf[0] + 3) ($sf[1] + 12) ($sf[0] + 3) ($sf[1] + 20) '#000000' 0.12 90
    Pocket ($sf[0] + 1) ($sf[1] + 14) 4 3.4 $pants
    Rect ($sf[0] + 2.8) ($sf[1] + 14.8) 0.4 0.4 '#8A8F96'
    Wrinkle ($sf[0] + 0.6) ($sf[1] + 8.4) ($sf[0] + 2.6) ($sf[1] + 10.4); Wrinkle ($sf[0] + 5.4) ($sf[1] + 8) ($sf[0] + 3.4) ($sf[1] + 10.4)
}
# Ruecken: Passe, Falte, Gesaesstaschen, Schrift
$bx0 = $Jj.back[0]; $by0 = $Jj.back[1]
Line $bx0 ($by0 + 1.4) ($bx0 + 8) ($by0 + 1.4) '#000000' 0.13 110; Stitch $bx0 ($by0 + 1.6) ($bx0 + 8) ($by0 + 1.6) (Shade $navy 2)
Line ($bx0 + 4) ($by0 + 7.8) ($bx0 + 4) ($by0 + 11) '#000000' 0.12 70
Wrinkle ($bx0 + 0.8) ($by0 + 10.5) ($bx0 + 3) ($by0 + 8.6); Wrinkle ($bx0 + 7.2) ($by0 + 10.5) ($bx0 + 5) ($by0 + 8.6)
Line ($bx0 + 4) ($by0 + 12) ($bx0 + 4) ($by0 + 20) '#000000' 0.2 110
Pocket ($bx0 + 0.7) ($by0 + 13) 2.6 2.6 $pants; Pocket ($bx0 + 4.7) ($by0 + 13) 2.6 2.6 $pants
Stitch $bx0 ($by0 + 19.6) ($bx0 + 8) ($by0 + 19.6) (Shade $pants 1.8)
$m = Mid $Jj.back
Text 'Prime' 18 $white $m[0] ($m[1] + 3 * $s)
Text 'Block' 18 $white $m[0] ($m[1] + 5.1 * $s)
Smile $m[0] ($m[1] + 7 * $s) (5.5 * $s) (0.42 * $s)

# --- Arme: Oberarme mit Falten, verschraenkte Unterarme mit Manschetten und Haenden ---
$Aa = Faces 44 22 4 8 4
FillAll $Aa $navy; FillFace $Aa.top (Shade $navy 1.2); FillFace $Aa.bottom $navyD
ShadeBox $Aa @('right', 'front', 'left', 'back') 1.15 0.82 0.72
$Bb = Faces 40 38 8 4 4
FillAll $Bb $navy; FillFace $Bb.bottom $navyD; FillFace $Bb.top (Shade $navy 1.15)
$bfr = $Bb.front
Rect $bfr[0] $bfr[1] 1.5 4 $skin; Rect ($bfr[0] + 6.5) $bfr[1] 1.5 4 $skin           # Haende
Rect ($bfr[0] + 1.5) $bfr[1] 0.7 4 $navyD; Rect ($bfr[0] + 5.8) $bfr[1] 0.7 4 $navyD   # Manschetten
foreach ($kk in 'right', 'left') { FillFace $Bb[$kk] $navy }
ShadeBox $Bb @('front', 'back', 'right', 'left') 1.1 0.8 0.86
Grain 37 0.045 0.04
foreach ($sy in 0.9, 1.9, 2.9) {
    Line $bfr[0] ($bfr[1] + $sy) ($bfr[0] + 1.45) ($bfr[1] + $sy) $skinS 0.14       # Finger
    Line ($bfr[0] + 6.55) ($bfr[1] + $sy) ($bfr[0] + 8) ($bfr[1] + $sy) $skinS 0.14
}
Line ($bfr[0] + 1.5) $bfr[1] ($bfr[0] + 6.5) ($bfr[1] + 4) '#000000' 0.2 110         # Arm ueber Arm
Line ($bfr[0] + 1.6) ($bfr[1] + 0.2) ($bfr[0] + 6.5) ($bfr[1] + 4.1) '#FFFFFF' 0.08 28
Wrinkle ($bfr[0] + 2.6) ($bfr[1] + 3.6) ($bfr[0] + 3.6) ($bfr[1] + 2.2); Wrinkle ($bfr[0] + 5.2) ($bfr[1] + 0.4) ($bfr[0] + 4.4) ($bfr[1] + 1.8)
foreach ($kk in 'right', 'front', 'left', 'back') {
    $af = $Aa[$kk]
    Line $af[0] ($af[1] + 0.5) ($af[0] + 4) ($af[1] + 0.5) '#000000' 0.12 90        # Schulternaht
    Stitch $af[0] ($af[1] + 0.7) ($af[0] + 4) ($af[1] + 0.7) (Shade $navy 2)
    Wrinkle ($af[0] + 0.5) ($af[1] + 6.8) ($af[0] + 3.4) ($af[1] + 5.8); Wrinkle ($af[0] + 0.5) ($af[1] + 4.6) ($af[0] + 3) ($af[1] + 3.9)
}

# --- Beine und Arbeitsschuhe ---
$Ll = Faces 0 22 4 12 4
FillAll $Ll $pants; SideRows $Ll 9.6 12 $shoe; FillFace $Ll.bottom '#101012'
Rect $Ll.top[0] $Ll.top[1] 4 4 $pants
ShadeBox $Ll @('right', 'front', 'left', 'back') 1.05 0.82 0.75
Grain 41 0.035 0.03
$lf = $Ll.front
Rect ($lf[0] + 0.5) ($lf[1] + 10.5) 3 0.9 '#2A2A2D'                                  # Schuhkappe
foreach ($ly in 9.85, 10.2) { Line ($lf[0] + 1.2) ($lf[1] + $ly) ($lf[0] + 2.8) ($lf[1] + $ly) '#B8B8B8' 0.11 }  # Schnuersenkel
foreach ($kk in 'right', 'front', 'left', 'back') {
    $lg = $Ll[$kk]
    Line $lg[0] ($lg[1] + 9.6) ($lg[0] + 4) ($lg[1] + 9.6) '#000000' 0.14 150
    Rect $lg[0] ($lg[1] + 11.4) 4 0.6 '#5C4230'                                     # Sohle
    Stitch $lg[0] ($lg[1] + 11.32) ($lg[0] + 4) ($lg[1] + 11.32) '#9A9A9A'
    Stitch $lg[0] ($lg[1] + 9.3) ($lg[0] + 4) ($lg[1] + 9.3) (Shade $pants 1.8)
}
$lb = $Ll.bottom; for ($k = 1; $k -lt 4; $k++) { Line $lb[0] ($lb[1] + $k) ($lb[0] + 4) ($lb[1] + $k) '#2B2B2B' 0.18 }
SaveCanvas 'textures\entity\villager\villager.png'

# Biom-Overlays bleiben leer, damit jeder Villager die Uniform traegt
foreach ($tn in 'desert', 'jungle', 'plains', 'savanna', 'snow', 'swamp', 'taiga') { NewCanvas 64 64 1; SaveCanvas "textures\entity\villager\type\$tn.png" }

# ===================== Berufe =====================
$jobs = @(
    @{ p = 'farmer';        title = 'FAHRER';     cap = $orange;   vest = '#FF8A00'; txt = '#1B1B1B'; hivis = $true }
    @{ p = 'fisherman';     title = 'HAFEN';      cap = '#0E7C86'; vest = '#14A3B0'; txt = '#FFFFFF'; whistle = $true }
    @{ p = 'shepherd';      title = 'RETOUREN';   cap = '#D45D9E'; vest = '#E87BB6'; txt = '#FFFFFF' }
    @{ p = 'fletcher';      title = 'VERSAND';    cap = $prime;    vest = '#4FC3F7'; txt = '#0D2A3A' }
    @{ p = 'librarian';     title = 'SERVICE';    cap = '#6A3FA0'; vest = '#8E5CC9'; txt = '#FFFFFF'; glasses = $true }
    @{ p = 'cartographer';  title = 'ROUTEN';     cap = '#2E7D32'; vest = '#43A047'; txt = '#FFFFFF'; clipboard = $true }
    @{ p = 'cleric';        title = 'SANI';       cap = '#F2F2F2'; vest = '#F2F2F2'; txt = '#C62828'; cross = $true }
    @{ p = 'armorer';       title = 'SECURITY';   cap = '#1A1A1A'; vest = '#2A2A2A'; txt = '#FFD54F'; guard = $true }
    @{ p = 'weaponsmith';   title = 'MANAGER';    cap = $null;     vest = '#2B2F36'; txt = '#FFFFFF'; tie = $true }
    @{ p = 'toolsmith';     title = 'TECHNIK';    cap = '#F9A825'; vest = '#FBC02D'; txt = '#1B1B1B'; belt = $true; hivis = $true }
    @{ p = 'mason';         title = 'LAGER';      cap = '#616161'; vest = '#8D8D8D'; txt = '#FFFFFF'; hivis = $true }
    @{ p = 'leatherworker'; title = 'PACKER';     cap = '#6D4C41'; vest = '#A9743F'; txt = '#FFFFFF'; apron = $true }
    @{ p = 'butcher';       title = 'KANTINE';    cap = '#F2F2F2'; vest = '#F2F2F2'; txt = '#C62828'; apron = $true }
    @{ p = 'nitwit';        title = 'PRAKTIKANT'; cap = '#7CB342'; vest = '#9CCC65'; txt = '#1B1B1B'; trainee = $true }
)
$seedNo = 100
foreach ($job in $jobs) {
    $seedNo += 13
    $vc = $job.vest; $vd = Shade $vc 0.72; $vl = Shade $vc 1.16
    # Smile() zeichnet in $orange: auf oranger/gelber Kleidung stattdessen dunkelblau, damit er sichtbar bleibt
    $orangeSaved = $orange
    if ($job.p -in 'farmer', 'toolsmith') { $orange = $navy }
    NewCanvas 64 64 $s
    $Hh = Faces 0 0 8 10 8
    $Jj = Faces 0 38 8 20 6
    $jx = $Jj.front[0]; $jy = $Jj.front[1]; $bx0 = $Jj.back[0]; $by0 = $Jj.back[1]

    # --- Flaechen ---
    if ($job.cap) {
        $cd = Shade $job.cap 0.68
        FillFace $Hh.top $job.cap; SideRows $Hh 0 3 $job.cap; SideRows $Hh 2.6 3 $cd
    }
    if ($job.apron) {
        Rect $jx ($jy + 2) 8 15 $vc
        Rect ($jx + 1.5) $jy 0.7 2 $vc; Rect ($jx + 5.8) $jy 0.7 2 $vc
        foreach ($kk in 'right', 'left') { Rect $Jj[$kk][0] ($Jj[$kk][1] + 8) $Jj[$kk][2] 0.6 $vc }
        Rect $bx0 ($by0 + 8) 8 0.6 $vc
        Rect ($bx0 + 1.5) $by0 0.7 8 $vc; Rect ($bx0 + 5.8) $by0 0.7 8 $vc
        Rect ($bx0 + 0.8) ($by0 + 1.7) 6.4 3.2 $vc                                    # Schild mit Jobtitel deckt die Rueckenschrift
        Rect ($bx0 + 0.8) ($by0 + 5) 6.4 2.8 $navy
    } else {
        foreach ($kk in 'right', 'left', 'back') { Rows $Jj[$kk] 0 11 $vc }
        Rect $jx $jy 3 11 $vc; Rect ($jx + 5) $jy 3 11 $vc
        if ($job.tie) {
            Rect ($jx + 3) $jy 2 11 '#F4F4F4'
            foreach ($kk in 'right', 'left', 'back') { Rows $Jj[$kk] 11 20 '#23262C' }
            Rows $Jj.front 12 20 '#23262C'
        }
    }
    # --- Licht + Stoff ---
    if ($job.cap) { ShadeBox $Hh @('right', 'front', 'left', 'back') 1.1 0.86 0.8 }
    ShadeBox $Jj @('right', 'front', 'left', 'back') 1.12 0.8 0.76
    Grain $seedNo 0.045 0.04

    # --- Kappe ---
    if ($job.cap) {
        $ct = $Hh.top; $cd = Shade $job.cap 0.68
        Line ($ct[0] + 4) $ct[1] ($ct[0] + 4) ($ct[1] + 8) '#000000' 0.12 80; Line $ct[0] ($ct[1] + 4) ($ct[0] + 8) ($ct[1] + 4) '#000000' 0.12 80
        Line $ct[0] $ct[1] ($ct[0] + 8) ($ct[1] + 8) '#000000' 0.12 60; Line ($ct[0] + 8) $ct[1] $ct[0] ($ct[1] + 8) '#000000' 0.12 60
        Rect ($ct[0] + 3.5) ($ct[1] + 3.5) 1 1 (Shade $job.cap 1.2); RectA ($ct[0] + 1) ($ct[1] + 1) 2.5 2.5 '#FFFFFF' 18
        foreach ($kk in 'right', 'front', 'left', 'back') {
            $cf = $Hh[$kk]
            Line ($cf[0] + 2.7) $cf[1] ($cf[0] + 2.7) ($cf[1] + 2.6) '#000000' 0.1 70; Line ($cf[0] + 5.3) $cf[1] ($cf[0] + 5.3) ($cf[1] + 2.6) '#000000' 0.1 70
            Stitch $cf[0] ($cf[1] + 2.45) ($cf[0] + 8) ($cf[1] + 2.45) (Shade $job.cap 1.5)
        }
        if ($job.cross) {
            $cf = $Hh.front; Rect ($cf[0] + 3.5) ($cf[1] + 0.5) 1 2 '#C62828'; Rect ($cf[0] + 3) ($cf[1] + 1) 2 1 '#C62828'
        } else { $m = Mid $Hh.front; Smile $m[0] ($m[1] + 1.4 * $s) (4 * $s) (0.42 * $s) }
    }
    if ($job.glasses) {
        $gfx = $Hh.front[0]; $gfy = $Hh.front[1]
        foreach ($gx in 0.7, 4.7) { $script:g.DrawRectangle((Pn '#111111' 3), [single](($gfx + $gx) * $s), [single](($gfy + 4.7) * $s), [single](2.6 * $s), [single](1.7 * $s)); RectA ($gfx + $gx + 0.2) ($gfy + 4.9) 0.6 0.5 '#FFFFFF' 60 }
        Rect ($gfx + 3.3) ($gfy + 5.2) 1.4 0.3 '#111111'
        Line $Hh.right[0] ($Hh.right[1] + 5.2) ($Hh.right[0] + 8) ($Hh.right[1] + 5.2) '#111111' 0.25
        Line $Hh.left[0] ($Hh.left[1] + 5.2) ($Hh.left[0] + 8) ($Hh.left[1] + 5.2) '#111111' 0.25
    }

    # --- Kleidung ---
    if ($job.apron) {
        # Schuerze mit Latz, Tasche, Naehten
        Line $jx ($jy + 2) ($jx + 8) ($jy + 2) '#000000' 0.14 110; Stitch ($jx + 0.2) ($jy + 2.25) ($jx + 7.8) ($jy + 2.25) $vl
        Stitch ($jx + 0.25) ($jy + 2.3) ($jx + 0.25) ($jy + 16.8) $vl; Stitch ($jx + 7.75) ($jy + 2.3) ($jx + 7.75) ($jy + 16.8) $vl
        Line $jx ($jy + 8) ($jx + 8) ($jy + 8) '#000000' 0.2 60; Rect ($jx + 3.5) ($jy + 7.7) 1 0.7 $vd                 # Band + Knoten
        Pocket ($jx + 1.6) ($jy + 10) 4.8 3.4 $vc
        Rect ($jx + 2.6) ($jy + 9.2) 0.3 1.1 '#D0D0D0'; Rect ($jx + 4.9) ($jy + 9) 0.4 1.3 '#C62828'                  # Stifte in der Tasche
        Wrinkle ($jx + 1) ($jy + 15.8) ($jx + 3) ($jy + 14.6); Wrinkle ($jx + 7) ($jy + 15.8) ($jx + 5) ($jy + 14.6); Wrinkle ($jx + 1) ($jy + 7.2) ($jx + 3) ($jy + 5.6)
        Line $jx ($jy + 17) ($jx + 8) ($jy + 17) '#000000' 0.14 110
        if ($job.p -eq 'leatherworker') {
            Rect ($jx + 5.1) ($jy + 3) 2 2.4 '#C79A62'; Rect ($jx + 5.85) ($jy + 3) 0.5 2.4 '#E2C38F'                 # Paket-Abzeichen
        } else {
            RectA ($jx + 5.2) ($jy + 14) 1.3 0.9 '#C62828' 45; RectA ($jx + 1.5) ($jy + 15.4) 0.9 0.6 '#C62828' 35       # Flecken
        }
        $m = Mid $Jj.front; FitText 'PrimeBlock' $job.txt $m[0] ($m[1] + 15.3 * $s) (7 * $s) 12   # unter den verschraenkten Armen
        $m = Mid $Jj.back; FitText $job.title $job.txt $m[0] ($m[1] + 3.3 * $s) (6 * $s) 16
        Smile $m[0] ($m[1] + 6.2 * $s) (5 * $s) (0.42 * $s)
        Stitch ($bx0 + 0.9) ($by0 + 1.85) ($bx0 + 7.1) ($by0 + 1.85) $vd; Stitch ($bx0 + 0.9) ($by0 + 4.75) ($bx0 + 7.1) ($by0 + 4.75) $vd
    } else {
        # Weste: Saum, Reissverschluss, Taschen, Passe, Seitennaht
        foreach ($sd in 0, 1) {
            $pxl = if ($sd -eq 0) { $jx } else { $jx + 5 }
            Rect $pxl ($jy + 10.4) 3 0.6 $vd
            Stitch $pxl ($jy + 10.3) ($pxl + 3) ($jy + 10.3) $vl
            $edge = if ($sd -eq 0) { $jx + 2.75 } else { $jx + 5 }
            Rect $edge $jy 0.25 11 $vd
            Pocket ($pxl + 0.4) ($jy + 7.4) 2.2 2.6 $vc
        }
        Stitch ($jx + 2.55) $jy ($jx + 2.55) ($jy + 10.3) $vl; Stitch ($jx + 5.45) $jy ($jx + 5.45) ($jy + 10.3) $vl
        Line ($jx + 0.3) ($jy + 0.7) ($jx + 2.7) ($jy + 1.2) '#000000' 0.1 70; Line ($jx + 7.7) ($jy + 0.7) ($jx + 5.3) ($jy + 1.2) '#000000' 0.1 70   # Schulternaht
        Wrinkle ($jx + 0.6) ($jy + 6.6) ($jx + 2.4) ($jy + 5.6); Wrinkle ($jx + 7.4) ($jy + 6.6) ($jx + 5.6) ($jy + 5.6)
        foreach ($kk in 'right', 'left') {
            $sf = $Jj[$kk]
            Rect $sf[0] ($sf[1] + 10.4) $sf[2] 0.6 $vd
            Line ($sf[0] + 3) ($sf[1] + 0.3) ($sf[0] + 3) ($sf[1] + 10.4) '#000000' 0.12 80
            Wrinkle ($sf[0] + 0.7) ($sf[1] + 8.8) ($sf[0] + 2.6) ($sf[1] + 7.2); Wrinkle ($sf[0] + 5.3) ($sf[1] + 8.8) ($sf[0] + 3.4) ($sf[1] + 7.2)
        }
        Rect $bx0 ($by0 + 10.4) 8 0.6 $vd
        Line $bx0 ($by0 + 1.3) ($bx0 + 8) ($by0 + 1.3) '#000000' 0.12 100; Stitch $bx0 ($by0 + 1.5) ($bx0 + 8) ($by0 + 1.5) $vl
        Wrinkle ($bx0 + 0.8) ($by0 + 9.8) ($bx0 + 3) ($by0 + 8.2); Wrinkle ($bx0 + 7.2) ($by0 + 9.8) ($bx0 + 5) ($by0 + 8.2)

        if ($job.hivis) {
            # Reflektorstreifen mit Lichtkante, Schulterstreifen
            foreach ($kk in 'right', 'left', 'back') { $sf = $Jj[$kk]; Rect $sf[0] ($sf[1] + 6) $sf[2] 0.9 $refl; RectA $sf[0] ($sf[1] + 6) $sf[2] 0.25 '#FFFFFF' 170 }
            foreach ($pxl in $jx, ($jx + 5)) { Rect $pxl ($jy + 6) 3 0.9 $refl; RectA $pxl ($jy + 6) 3 0.25 '#FFFFFF' 170; Rect ($pxl + 1) $jy 0.8 6 $refl; RectA ($pxl + 1) $jy 0.22 6 '#FFFFFF' 150 }
            Rect ($bx0 + 1) $by0 0.8 2.2 $refl; Rect ($bx0 + 6.2) $by0 0.8 2.2 $refl       # nur bis ueber den Jobtitel
        }
        if ($job.tie) {
            # Anzug: Hemdkragen, Revers, gestreifte Krawatte, Einstecktuch, Knoepfe
            foreach ($sd in -1, 1) {
                $script:g.FillPolygon((Br '#FFFFFF'), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF ([single](($jx + 4) * $s)), ([single](($jy + 0.5) * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 1) * $s)), ([single]($jy * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 1.3) * $s)), ([single](($jy + 1) * $s)))))
                $script:g.FillPolygon((Br '#1D2026'), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 1) * $s)), ([single]($jy * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 2.6) * $s)), ([single]($jy * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 2.4) * $s)), ([single](($jy + 3) * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4 + $sd * 1) * $s)), ([single](($jy + 6.5) * $s)))))
                Line ($jx + 4 + $sd * 1) ($jy + 6.5) ($jx + 4 + $sd * 2.4) ($jy + 3) '#000000' 0.1 150
            }
            Rect ($jx + 3.55) ($jy + 0.9) 0.9 0.8 '#9E1F1F'
            $script:g.FillPolygon((Br '#C62828'), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF ([single](($jx + 3.6) * $s)), ([single](($jy + 1.7) * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4.4) * $s)), ([single](($jy + 1.7) * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4.7) * $s)), ([single](($jy + 7.2) * $s))), (New-Object System.Drawing.PointF ([single](($jx + 4) * $s)), ([single](($jy + 8) * $s))), (New-Object System.Drawing.PointF ([single](($jx + 3.3) * $s)), ([single](($jy + 7.2) * $s)))))
            foreach ($ty in 2.4, 3.6, 4.8, 6) { Line ($jx + 3.45) ($jy + $ty + 0.5) ($jx + 4.55) ($jy + $ty) '#8E1B1B' 0.16 }
            foreach ($ty in 8.6, 9.8) { Rect ($jx + 3.8) ($jy + $ty) 0.4 0.4 '#3A3F47' }
            Rect ($jx + 5.8) ($jy + 3.4) 1.2 0.5 '#C62828'; Line ($jx + 5.7) ($jy + 3.9) ($jx + 7.1) ($jy + 3.9) '#000000' 0.1 150  # Einstecktuch
            Rows $Jj.front 11 12 '#111111'; Rect ($jx + 3.5) ($jy + 11) 1 1 '#C9CDD2'
            Line ($jx + 4) ($jy + 12) ($jx + 4) ($jy + 20) '#000000' 0.2 150
            Line ($jx + 2) ($jy + 12.3) ($jx + 2) ($jy + 20) '#FFFFFF' 0.09 45; Line ($jx + 6) ($jy + 12.3) ($jx + 6) ($jy + 20) '#FFFFFF' 0.09 45  # Buegelfalte
        } else {
            # Namensschild mit Clip
            Rect ($jx + 5.5) ($jy + 2.2) 2 1.25 '#F4F4F4'; Rect ($jx + 5.5) ($jy + 2.2) 2 0.3 $vd
            Rect ($jx + 5.7) ($jy + 2.75) 1.6 0.18 '#555555'; Rect ($jx + 5.7) ($jy + 3.05) 1 0.14 '#999999'
            Rect ($jx + 6.3) ($jy + 1.9) 0.4 0.35 '#9EA4AA'
        }
        if ($job.guard) {
            Rect ($Jj.right[0] + 1) $Jj.right[1] 4 0.7 '#FFD54F'; Rect ($Jj.left[0] + 1) $Jj.left[1] 4 0.7 '#FFD54F'      # Schulterklappen
            Rect ($jx + 0.7) ($jy + 2) 1.5 1.8 '#FFD54F'; Rect ($jx + 1.1) ($jy + 2.5) 0.7 0.7 '#8A6D00'                    # Dienstmarke
            Rect ($jx + 0.9) ($jy + 4.6) 1 1.8 '#111111'; Rect ($jx + 1.1) ($jy + 3.9) 0.15 0.8 '#111111'                  # Funkgeraet
        }
        if ($job.whistle) { Line ($jx + 2.8) ($jy + 0.2) ($jx + 1.6) ($jy + 4.2) '#F5C400' 0.14; Rect ($jx + 1.1) ($jy + 4.2) 1 0.6 '#C9CDD2' }
        if ($job.trainee) { Rect ($jx + 0.7) ($jy + 2.3) 1.8 1.8 '#FFFFFF'; Rect ($jx + 1.1) ($jy + 2.6) 0.3 1.2 '#C62828'; Rect ($jx + 1.1) ($jy + 3.5) 1 0.3 '#C62828' }   # L-Schild
        if ($job.cross) {
            Rect ($bx0 + 3.25) ($by0 + 2) 1.5 3.9 '#C62828'; Rect ($bx0 + 2) ($by0 + 3.2) 4 1.5 '#C62828'
            $m = Mid $Jj.back; FitText $job.title $job.txt $m[0] ($m[1] + 7.7 * $s) (7.2 * $s) 16
            Rect ($jx + 0.8) ($jy + 2.2) 1.5 0.5 '#C62828'; Rect ($jx + 1.3) ($jy + 1.7) 0.5 1.5 '#C62828'
        } else {
            $m = Mid $Jj.back
            FitText $job.title $job.txt $m[0] ($m[1] + 3.6 * $s) (7.4 * $s) 16
            if (-not $job.hivis) { Smile $m[0] ($m[1] + 5.4 * $s) (5 * $s) (0.42 * $s) } else { Smile $m[0] ($m[1] + 8.4 * $s) (5 * $s) (0.42 * $s) }
        }
    }
    if ($job.belt) {
        foreach ($kk in 'right', 'front', 'left', 'back') { Rows $Jj[$kk] 10.8 11.8 '#5D4037'; Stitch $Jj[$kk][0] ($Jj[$kk][1] + 10.95) ($Jj[$kk][0] + $Jj[$kk][2]) ($Jj[$kk][1] + 10.95) '#A98770' }
        Rect ($jx + 0.3) ($jy + 11.8) 2 2.3 '#5D4037'; Line ($jx + 0.3) ($jy + 12.5) ($jx + 2.3) ($jy + 12.5) '#3E2A22' 0.14    # Werkzeugtasche
        Rect ($jx + 0.7) ($jy + 11) 0.3 1.6 '#9E9E9E'; Rect ($jx + 1.4) ($jy + 11.1) 0.5 1.2 '#E53935'                         # Schraubenzieher + Griff
        Rect ($jx + 5.9) ($jy + 11.8) 1.8 2 '#5D4037'; Rect ($jx + 6.4) ($jy + 10.9) 0.3 2 '#9E9E9E'; Rect ($jx + 6.1) ($jy + 10.7) 0.9 0.4 '#6E6E6E'   # Hammer
    }
    if ($job.clipboard) {
        $Mid2 = Faces 40 38 8 4 4
        $mf = $Mid2.front
        Rect ($mf[0] + 2) $mf[1] 4 4 '#6D4C2F'; Rect ($mf[0] + 2.35) ($mf[1] + 0.35) 3.3 3.3 '#F6F1E4'
        Rect ($mf[0] + 3.3) $mf[1] 1.4 0.5 '#9EA4AA'
        for ($k = 0; $k -lt 3; $k++) { Rect ($mf[0] + 2.7) ($mf[1] + 1.1 + $k * 0.8) 2.6 0.22 '#43A047' }
    }
    SaveCanvas "textures\entity\villager\profession\$($job.p).png"
    $orange = $orangeSaved
}
