# Start the Spring Boot API (port 9090) using values from .env.
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (Test-Path "$Root/.env") {
  Get-Content "$Root/.env" | Where-Object { $_ -match '^\s*[^#\s][^=]*=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim(), 'Process')
  }
}

function Test-Jdk25($Candidate) {
  if (-not $Candidate -or -not (Test-Path "$Candidate/bin/java.exe") -or -not (Test-Path "$Candidate/bin/javac.exe") -or -not (Test-Path "$Candidate/release")) {
    return $false
  }
  $match = Select-String -Path "$Candidate/release" -Pattern '^JAVA_VERSION="25([."]|$)' -Quiet
  return [bool]$match
}

if (-not (Test-Jdk25 $env:JAVA_HOME)) {
  $discovered = Get-ChildItem -Path 'C:\Program Files\Eclipse Adoptium\jdk-25*', 'C:\Program Files\Java\jdk-25*', 'C:\Program Files\Microsoft\jdk-25*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Jdk25 $_.FullName } |
    Select-Object -First 1
  if ($discovered) {
    $env:JAVA_HOME = $discovered.FullName
  }
}

if (-not (Test-Jdk25 $env:JAVA_HOME)) {
  Write-Error "JDK 25 with java and javac is required. Install it (e.g. 'winget install EclipseAdoptium.Temurin.25.JDK') or set JAVA_HOME to its installation directory."
  exit 1
}

$env:Path = "$env:JAVA_HOME\bin;$env:Path"
Set-Location "$Root/services/api"
$javaSources = Get-ChildItem -Path 'src/main/java' -Filter '*.java' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $javaSources) {
  if (-not (Test-Path 'target/classes/imedix/saMiX/SaMiXApplication.class') -and (Test-Path 'target/saMiX-0.0.1-SNAPSHOT.jar.original.zip')) {
    New-Item -ItemType Directory -Force 'target/classes' | Out-Null
    Expand-Archive -Path 'target/saMiX-0.0.1-SNAPSHOT.jar.original.zip' -DestinationPath 'target/classes' -Force
    Remove-Item -Path 'target/classes/META-INF' -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item 'src/main/resources/application.properties' 'target/classes/application.properties' -Force
  }
  & .\mvnw.cmd spring-boot:run '-Dmaven.main.skip=true' @args
  exit $LASTEXITCODE
}
& .\mvnw.cmd spring-boot:run @args
