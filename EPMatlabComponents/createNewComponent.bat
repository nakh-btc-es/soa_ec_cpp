@echo off &SETLOCAL
set JAVA_HOME=C:\Program Files\Java\jdk-17.0.8.7-hotspot
::setting coloured output stuff
SETLOCAL EnableDelayedExpansion
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "DEL=%%a"
)

:START
set /p type=Enter the number of the component's type [Java (1) / Matlab (2) /  C (3) / C-Bundle (4) / Add C-Bundle (5)]: 

::checking for invalid types
set valid=false
if %type%==1 set valid=true
if %type%==2 set valid=true
if %type%==3 set valid=true
if %type%==4 set valid=true
if %type%==5 set valid=true
if %valid%==false (
    call :ColorText 0C "%type% is an invalid type. Choose 1, 2, 3, 4 or 5."
    echo(
    pause
    goto START
)

set /p artifactId=Enter the component artifactId: 
set package=%artifactId%

::archetype instatiation depending on the selected type
set feature=slmodel
:: read the current version from the pom
for /f %%i in ('C:\cygwin\bin\bash -ic "grep -oPm1 '(?<=<version>)[^<]+' pom.xml"') do set archVersion=%%i
set archVersion=%archVersion:-SNAPSHOT=%
set pluginType=java

echo Running with archetype version %archVersion%.

if %type%==1 (
    if "%artifactId:~-3%"==".bl" (
        set pluginType=bl
    ) else if "%artifactId:~-8%"==".bl.impl" (
        set pluginType=bl.impl
        ::Implementation: set package to artifactId (withouth .impl suffix)
        set package=%artifactId:~0,-5%
    ) else if "%artifactId:~-3%"==".al" (
        set pluginType=al
    ) else if "%artifactId:~-8%"==".al.impl" (
        set pluginType=al.impl
        ::Implementation: set package to artifactId (withouth .impl suffix)
        set package=%artifactId:~0,-5%
    )
)
if %type%==2 (
    set pluginType=m
)
if %type%==3 (
    set pluginType=c
)
if %type%==4 (
    set pluginType=bundle.c
)
if %type%==5 (
    set pluginType=bundle.c.add
)
call mvn -N org.apache.maven.plugins:maven-archetype-plugin:2.4:generate -DarchetypeArtifactId=com.btc.epp.archetype.%pluginType% -DarchetypeCatalog=http://p-nexus:8081/nexus/content/repositories/releases -DarchetypeVersion=%archVersion% -DarchetypeGroupId=btc_es -DfeatureName=%feature% -DartifactId=%artifactId% -Dpackage=%package% -DinteractiveMode=false

::catch maven failure
if ERRORLEVEL 1 GOTO FAILURE

if %type%==1 (
    :: add java plugin to feature.xml
    call mvn -N exec:java -Dexec.mainClass="com.btc.bm.archetypesupport.ArchetypeSupport" -Dexec.args="%artifactId%"
) else if %type%==4 (
    :: add bundle to feature.xml
    call mvn -N exec:java -Dexec.mainClass="com.btc.bm.archetypesupport.ArchetypeSupport" -Dexec.args="%artifactId%"
) else if %type%==5 (
    :: add bundle to feature.xml
    call mvn -N exec:java -Dexec.mainClass="com.btc.bm.archetypesupport.ArchetypeSupport" -Dexec.args="%artifactId%.bundle"
    :: remind user to include the bundle module in the reactor pom (c-bundle add)
    call :ColorText E "The Bundle was added to '%artifactId%'. Edit its reactor pom in order to include the commented-out bundle module."    
    echo(
)

:SUCCESS
set targetDir=%cd%\%artifactId%

echo(
call :ColorText 0a "Component successfully generated to"
echo(
echo %targetDir%
echo(
::java plugin eclipse import
if %type%==1 (
    call :ColorText 0a "You can now import the plugin into eclipse via Import - General - Existing Project into Workspace."    
    echo(
)
pause

exit 0

:FAILURE
echo(
call :ColorText 0C "Errors occurred during the creation of the new component '%artifactId%'!"
echo(
pause

exit ERRORLEVEL

:ColorText
echo off
<nul set /p ".=%DEL%" > "%~2"
findstr /v /a:%1 /R "^$" "%~2" nul
del "%~2" > nul 2>&1
goto :eof
