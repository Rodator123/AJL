<#
    Creer-Cle-Bootable.ps1
    Écrit une image ISO hybride (ex. ISO archiso / Arch Linux) sur une clé USB.

    Utilisation :
      1. Clic droit sur PowerShell > "Exécuter en tant qu'administrateur"
      2. Set-ExecutionPolicy -Scope Process Bypass
      3. .\Creer-Cle-Bootable.ps1 -Iso "C:\chemin\vers\mon-os.iso"

    ATTENTION : TOUT le contenu de la clé choisie sera effacé définitivement.
    Seuls les disques détectés comme USB sont proposés.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Iso
)

$ErrorActionPreference = 'Stop'

# --- Vérifications préalables ---------------------------------------------
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
         ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Host "Ce script doit être lancé en tant qu'administrateur." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $Iso -PathType Leaf)) {
    Write-Host "ISO introuvable : $Iso" -ForegroundColor Red
    exit 1
}
$isoInfo = Get-Item -LiteralPath $Iso

# --- Liste des clés USB ----------------------------------------------------
$usbDisks = Get-Disk | Where-Object { $_.BusType -eq 'USB' }
if (-not $usbDisks) {
    Write-Host "Aucune clé USB détectée. Branchez-la puis relancez le script." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Clés USB détectées :" -ForegroundColor Cyan
$usbDisks | ForEach-Object {
    "{0,-3} {1,-30} {2,8:N1} Go" -f $_.Number, $_.FriendlyName, ($_.Size / 1GB)
}
Write-Host ""

$num = Read-Host "Numéro du disque à effacer et à rendre bootable"
$disk = $usbDisks | Where-Object { $_.Number -eq [int]$num }
if (-not $disk) {
    Write-Host "Numéro invalide (seules les clés USB listées sont acceptées)." -ForegroundColor Red
    exit 1
}

if ($isoInfo.Length -gt $disk.Size) {
    Write-Host "L'ISO est plus grande que la clé." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host ("Cible : disque {0} - {1} ({2:N1} Go)" -f $disk.Number, $disk.FriendlyName, ($disk.Size / 1GB)) -ForegroundColor Yellow
Write-Host "TOUTES LES DONNÉES DE CETTE CLÉ SERONT EFFACÉES." -ForegroundColor Yellow
$confirm = Read-Host "Tapez EFFACER pour confirmer"
if ($confirm -ne 'EFFACER') {
    Write-Host "Annulé."
    exit 0
}

# --- Nettoyage de la table de partitions -----------------------------------
Write-Host "Nettoyage de la clé..."
Clear-Disk -Number $disk.Number -RemoveData -RemoveOEM -Confirm:$false
Start-Sleep -Seconds 2

# --- Écriture brute de l'ISO ------------------------------------------------
$devicePath = "\\.\PhysicalDrive$($disk.Number)"
$blockSize  = 4MB
$buffer     = New-Object byte[] $blockSize

$src = [System.IO.File]::OpenRead($isoInfo.FullName)
$dst = New-Object System.IO.FileStream(
    $devicePath,
    [System.IO.FileMode]::Open,
    [System.IO.FileAccess]::Write,
    [System.IO.FileShare]::ReadWrite,
    $blockSize
)

try {
    $total   = $src.Length
    $written = 0L
    Write-Host "Écriture de l'ISO..."
    while (($read = $src.Read($buffer, 0, $buffer.Length)) -gt 0) {
        # Les écritures sur un disque brut doivent être alignées sur 512 octets
        $toWrite = [int]([math]::Ceiling($read / 512.0) * 512)
        if ($toWrite -gt $read) {
            [Array]::Clear($buffer, $read, $toWrite - $read)
        }
        $dst.Write($buffer, 0, $toWrite)
        $written += $read
        $pct = [int](($written / $total) * 100)
        Write-Progress -Activity "Écriture sur la clé USB" -Status "$pct %" -PercentComplete $pct
    }
    $dst.Flush()
}
finally {
    $dst.Close()
    $src.Close()
    Write-Progress -Activity "Écriture sur la clé USB" -Completed
}

Update-HostStorageCache
Write-Host ""
Write-Host "Terminé. Éjectez la clé proprement, puis démarrez dessus (menu de boot du BIOS/UEFI)." -ForegroundColor Green
Write-Host "Windows peut proposer de formater la clé : refusez."
