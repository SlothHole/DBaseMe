Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Get-Location).ProviderPath
$outFile  = Join-Path $repoRoot 'REPO_INTEL_EXPORT.txt'

# --- helper ---
function Write-Section {
    param([string]$Name)
    "`n===== SECTION: $Name =====`n"
}

function Test-AsciiFile {
    param([string]$Path)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $buffer = New-Object byte[] 8192
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            for ($i = 0; $i -lt $read; $i++) {
                if ($buffer[$i] -gt 127) { return $false }
            }
        }
        return $true
    }
    finally {
        $stream.Dispose()
    }
}

function Get-FileTypeGuess {
    param([System.IO.FileInfo]$File)
    switch ($File.Extension.ToLowerInvariant()) {
        '.qcow2' { 'Virtual disk image (QCOW2)' }
        '.png'   { 'Image (PNG)' }
        '.jpg'   { 'Image (JPEG)' }
        '.jpeg'  { 'Image (JPEG)' }
        '.gif'   { 'Image (GIF)' }
        '.webp'  { 'Image (WebP)' }
        '.pdf'   { 'Document (PDF)' }
        '.zip'   { 'Archive (ZIP)' }
        '.7z'    { 'Archive (7z)' }
        '.tar'   { 'Archive (TAR)' }
        '.gz'    { 'Archive (GZip)' }
        '.tgz'   { 'Archive (TAR.GZ)' }
        '.mp3'   { 'Audio (MP3)' }
        '.mp4'   { 'Video (MP4)' }
        '.exe'   { 'Executable (Windows)' }
        '.dll'   { 'Library (Windows DLL)' }
        '.so'    { 'Library (Unix shared object)' }
        '.dylib' { 'Library (macOS dylib)' }
        default  { "Binary ($($File.Extension))" }
    }
}

# --- collect files ---
# Exclude VCS + common runtime artifact directories (cache/venv, etc.)
$excludeDirPattern = '(\\|/)(\.git|\.cache|cache|__pycache__|\.pytest_cache|\.mypy_cache|\.ruff_cache|venv|\.venv|env|\.env)(\\|/)'
$files = Get-ChildItem -LiteralPath $repoRoot -Recurse -File -Force |
    Where-Object { $_.FullName -notmatch $excludeDirPattern }

# --- language detection ---
$extToLang = @{
    '.ps1'  = 'PowerShell'
    '.psm1' = 'PowerShell'
    '.psd1' = 'PowerShell'
    '.py'   = 'Python'
    '.js'   = 'JavaScript'
    '.ts'   = 'TypeScript'
    '.sql'  = 'SQL'
    '.cs'   = 'CSharp'
    '.cpp'  = 'C++'
    '.c'    = 'C'
    '.h'    = 'C/C++ Header'
    '.java' = 'Java'
    '.go'   = 'Go'
    '.rs'   = 'Rust'
    '.rb'   = 'Ruby'
    '.php'  = 'PHP'
    '.sh'   = 'Shell'
}

$languages = @{}
foreach ($f in $files) {
    $ext = $f.Extension.ToLowerInvariant()
    if ($extToLang.ContainsKey($ext)) {
        $languages[$extToLang[$ext]] = $true
    }
}

# --- dependency heuristics (file-based only) ---
$tools = @{}
$deps  = @{}

foreach ($f in $files) {
    switch -Regex ($f.Name) {
        '^requirements\.txt$' { $tools['Python'] = $true; $deps['pip'] = $true }
        '^pyproject\.toml$'   { $tools['Python'] = $true; $deps['poetry'] = $true }
        '^package\.json$'     { $tools['NodeJS'] = $true; $deps['npm'] = $true }
        '^go\.mod$'           { $tools['Go'] = $true }
        '^Cargo\.toml$'       { $tools['Rust'] = $true }
        '^composer\.json$'    { $tools['PHP'] = $true }
        '\.psd1$'             { $tools['PowerShell'] = $true }
    }
}

# --- write output ---
$sb = [System.Text.StringBuilder]::new()

$sb.AppendLine((Write-Section 'REPO_ROOT')) | Out-Null
$sb.AppendLine($repoRoot) | Out-Null

$sb.AppendLine((Write-Section 'FILE_STRUCTURE')) | Out-Null
foreach ($f in $files) {
    $rel = $f.FullName.Substring($repoRoot.Length).TrimStart('\','/')
    $sb.AppendLine($rel) | Out-Null
}

$sb.AppendLine((Write-Section 'LANGUAGES')) | Out-Null
foreach ($k in ($languages.Keys | Sort-Object)) {
    $sb.AppendLine($k) | Out-Null
}

$sb.AppendLine((Write-Section 'REQUIRED_TOOLS')) | Out-Null
foreach ($k in ($tools.Keys | Sort-Object)) {
    $sb.AppendLine($k) | Out-Null
}

$sb.AppendLine((Write-Section 'REQUIRED_DEPENDENCIES')) | Out-Null
foreach ($k in ($deps.Keys | Sort-Object)) {
    $sb.AppendLine($k) | Out-Null
}

$sb.AppendLine((Write-Section 'FILE_CONTENTS')) | Out-Null
foreach ($f in $files) {
    $rel = $f.FullName.Substring($repoRoot.Length).TrimStart('\','/')
    $sb.AppendLine("----- FILE: $rel -----") | Out-Null
    try {
        if (-not (Test-AsciiFile -Path $f.FullName)) {
            $sb.AppendLine('[CONTENT OMITTED: NON-ASCII]') | Out-Null
            $sb.AppendLine("TYPE_GUESS: $(Get-FileTypeGuess -File $f)") | Out-Null
            $sb.AppendLine("SIZE_BYTES: $($f.Length)") | Out-Null
        }
        else {
            Get-Content -LiteralPath $f.FullName -Raw |
                ForEach-Object { $sb.AppendLine($_) | Out-Null }
        }
    }
    catch {
        $sb.AppendLine('[UNREADABLE FILE]') | Out-Null
    }
}

$sb.ToString() | Set-Content -LiteralPath $outFile -Encoding UTF8 -NoNewline

$outFile
