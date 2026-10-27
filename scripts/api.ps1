# Start the Spring Boot API (port 9090) using values from .env.
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (Test-Path "$Root/.env") {
  Get-Content "$Root/.env" | Where-Object { $_ -match '^\s*[^#\s][^=]*=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim(), 'Process')
  }
}
Set-Location "$Root/services/api"
& .\mvnw.cmd spring-boot:run @args
