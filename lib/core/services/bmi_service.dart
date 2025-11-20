import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BmiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Checks if the current user has BMI data in Firestore
  Future<bool> hasBmiData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final bmiDoc = await _firestore
          .collection('bmi_records')
          .doc(user.uid)
          .get();

      if (!bmiDoc.exists) return false;
      
      // Check if it's an empty placeholder record
      final data = bmiDoc.data();
      if (data != null && data['isEmpty'] == true) {
        return false; // Treat empty placeholder as no BMI data
      }
      
      return true;
    } catch (e) {
      print('Error checking BMI data: $e');
      return false;
    }
  }

  /// Gets the latest BMI data for the current user
  Future<Map<String, dynamic>?> getLatestBmiData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final bmiDoc = await _firestore
          .collection('bmi_records')
          .doc(user.uid)
          .get();

      if (bmiDoc.exists) {
        final data = bmiDoc.data();
        // Return null if it's an empty placeholder record
        if (data != null && data['isEmpty'] == true) {
          return null;
        }
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting BMI data: $e');
      return null;
    }
  }

  /// Checks if user can update BMI (once per month restriction)
  Future<Map<String, dynamic>> canUpdateBMI() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'canUpdate': false, 'reason': 'User not authenticated'};
      }

      final bmiDoc = await _firestore
          .collection('bmi_records')
          .doc(user.uid)
          .get();

      if (!bmiDoc.exists) {
        return {'canUpdate': true, 'reason': 'No existing BMI data'};
      }

      final data = bmiDoc.data()!;
      // Check if it's an empty placeholder record
      if (data['isEmpty'] == true) {
        return {'canUpdate': true, 'reason': 'Empty placeholder record - can be updated'};
      }

      final timestamp = data['timestamp'] as Timestamp?;
      
      if (timestamp == null) {
        return {'canUpdate': true, 'reason': 'No timestamp found'};
      }

      final lastUpdate = timestamp.toDate();
      final now = DateTime.now();
      final daysSinceUpdate = now.difference(lastUpdate).inDays;

      if (daysSinceUpdate < 30) {
        final daysRemaining = 30 - daysSinceUpdate;
        return {
          'canUpdate': false,
          'reason': 'BMI can only be updated once per month. Please wait $daysRemaining more days.',
          'daysRemaining': daysRemaining,
          'lastUpdate': lastUpdate,
        };
      }

      return {'canUpdate': true, 'reason': 'Monthly restriction satisfied'};
    } catch (e) {
      print('Error checking BMI update eligibility: $e');
      return {'canUpdate': false, 'reason': 'Error checking eligibility: $e'};
    }
  }

  /// Saves BMI data for the current user with monthly validation
  Future<Map<String, dynamic>> saveBmiData({
    required double height,
    required double weight,
    required double bmi,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Check if user can update BMI
      final canUpdateResult = await canUpdateBMI();
      if (!canUpdateResult['canUpdate']) {
        return {
          'success': false,
          'message': canUpdateResult['reason'],
          'canUpdate': false,
        };
      }

      // Save BMI data with new structure
      await _firestore.collection('bmi_records').doc(user.uid).set({
        'height': height,
        'weight': weight,
        'bmi': bmi,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'monthlyUpdate': true,
        'updateDate': DateTime.now().toIso8601String(),
        'isEmpty': false, // Remove empty flag when updating with real data
      }, SetOptions(merge: true));

      return {
        'success': true,
        'message': 'BMI data saved successfully',
        'canUpdate': true,
      };
    } catch (e) {
      print('Error saving BMI data: $e');
      return {
        'success': false,
        'message': 'Error saving BMI data: $e',
      };
    }
  }

  /// Gets BMI history for the current user
  Future<List<Map<String, dynamic>>> getBmiHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Get all BMI records from a subcollection for history tracking
      final historySnapshot = await _firestore
          .collection('bmi_records')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(12) // Last 12 months
          .get();

      return historySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting BMI history: $e');
      return [];
    }
  }

  /// Saves BMI update to history (for tracking monthly updates)
  Future<void> saveBmiToHistory({
    required double height,
    required double weight,
    required double bmi,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('bmi_records')
          .doc(user.uid)
          .collection('history')
          .add({
        'height': height,
        'weight': weight,
        'bmi': bmi,
        'timestamp': FieldValue.serverTimestamp(),
        'updateDate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving BMI to history: $e');
    }
  }
}