# One-time local setup for Windows (PowerShell 5.1+). Legacy build scripts need Git Bash or WSL.
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Fwd = $Root -replace '\\', '/'
$TomcatVersion = if ($env:TOMCAT_VERSION) { $env:TOMCAT_VERSION } else { '9.0.98' }
Set-Location $Root

if (-not (Test-Path .env)) { Copy-Item .env.example .env; Write-Host 'Created .env - edit it and set real values.' }

function Render($Template, $Target) {
  if (Test-Path $Target) { return }
  (Get-Content $Template -Raw).Replace('@PROJECT_ROOT@', $Fwd) | Set-Content -NoNewline $Target
  Write-Host "Generated $Target - review credentials."
}
Render 'services/legacy/runtime/gblinfo.inf.template' 'services/legacy/runtime/gblinfo.inf'
Render 'apps/web/config.info.template' 'apps/web/config.info'

'temp', 'SystemLog', 'GenSqlLog' | ForEach-Object { New-Item -ItemType Directory -Force "services/legacy/runtime/$_" | Out-Null }
New-Item -ItemType Directory -Force tools | Out-Null

if (-not (Test-Path tools/tomcat9/bin)) {
  Write-Host "Downloading Tomcat $TomcatVersion ..."
  $zip = "tools/tomcat.zip"
  Invoke-WebRequest "https://archive.apache.org/dist/tomcat/tomcat-9/v$TomcatVersion/bin/apache-tomcat-$TomcatVersion.zip" -OutFile $zip
  Expand-Archive $zip -DestinationPath tools/_tc -Force
  Move-Item "tools/_tc/apache-tomcat-$TomcatVersion" tools/tomcat9
  Remove-Item $zip, tools/_tc -Recurse -Force
}

New-Item -ItemType Directory -Force tools/tomcat9/conf/Catalina/localhost | Out-Null
"<Context docBase=`"$Fwd/apps/web`" reloadable=`"false`" />" | Set-Content tools/tomcat9/conf/Catalina/localhost/M-Dosthi.xml

Write-Host 'Prerequisites:'
foreach ($c in 'java', 'javac', 'mvn', 'mysql', 'flutter') {
  if (Get-Command $c -ErrorAction SilentlyContinue) { Write-Host "  ok      $c" } else { Write-Host "  MISSING $c" }
}
Write-Host 'Done. See docs/setup.md for the next steps.'
