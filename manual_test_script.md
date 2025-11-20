# Manual Test Script for Role-Based Access Control

## Prerequisites
- PathFit application installed on a test device
- Access to Firebase console for the project
- Two test accounts: one student and one instructor

## Test Procedure

### Test 1: Role Selection During Registration

1. Open the PathFit application
2. Navigate to the signup screen
3. Fill in all required fields but do not select a role
4. Tap the "Sign Up" button
5. **Expected Result**: Error message appears indicating role selection is required
6. Select the "Student" role
7. Tap the "Sign Up" button
8. **Expected Result**: Role confirmation dialog appears with student role information
9. Tap "Cancel" on the dialog
10. Change role to "Instructor"
11. Tap the "Sign Up" button
12. **Expected Result**: Role confirmation dialog appears with instructor role information
13. Tap "Confirm" to complete registration
14. **Expected Result**: Registration completes and user is directed to the instructor dashboard

### Test 2: Role Verification on Login

1. Log out of the application
2. Access Firebase console and locate the user you just created
3. Manually change the user's role from "instructor" to "student"
4. Log back into the application using the same credentials
5. **Expected Result**: User should be logged in and directed to the student dashboard (role should be updated to match Firestore)

### Test 3: Student Role Access Restrictions

1. Log in as a student user
2. Verify access to the following screens:
   - Student Dashboard
   - Student Library
   - Student Progress
   - Module Detail
3. Attempt to access instructor screens by directly entering the URLs:
   - `/instructor-dashboard`
   - `/quiz-dashboard`
   - `/module-upload`
4. **Expected Result**: Access to student screens is granted, but attempts to access instructor screens redirect to the login screen

### Test 4: Instructor Role Access Restrictions

1. Log in as an instructor user
2. Verify access to the following screens:
   - Instructor Dashboard
   - Quiz Dashboard
   - Module Upload
   - Student Management screens
3. Attempt to access student screens by directly entering the URLs:
   - `/student-dashboard`
   - `/student-library`
   - `/student-progress`
4. **Expected Result**: Access to instructor screens is granted, but attempts to access student screens redirect to the login screen

### Test 5: Role Guard Widget Behavior

1. Log in as a student user
2. Navigate to the student dashboard
3. Observe if there is a brief loading state showing "Verifying student access..."
4. **Expected Result**: Loading state may appear briefly before the dashboard content loads

### Test 6: Splash Screen Navigation

1. Log out of the application
2. Access Firebase console and locate a student user
3. Manually change the user's role from "student" to "instructor"
4. Close and reopen the application (do not log in)
5. **Expected Result**: The splash screen should detect the role change and navigate to the instructor dashboard

### Test 7: Force Sign-Out on Role Mismatch

1. Log in as a student user
2. Keep the application open
3. Access Firebase console and change the user's role to "unknown"
4. Navigate to different screens within the application
5. **Expected Result**: The user should be forced to sign out and redirected to the login screen with an appropriate message

## Test Results

For each test, record:
- Pass/Fail status
- Any unexpected behavior
- Screenshots of errors or issues
- Device and OS information

## Notes

- These tests should be performed on both Android and iOS devices
- Test with different network conditions (good connection, poor connection, offline)
- Test with both new and existing user accounts