# UID Consistency Test Guide

This guide provides comprehensive testing procedures to verify the UID-based authentication system is working correctly across the entire PathFit application.

## Overview

The migration from studentId-based to UID-based authentication ensures that Firebase Auth UID is used consistently as the Firestore document ID and reference key throughout the application.

## Test Categories

### 1. Authentication Flow Tests

#### 1.1 User Registration
```bash
# Test registration with new UID system
1. Create new account via registration form
2. Verify Firestore document uses UID as document ID
3. Check that studentId is stored as a field, not document ID
4. Confirm all related collections use UID as foreign key
```

#### 1.2 User Login
```bash
# Test login functionality
1. Login with existing credentials
2. Verify user data loads correctly using UID
3. Check that profile data matches UID-based document
4. Confirm session management uses UID
```

#### 1.3 Password Reset
```bash
# Test password reset flow
1. Initiate password reset
2. Complete reset process
3. Verify user can login with new password
4. Confirm UID-based document remains intact
```

### 2. Data Consistency Tests

#### 2.1 User Profile Updates
```bash
# Test profile update functionality
1. Update user profile information
2. Verify changes saved to UID-based document
3. Check that studentId field remains correct
4. Confirm no duplicate documents created
```

#### 2.2 Course Enrollment
```bash
# Test course enrollment
1. Enroll user in course
2. Verify enrollment uses UID as user reference
3. Check course progress tracking uses UID
4. Confirm enrollment data consistency
```

#### 2.3 Quiz/Assessment Data
```bash
# Test quiz and assessment functionality
1. Complete a quiz
2. Verify quiz results stored with UID
3. Check quiz history loads correctly
4. Confirm leaderboard uses UID references
```

### 3. Cloud Functions Tests

#### 3.1 Registration Cloud Function
```javascript
// Test completeStudentRegistration
const registrationData = {
  code: '123456',
  email: 'test@example.com'
};

// Expected: Creates Auth user and UID-based document
```

#### 3.2 User Deletion Cloud Function
```javascript
// Test deleteUserAccount
// Expected: Removes all UID-based data and Auth account
```

#### 3.3 Data Sync Function
```javascript
// Test syncAuthUserWithFirestore
// Expected: Ensures UID-based document exists
```

### 4. Migration Tests

#### 4.1 Existing User Migration
```bash
# Run migration script
node migrate_to_uid.js

# Verify:
# 1. All user documents use UID as ID
# 2. Related collections updated to use UID
# 3. No data loss occurred
# 4. Student ID preserved as field
```

### 5. Edge Case Tests

#### 5.1 Duplicate Student IDs
```bash
# Test handling of duplicate student IDs
1. Attempt to register with existing student ID
2. Verify proper error handling
3. Check that UID-based system prevents conflicts
```

#### 5.2 Missing Auth Users
```bash
# Test orphaned Firestore documents
1. Create Firestore document without Auth user
2. Verify migration handles gracefully
3. Check error handling and logging
```

## Testing Checklist

### Pre-Migration Checklist
- [ ] Backup all Firestore data
- [ ] Export user collection
- [ ] Document current studentId usage
- [ ] Test migration script on staging data

### Post-Migration Checklist
- [ ] Verify all user documents use UID as ID
- [ ] Check all related collections updated
- [ ] Test user login functionality
- [ ] Verify profile data integrity
- [ ] Test course enrollment
- [ ] Verify quiz/assessment data
- [ ] Check admin panel functionality
- [ ] Test password reset flow
- [ ] Verify email notifications
- [ ] Test user deletion

### Automated Testing

#### Run Unit Tests
```bash
# Run Flutter unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

#### Run Migration Tests
```bash
# Run UID consistency tests
node test_uid_consistency.js

# Run migration verification
node verify_migration.js
```

## Testing Commands

### Manual Testing Commands

#### Check Document Structure
```javascript
// Check user document uses UID
const userDoc = await db.collection('users').doc(uid).get();
console.log('Document ID:', userDoc.id);
console.log('UID field:', userDoc.data().uid);
console.log('Student ID field:', userDoc.data().studentId);
```

#### Verify Related Collections
```javascript
// Check all related collections use UID
const collections = [
  'userAchievements',
  'studentQuizzes',
  'studentModules',
  'assignmentSubmissions'
];

collections.forEach(async (collection) => {
  const docs = await db.collection(collection)
    .where('userId', '==', uid)
    .get();
  console.log(`${collection}: ${docs.size} documents`);
});
```

#### Verify No Student ID References
```javascript
// Check for remaining studentId references
const studentId = 'S2024001';
const collections = [...]; // same as above

collections.forEach(async (collection) => {
  const docs = await db.collection(collection)
    .where('studentId', '==', studentId)
    .get();
  console.log(`${collection}: ${docs.size} documents with old studentId`);
});
```

## Error Handling Tests

### Expected Error Scenarios

1. **Duplicate UID**: Should not occur (Firebase Auth handles)
2. **Missing Student ID**: Should be handled gracefully
3. **Orphaned Documents**: Should be logged and handled
4. **Migration Failures**: Should rollback and preserve data

### Error Monitoring

#### Check Migration Logs
```bash
# Review migration logs
grep "MIGRATION" /var/log/firebase/functions.log

# Check for errors
grep "ERROR" /var/log/firebase/functions.log
```

## Performance Testing

### Load Testing
```bash
# Test with concurrent users
# Monitor Firestore read/write operations
# Check authentication response times
```

### Migration Performance
- [ ] Document migration time per user
- [ ] Total migration duration
- [ ] Memory usage during migration
- [ ] Firestore operation limits

## Rollback Plan

### If Issues Occur
1. **Immediate**: Stop new registrations
2. **Short-term**: Restore from backup
3. **Long-term**: Fix issues and re-migrate

### Rollback Commands
```bash
# Restore from backup
firebase firestore:import --collection-ids users backup_users.json

# Restore related collections
# (Manual process - see backup documentation)
```

## Success Criteria

### Migration Success Indicators
- [ ] 100% of user documents use UID as document ID
- [ ] 100% of related collections use UID as foreign key
- [ ] Zero data loss
- [ ] All functionality working
- [ ] Performance maintained or improved

### User Experience Indicators
- [ ] Login working normally
- [ ] Profile data intact
- [ ] Course progress preserved
- [ ] Quiz history complete
- [ ] Notifications working

## Support and Troubleshooting

### Common Issues
1. **Auth User Not Found**: Check email matching
2. **Document Conflicts**: Handle duplicate student IDs
3. **Collection Updates**: Ensure all references updated
4. **Performance Issues**: Monitor Firestore limits

### Debug Commands
```bash
# Check specific user
firebase auth:get-user <uid>

# Check Firestore document
firebase firestore:get /users/<uid>

# Check related collections
firebase firestore:get /userAchievements --where userId=<uid>
```

## Final Verification

### Complete System Test
```bash
# Run full system test
1. Register new user
2. Complete profile
3. Enroll in course
4. Complete quiz
5. Update profile
6. Reset password
7. Delete account
8. Verify cleanup
```

### Documentation Updates
- [ ] Update API documentation
- [ ] Update admin panel guides
- [ ] Update user guides
- [ ] Update troubleshooting docs