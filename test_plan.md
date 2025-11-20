# Role-Based Access Control Test Plan

## Overview
This test plan outlines the procedures to verify that the role-based access control (RBAC) implementation is working correctly in the PathFit application. The tests focus on ensuring that users can only access screens and features appropriate for their assigned roles.

## Test Scenarios

### 1. Role Selection During Registration

#### Test Case 1.1: Role Selection Enforcement
- **Objective**: Verify that users must select a role during registration
- **Steps**:
  1. Navigate to the unified signup screen
  2. Fill in all required fields except role selection
  3. Attempt to submit the form
- **Expected Result**: Form submission fails with an error message indicating role selection is required

#### Test Case 1.2: Role Confirmation Dialog
- **Objective**: Verify that the role confirmation dialog appears and works correctly
- **Steps**:
  1. Navigate to the unified signup screen
  2. Fill in all required fields including role selection
  3. Submit the form
- **Expected Result**: Role confirmation dialog appears with correct role information and warning about immutability

### 2. Role-Based Navigation

#### Test Case 2.1: Student Role Navigation
- **Objective**: Verify that students can only access student-specific screens
- **Steps**:
  1. Log in as a student user
  2. Verify access to student dashboard
  3. Attempt to access instructor dashboard by directly entering the URL
- **Expected Result**: Student can access student dashboard but is redirected to login when attempting to access instructor dashboard

#### Test Case 2.2: Instructor Role Navigation
- **Objective**: Verify that instructors can only access instructor-specific screens
- **Steps**:
  1. Log in as an instructor user
  2. Verify access to instructor dashboard
  3. Attempt to access student dashboard by directly entering the URL
- **Expected Result**: Instructor can access instructor dashboard but is redirected to login when attempting to access student dashboard

### 3. Role Verification in AuthProvider

#### Test Case 3.1: Role Verification on Login
- **Objective**: Verify that the system checks the user's role against Firestore on login
- **Steps**:
  1. Create a test user with a specific role
  2. Manually modify the role in Firestore
  3. Log in as the test user
- **Expected Result**: The system should detect the role mismatch and update the user's role to match Firestore

#### Test Case 3.2: Role Access Enforcement
- **Objective**: Verify that the enforceRoleAccess method correctly restricts access
- **Steps**:
  1. Log in as a student user
  2. Use the enforceRoleAccess method to check access for 'student' role
  3. Use the enforceRoleAccess method to check access for 'instructor' role
- **Expected Result**: Access should be granted for 'student' role and denied for 'instructor' role

### 4. RoleGuard Widget

#### Test Case 4.1: RoleGuard with Correct Role
- **Objective**: Verify that RoleGuard allows access when the user has the correct role
- **Steps**:
  1. Log in as a student user
  2. Navigate to a screen protected by RoleGuard with requiredRole='student'
- **Expected Result**: User can access the screen

#### Test Case 4.2: RoleGuard with Incorrect Role
- **Objective**: Verify that RoleGuard prevents access when the user has an incorrect role
- **Steps**:
  1. Log in as a student user
  2. Navigate to a screen protected by RoleGuard with requiredRole='instructor'
- **Expected Result**: User is redirected to the fallback route (login screen)

## Test Environment
- Test on both Android and iOS platforms
- Test with both new and existing user accounts
- Test with different network conditions (online and offline)

## Test Data
- Create test accounts for both student and instructor roles
- Prepare test data for each role (modules, quizzes, etc.)

## Reporting
Document any issues found during testing with the following information:
- Test case ID
- Steps to reproduce
- Expected vs. actual results
- Screenshots or videos if applicable
- Device and OS information