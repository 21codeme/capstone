@echo off
echo Running role to isStudent migration script...
echo.

cd %~dp0..\..\..\..

dart run lib/core/scripts/migrate_role_to_isStudent.dart

echo.
echo Migration script execution completed.
pause