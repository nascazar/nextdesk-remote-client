$ErrorActionPreference = "Stop"

function Assert-Contains([string]$Path, [string]$Expected) {
    $content = Get-Content -LiteralPath $Path -Raw
    if (-not $content.Contains($Expected)) {
        throw "Expected '$Expected' in $Path"
    }
}

function Assert-NotContains([string]$Path, [string]$Unexpected) {
    $content = Get-Content -LiteralPath $Path -Raw
    if ($content.Contains($Unexpected)) {
        throw "Unexpected '$Unexpected' in $Path"
    }
}

Assert-Contains "Cargo.toml" 'ProductName = "NextDesk Remote"'
Assert-Contains "Cargo.toml" 'FileDescription = "NextDesk Remote"'
Assert-NotContains "Cargo.toml" 'FileDescription = "RustDesk Remote Desktop"'
Assert-Contains ".github/workflows/nextdesk-build.yml" "if: matrix.job.arch == 'x86_64'"
Assert-Contains ".github/workflows/nextdesk-build.yml" '$releaseDir = "rustdesk"'
Assert-Contains "flutter/windows/runner/Runner.rc" 'VALUE "FileDescription", "NextDesk Remote" "\0"'
Assert-Contains "src/platform/windows.rs" '"URL:NextDesk Remote Protocol"'
Assert-Contains "src/platform/windows.rs" '"rustdesk".to_owned()'
Assert-Contains "res/msi/Package/Components/Regs.wxs" 'Key="rustdesk"'
Assert-Contains "res/msi/Package/Components/Regs.wxs" 'Value="URL:NextDesk Remote Protocol"'

Write-Host "NextDesk product identity and protocol registration are valid."
