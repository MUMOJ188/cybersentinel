# Loads backend/.env into the current PowerShell session's environment variables.
#
# IMPORTANT: run this with a leading dot so it affects your CURRENT shell:
#   . .\load-env.ps1

Get-Content .env | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }

    $parts = $line -split "=", 2
    if ($parts.Length -eq 2) {
        $name = $parts[0].Trim()
        $value = $parts[1].Trim()
        Set-Item -Path "Env:$name" -Value $value
        Write-Host "Set $name"
    }
}