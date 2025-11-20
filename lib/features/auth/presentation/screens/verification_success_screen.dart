import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathfitcapstone/features/auth/presentation/providers/auth_provider.dart';
import 'package:pathfitcapstone/features/auth/data/services/student_registration_service.dart';
import 'package:pathfitcapstone/core/services/jwt_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class VerificationSuccessScreen extends StatefulWidget {
  final String? token;

  const VerificationSuccessScreen({Key? key, required this.token}) : super(key: key);

  @override
  _VerificationSuccessScreenState createState() => _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen> {
  bool _isLoading = true;
  bool _verificationComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _completeVerification();
  }

  Future<void> _completeVerification() async {
    try {
      final jwtService = JwtService();
      final registrationService = StudentRegistrationService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.token == null) {
        setState(() {
          _errorMessage = 'No verification token provided';
          _isLoading = false;
        });
        return;
      }

      // Verify the token and get email
      final payload = JwtService.verifyEmailToken(widget.token!);
      if (payload == null) {
        setState(() {
          _errorMessage = 'Invalid or expired verification link';
          _isLoading = false;
        });
        return;
      }
      final email = payload['email'] as String;

      // Get pending student data
      final pendingStudent = await registrationService.getStudentByEmail(email);
      if (pendingStudent == null) {
        setState(() {
          _errorMessage = 'No pending registration found for this email';
          _isLoading = false;
        });
        return;
      }

      // Create the actual Firebase account
      final success = await authProvider.createVerifiedStudentAccount(
        email: pendingStudent['email'],
        password: pendingStudent['password'],
        firstName: pendingStudent['firstName'],
        lastName: pendingStudent['lastName'],
        middleName: pendingStudent['middleName'],
        age: pendingStudent['age'],
        gender: pendingStudent['gender'],
        course: pendingStudent['course'],
        year: pendingStudent['year'],
        section: pendingStudent['section'],
      );

      if (success) {
        // Complete the verification process
        await registrationService.verifyStudentEmailWithCode(
          email: email,
          code: pendingStudent['verificationCode'],
        );
        
        setState(() {
          _verificationComplete = true;
          _isLoading = false;
        });

        // Navigate to home after 3 seconds
        Future.delayed(Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to create account';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during verification';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Completing your registration...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 24),
          Text(
            'Verification Failed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Return to Login'),
          ),
        ],
      );
    }

    if (_verificationComplete) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green,
          ),
          SizedBox(height: 24),
          Text(
            'Registration Complete!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          Text(
            'Your account has been successfully created.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          Text(
            'Redirecting to your dashboard...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return SizedBox();
  }
}