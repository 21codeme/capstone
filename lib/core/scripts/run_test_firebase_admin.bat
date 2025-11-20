@echo off
echo ======================================================
echo Firebase Admin SDK Configuration Test
echo ======================================================
echo.

cd %~dp0
node test_firebase_admin.js

echo.
echo Test completed.
pause