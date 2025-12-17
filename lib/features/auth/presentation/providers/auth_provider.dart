import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/auth_error_handler.dart';
import '../../data/models/user.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../app/theme/theme_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  User? _currentUser;
  UserModel? _userData;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _registrationInFlight = false;
  bool _signOutInProgress = false;

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get currentUserModel => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  bool get isStudent => _userData?.isStudent ?? true;
  bool get isInstructor => !isStudent;

  // Initialize the auth provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();
    try {
      // Listen to auth state changes
      _authService.authStateChanges.listen((User? user) {
        _currentUser = user;
        if (user != null) {
          _loadUserData(user.uid);
        } else {
          _userData = null;
        }
        notifyListeners();
      });

      // Check current user
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        await _loadUserData(_currentUser!.uid);
      }
    } catch (e) {
      _setError(AuthErrorHandler.getErrorMessage(e, 'Initialize'));
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  // Load user data using UID
  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await _authService.getUserData(uid);
      if (userData != null) {
        final accountStatus = userData['accountStatus'] as String?;
        if (accountStatus == 'inactive') {
          await signOut();
          _setError('Your account is inactive. Please contact support.');
          return;
        }

        _userData = UserModel.fromMap(userData);
      } else {
        if (_currentUser != null) {
          final role = await _authService.getUserRole(uid);
          final isStudent = role == 'student';
          _userData = UserModel(
            uid: uid,
            studentId: uid,
            email: _currentUser!.email ?? '',
            fullName: _currentUser!.displayName ?? '',
            isStudent: isStudent,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _handleAuthError(e);
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      _currentUser = userCredential.user;

      if (_currentUser != null) {
        await _loadUserData(_currentUser!.uid);
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  // Alternative sign in method (compatibility)
  Future<bool> signInUser({required String email, required String password}) async {
    return signIn(email, password);
  }

  // Register a new user
  Future<bool> registerUser({
    required String email,
    required String password,
    required String displayName,
    required bool isStudent,
    String? firstName,
    String? middleName,
    String? lastName,
    int? age,
    String? gender,
    String? course,
    String? year,
    String? section,
  }) async {
    if (_registrationInFlight || _isLoading) return false;

    final normalizedEmail = email.trim();

    try {
      _registrationInFlight = true;
      _setLoading(true);
      _clearError();

      if (_authService.currentUser != null) {
        await _authService.signOut();
      }

      final methods = await _authService.fetchSignInMethods(normalizedEmail);
      if (methods.isNotEmpty) {
        if (methods.contains('password')) {
          _setError('This email is already registered. Try signing in instead.');
        } else {
          final provider = methods.join(', ');
          _setError('This email is already registered via $provider. Use that to sign in or link your email in Account Settings.');
        }
        _setLoading(false);
        return false;
      }

      final userCredential = await _authService.createUserWithEmailAndPassword(normalizedEmail, password);
      _currentUser = userCredential.user;

      if (_currentUser == null) {
        _setError('Registration failed. Please try again.');
        _setLoading(false);
        return false;
      }

      await _authService.updateUserDisplayName(user: _currentUser!, displayName: displayName);

      final uid = _currentUser!.uid;
      await _authService.createUserDocument(
        uid,
        normalizedEmail,
        displayName,
        isStudent,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        age: age,
        gender: gender,
        course: course,
        year: year,
        section: section,
      );

      await _loadUserData(uid);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final methods = await _authService.fetchSignInMethods(normalizedEmail);
        if (methods.contains('password')) {
          _setError('This email is already registered. Try signing in instead.');
        } else if (methods.isNotEmpty) {
          final provider = methods.join(', ');
          _setError('This email is already registered via $provider. Use that to sign in or link your email.');
        } else {
          _setError('This email is already registered.');
        }
      } else {
        _setError(AuthErrorHandler.getErrorMessage(e, 'Registration'));
      }
      return false;
    } finally {
      _registrationInFlight = false;
    }
  }

  // Secure sign out (optimized for speed)
  Future<void> signOut() async {
    if (_signOutInProgress) return;
    _signOutInProgress = true;
    try {
      _setLoading(true);
      
      // Clear local state immediately (no network call)
      _currentUser = null;
      _userData = null;
      _clearError();
      
      // Sign out from Firebase (this is the critical path)
      await _authService.signOut();
      
      // Clear persistent data in background (non-blocking)
      _authService.clearPersistentData().catchError((e) {
        print('⚠️ Error clearing persistent data: $e');
      });
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to sign out: $e');
      _setLoading(false);
    } finally {
      _signOutInProgress = false;
    }
  }

  // Reset the application state and sign out
  Future<void> resetAppState(BuildContext context) async {
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.resetState();
      await signOut();
    } catch (e) {
      _setError('Failed to reset app state: $e');
      rethrow;
    }
  }

  // Create verified student account
  Future<bool> createVerifiedStudentAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? middleName,
    required int age,
    required String gender,
    required String course,
    required String year,
    required String section,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final normalizedEmail = email.trim().toLowerCase();
      final methods = await _authService.fetchSignInMethods(normalizedEmail);
      if (methods.isNotEmpty) {
        _setError('This email is already registered.');
        _setLoading(false);
        return false;
      }

      final userCredential = await _authService.createUserWithEmailAndPassword(normalizedEmail, password);
      _currentUser = userCredential.user;

      if (_currentUser == null) {
        _setError('Account creation failed. Please try again.');
        _setLoading(false);
        return false;
      }

      final displayName = '$firstName $lastName'.trim();
      await _authService.updateUserDisplayName(user: _currentUser!, displayName: displayName);

      final uid = _currentUser!.uid;
      await _authService.createUserDocument(
        uid,
        normalizedEmail,
        displayName,
        true,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        age: age,
        gender: gender,
        course: course,
        year: year,
        section: section,
      );

      await _loadUserData(uid);

      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? lastName,
    String? bio,
    String? photoURL,
  }) async {
    try {
      if (_currentUser == null) return false;
      _setLoading(true);
      _clearError();

      if (displayName != null) {
        await _authService.updateUserDisplayName(user: _currentUser!, displayName: displayName);
      }

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (lastName != null) updates['lastName'] = lastName;
      if (bio != null) updates['bio'] = bio;
      if (photoURL != null) updates['photoURL'] = photoURL;

      if (updates.isNotEmpty) {
        await _authService.updateUserDocument(_currentUser!.uid, updates);
        await _loadUserData(_currentUser!.uid);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  // Update profile with map data
  Future<bool> updateProfile([Map<String, dynamic>? data]) async {
    try {
      if (_currentUser == null) return false;
      _setLoading(true);
      _clearError();

      if (data != null && data.isNotEmpty) {
        await _authService.updateUserDocument(_currentUser!.uid, data);
        await _loadUserData(_currentUser!.uid);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  // Update profile with UserModel data
  Future<bool> updateProfileWithUserModel(UserModel updatedUser) async {
    try {
      if (_currentUser == null) return false;
      _setLoading(true);
      _clearError();

      final updateData = updatedUser.toMap();
      await _authService.updateUserDocument(_currentUser!.uid, updateData);
      await _loadUserData(_currentUser!.uid);

      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  // Update user password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null || _currentUser!.email == null) {
        _setError('User not logged in');
        return false;
      }
      _setLoading(true);
      _clearError();

      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: currentPassword,
      );

      await _currentUser!.reauthenticateWithCredential(credential);
      await _currentUser!.updatePassword(newPassword);

      _setLoading(false);
      return true;
    } catch (e) {
      _handleAuthError(e);
      _setLoading(false);
      return false;
    }
  }

  // Enforce role-based access control
  Future<bool> enforceRoleAccess(String requiredRole) async {
    try {
      if (_currentUser == null) return false;
      if (requiredRole == 'any') return true;

      final email = _currentUser?.email;
      if (email == null) return false;

      final studentId = await _authService.getStudentIdByEmail(email);
      if (studentId == null) return false;

      final userData = await _authService.getUserData(studentId);
      if (userData == null) return false;

      final accountStatus = userData['accountStatus'] as String?;
      if (accountStatus != 'active') {
        await signOut();
        return false;
      }

      final isStudent = userData['isStudent'] as bool? ?? true;
      final userRole = isStudent ? 'student' : 'instructor';
      return userRole == requiredRole;
    } catch (_) {
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  void _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          _setError('No user found with this email.');
          break;
        case 'wrong-password':
          _setError('Incorrect password.');
          break;
        case 'email-already-in-use':
          _setError('This email is already registered.');
          break;
        case 'weak-password':
          _setError('Password is too weak. Use at least 8 characters.');
          break;
        case 'invalid-email':
          _setError('Invalid email address.');
          break;
        default:
          _setError('Authentication error: ${error.message}');
      }
    } else {
      _setError('Authentication error: $error');
    }
  }

  // Test Firebase connection
  Future<Map<String, dynamic>> testFirebaseConnection() async {
    try {
      final user = _authService.currentUser;
      return {
        'success': true,
        'auth': true,
        'message': 'Firebase connection successful',
        'user': user?.uid ?? 'No user signed in',
      };
    } catch (e) {
      return {
        'success': false,
        'auth': false,
        'message': 'Firebase connection failed: $e',
      };
    }
  }

  // Check email status
  Future<Map<String, dynamic>> checkEmailStatus(String email) async {
    try {
      final methods = await _authService.fetchSignInMethods(email.trim());
      final exists = methods.isNotEmpty;
      return {
        'exists': exists,
        'methods': methods,
        'message': exists
            ? (methods.contains('password')
                ? 'Email already registered (password).'
                : 'Email registered via ${methods.join(', ')}.')
            : 'Email available',
        'status': exists ? 'exists' : 'available',
      };
    } catch (e) {
      return {
        'exists': false,
        'methods': const <String>[],
        'message': 'Error checking email: $e',
        'status': 'error',
      };
    }
  }
}