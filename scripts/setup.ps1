# One-time local setup for Windows (PowerShell 5.1+).
# Supports both Individual Tomcat (M-Dosthi-Codebase/tools/tomcat9) and Shared Tomcat (SHARED_TOMCAT_HOME).
# Usage: powershell -ExecutionPolicy Bypass -File scripts/setup.ps1 [-Mode auto|individual|shared]
param(
  [ValidateSet('auto', 'individual', 'shared')]
  [string]$Mode = 'auto'
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Fwd = $Root -replace '\\', '/'
$TomcatVersion = if ($env:TOMCAT_VERSION) { $env:TOMCAT_VERSION } else { '9.0.98' }
$SharedTomcatHome = if ($Mode -eq 'individual') { $null } else { $env:SHARED_TOMCAT_HOME }
if ($Mode -eq 'shared' -and -not $SharedTomcatHome) {
  $defaultShared = Join-Path (Split-Path $Root -Parent) 'eDosthi codebases/DEVELOPMENT/eDosthi/Tomcat9'
  if (Test-Path $defaultShared) {
    $SharedTomcatHome = $defaultShared
  } else {
    throw '-Mode shared requires SHARED_TOMCAT_HOME to be set (or ..\eDosthi codebases\DEVELOPMENT\eDosthi\Tomcat9 to exist).'
  }
}

$DefaultRmiPort = '1100'
$LegacyRmiPort = if ($env:LEGACY_RMI_PORT) { $env:LEGACY_RMI_PORT } else { $DefaultRmiPort }
if ($LegacyRmiPort -notmatch '^[1-9][0-9]{0,4}$' -or [int]$LegacyRmiPort -gt 65535) {
  throw 'LEGACY_RMI_PORT must be a valid TCP port number between 1 and 65535.'
}
Set-Location $Root
$IndividualTomcatHome = Join-Path $Root 'tools/tomcat9'
$TomcatHome = if ($SharedTomcatHome) { (Resolve-Path $SharedTomcatHome).Path } else { $IndividualTomcatHome }

if (-not (Test-Path .env)) { Copy-Item .env.example .env; Write-Host 'Created .env - edit it and set real values.' }

'temp', 'SystemLog', 'GenSqlLog' | ForEach-Object { New-Item -ItemType Directory -Force "services/legacy/runtime/$_" | Out-Null }
New-Item -ItemType Directory -Force tools | Out-Null

if (-not (Test-Path (Join-Path $IndividualTomcatHome 'bin'))) {
  Write-Host "Downloading M-Dosthi Individual Tomcat $TomcatVersion ..."
  $zip = "tools/tomcat.zip"
  Invoke-WebRequest "https://archive.apache.org/dist/tomcat/tomcat-9/v$TomcatVersion/bin/apache-tomcat-$TomcatVersion.zip" -OutFile $zip
  Expand-Archive $zip -DestinationPath tools/_tc -Force
  Move-Item "tools/_tc/apache-tomcat-$TomcatVersion" $IndividualTomcatHome
  Remove-Item $zip, tools/_tc -Recurse -Force
}

'logs', 'temp', 'work' | ForEach-Object { New-Item -ItemType Directory -Force (Join-Path $IndividualTomcatHome $_) | Out-Null }

function Get-TomcatHttpPort($TargetTomcat, $Fallback) {
  $serverXml = Join-Path $TargetTomcat 'conf/server.xml'
  if (-not (Test-Path $serverXml)) { return $Fallback }
  $raw = (Get-Content $serverXml -Raw) -replace '(?s)<!--.*?-->', ''
  if ($raw -match '<Connector\s+port="(\d+)"\s+protocol="HTTP/1\.1"') {
    return $Matches[1]
  }
  return $Fallback
}

$ConfigHttpPort = if ($env:TOMCAT_HTTP_PORT) {
  $env:TOMCAT_HTTP_PORT
} elseif ($SharedTomcatHome) {
  Get-TomcatHttpPort $TomcatHome '8080'
} else {
  Get-TomcatHttpPort $IndividualTomcatHome '8081'
}

function Render($Template, $Target) {
  if (Test-Path $Target) { return }
  (Get-Content $Template -Raw) `
    .Replace('@PROJECT_ROOT@', $Fwd) `
    .Replace('@LEGACY_RMI_PORT@', $LegacyRmiPort) `
    .Replace('@TOMCAT_HTTP_PORT@', $ConfigHttpPort) | Set-Content -NoNewline $Target
  Write-Host "Generated $Target - review credentials."
}
Render 'services/legacy/runtime/gblinfo.inf.template' 'services/legacy/runtime/gblinfo.inf'
Render 'apps/web/config.info.template' 'apps/web/config.info'
Render 'apps/web/WEB-INF/classes/mail.properties.template' 'apps/web/WEB-INF/classes/mail.properties'
Render 'apps/web/jspfiles/whatsappConfig.jsp.template' 'apps/web/jspfiles/whatsappConfig.jsp'

$DocBase = [System.Security.SecurityElement]::Escape("$Fwd/apps/web")
$ExpectedContext = "<Context docBase=`"$DocBase`" reloadable=`"false`" />"

function Write-ContextDescriptor($TargetTomcat) {
  $configDir = Join-Path $TargetTomcat 'conf/Catalina/localhost'
  New-Item -ItemType Directory -Force $configDir | Out-Null
  foreach ($contextName in 'M-Dosthi', 'mDosthi') {
    $descriptor = Join-Path $configDir "$contextName.xml"
    if (-not (Test-Path $descriptor) -or ((Get-Content $descriptor -Raw).Trim() -ne $ExpectedContext)) {
      $ExpectedContext | Set-Content $descriptor
    }
  }
}

Write-ContextDescriptor $IndividualTomcatHome

if ($SharedTomcatHome) {
  if (-not (Test-Path (Join-Path $TomcatHome 'bin/catalina.bat')) -or
      -not (Test-Path (Join-Path $TomcatHome 'lib/servlet-api.jar'))) {
    throw 'SHARED_TOMCAT_HOME must point to a Tomcat 9 installation with catalina.bat and servlet-api.jar.'
  }
  Write-ContextDescriptor $TomcatHome
}

if (-not $env:JAVA_HOME) {
  $jdkCandidate = Get-ChildItem -Path 'C:\Program Files\Eclipse Adoptium\jdk-25*', 'C:\Program Files\Java\jdk-25*', 'C:\Program Files\Microsoft\jdk-25*' -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($jdkCandidate) {
    $env:JAVA_HOME = $jdkCandidate.FullName
    $env:Path = "$($jdkCandidate.FullName)\bin;$env:Path"
  }
}
foreach ($extraPath in @(
  (Get-ChildItem 'C:\Program Files\MySQL\MySQL Server*\bin' -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName),
  'C:\src\flutter\bin',
  "$HOME\flutter\bin"
)) {
  if ($extraPath -and (Test-Path $extraPath)) {
    $env:Path = "$extraPath;$env:Path"
  }
}

Write-Host 'Prerequisites:'
foreach ($c in 'java', 'javac', 'mvn', 'mysql', 'flutter') {
  if (Get-Command $c -ErrorAction SilentlyContinue) { Write-Host "  ok      $c" } else { Write-Host "  MISSING $c" }
}
Write-Host "Configured M-Dosthi Individual Tomcat: $IndividualTomcatHome"
if ($SharedTomcatHome) {
  Write-Host "Configured M-Dosthi in Shared Tomcat:  $TomcatHome"
  Write-Host 'Restart that Tomcat to load the /mDosthi context, or run scripts/legacy.ps1 -Mode individual to use M-Dosthi''s own Tomcat.'
}
Write-Host 'Done. See docs/setup.md for the next steps.'
