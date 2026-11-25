# Provision the local MySQL database and dedicated non-root API account on Windows.
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$EnvFile = Join-Path $Root '.env'

if (-not (Test-Path $EnvFile)) {
  throw "Missing $EnvFile. Copy .env.example to .env and configure database values."
}

foreach ($extraPath in (Get-ChildItem 'C:\Program Files\MySQL\MySQL Server*\bin' -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)) {
  if ($extraPath -and (Test-Path $extraPath)) {
    $env:Path = "$extraPath;$env:Path"
  }
}

$cfg = @{}
Get-Content $EnvFile | Where-Object { $_ -match '^\s*[^#\s][^=]*=' } | ForEach-Object {
  $k, $v = $_ -split '=', 2
  $cfg[$k.Trim()] = $v.Trim()
}

$appUser = $cfg['SPRING_DATASOURCE_USERNAME']
$appPassword = $cfg['SPRING_DATASOURCE_PASSWORD']
$rootPassword = $cfg['MYSQL_ROOT_PASSWORD']
$database = if ($cfg['MYSQL_DATABASE']) { $cfg['MYSQL_DATABASE'] } else { 'mDosthi' }
$adminHost = if ($cfg['MYSQL_ADMIN_HOST']) { $cfg['MYSQL_ADMIN_HOST'] } else { '127.0.0.1' }
$adminPort = if ($cfg['MYSQL_ADMIN_PORT']) { $cfg['MYSQL_ADMIN_PORT'] } else { '3306' }

if (-not $appUser -or -not $appPassword -or -not $rootPassword) {
  throw 'Set SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD, and MYSQL_ROOT_PASSWORD in .env.'
}
if ($appUser -notmatch '^[A-Za-z0-9_]+$' -or $database -notmatch '^[A-Za-z0-9_]+$') {
  throw 'The application username and database name may contain only letters, digits, and underscores.'
}
if ($adminHost -notmatch '^[A-Za-z0-9.-]+$' -or $adminPort -notmatch '^[0-9]+$') {
  throw 'MYSQL_ADMIN_HOST or MYSQL_ADMIN_PORT is invalid.'
}

$quotedUser = "'" + ($appUser -replace '\\', '\\' -replace "'", "''") + "'"
$quotedPassword = "'" + ($appPassword -replace '\\', '\\' -replace "'", "''") + "'"

$sql = @"
CREATE DATABASE IF NOT EXISTS ``$database`` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS $quotedUser@'%' IDENTIFIED BY $quotedPassword;
ALTER USER $quotedUser@'%' IDENTIFIED BY $quotedPassword;
GRANT ALL PRIVILEGES ON ``$database``.* TO $quotedUser@'%';
CREATE USER IF NOT EXISTS $quotedUser@'localhost' IDENTIFIED BY $quotedPassword;
ALTER USER $quotedUser@'localhost' IDENTIFIED BY $quotedPassword;
GRANT ALL PRIVILEGES ON ``$database``.* TO $quotedUser@'localhost';
FLUSH PRIVILEGES;
"@

$env:MYSQL_PWD = $rootPassword
try {
  $sql | & mysql --protocol=TCP --host=$adminHost --port=$adminPort --user=root
  if ($LASTEXITCODE -ne 0) {
    throw "MySQL exited with code $LASTEXITCODE"
  }
} finally {
  Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
}

Write-Host "Provisioned the non-root API account for database '$database'."
