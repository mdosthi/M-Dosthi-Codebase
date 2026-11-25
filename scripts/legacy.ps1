# Build and start the legacy stack on Windows (Tomcat web app + RMI business logic).
# Supports both Individual Tomcat (M-Dosthi-Codebase/tools/tomcat9) and Shared Tomcat (SHARED_TOMCAT_HOME).
# Usage: powershell -ExecutionPolicy Bypass -File scripts/legacy.ps1 [build|start|stop|run|status] [-Mode auto|individual|shared]
param(
  [ValidateSet('build', 'start', 'stop', 'run', 'status')]
  [string]$Action = 'run',
  [ValidateSet('auto', 'individual', 'shared')]
  [string]$Mode = 'auto'
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Fwd = $Root -replace '\\', '/'
$Legacy = Join-Path $Root 'services/legacy'
$SharedTomcatHome = if ($Mode -eq 'individual') { $null } else { $env:SHARED_TOMCAT_HOME }
if ($Mode -eq 'shared' -and -not $SharedTomcatHome) {
  $defaultShared = Join-Path (Split-Path $Root -Parent) 'eDosthi codebases/DEVELOPMENT/eDosthi/Tomcat9'
  if (Test-Path $defaultShared) {
    $SharedTomcatHome = $defaultShared
  } else {
    throw '-Mode shared requires SHARED_TOMCAT_HOME to be set (or ..\eDosthi codebases\DEVELOPMENT\eDosthi\Tomcat9 to exist).'
  }
}

$IndividualTomcat = Join-Path $Root 'tools/tomcat9'
$Tomcat = if ($SharedTomcatHome) { (Resolve-Path $SharedTomcatHome).Path } else { $IndividualTomcat }
$PidFile = Join-Path $Legacy 'runtime/iMediXBusinessLogic.pid'
$TomcatPidFile = Join-Path $IndividualTomcat 'logs/tomcat.pid'

function Test-SupportedJdk($Candidate) {
  if (-not $Candidate -or -not (Test-Path "$Candidate/bin/java.exe") -or -not (Test-Path "$Candidate/bin/javac.exe") -or -not (Test-Path "$Candidate/release")) {
    return $false
  }
  $line = Select-String -Path "$Candidate/release" -Pattern '^JAVA_VERSION="([^"]+)"' | Select-Object -First 1
  if (-not $line) { return $false }
  $ver = ($line.Matches[0].Groups[1].Value -split '\.')[0]
  return ([int]$ver -ge 11)
}

if (-not (Test-SupportedJdk $env:JAVA_HOME)) {
  $candidates = @("$Root/tools/jdk11") + (
    Get-ChildItem -Path 'C:\Program Files\Eclipse Adoptium\jdk-*', 'C:\Program Files\Java\jdk-*', 'C:\Program Files\Microsoft\jdk-*' -Directory -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty FullName
  )
  foreach ($c in $candidates) {
    if (Test-SupportedJdk $c) {
      $env:JAVA_HOME = $c
      break
    }
  }
}

if (-not (Test-SupportedJdk $env:JAVA_HOME)) {
  throw 'JDK 11 or later with javac is required. Set JAVA_HOME to a JDK installation.'
}

$JavaBin = Join-Path $env:JAVA_HOME 'bin/java.exe'
$JavacBin = Join-Path $env:JAVA_HOME 'bin/javac.exe'
$JarBin = Join-Path $env:JAVA_HOME 'bin/jar.exe'

if (-not (Test-Path "$Legacy/runtime/gblinfo.inf") -or -not (Test-Path "$Tomcat/bin")) {
  throw 'Run scripts/setup.ps1 first (with the same SHARED_TOMCAT_HOME, if applicable).'
}

function Get-TomcatHttpPort($TargetTomcat, $Fallback) {
  $serverXml = Join-Path $TargetTomcat 'conf/server.xml'
  if (-not (Test-Path $serverXml)) { return $Fallback }
  $raw = (Get-Content $serverXml -Raw) -replace '(?s)<!--.*?-->', ''
  if ($raw -match '<Connector\s+port="(\d+)"\s+protocol="HTTP/1\.1"') {
    return $Matches[1]
  }
  return $Fallback
}

function Set-IndividualTomcatPorts {
  $serverXml = Join-Path $IndividualTomcat 'conf/server.xml'
  if (-not (Test-Path $serverXml)) { return }
  $content = Get-Content $serverXml -Raw
  $changed = $false
  if ($env:TOMCAT_HTTP_PORT) {
    $content = $content -replace '<Connector port="\d+" protocol="HTTP/1\.1"', "<Connector port=`"$($env:TOMCAT_HTTP_PORT)`" protocol=`"HTTP/1.1`""
    $changed = $true
  }
  if ($env:TOMCAT_SHUTDOWN_PORT) {
    $content = $content -replace '<Server port="\d+" shutdown="SHUTDOWN">', "<Server port=`"$($env:TOMCAT_SHUTDOWN_PORT)`" shutdown=`"SHUTDOWN`">"
    $changed = $true
  }
  if ($changed) {
    Set-Content -Path $serverXml -Value $content -NoNewline
  }
}

function Ensure-ContextDescriptor($TargetTomcat) {
  $DocBase = [System.Security.SecurityElement]::Escape("$Fwd/apps/web")
  $Expected = "<Context docBase=`"$DocBase`" reloadable=`"false`" />"
  $ConfigDir = Join-Path $TargetTomcat 'conf/Catalina/localhost'
  $Descriptor = Join-Path $ConfigDir 'M-Dosthi.xml'
  if ((Test-Path $Descriptor) -and ((Get-Content $Descriptor -Raw).Trim() -eq $Expected)) {
    return
  }
  New-Item -ItemType Directory -Force $ConfigDir | Out-Null
  $Expected | Set-Content $Descriptor
}

function Test-PidAlive($TargetPid) {
  if (-not $TargetPid -or $TargetPid -notmatch '^[0-9]+$') { return $false }
  return [bool](Get-Process -Id ([int]$TargetPid) -ErrorAction SilentlyContinue)
}

function Test-RmiRunning {
  if (-not (Test-Path $PidFile)) { return $false }
  $rmiPid = (Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
  if ($rmiPid) { $rmiPid = $rmiPid.Trim() }
  return (Test-PidAlive $rmiPid)
}

function Test-IndividualTomcatRunning {
  if (-not (Test-Path $TomcatPidFile)) { return $false }
  $tPid = (Get-Content $TomcatPidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
  if ($tPid) { $tPid = $tPid.Trim() }
  return (Test-PidAlive $tPid)
}

function Invoke-LegacyBuild {
  $ServerSrc = Join-Path $Legacy 'server-src'
  $ServletSrc = Join-Path $Legacy 'servlet-src/WEB-INF/classes/src'
  $ExtLib = Join-Path $Legacy 'external-lib'
  $WebApp = Join-Path $Root 'apps/web'
  $ServletJar = if ($env:SERVLET_API_JAR) { $env:SERVLET_API_JAR } else { Join-Path $Tomcat 'lib/servlet-api.jar' }
  if (-not (Test-Path $ServletJar)) {
    throw "Servlet API JAR not found at $ServletJar"
  }

  Push-Location $ServerSrc
  try {
    $javaFiles = Get-ChildItem -Filter '*.java' | Select-Object -ExpandProperty Name
    & $JavacBin --release 11 -classpath ".;$ServerSrc/ftp.jar;$ExtLib/*;" -d $ServerSrc @javaFiles
    & $JarBin -cf imedix.jar (Get-ChildItem 'imedix/*.class' | ForEach-Object { "imedix/$($_.Name)" })
    & $JarBin -cf tuberculosis.jar (Get-ChildItem 'tuberculosis/*.class' | ForEach-Object { "tuberculosis/$($_.Name)" })
    & $JarBin -cf phiv.jar (Get-ChildItem 'phiv/*.class' | ForEach-Object { "phiv/$($_.Name)" })
    & $JarBin -cf logger.jar (Get-ChildItem 'logger/*.class' | ForEach-Object { "logger/$($_.Name)" })
    & $JarBin -cf onlinegc.jar (Get-ChildItem 'onlinegc/*.class' | ForEach-Object { "onlinegc/$($_.Name)" })
    & $JarBin -cmf imedixserver.txt iMediXBusinessLogic.jar (Get-ChildItem 'imedixserver/*.class' | ForEach-Object { "imedixserver/$($_.Name)" })
    Copy-Item '*.jar' (Join-Path $Legacy 'runtime/lib/') -Force
    Copy-Item 'iMediXBusinessLogic.jar' (Join-Path $Legacy 'runtime/') -Force
  } finally {
    Pop-Location
  }

  Push-Location $ServletSrc
  try {
    Copy-Item (Join-Path $ServerSrc 'imedix') $ServletSrc -Recurse -Force
    New-Item -ItemType Directory -Force (Join-Path $ServletSrc 'imedixservlets'), (Join-Path $ServletSrc 'src_servlet'), (Join-Path $WebApp 'WEB-INF/classes/imedix') | Out-Null
    $javaFiles = Get-ChildItem -Filter '*.java' | Select-Object -ExpandProperty Name
    & $JavacBin --release 11 -classpath ".;$ServerSrc/ftp.jar;$ServerSrc;$ExtLib/*;" -d $ServletSrc @javaFiles
    & $JavacBin --release 11 -classpath ".;$ServerSrc/ftp.jar;$ServerSrc;$ExtLib/*;$ServletJar" -d (Join-Path $ServletSrc 'src_servlet') @javaFiles
    Copy-Item 'src_servlet/imedixservlets/*' 'imedixservlets/' -Recurse -Force
    Copy-Item 'imedix/*.class' (Join-Path $WebApp 'WEB-INF/classes/imedix/') -Force
    & $JarBin -cf imedix.jar (Get-ChildItem 'imedix/*.class' | ForEach-Object { "imedix/$($_.Name)" })
    & $JarBin -cf telem.jar (Get-ChildItem 'telem/*.class' | ForEach-Object { "telem/$($_.Name)" })
    & $JarBin -cf tuberculosis.jar (Get-ChildItem 'tuberculosis/*.class' | ForEach-Object { "tuberculosis/$($_.Name)" })
    & $JarBin -uf tuberculosis.jar -C $ServerSrc 'tuberculosis/tbOperationsInterface.class' -C $ServerSrc 'tuberculosis/tbOperations_Stub.class'
    & $JarBin -cf phiv.jar (Get-ChildItem 'phiv/*.class' | ForEach-Object { "phiv/$($_.Name)" })
    & $JarBin -uf phiv.jar -C $ServerSrc 'phiv/phivdataentryinterface.class' -C $ServerSrc 'phiv/phivdataentry_Stub.class'
    & $JarBin -cf onlinegc.jar (Get-ChildItem 'onlinegc/*.class' | ForEach-Object { "onlinegc/$($_.Name)" })
    & $JarBin -uf onlinegc.jar -C $ServerSrc 'onlinegc/onlineinterface.class' -C $ServerSrc 'onlinegc/onlinecommunicator_Stub.class'
    & $JarBin -cf logger.jar (Get-ChildItem 'logger/*.class' | ForEach-Object { "logger/$($_.Name)" })
    & $JarBin -uf logger.jar -C $ServerSrc 'logger/imedixloggerInterface.class' -C $ServerSrc 'logger/imedixlogger_Stub.class'
    & $JarBin -cf imedixservlets.jar (Get-ChildItem 'imedixservlets/*.class' | ForEach-Object { "imedixservlets/$($_.Name)" })
    Copy-Item '*.jar' (Join-Path $WebApp 'WEB-INF/lib/') -Force
    Copy-Item (Join-Path $ExtLib 'commons-codec-1.7.jar'), (Join-Path $ExtLib 'json-simple-1.1.1.jar') (Join-Path $WebApp 'WEB-INF/lib/') -Force
  } finally {
    Pop-Location
  }
}

function Stop-LegacyStack {
  if (-not $SharedTomcatHome -and (Test-Path "$IndividualTomcat/bin/shutdown.bat")) {
    try { & "$IndividualTomcat/bin/shutdown.bat" | Out-Null } catch {}
    if (Test-Path $TomcatPidFile) {
      $tPid = (Get-Content $TomcatPidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
      if ($tPid) { $tPid = $tPid.Trim() }
      for ($i = 0; $i -lt 10; $i++) {
        if (-not (Test-PidAlive $tPid)) { break }
        Start-Sleep -Seconds 1
      }
      if (Test-PidAlive $tPid) {
        Stop-Process -Id ([int]$tPid) -Force -ErrorAction SilentlyContinue
      }
      Remove-Item $TomcatPidFile -Force -ErrorAction SilentlyContinue
    }
  }
  if (Test-Path $PidFile) {
    $rmiPid = (Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($rmiPid) { $rmiPid = $rmiPid.Trim() }
    if (Test-PidAlive $rmiPid) {
      Stop-Process -Id ([int]$rmiPid) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
  }
}

function Start-LegacyStack {
  $configInfo = Join-Path $Root 'apps/web/config.info'
  $gblInfo = Join-Path $Legacy 'runtime/gblinfo.inf'
  $webRmiPort = $null
  $serverRmiPort = $null
  if (Test-Path $configInfo) {
    $m = Select-String -Path $configInfo -Pattern '^\s*03\)\s*blport\s*=\s*(\d+)' | Select-Object -First 1
    if ($m) { $webRmiPort = $m.Matches[0].Groups[1].Value }
  }
  if (Test-Path $gblInfo) {
    $m = Select-String -Path $gblInfo -Pattern '^\s*blport\s*=\s*(\d+)' | Select-Object -First 1
    if ($m) { $serverRmiPort = $m.Matches[0].Groups[1].Value }
  }
  if (-not $webRmiPort -or $webRmiPort -ne $serverRmiPort) {
    throw 'M-Dosthi RMI ports must match in apps/web/config.info and services/legacy/runtime/gblinfo.inf.'
  }

  if ($SharedTomcatHome) {
    $sharedDesc = Join-Path $Tomcat 'conf/Catalina/localhost/M-Dosthi.xml'
    if (-not (Test-Path $sharedDesc)) {
      throw "Missing shared Tomcat context descriptor ($sharedDesc). Run scripts/setup.ps1 -Mode shared first."
    }
  } else {
    Ensure-ContextDescriptor $IndividualTomcat
    'logs', 'temp', 'work' | ForEach-Object { New-Item -ItemType Directory -Force (Join-Path $IndividualTomcat $_) | Out-Null }
    Set-IndividualTomcatPorts
    if (Test-IndividualTomcatRunning) {
      Write-Host "M-Dosthi Individual Tomcat is already running (PID $((Get-Content $TomcatPidFile -First 1).Trim()))."
    } else {
      $testCenter = if ($env:LEGACY_ENABLE_TEST_CENTERS -eq 'true') { 'true' } else { 'false' }
      $prevCatalinaOpts = $env:CATALINA_OPTS
      $env:CATALINA_OPTS = "$prevCatalinaOpts -Dimedix.testCenterCreation=$testCenter".Trim()
      try {
        $tcProc = Start-Process -FilePath (Join-Path $IndividualTomcat 'bin/catalina.bat') -WorkingDirectory $IndividualTomcat -ArgumentList @('run') `
          -RedirectStandardOutput (Join-Path $IndividualTomcat 'logs/catalina.out') `
          -RedirectStandardError (Join-Path $IndividualTomcat 'logs/catalina.err') -PassThru -WindowStyle Hidden
        Set-Content -Path $TomcatPidFile -Value $tcProc.Id
      } finally {
        $env:CATALINA_OPTS = $prevCatalinaOpts
      }
    }
  }

  $RuntimeDir = Join-Path $Legacy 'runtime'
  $JavaXms = if ($env:LEGACY_JAVA_XMS) { $env:LEGACY_JAVA_XMS } else { '128M' }
  $JavaXmx = if ($env:LEGACY_JAVA_XMX) { $env:LEGACY_JAVA_XMX } else { '512M' }
  $RmiHost = if ($env:LEGACY_RMI_ADVERTISE_HOST) { $env:LEGACY_RMI_ADVERTISE_HOST } else { '127.0.0.1' }
  $LogOut = Join-Path $RuntimeDir 'SystemLog/bl.out'
  $LogErr = Join-Path $RuntimeDir 'SystemLog/bl.err'
  if (Test-RmiRunning) {
    Write-Host "M-Dosthi RMI is already running (PID $((Get-Content $PidFile -First 1).Trim()), port $serverRmiPort)."
  } else {
    $proc = Start-Process -FilePath $JavaBin -WorkingDirectory $RuntimeDir -ArgumentList @(
      "-Xms$JavaXms",
      "-Xmx$JavaXmx",
      "-Djava.rmi.server.hostname=$RmiHost",
      '-javaagent:lib/aspectjweaver-1.6.2.jar',
      '--module-path', 'lib/',
      '-jar', (Join-Path $RuntimeDir 'iMediXBusinessLogic.jar')
    ) -RedirectStandardOutput $LogOut -RedirectStandardError $LogErr -PassThru -WindowStyle Hidden
    Set-Content -Path $PidFile -Value $proc.Id
    Write-Host "Started M-Dosthi RMI (PID $($proc.Id))."
  }

  if ($SharedTomcatHome) {
    $port = Get-TomcatHttpPort $Tomcat '8080'
    Write-Host "Started. Web UI: http://localhost:$port/M-Dosthi/ (RMI port $serverRmiPort)"
    Write-Host "Mode: Shared Tomcat ($Tomcat) - Tomcat lifecycle is externally managed."
  } else {
    $port = Get-TomcatHttpPort $IndividualTomcat '8081'
    Write-Host "Started. Web UI: http://localhost:$port/M-Dosthi/ (RMI port $serverRmiPort)"
    Write-Host "Mode: M-Dosthi Individual Tomcat ($IndividualTomcat)"
  }
}

function Show-LegacyStatus {
  $serverRmiPort = '1100'
  $gblInfo = Join-Path $Legacy 'runtime/gblinfo.inf'
  if (Test-Path $gblInfo) {
    $m = Select-String -Path $gblInfo -Pattern '^\s*blport\s*=\s*(\d+)' | Select-Object -First 1
    if ($m) { $serverRmiPort = $m.Matches[0].Groups[1].Value }
  }
  $indPort = Get-TomcatHttpPort $IndividualTomcat '8081'
  if (Test-RmiRunning) {
    Write-Host "M-Dosthi RMI:               RUNNING (PID $((Get-Content $PidFile -First 1).Trim()), port $serverRmiPort)"
  } else {
    Write-Host 'M-Dosthi RMI:               STOPPED'
  }
  if (Test-IndividualTomcatRunning) {
    Write-Host "M-Dosthi Individual Tomcat: RUNNING (PID $((Get-Content $TomcatPidFile -First 1).Trim()), http://localhost:$indPort/M-Dosthi/)"
  } else {
    Write-Host "M-Dosthi Individual Tomcat: STOPPED (configured for http://localhost:$indPort/M-Dosthi/)"
  }
  if ($SharedTomcatHome) {
    $shPort = Get-TomcatHttpPort $Tomcat '8080'
    Write-Host "Shared Tomcat:              EXTERNAL (configured for http://localhost:$shPort/M-Dosthi/ at $Tomcat)"
  }
}

switch ($Action) {
  'build'  { Invoke-LegacyBuild }
  'start'  { Start-LegacyStack }
  'stop'   { Stop-LegacyStack }
  'status' { Show-LegacyStatus }
  'run'    { Invoke-LegacyBuild; Stop-LegacyStack; Start-LegacyStack }
}
