# Prueba de la función FibMemo: pide cada valor dos veces (miss y luego hit)
# y registra las cabeceras de caché e instancia en un CSV.
#
# Procedimiento del laboratorio:
#   1) powershell -ExecutionPolicy Bypass -File scripts\prueba_fibmemo.ps1 -Archivo fase1_antes.csv
#   2) No hacer peticiones durante al menos 5 minutos (en el laboratorio fueron ~30).
#   3) powershell -ExecutionPolicy Bypass -File scripts\prueba_fibmemo.ps1 -Archivo fase2_despues.csv

param(
    [string]$Url = "https://functionprojectfibonacci-fhf9czb7cxh8hxcc.chilecentral-01.azurewebsites.net/api/FibMemo",
    [int[]]$Valores = @(1000, 3000, 5000),
    [string]$Archivo = "fibmemo.csv"
)

$raiz = Split-Path -Parent $PSScriptRoot
$secuencia = $Valores + $Valores   # primera pasada (miss) + segunda pasada (hit)

$filas = foreach ($n in $secuencia) {
    $body = @{ nth = $n } | ConvertTo-Json
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $resp = Invoke-WebRequest -Uri $Url -Method Post -Body $body -ContentType "application/json" -UseBasicParsing
    } catch {
        Write-Error "La petición nth=$n falló: $($_.Exception.Message). ¿La Function App está iniciada (Start) en el portal?"
        exit 1
    }
    $sw.Stop()

    [pscustomobject]@{
        Hora      = (Get-Date).ToString("HH:mm:ss")
        Nth       = $n
        Hit       = $resp.Headers["x-cache-hit"]
        Size      = $resp.Headers["x-cache-size"]
        Ms        = $sw.ElapsedMilliseconds
        Instancia = $resp.Headers["x-instance-started"]
    }
}

$filas | Format-Table
$filas | Export-Csv -Path (Join-Path $raiz $Archivo) -NoTypeInformation -Encoding UTF8
"Resultados guardados en $Archivo"
