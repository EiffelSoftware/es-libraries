@echo off
echo Cleaning up test_output directory...
if exist "testing\test_output" (
    rmdir /s /q "testing\test_output"
    echo test_output directory deleted.
) else (
    echo test_output directory does not exist.
)
pause

