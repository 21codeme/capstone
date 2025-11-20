// import 'package:flutter/material.dart';
// import 'package:firebase_functions/firebase_functions.dart';
// import 'dart:async';

// /// Complete registration screen with email OTP verification
// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({Key? key}) : super(key: key);

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _otpController = TextEditingController();
  
//   bool _isLoading = false;
//   bool _isOtpSent = false;
//   bool _isVerifying = false;
//   String? _otpCode;
//   DateTime? _otpExpiry;
//   Timer? _timer;
//   int _remainingTime = 0;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _otpController.dispose();
//     _timer?.cancel();
//     super.dispose();
//   }

//   void _startOtpTimer() {
//     if (_otpExpiry == null) return;
    
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       final now = DateTime.now();
//       final remaining = _otpExpiry!.difference(now).inSeconds;
      
//       if (remaining <= 0) {
//         timer.cancel();
//         setState(() {
//           _remainingTime = 0;
//           _isOtpSent = false;
//           _otpCode = null;
//         });
        
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('OTP has expired. Please request a new one.')),
//           );
//         }
//       } else {
//         setState(() {
//           _remainingTime = remaining;
//         });
//       }
//     });
//   }

//   Future<void> _sendOtp() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Call the Firebase function to send OTP
//       final result = await FirebaseFunctions.instance
//           .httpsCallable('sendRegistrationOtp')
//           .call({
//         'email': _emailController.text.trim(),
//         'firstName': _firstNameController.text.trim(),
//         'lastName': _lastNameController.text.trim(),
//       });

//       if (result.data['success'] == true) {
//         setState(() {
//           _isOtpSent = true;
//           _otpCode = result.data['otp']; // Store for verification (remove in production)
//           _otpExpiry = DateTime.fromMillisecondsSinceEpoch(result.data['expiry']);
//         });
        
//         _startOtpTimer();
        
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('OTP sent to your email!')),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send OTP: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _verifyOtp() async {
//     if (_otpController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter the OTP code')),
//       );
//       return;
//     }

//     setState(() {
//       _isVerifying = true;
//     });

//     try {
//       // In a real app, you would call a verification function here
//       // For now, we'll just check if the OTP matches
//       if (_otpController.text == _otpCode) {
//         // OTP is correct, proceed with registration
//         await _completeRegistration();
//       } else {
//         throw Exception('Invalid OTP code');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Verification failed: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isVerifying = false;
//         });
//       }
//     }
//   }

//   Future<void> _completeRegistration() async {
//     // Here you would typically:
//     // 1. Create the user account
//     // 2. Store user data in Firestore
//     // 3. Navigate to the next screen
    
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Registration successful!')),
//       );
      
//       // Navigate to login or home screen
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   String _formatTime(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Register'),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 20),
//               const Text(
//                 'Create your account',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 30),
              
//               // Name fields
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _firstNameController,
//                       decoration: const InputDecoration(
//                         labelText: 'First Name',
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.person),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your first name';
//                         }
//                         return null;
//                       },
//                       enabled: !_isOtpSent,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _lastNameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Last Name',
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.person_outline),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your last name';
//                         }
//                         return null;
//                       },
//                       enabled: !_isOtpSent,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
              
//               // Email field
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.email),
//                   hintText: 'Enter your email address',
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your email';
//                   }
//                   if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
//                     return 'Please enter a valid email';
//                   }
//                   return null;
//                 },
//                 enabled: !_isOtpSent,
//               ),
//               const SizedBox(height: 24),
              
//               // OTP Section (shown after OTP is sent)
//               if (_isOtpSent) ...[
//                 TextFormField(
//                   controller: _otpController,
//                   decoration: InputDecoration(
//                     labelText: 'Verification Code',
//                     border: const OutlineInputBorder(),
//                     prefixIcon: const Icon(Icons.lock),
//                     suffixText: _remainingTime > 0 
//                         ? _formatTime(_remainingTime)
//                         : 'Expired',
//                   ),
//                   keyboardType: TextInputType.number,
//                   maxLength: 6,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter the verification code';
//                     }
//                     if (value.length != 6) {
//                       return 'OTP must be 6 digits';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
                
//                 // Verify OTP button
//                 ElevatedButton(
//                   onPressed: _isVerifying ? null : _verifyOtp,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: _isVerifying
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text('Verify & Complete Registration'),
//                 ),
                
//                 const SizedBox(height: 16),
                
//                 // Resend OTP button
//                 TextButton(
//                   onPressed: _remainingTime > 0 ? null : _sendOtp,
//                   child: Text(
//                     _remainingTime > 0 
//                         ? 'Resend OTP in ${_formatTime(_remainingTime)}'
//                         : 'Resend OTP',
//                   ),
//                 ),
//               ] else ...[
//                 // Send OTP button (shown initially)
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : _sendOtp,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator()
//                       : const Text('Send Verification Code'),
//                 ),
//               ],
              
//               const SizedBox(height: 24),
              
//               // Login link
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text('Already have an account?'),
//                   TextButton(
//                     onPressed: () => Navigator.pushNamed(context, '/login'),
//                     child: const Text('Login here'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }