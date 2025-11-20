import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/registration_service.dart';

/// Example registration screen with email OTP verification
class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationService = RegistrationService();
  
  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();
  final _sectionController = TextEditingController();
  final _otpController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _otpSent = false;
  String? _sentOTP; // For testing purposes - remove in production
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _sectionController.dispose();
    _otpController.dispose();
    super.dispose();
  }
  
  /// Send OTP to email
  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _registrationService.sendRegistrationOTP(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      
      if (result['success']) {
        setState(() {
          _otpSent = true;
          _sentOTP = result['data']['otp']; // For testing - remove in production
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to your email!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Complete registration
  Future<void> _completeRegistration() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the OTP code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // For testing purposes - remove this validation in production
    if (_sentOTP != null && _otpController.text != _sentOTP) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid OTP code. For testing, use: $_sentOTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final result = await _registrationService.completeRegistration(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        course: _courseController.text.trim(),
        year: _yearController.text.trim(),
        section: _sectionController.text.trim(),
        otpCode: _otpController.text.trim(),
      );
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! Welcome to PathFit!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home screen or login screen
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register with PathFit'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information Section
              Text(
                'Personal Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800]),
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'First name is required' : null,
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Last name is required' : null,
              ),
              SizedBox(height: 24),
              
              // Academic Information Section
              Text(
                'Academic Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800]),
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _courseController,
                decoration: InputDecoration(
                  labelText: 'Course *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Course is required' : null,
              ),
              SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: InputDecoration(
                        labelText: 'Year *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Year is required' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sectionController,
                      decoration: InputDecoration(
                        labelText: 'Section *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Section is required' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Account Information Section
              Text(
                'Account Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800]),
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email is required';
                  if (!value!.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Password is required';
                  if (value!.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // OTP Verification Section
              if (_otpSent) ...[
                Text(
                  'Email Verification',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
                SizedBox(height: 16),
                
                Text(
                  'We\'ve sent a 6-digit verification code to ${_emailController.text}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'Enter Verification Code *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.confirmation_number),
                    hintText: '6-digit code',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter the verification code';
                    if (value!.length != 6) return 'Please enter a 6-digit code';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                TextButton.icon(
                  onPressed: _isLoading ? null : () async {
                    final result = await _registrationService.resendRegistrationOTP(
                      email: _emailController.text.trim(),
                      firstName: _firstNameController.text.trim(),
                      lastName: _lastNameController.text.trim(),
                    );
                    
                    if (result['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('OTP resent to your email!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to resend OTP: ${result["error"]}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Resend Code'),
                ),
                SizedBox(height: 24),
              ],
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
                SizedBox(height: 16),
              ],
              
              // Action Button
              ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _completeRegistration : _sendOTP),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _otpSent ? 'Complete Registration' : 'Send Verification Code',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              
              SizedBox(height: 16),
              
              // Login Link
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: Text(
                  'Already have an account? Login here',
                  style: TextStyle(color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}