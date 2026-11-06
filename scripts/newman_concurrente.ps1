# Lanza N ejecuciones concurrentes de la colección de Postman con Newman
# y guarda un reporte JSON por ejecución en first_newman/.
#
# Uso (desde la raíz del repositorio):
#   powershell -ExecutionPolicy Bypass -File scripts\newman_concurrente.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\newman_concurrente.ps1 -Peticiones 10 -Salida first_newman
#
# Requisitos: Node.js y Newman (npm install -g newman)

param(
    [int]$Peticiones = 10,
    [string]$Coleccion = "collection.json",
    [string]$Salida = "first_newman"
)

$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz
New-Item -ItemType Directory -Force $Salida | Out-Null

Get-Job | Remove-Job -Force

1..$Peticiones | ForEach-Object {
    Start-Job -ArgumentList $_, $raiz, $Coleccion, $Salida -ScriptBlock {
        param($i, $dir, $col, $out)
        Set-Location $dir
        newman run $col --reporters json --reporter-json-export "$out/result_$i.json"
    }
} | Out-Null

Get-Job | Wait-Job | Out-Null
Get-Job | Remove-Job -Force

# Resumen de resultados
$filas = 1..$Peticiones | ForEach-Object {
    $r = Get-Content "$Salida/result_$_.json" -Raw | ConvertFrom-Json
    $e = $r.run.executions[0]
    [pscustomobject]@{
        Run    = $_
        Status = $e.response.code
        Ms     = $e.response.responseTime
        Bytes  = $e.response.responseSize
    }
}
$filas | Format-Table

$ms = $filas | Measure-Object -Property Ms -Average -Minimum -Maximum
$ok = ($filas | Where-Object { $_.Status -eq 200 }).Count
"Exitosas: $ok / $Peticiones"
"Promedio: {0:N0} ms | Min: {1} ms | Max: {2} ms" -f $ms.Average, $ms.Minimum, $ms.Maximum
