@echo off
echo Building and running oMessage_Model unit tests...

REM Check if build directory exists, create if not
if not exist "build" (
    mkdir build
)

cd build

REM Configure with CMake
echo Configuring with CMake...
cmake .. -DCMAKE_BUILD_TYPE=Debug

if %ERRORLEVEL% neq 0 (
    echo CMake configuration failed!
    pause
    exit /b 1
)

REM Build the project
echo Building project...
cmake --build . --config Debug

if %ERRORLEVEL% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

REM Run the tests
echo Running tests...
ctest --output-on-failure --verbose

if %ERRORLEVEL% neq 0 (
    echo Some tests failed!
    pause
    exit /b 1
)

echo All tests passed successfully!
pause