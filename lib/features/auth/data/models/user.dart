
enum Gender { male, female, other, preferNotToSay }
enum UserRole { student, instructor, admin }

class UserModel {
  final String uid; // Firebase Auth UID
  final String studentId; // Student ID (primary identifier)
  final String email;
  final String fullName;
  final bool isStudent; // Changed from role to boolean isStudent
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final String profilePicture;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? gender;
  final String accountStatus;
  final String? course;
  final String? year;
  final String? section;

  UserModel({
    required this.uid,
    required this.studentId,
    required this.email,
    required this.fullName,
    required this.isStudent,
    this.createdAt,
    this.lastLogin,
    this.profilePicture = '',
    this.phoneNumber = '',
    this.firstName,
    this.lastName,
    this.age,
    this.gender,
    this.accountStatus = 'active',
    this.course,
    this.year,
    this.section,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      // Handle both new isStudent field and legacy role field
      bool isStudent;
      if (map.containsKey('isStudent')) {
        isStudent = map['isStudent'] as bool;
      } else if (map.containsKey('role')) {
        // Convert legacy role field to isStudent boolean
        isStudent = (map['role'] as String?) == 'student';
      } else {
        // Default to student if neither field exists
        isStudent = true;
      }
      
      return UserModel(
        uid: map['uid'] ?? '',
        studentId: map['studentId'] ?? map['uid'] ?? '', // Use studentId if available, fallback to uid
        email: map['email'] ?? '',
        fullName: map['fullName'] ?? '',
        isStudent: isStudent,
        createdAt: _parseDateTime(map['createdAt']),
        lastLogin: _parseDateTime(map['lastLogin']),
        profilePicture: map['profilePicture'] ?? '',
        phoneNumber: map['phoneNumber'] ?? '',
        firstName: map['firstName'],
        lastName: map['lastName'],
        age: map['age']?.toInt(),
        gender: map['gender'],
        accountStatus: map['accountStatus'] ?? 'active',
        course: map['course'],
        year: map['year'],
        section: map['section'],
      );
    } catch (e) {
      print('❌ Error creating UserModel from map: $e');
      print('📄 Map data: $map');
      rethrow;
    }
  }

  // Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is DateTime) {
        return value;
      } else if (value.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp string representation
        final timestampStr = value.toString();
        final secondsMatch = RegExp(r'seconds=(\d+)').firstMatch(timestampStr);
        if (secondsMatch != null) {
          final seconds = int.parse(secondsMatch.group(1)!);
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value.toString().isNotEmpty) {
        // Try to parse as regular string
        return DateTime.parse(value.toString());
      }
    } catch (e) {
      print('⚠️ Error parsing DateTime: $e for value: $value');
    }
    
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'studentId': studentId,
      'email': email,
      'fullName': fullName,
      'isStudent': isStudent,
      'role': isStudent ? 'student' : 'instructor', // Keep role for backward compatibility
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'profilePicture': profilePicture,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'gender': gender,
      'accountStatus': accountStatus,
      'course': course,
      'year': year,
      'section': section,
    };
  }

  UserModel copyWith({
    String? uid,
    String? studentId,
    String? email,
    String? fullName,
    bool? isStudent,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? profilePicture,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    String? accountStatus,
    String? course,
    String? year,
    String? section,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isStudent: isStudent ?? this.isStudent,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      profilePicture: profilePicture ?? this.profilePicture,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      accountStatus: accountStatus ?? this.accountStatus,
      course: course ?? this.course,
      year: year ?? this.year,
      section: section ?? this.section,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, studentId: $studentId, email: $email, fullName: $fullName, isStudent: $isStudent, accountStatus: $accountStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.studentId == studentId;
  }

  @override
  int get hashCode => studentId.hashCode;
}
