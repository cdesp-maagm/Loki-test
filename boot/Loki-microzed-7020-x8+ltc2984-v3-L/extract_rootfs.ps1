<#
.SYNOPSIS
    Extrait le payload cpio d'une image U-Boot legacy (uImage) contenant un
    RAMDisk non compresse, puis liste et extrait son contenu pour analyse.

.PREREQUIS
    7-Zip doit etre installe : https://www.7-zip.org/
    Par defaut, ce script cherche 7z.exe dans :
      C:\Program Files\7-Zip\7z.exe
    Adapte la variable $SevenZipPath ci-dessous si besoin.

.USAGE
    .\extract_rootfs.ps1 -InputFile "rootfs.cpio.gz" [-OutDir "rootfs_extraction"]

    Si l'execution de scripts est bloquee, lance d'abord (dans le meme
    terminal PowerShell, en tant qu'administrateur si besoin) :
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [string]$OutDir = "rootfs_extraction"
)

$ErrorActionPreference = "Stop"

# --- Localisation de 7-Zip ---
$SevenZipPath = "C:\Program Files\7-Zip\7z.exe"
if (-not (Test-Path $SevenZipPath)) {
    $SevenZipPath = "C:\Program Files (x86)\7-Zip\7z.exe"
}
if (-not (Test-Path $SevenZipPath)) {
    Write-Host "ERREUR : 7z.exe introuvable." -ForegroundColor Red
    Write-Host "Installe 7-Zip depuis https://www.7-zip.org/ puis relance ce script."
    Write-Host "Si 7-Zip est installe ailleurs, modifie la variable `$SevenZipPath dans ce script."
    exit 1
}

# --- Verification du fichier d'entree ---
if (-not (Test-Path $InputFile)) {
    Write-Host "ERREUR : fichier introuvable : $InputFile" -ForegroundColor Red
    exit 1
}
$InputFile = (Resolve-Path $InputFile).Path

# --- Preparation du dossier de sortie ---
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir     = (Resolve-Path $OutDir).Path
$CpioFile   = Join-Path $OutDir "rootfs.cpio"
$ListFile   = Join-Path $OutDir "liste_fichiers.txt"
$ExtractDir = Join-Path $OutDir "extracted"

Write-Host "== 1. Lecture de l'en-tete du fichier ==" -ForegroundColor Cyan
$headerBytes = New-Object byte[] 64
$fs = [System.IO.File]::OpenRead($InputFile)
$fs.Read($headerBytes, 0, 64) | Out-Null
$fs.Close()
$magic = "{0:X2}{1:X2}{2:X2}{3:X2}" -f $headerBytes[0], $headerBytes[1], $headerBytes[2], $headerBytes[3]
Write-Host "Magic number (4 premiers octets) : 0x$magic"
if ($magic -eq "27051956") {
    Write-Host "-> En-tete U-Boot legacy (uImage) confirme."
} else {
    Write-Host "-> Attention : magic number different de celui d'une image U-Boot (0x27051956)." -ForegroundColor Yellow
    Write-Host "   Le fichier n'est peut-etre pas au format attendu, mais on continue quand meme."
}
Write-Host ""

# --- Extraction du payload (retrait des 64 premiers octets d'en-tete) ---
Write-Host "== 2. Extraction du payload (retrait de l'en-tete U-Boot, 64 octets) ==" -ForegroundColor Cyan
$inputStream  = [System.IO.File]::OpenRead($InputFile)
$outputStream = [System.IO.File]::Create($CpioFile)
$inputStream.Seek(64, [System.IO.SeekOrigin]::Begin) | Out-Null
$inputStream.CopyTo($outputStream)
$inputStream.Close()
$outputStream.Close()
Write-Host "Payload ecrit dans : $CpioFile"
Write-Host ""

# --- Listing du contenu (sans extraction sur disque) ---
Write-Host "== 3. Generation de la liste des fichiers (7-Zip) ==" -ForegroundColor Cyan
& "$SevenZipPath" l -ttar $CpioFile *>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    $FormatArg = "-ttar"
} else {
    $FormatArg = "-tcpio"
}
& "$SevenZipPath" l $FormatArg $CpioFile | Out-File -Encoding utf8 $ListFile
Write-Host "Liste ecrite dans : $ListFile"
Write-Host ""

# --- Extraction complete pour analyse ---
Write-Host "== 4. Extraction complete de l'arborescence ==" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $ExtractDir | Out-Null
& "$SevenZipPath" x $FormatArg $CpioFile "-o$ExtractDir" -y | Out-Null
Write-Host "Fichiers extraits dans : $ExtractDir"
Write-Host ""

Write-Host "== Termine ==" -ForegroundColor Green
Write-Host "Resume :"
Write-Host "  - Payload cpio       : $CpioFile"
Write-Host "  - Liste des fichiers : $ListFile"
Write-Host "  - Arborescence       : $ExtractDir"
