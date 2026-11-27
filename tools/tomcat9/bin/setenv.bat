@echo off
if not defined JAVA_HOME if not defined JRE_HOME (
  for %%D in (
    "C:\Program Files\Eclipse Adoptium\jdk-25*"
    "C:\Program Files\Eclipse Adoptium\jdk-21*"
    "C:\Program Files\Eclipse Adoptium\jdk-17*"
    "C:\Program Files\Java\jdk-25*"
    "C:\Program Files\Java\jdk-21*"
    "C:\Program Files\Java\jdk-17*"
    "C:\Program Files\Microsoft\jdk-25*"
    "C:\Program Files\Microsoft\jdk-21*"
    "C:\Program Files\Microsoft\jdk-17*"
  ) do (
    for /d %%J in (%%D) do (
      if exist "%%~fJ\bin\java.exe" if not defined JAVA_HOME set "JAVA_HOME=%%~fJ"
    )
  )
)

echo.%JDK_JAVA_OPTIONS% | findstr /C:"java.xml.crypto/com.sun.org.apache.xml.internal.security.utils" >nul 2>&1
if errorlevel 1 (
  set "JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% --add-exports=java.xml.crypto/com.sun.org.apache.xml.internal.security.utils=ALL-UNNAMED --add-opens=java.xml.crypto/com.sun.org.apache.xml.internal.security.utils=ALL-UNNAMED"
)

set "MDOSTHI_ROOT="
for %%R in ("%CATALINA_HOME%\.." "%CATALINA_HOME%\..\..") do (
  if not defined MDOSTHI_ROOT if exist "%%~fR\apps\web" set "MDOSTHI_ROOT=%%~fR"
)

if defined MDOSTHI_ROOT (
  set "MDOSTHI_DOCBASE=%MDOSTHI_ROOT:\=/%/apps/web"
  if not exist "%CATALINA_BASE%\conf\Catalina\localhost" mkdir "%CATALINA_BASE%\conf\Catalina\localhost"
  >"%CATALINA_BASE%\conf\Catalina\localhost\mDosthi.xml" echo ^<Context docBase="%MDOSTHI_DOCBASE%" reloadable="false" /^>
)
