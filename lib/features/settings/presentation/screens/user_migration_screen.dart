import 'package:flutter/material.dart';
import '../../../../core/services/user_migration_service.dart';

class UserMigrationScreen extends StatefulWidget {
  const UserMigrationScreen({Key? key}) : super(key: key);

  @override
  _UserMigrationScreenState createState() => _UserMigrationScreenState();
}

class _UserMigrationScreenState extends State<UserMigrationScreen> {
  final UserMigrationService _migrationService = UserMigrationService();
  bool _isMigrating = false;
  bool _isVerifying = false;
  bool _migrationComplete = false;
  bool _verificationComplete = false;
  MigrationResult? _migrationResults;
  VerificationResult? _verificationResults;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Data Migration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database Migration Tool',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This tool will migrate all user records from the current database to the new users collection. '
              'The migration process maintains data integrity and preserves all user attributes.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (_isMigrating)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Migration in progress...', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _migrationResults != null && _migrationResults!.totalUsers > 0
                        ? (_migrationService.migratedUsers / _migrationService.totalUsers)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _migrationResults != null
                        ? 'Migrated ${_migrationService.migratedUsers} of ${_migrationService.totalUsers} users'
                        : 'Preparing migration...',
                  ),
                ],
              )
            else if (_migrationComplete)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _migrationService.isComplete ? Icons.check_circle : Icons.warning,
                        color: _migrationService.isComplete ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _migrationService.isComplete
                            ? 'Migration completed successfully!'
                            : 'Migration completed with issues',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Total users: ${_migrationResults?.totalUsers ?? 0}'),
                  Text('Successfully migrated: ${_migrationResults?.successCount ?? 0}'),
                  Text('Failed migrations: ${_migrationResults?.failureCount ?? 0}'),
                  if (_migrationService.errors.isNotEmpty) ...[  
                    const SizedBox(height: 8),
                    const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        itemCount: _migrationService.errors.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              _migrationService.errors[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            if (_isVerifying)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verifying migration...', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
              )
            else if (_verificationComplete)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _verificationResults?.isSuccessful == true ? Icons.check_circle : Icons.warning,
                        color: _verificationResults?.isSuccessful == true ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _verificationResults?.isSuccessful == true
                            ? 'Verification completed successfully!'
                            : 'Verification completed with issues',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Source collection count: ${_verificationResults?.sourceCount ?? 0}'),
                  Text('Destination collection count: ${_verificationResults?.targetCount ?? 0}'),
                  Text('Missing documents: ${_verificationResults?.missingUserIds.length ?? 0}'),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: (_isMigrating || _isVerifying) ? null : _startMigration,
                  child: const Text('Start Migration'),
                ),
                ElevatedButton(
                  onPressed: (_isMigrating || _isVerifying || !_migrationComplete) ? null : _verifyMigration,
                  child: const Text('Verify Migration'),
                ),
                ElevatedButton(
                  onPressed: (_isMigrating || _isVerifying || !_migrationComplete) ? null : _rollbackMigration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Rollback'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMigration() async {
    setState(() {
      _isMigrating = true;
      _errorMessage = '';
      _migrationComplete = false;
      _verificationComplete = false;
      _migrationResults = null;
      _verificationResults = null;
    });

    try {
      final results = await _migrationService.migrateUsers();
      setState(() {
        _migrationResults = results;
        _migrationComplete = true;
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Migration failed: $e';
        _isMigrating = false;
      });
    }
  }

  Future<void> _verifyMigration() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
      _verificationComplete = false;
      _verificationResults = null;
    });

    try {
      final results = await _migrationService.verifyMigration();
      setState(() {
        _verificationResults = results;
        _verificationComplete = true;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed: $e';
        _isVerifying = false;
      });
    }
  }

  Future<void> _rollbackMigration() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rollback'),
        content: const Text(
          'Are you sure you want to rollback the migration? This will delete all data in the new collection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rollback'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isVerifying = true; // Reuse the verification progress indicator
      _errorMessage = '';
    });

    try {
      final result = await _migrationService.rollbackMigration();
      setState(() {
        _isVerifying = false;
        if (result.isSuccessful) {
          _migrationComplete = false;
          _verificationComplete = false;
          _migrationResults = null;
          _verificationResults = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Migration rolled back successfully')),
          );
        } else {
          _errorMessage = 'Rollback failed: ${result.errorMessage ?? "Unknown error"}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Rollback failed: $e';
        _isVerifying = false;
      });
    }
  }
}