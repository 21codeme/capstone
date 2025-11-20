@echo off
echo ======================================================
echo Firebase Admin Script: Delete ALL Users
echo ======================================================
echo.
echo WARNING: This script will delete ALL users from both
echo Firebase Authentication and Firestore databases.
echo.
echo This is a DESTRUCTIVE operation and cannot be undone!
echo.
echo Press Ctrl+C now to cancel or any key to continue...
pause

cd %~dp0
node delete_all_users.js

echo.
echo Script execution completed.
pause