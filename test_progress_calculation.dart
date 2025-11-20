import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/student_progress_service.dart';

void main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized');
    
    // Test the progress calculation function
    const testStudentId = '2hE6RoCCYSRvfCiL4jOspmQy6by1';
    print('🔄 Testing progress calculation for student: $testStudentId');
    
    final progress = await StudentProgressService.calculateOverallProgress(testStudentId);
    print('🎯 Calculated progress: $progress (${(progress * 100).toStringAsFixed(2)}%)');
    
    // Expected: 88.94% based on manual calculation
    print('✅ Test completed');
  } catch (e) {
    print('❌ Error during test: $e');
  }
}