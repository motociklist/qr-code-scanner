Add-Type -AssemblyName System.Drawing

$bmp = New-Object System.Drawing.Bitmap(1024, 1024)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::White)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
$cellSize = 40

# Draw corner squares
$g.FillRectangle($brush, 0, 0, 280, 280)
$g.FillRectangle([System.Drawing.Brushes]::White, 40, 40, 200, 200)
$g.FillRectangle($brush, 80, 80, 120, 120)

$g.FillRectangle($brush, 744, 0, 280, 280)
$g.FillRectangle([System.Drawing.Brushes]::White, 784, 40, 200, 200)
$g.FillRectangle($brush, 824, 80, 120, 120)

$g.FillRectangle($brush, 0, 744, 280, 280)
$g.FillRectangle([System.Drawing.Brushes]::White, 40, 784, 200, 200)
$g.FillRectangle($brush, 80, 824, 120, 120)

# Draw data pattern
for ($i = 0; $i -lt 25; $i++) {
    for ($j = 0; $j -lt 25; $j++) {
        $inCorner = (($i -lt 7 -and $j -lt 7) -or ($i -ge 18 -and $j -lt 7) -or ($i -lt 7 -and $j -ge 18))
        if (-not $inCorner) {
            if ((($i + $j) % 3 -eq 0) -or (($i * $j) % 7 -eq 0)) {
                $g.FillRectangle($brush, $i * $cellSize, $j * $cellSize, $cellSize, $cellSize)
            }
        }
    }
}

# Save the image
$outputPath = Join-Path $PSScriptRoot "..\assets\images\app_icon.png"
$directory = Split-Path $outputPath -Parent
if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}
$bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()

Write-Host "Icon created at $outputPath"

