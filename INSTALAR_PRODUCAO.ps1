param(
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ManifestUrl = "https://raw.githubusercontent.com/ApriMax/restaurante-massas-releases/main/latest.json"
$AppUrl = "http://127.0.0.1:8876"
$Root = Join-Path $env:LOCALAPPDATA "SistemaRestauranteMassas"
$EnvironmentFile = Join-Path $Root "environment.json"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\SistemaRestauranteMassas"
$Exe = Join-Path $InstallDir "Sistema_Restaurante_Massas.exe"
$Rollback = Join-Path $Root "installer_rollback"

function Stop-Restaurant {
    Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine.Contains("--app=$AppUrl") } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Get-Process "Sistema_Restaurante_Massas" -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

function New-AppShortcut {
    param([string]$Folder,[string]$Name)
    if(-not (Test-Path -LiteralPath $Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
    $ws = New-Object -ComObject WScript.Shell
    $path = Join-Path $Folder $Name
    $lnk = $ws.CreateShortcut($path)
    $lnk.TargetPath = $Exe
    $lnk.WorkingDirectory = $InstallDir
    $lnk.IconLocation = "$Exe,0"
    $lnk.Description = "Sistema Restaurante Massas - PRODUCAO"
    $lnk.Save()
}

function Write-ProductionMarker {
    New-Item -ItemType Directory -Force -Path $Root | Out-Null
    if(Test-Path -LiteralPath $EnvironmentFile){
        try {
            $current = Get-Content -LiteralPath $EnvironmentFile -Raw | ConvertFrom-Json
            if([string]$current.environment -eq "homologation"){
                throw "Este computador esta marcado como HOMOLOGACAO. O instalador de PRODUCAO foi bloqueado para evitar mistura de ambientes."
            }
        } catch {
            if($_.Exception.Message -like "*HOMOLOGACAO*"){ throw }
        }
    }
    @{
        environment = "production"
        label = "PRODUCAO"
        installed_by = "INSTALAR_PRODUCAO"
    } | ConvertTo-Json | Set-Content -LiteralPath $EnvironmentFile -Encoding UTF8
}

function Restore-Rollback {
    if(Test-Path -LiteralPath $Rollback){
        Write-Host "Restaurando arquivos anteriores..."
        New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
        robocopy $Rollback $InstallDir /MIR /R:2 /W:1 | Out-Null
        if(Test-Path -LiteralPath $Exe){ Start-Process -FilePath $Exe -WorkingDirectory $InstallDir }
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host " INSTALADOR OFICIAL - SISTEMA RESTAURANTE MASSAS - PRODUCAO"
Write-Host "============================================================"
Write-Host ""
Write-Host "Canal: PRODUCAO (stable)"
Write-Host "Manifesto: $ManifestUrl"
Write-Host ""
Write-ProductionMarker

$temp = Join-Path $env:TEMP ("SistemaRestauranteMassas_Install_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $temp | Out-Null

try {
    Write-Host "[1/7] Consultando a versao estavel aprovada..."
    $manifest = Invoke-RestMethod -UseBasicParsing -Uri $ManifestUrl -TimeoutSec 30
    if([string]$manifest.channel -ne "stable"){ throw "Manifesto invalido: o canal publicado nao e stable." }
    if(-not $manifest.download_url -or -not $manifest.sha256 -or -not $manifest.build){ throw "Manifesto de producao incompleto." }
    Write-Host ("Versao aprovada: {0} - {1}" -f $manifest.release,$manifest.build)

    $zip = Join-Path $temp "package.zip"
    Write-Host "[2/7] Baixando pacote oficial..."
    Invoke-WebRequest -UseBasicParsing -Uri ([string]$manifest.download_url) -OutFile $zip -TimeoutSec 180

    Write-Host "[3/7] Conferindo integridade SHA-256..."
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    if($hash -ne ([string]$manifest.sha256).ToLowerInvariant()){ throw "Hash do pacote diferente do manifesto. Instalacao cancelada." }

    $stage = Join-Path $temp "stage"
    Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force
    $newApp = Join-Path $stage "app"
    $newExe = Join-Path $newApp "Sistema_Restaurante_Massas.exe"
    if(-not (Test-Path -LiteralPath $newExe)){ throw "Pacote invalido: executavel nao encontrado." }

    Write-Host "[4/7] Encerrando uma versao anterior, se existir..."
    Stop-Restaurant

    if(Test-Path -LiteralPath $Rollback){ Remove-Item -LiteralPath $Rollback -Recurse -Force }
    if(Test-Path -LiteralPath $InstallDir){
        Copy-Item -LiteralPath $InstallDir -Destination $Rollback -Recurse -Force
    }

    Write-Host "[5/7] Instalando em $InstallDir ..."
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    robocopy $newApp $InstallDir /MIR /R:2 /W:1 | Out-Null
    if($LASTEXITCODE -ge 8){ throw "Falha ao copiar os arquivos do aplicativo." }

    Write-Host "[6/7] Criando atalhos..."
    New-AppShortcut -Folder ([Environment]::GetFolderPath("Desktop")) -Name "Sistema Restaurante Massas.lnk"
    New-AppShortcut -Folder ([Environment]::GetFolderPath("Programs")) -Name "Sistema Restaurante Massas.lnk"
    New-AppShortcut -Folder ([Environment]::GetFolderPath("Startup")) -Name "Sistema Restaurante Massas.lnk"

    Write-Host "[7/7] Abrindo e validando PRODUCAO..."
    Start-Process -FilePath $Exe -WorkingDirectory $InstallDir
    $ok=$false
    $lastHealth=$null
    1..100 | ForEach-Object {
        if(-not $ok){
            Start-Sleep -Milliseconds 500
            try {
                $h=Invoke-RestMethod -UseBasicParsing -Uri "$AppUrl/api/health" -TimeoutSec 1
                $lastHealth=$h
                if(($h.build -eq [string]$manifest.build) -and ($h.environment -eq "production")){ $ok=$true }
            } catch {}
        }
    }
    if(-not $ok){
        Stop-Restaurant
        Restore-Rollback
        $detail = if($lastHealth){ " Build detectado: $($lastHealth.build); ambiente: $($lastHealth.environment)." } else { "" }
        throw "A instalacao nao passou na validacao de PRODUCAO.$detail"
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host " INSTALACAO DE PRODUCAO CONCLUIDA"
    Write-Host "============================================================"
    Write-Host ("Release: {0}" -f $manifest.release)
    Write-Host ("Build:   {0}" -f $manifest.build)
    Write-Host ("Schema:  {0}" -f $manifest.schema)
    Write-Host "Ambiente confirmado: PRODUCAO"
    Write-Host ""
    Write-Host "Em computador novo, o sistema iniciara a Primeira Instalacao"
    Write-Host "e criara um banco local novo com o catalogo-base."
}
catch {
    Write-Host ""
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "A instalacao de PRODUCAO nao foi concluida."
    if(-not $NoPause){ Read-Host "Pressione ENTER para fechar" | Out-Null }
    exit 1
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}

if(-not $NoPause){ Read-Host "Pressione ENTER para fechar" | Out-Null }
exit 0
