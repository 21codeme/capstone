# Registration OTP Email Verification Setup

This guide explains how to use the new server-side Nodemailer function that sends 6-digit OTP codes for email verification during user registration.

## 🚀 What's New

A new Firebase Cloud Function `sendRegistrationOtp` has been created that:
- Generates a secure 6-digit OTP code
- Sends a professionally designed HTML email with the OTP
- Includes expiration time (10 minutes) for security
- Provides comprehensive error handling
- Returns the OTP and expiry time for testing purposes

## 📧 Email Features

The registration email includes:
- **Professional Design**: Modern gradient header with PathFit branding
- **Clear Instructions**: Step-by-step guidance for users
- **OTP Display**: Large, easy-to-read 6-digit code
- **Security Notice**: 10-minute expiration warning
- **Next Steps**: Helpful information about what to do after verification

## 🔧 Function Details

### Function: `sendRegistrationOtp`

**Location**: `functions/index.js`

**Parameters**:
```json
{
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Registration OTP sent successfully",
  "otp": "123456",        // For testing only - remove in production
  "expiry": 1758452154219  // Unix timestamp
}
```

## 📱 Flutter Integration

### 1. Add Firebase Functions to your Flutter app

Add to your `pubspec.yaml`:
```yaml
dependencies:
  firebase_functions: ^4.0.0
```

### 2. Use the Registration Service

```dart
import 'package:firebase_functions/firebase_functions.dart';

class RegistrationService {
  static Future<Map<String, dynamic>> sendRegistrationOtp({
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('sendRegistrationOtp')
          .call({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      });

      return result.data;
    } catch (e) {
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }
}
```

### 3. Implement the Registration Screen

Use the provided `registration_screen.dart` which includes:
- Form validation for email and names
- OTP input with countdown timer
- Resend OTP functionality
- Professional UI with loading states

## 🧪 Testing

### Test the Function Directly

1. **Using Dart Test Script**:
```bash
cd pathfitcapstone
dart run test_registration_otp_proper.dart
```

2. **Using Firebase Emulator** (for local testing):
```bash
cd functions
firebase emulators:start
```

### Test with Invalid Data

The function handles various error cases:
- Missing email → Returns 400 error
- Invalid email format → Returns 400 error  
- Nodemailer issues → Returns 500 error with detailed message

## 🔒 Security Considerations

1. **Remove OTP from Response**: In production, remove the OTP from the response and only return success/failure
2. **Rate Limiting**: Consider adding rate limiting to prevent abuse
3. **Email Validation**: The function includes basic email validation
4. **Expiration**: OTP codes expire after 10 minutes
5. **HTTPS Only**: All communications are encrypted via HTTPS

## 📊 Monitoring

Check function logs:
```bash
cd functions
firebase functions:log --only sendRegistrationOtp
```

## 🛠️ Deployment

The function is automatically deployed with:
```bash
cd functions
firebase deploy --only functions:sendRegistrationOtp
```

## 🔧 Customization

### Modify Email Template

Edit the HTML template in `functions/index.js` within the `sendRegistrationOtp` function:

```javascript
const mailOptions = {
  from: 'YourApp <your-email@gmail.com>',
  to: email,
  subject: 'Your Custom Subject',
  html: `
    <!-- Your custom HTML email template -->
  `
};
```

### Change OTP Length or Expiration

```javascript
// Generate different length OTP
const otp = Math.floor(1000 + Math.random() * 9000).toString(); // 4-digit

// Change expiration time
const expiry = Date.now() + (5 * 60 * 1000); // 5 minutes
```

## 📋 Integration Checklist

- [ ] Deploy the function to Firebase
- [ ] Update Flutter app with Firebase Functions dependency
- [ ] Implement registration screen with OTP verification
- [ ] Test with valid and invalid email addresses
- [ ] Remove OTP from response in production
- [ ] Add proper error handling in Flutter app
- [ ] Test the complete registration flow
- [ ] Monitor function logs for any issues

## 🆘 Troubleshooting

### Common Issues

1. **"Email is required" error**: Make sure you're passing the data in the correct format
2. **Function not found**: Ensure the function is deployed and the name matches exactly
3. **Email not received**: Check spam folder and verify Nodemailer configuration
4. **CORS errors**: Use the Firebase Functions SDK instead of direct HTTP calls

### Debug Steps

1. Check Firebase Functions logs for detailed error messages
2. Verify your Firebase project configuration
3. Test with the provided Dart test scripts
4. Ensure your Flutter app has proper Firebase configuration

## 📞 Support

For issues with the function:
1. Check the Firebase Functions logs
2. Test with the provided test scripts
3. Verify your Firebase project setup
4. Ensure proper error handling in your Flutter app

---

**Note**: This function is designed for registration verification. For production use, consider removing the OTP from the response and implementing additional security measures like rate limiting and email domain validation.