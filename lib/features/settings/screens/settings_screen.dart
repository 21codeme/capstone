import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/data/models/user.dart';
import '../../../core/services/profile_picture_service.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import 'package:pathfitcapstone/app/routes/app_router.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _limitFirebaseConnections = false;

  String _getInitials(String? displayName) {
    if (displayName == null || displayName.isEmpty) return 'JS';
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.length == 1) {
      return names[0][0].toUpperCase();
    }
    return 'JS';
  }
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  
  /// Get profile picture widget
  Widget _getProfilePicture(UserModel? user, ColorScheme colorScheme) {
    if (user?.profilePicture != null && user!.profilePicture.isNotEmpty) {
      try {
        // Try to decode as base64 first
        if (user.profilePicture.startsWith('data:image') || user.profilePicture.length > 100) {
          // This is likely a base64 image
          final imageWidget = _profilePictureService.base64ToImage(user.profilePicture);
          if (imageWidget != null) {
            return CircleAvatar(
              radius: 50,
              backgroundImage: imageWidget.image as ImageProvider?,
              backgroundColor: colorScheme.primary,
            );
          }
        } else {
          // This might be a file path
          final file = File(user.profilePicture);
          if (file.existsSync()) {
            return CircleAvatar(
              radius: 50,
              backgroundImage: FileImage(file),
              backgroundColor: colorScheme.primary,
            );
          }
        }
      } catch (e) {
        // Fallback to initials if there's an error
        // Error handling is silent for production
      }
    }
    
    // Fallback to initials
    return CircleAvatar(
      radius: 50,
      backgroundColor: colorScheme.primary,
      child: Text(
        _getInitials(user?.fullName) ?? 'JS',
        style: AppTextStyles.textTheme.headlineMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    // Get actual user data from auth provider
    final user = authProvider.currentUserModel;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            // Navigate back based on user role
            if (user?.isStudent == true) {
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/student-dashboard', 
                (route) => false
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/instructor-dashboard', 
                (route) => false
              );
            }
          },
        ),
        title: Text(
          'Settings',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Profile Picture
                  _getProfilePicture(user, colorScheme),
                  
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    user?.fullName ?? 'User Name',
                    style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Email
                  Text(
                    user?.email ?? 'user@email.com',
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Edit Profile Button
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile-settings');
                    },
                    child: Text(
                      'Edit Profile',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  

                ],
              ),
            ),
            
            // Settings Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Account Settings Section
                  _SettingsSection(
                    title: 'Account Settings',
                    items: [
                                             _SettingsItem(
                         icon: Icons.person,
                         title: 'Profile Settings',
                         onTap: () {
                           Navigator.pushNamed(context, '/profile-settings');
                         },
                       ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App Settings Section
                  _SettingsSection(
                    title: 'App Settings',
                    items: [
                      _SettingsItem(
                        icon: Icons.volume_up,
                        title: 'Sound & Vibration',
                        onTap: () {
                          _showSoundSettings();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  

                  
                  // Social & Support Section
                  _SettingsSection(
                    title: 'Social & Support',
                    items: [
                       _SettingsItem(
                         icon: Icons.info,
                         title: 'About Us',
                         onTap: () {
                           _showAboutUs();
                         },
                       ),
                       _SettingsItem(
                         icon: Icons.description,
                         title: 'Privacy Policy',
                         onTap: () {
                           _showPrivacyPolicy();
                         },
                       ),
                       _SettingsItem(
                         icon: Icons.gavel,
                         title: 'Terms of Service',
                         onTap: () {
                           _showTermsOfService();
                         },
                       ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                                     // Version Number
                   Text(
                     'Version 2.0.1',
                     style: AppTextStyles.textTheme.bodySmall?.copyWith(
                       color: colorScheme.onSurface.withOpacity(0.7),
                     ),
                   ),
                   
                   const SizedBox(height: 32),
                   
                   // Account Section
                   _SettingsSection(
                     title: 'Account',
                     items: [
                       _SettingsItem(
                         icon: Icons.logout,
                         title: 'Log Out',
                         onTap: _showLogoutDialog,
                         isLogout: true,
                       ),
                       // Delete Account option removed - accounts are automatically deleted after 10 minutes if unverified
                     ],
                   ),
                   
                   const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
       ),
     );
   }
   
   // Logout Dialog
   void _showLogoutDialog() {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log Out',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
           ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () async {
              // Close the confirm dialog
              Navigator.pop(context);

              // Show a blocking progress dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: Text(
                    'Logging Out',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Securely terminating your session...',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);

                // IMPORTANT: actually sign out + clear app state here
                // resetAppState calls signOut() internally and resets other providers.
                await authProvider.resetAppState(context);

                // Close the spinner dialog
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                if (!context.mounted) return;

                // Navigate AFTER sign out completes
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);

                // Show success on the next frame (so ScaffoldMessenger uses the new route)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final cs = context.read<ThemeProvider>().colorScheme;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Logged out successfully'),
                      backgroundColor: cs.primary,
                    ),
                  );
                });
              } catch (e) {
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context); // close spinner
                }
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error during logout: $e'),
                    backgroundColor: colorScheme.error,
                  ),
                );
              }
            },
            child: Text(
              'Log Out',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
   
    
   
   // Language Settings
   void _showLanguageSettings() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Language',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             _LanguageOption(
               title: 'English',
               subtitle: 'US English',
               flag: '🇺🇸',
               isSelected: true,
               onTap: () {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Language changed to English'),
                     backgroundColor: colorScheme.primary,
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _LanguageOption(
               title: 'Spanish',
               subtitle: 'Español',
               flag: '🇪🇸',
               isSelected: false,
               onTap: () {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Language changed to Spanish'),
                     backgroundColor: colorScheme.primary,
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _LanguageOption(
               title: 'French',
               subtitle: 'Français',
               flag: '🇫🇷',
               isSelected: false,
               onTap: () {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Language changed to French'),
                     backgroundColor: colorScheme.primary,
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _LanguageOption(
               title: 'German',
               subtitle: 'Deutsch',
               flag: '🇩🇪',
               isSelected: false,
               onTap: () {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Language changed to German'),
                     backgroundColor: colorScheme.primary,
                   ),
                 );
               },
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Cancel',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Theme Settings
   void _showThemeSettings() {
     final themeProvider = context.read<ThemeProvider>();
     final currentMode = themeProvider.currentThemeMode;
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Theme',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             _ThemeOption(
               title: 'Light',
               subtitle: 'Clean and bright interface',
               icon: Icons.light_mode,
               isSelected: currentMode == AppThemeMode.light,
               onTap: () {
                 themeProvider.setThemeMode(AppThemeMode.light);
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Light theme applied successfully!'),
                     backgroundColor: colorScheme.primary,
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _ThemeOption(
               title: 'Dark',
               subtitle: 'Easy on the eyes',
               icon: Icons.dark_mode,
               isSelected: currentMode == AppThemeMode.dark,
               onTap: () {
                 themeProvider.setThemeMode(AppThemeMode.dark);
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Dark theme applied successfully!'),
                     backgroundColor: colorScheme.primary,
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _ThemeOption(
               title: 'Auto',
               subtitle: 'Follow system settings',
               icon: Icons.brightness_auto,
               isSelected: currentMode == AppThemeMode.auto,
               onTap: () {
                 themeProvider.setThemeMode(AppThemeMode.auto);
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Auto theme applied successfully!'),
                     backgroundColor: colorScheme.primary,
                   ),
                 );
               },
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Cancel',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Sound Settings
   void _showSoundSettings() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Sound & Vibration',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             _SoundToggleItem(
               title: 'Sound Effects',
               subtitle: 'Play sounds for actions',
               value: true,
               onChanged: (value) {
                 // TODO: Implement sound toggle
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Sound effects ${value ? 'enabled' : 'disabled'}'),
                     backgroundColor: value ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _SoundToggleItem(
               title: 'Vibration',
               subtitle: 'Haptic feedback',
               value: true,
               onChanged: (value) {
                 // TODO: Implement vibration toggle
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Vibration ${value ? 'enabled' : 'disabled'}'),
                     backgroundColor: value ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _SoundToggleItem(
               title: 'Notification Sounds',
               subtitle: 'Play sounds for notifications',
               value: false,
               onChanged: (value) {
                 // TODO: Implement notification sound toggle
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Notification sounds ${value ? 'enabled' : 'disabled'}'),
                     backgroundColor: value ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                   ),
                 );
               },
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Close',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Data Usage Settings
   void _showDataUsageSettings() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Data Usage',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             _DataUsageItem(
               title: 'Auto-sync',
               subtitle: 'Automatically sync data',
               value: true,
               onChanged: (value) {
                 // TODO: Implement auto-sync toggle
               },
             ),
             const SizedBox(height: 16),
             _DataUsageItem(
               title: 'High Quality Videos',
               subtitle: 'Download HD content',
               value: false,
               onChanged: (value) {
                 // TODO: Implement video quality toggle
               },
             ),
             const SizedBox(height: 16),
             _DataUsageItem(
               title: 'Background Refresh',
               subtitle: 'Update content in background',
               value: true,
               onChanged: (value) {
                 // TODO: Implement background refresh toggle
               },
             ),
             const SizedBox(height: 16),
             _DataUsageItem(
               title: 'Limit Firebase Connections',
               subtitle: 'Prevent too many connection attempts',
               value: _limitFirebaseConnections,
               onChanged: (value) {
                 // Implement Firebase connection limiting
                 setState(() {
                   _limitFirebaseConnections = value;
                 });
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Firebase connection limiting ${value ? 'enabled' : 'disabled'}'),
                     backgroundColor: value ? colorScheme.primary : colorScheme.error,
                   ),
                 );
               },
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Close',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.primary,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Storage Settings
   void _showStorageSettings() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Storage',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             _StorageItem(
               title: 'App Data',
               subtitle: '2.4 GB used',
               trailing: TextButton(
                 onPressed: () {
                   // TODO: Implement clear app data
                 },
                 child: Text(
                   'Clear',
                   style: AppTextStyles.textTheme.labelMedium?.copyWith(
                     color: colorScheme.error,
                   ),
                 ),
               ),
             ),
             const SizedBox(height: 16),
             _StorageItem(
               title: 'Cache',
               subtitle: '156 MB used',
               trailing: TextButton(
                 onPressed: () {
                   // TODO: Implement clear cache
                 },
                 child: Text(
                   'Clear',
                   style: AppTextStyles.textTheme.labelMedium?.copyWith(
                     color: colorScheme.error,
                   ),
                 ),
               ),
             ),
             const SizedBox(height: 16),
             _StorageItem(
               title: 'Downloads',
               subtitle: '89 MB used',
               trailing: TextButton(
                 onPressed: () {
                   // TODO: Implement clear downloads
                 },
                 child: Text(
                   'Clear',
                   style: AppTextStyles.textTheme.labelMedium?.copyWith(
                     color: colorScheme.error,
                   ),
                 ),
               ),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Close',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.primary,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Invite Friends
   void _showInviteFriends() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Invite Friends',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text(
               'Share your fitness journey with friends and family!',
               style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 24),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 _ShareButton(
                   icon: Icons.share,
                   label: 'Share Link',
                   onTap: () {
                     // TODO: Implement share link
                     Navigator.pop(context);
                   },
                 ),
                 _ShareButton(
                   icon: Icons.qr_code,
                   label: 'QR Code',
                   onTap: () {
                     // TODO: Implement QR code
                     Navigator.pop(context);
                   },
                 ),
               ],
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Cancel',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Help Center
   void _showHelpCenter() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Help Center',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             _HelpItem(
               icon: Icons.article,
               title: 'User Guide',
               subtitle: 'Learn how to use the app',
               onTap: () {
                 // TODO: Navigate to user guide
                 Navigator.pop(context);
               },
             ),
             const SizedBox(height: 16),
             _HelpItem(
               icon: Icons.question_answer,
               title: 'FAQ',
               subtitle: 'Frequently asked questions',
               onTap: () {
                 // TODO: Navigate to FAQ
                 Navigator.pop(context);
               },
             ),
             const SizedBox(height: 16),
             _HelpItem(
               icon: Icons.support_agent,
               title: 'Contact Support',
               subtitle: 'Get help from our team',
               onTap: () {
                 // TODO: Navigate to contact support
                 Navigator.pop(context);
               },
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Close',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.primary,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // About Us
   void _showAboutUs() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'About Us',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             CircleAvatar(
               radius: 40,
               backgroundColor: colorScheme.primary,
               child: Icon(
                 Icons.fitness_center,
                 size: 40,
                 color: colorScheme.onPrimary,
               ),
             ),
             const SizedBox(height: 16),
             Text(
               'PathFit',
               style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                 color: colorScheme.onSurface,
                 fontWeight: FontWeight.bold,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               'Empowering fitness education through innovative technology',
               style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 16),
             Text(
               'Version 2.0.1',
               style: AppTextStyles.textTheme.bodySmall?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Close',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.primary,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Privacy Policy
   void _showPrivacyPolicy() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Privacy Policy',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: SingleChildScrollView(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'Your privacy is important to us. This policy explains how we collect, use, and protect your information.',
                 style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                   color: colorScheme.onSurface.withOpacity(0.7),
                 ),
               ),
               const SizedBox(height: 16),
               Text(
                 'Information We Collect:',
                 style: AppTextStyles.textTheme.titleMedium?.copyWith(
                   color: colorScheme.onSurface,
                   fontWeight: FontWeight.w600,
                 ),
               ),
               const SizedBox(height: 8),
               Text(
                 '• Personal information (name, email, profile data)\n• Usage data and preferences\n• Device information and analytics',
                 style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                   color: colorScheme.onSurface.withOpacity(0.7),
                 ),
               ),
               const SizedBox(height: 16),
               Text(
                 'How We Use Your Information:',
                 style: AppTextStyles.textTheme.titleMedium?.copyWith(
                   color: colorScheme.onSurface,
                   fontWeight: FontWeight.w600,
                 ),
               ),
               const SizedBox(height: 8),
               Text(
                 '• Provide personalized fitness content\n• Improve app functionality\n• Send important updates and notifications',
                 style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                   color: colorScheme.onSurface.withOpacity(0.7),
                 ),
               ),
             ],
           ),
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Close',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.primary,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Terms of Service
   void _showTermsOfService() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Terms of Service',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: SingleChildScrollView(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'By using PathFit, you agree to these terms and conditions.',
                 style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                   color: colorScheme.onSurface.withOpacity(0.7),
                 ),
               ),
               const SizedBox(height: 16),
               Text(
                 'Acceptable Use:',
                 style: AppTextStyles.textTheme.titleMedium?.copyWith(
                   color: colorScheme.onSurface,
                   fontWeight: FontWeight.w600,
                 ),
               ),
               const SizedBox(height: 8),
               Text(
                 '• Use the app for personal fitness education\n• Respect intellectual property rights\n• Follow community guidelines',
                 style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                   color: colorScheme.onSurface.withOpacity(0.7),
                 ),
               ),
               const SizedBox(height: 16),
               Text(
                 'Limitations:',
                 style: AppTextStyles.textTheme.titleMedium?.copyWith(
                   color: colorScheme.onSurface,
                   fontWeight: FontWeight.w600,
                 ),
               ),
               const SizedBox(height: 8),
               Text(
                 '• App is for educational purposes only\n• Not a substitute for professional medical advice\n• Use at your own risk',
                 style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                   color: colorScheme.onSurface.withOpacity(0.7),
                 ),
               ),
             ],
           ),
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Close',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.primary,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
     );
   }

   // Privacy & Security Settings
   void _showPrivacySecuritySettings() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Privacy & Security',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             _PrivacyToggleItem(
               title: 'Location Services',
               subtitle: 'Allow app to access location',
               value: true,
               onChanged: (value) {
                 // TODO: Implement location toggle
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Location services ${value ? 'enabled' : 'disabled'}'),
                     backgroundColor: value ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _PrivacyToggleItem(
               title: 'Camera Access',
               subtitle: 'Allow app to use camera',
               value: false,
               onChanged: (value) {
                 // TODO: Implement camera toggle
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Camera access ${value ? 'enabled' : 'disabled'}'),
                     backgroundColor: value ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _PrivacyToggleItem(
               title: 'Microphone Access',
               subtitle: 'Allow app to use microphone',
               value: false,
               onChanged: (value) {
                 // TODO: Implement microphone toggle
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Microphone access ${value ? 'enabled' : 'disabled'}'),
                     backgroundColor: value ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             _PrivacyToggleItem(
               title: 'Data Analytics',
               subtitle: 'Share usage data for improvements',
               value: true,
               onChanged: (value) {
                 // TODO: Implement analytics toggle
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Data analytics ${value ? 'enabled' : 'disabled'}'),
                     backgroundColor: value ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                   ),
                 );
               },
             ),
             const SizedBox(height: 16),
             // Change Password Option
             InkWell(
               onTap: () {
                 Navigator.pop(context);
                 _showChangePasswordDialog();
               },
               borderRadius: BorderRadius.circular(12),
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: colorScheme.primary.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: colorScheme.primary),
                 ),
                 child: Row(
                   children: [
                     Container(
                       width: 40,
                       height: 40,
                       decoration: BoxDecoration(
                         color: colorScheme.primary,
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Icon(
                         Icons.lock_outline,
                         color: colorScheme.onPrimary,
                         size: 20,
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'Change Password',
                             style: AppTextStyles.textTheme.titleMedium?.copyWith(
                               color: colorScheme.primary,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                           const SizedBox(height: 4),
                           Text(
                             'Update your account password',
                             style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                               color: colorScheme.onSurface.withOpacity(0.7),
                             ),
                           ),
                         ],
                       ),
                     ),
                     Icon(
                       Icons.arrow_forward_ios,
                       color: colorScheme.primary,
                       size: 16,
                     ),
                   ],
                 ),
               ),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Close',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Change Password Dialog
   void _showChangePasswordDialog() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     final currentPasswordController = TextEditingController();
     final newPasswordController = TextEditingController();
     final confirmPasswordController = TextEditingController();
     final emailController = TextEditingController();
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Change Password',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text(
               'Enter your current password and new password. A confirmation email will be sent to your registered email address.',
               style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
             const SizedBox(height: 16),
             TextFormField(
               controller: currentPasswordController,
               obscureText: true,
               decoration: InputDecoration(
                 labelText: 'Current Password',
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(8),
                 ),
                 prefixIcon: Icon(Icons.lock, color: colorScheme.onSurface),
               ),
             ),
             const SizedBox(height: 16),
             TextFormField(
               controller: newPasswordController,
               obscureText: true,
               decoration: InputDecoration(
                 labelText: 'New Password',
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(8),
                 ),
                 prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurface),
               ),
             ),
             const SizedBox(height: 16),
             TextFormField(
               controller: confirmPasswordController,
               obscureText: true,
               decoration: InputDecoration(
                 labelText: 'Confirm New Password',
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(8),
                 ),
                 prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurface),
               ),
             ),
             const SizedBox(height: 16),
             TextFormField(
               controller: emailController,
               decoration: InputDecoration(
                 labelText: 'Email for Confirmation',
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(8),
                 ),
                 prefixIcon: Icon(Icons.email, color: colorScheme.onSurface),
               ),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Cancel',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ),
           ElevatedButton(
             onPressed: () {
               // Validate inputs
               if (currentPasswordController.text.isEmpty ||
                   newPasswordController.text.isEmpty ||
                   confirmPasswordController.text.isEmpty ||
                   emailController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Please fill in all fields'),
                     backgroundColor: colorScheme.error,
                   ),
                 );
                 return;
               }
               
               if (newPasswordController.text != confirmPasswordController.text) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('New passwords do not match'),
                     backgroundColor: colorScheme.error,
                   ),
                 );
                 return;
               }
               
               if (newPasswordController.text.length < 8) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Password must be at least 8 characters'),
                     backgroundColor: colorScheme.error,
                   ),
                 );
                 return;
               }
               
               // Close dialog and show confirmation process
               Navigator.pop(context);
               _processPasswordChange(
                 currentPasswordController.text,
                 newPasswordController.text,
                 emailController.text,
               );
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: colorScheme.primary,
               foregroundColor: colorScheme.onPrimary,
             ),
             child: Text(
               'Change Password',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.onPrimary,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   // Process Password Change
   void _processPasswordChange(String currentPassword, String newPassword, String email) {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => AlertDialog(
         title: Text(
           'Changing Password',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             CircularProgressIndicator(
               color: colorScheme.primary,
             ),
             const SizedBox(height: 16),
             Text(
               'Processing password change and sending confirmation email...',
               style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
               textAlign: TextAlign.center,
             ),
           ],
         ),
       ),
     );
     
     // Simulate password change process
     Future.delayed(const Duration(seconds: 3), () {
       Navigator.pop(context);
       
       // Show success dialog
       showDialog(
         context: context,
         builder: (context) => AlertDialog(
           title: Row(
             children: [
               Icon(
                 Icons.check_circle,
                 color: colorScheme.primary,
                 size: 28,
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   'Password Changed Successfully!',
                   style: AppTextStyles.textTheme.titleLarge?.copyWith(
                     color: colorScheme.primary,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
             ],
           ),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'Your password has been updated successfully.',
                 style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                   color: colorScheme.onSurface,
                 ),
               ),
               const SizedBox(height: 16),
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: colorScheme.primary.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: colorScheme.primary),
                 ),
                 child: Row(
                   children: [
                     Icon(
                       Icons.email,
                       color: colorScheme.primary,
                       size: 20,
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Text(
                         'A confirmation email has been sent to $email',
                         style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                           color: colorScheme.primary,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 16),
               Text(
                 'Please check your email and click the confirmation link to complete the process.',
                 style: AppTextStyles.textTheme.bodySmall?.copyWith(
                   color: colorScheme.onSurface.withOpacity(0.7),
                 ),
               ),
             ],
           ),
           actions: [
             ElevatedButton(
               onPressed: () => Navigator.pop(context),
               style: ElevatedButton.styleFrom(
                 backgroundColor: colorScheme.primary,
                 foregroundColor: colorScheme.onPrimary,
               ),
               child: Text(
                 'OK',
                 style: AppTextStyles.textTheme.titleMedium?.copyWith(
                   color: colorScheme.onPrimary,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ),
           ],
         ),
       );
       
       // Show success snackbar
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Password changed successfully! Check your email for confirmation.'),
           backgroundColor: colorScheme.primary,
           duration: const Duration(seconds: 5),
         ),
       );
     });
   }
   
   // Data Export
   void _exportData() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Export Data',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text(
               'Choose what data you want to export:',
               style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
             const SizedBox(height: 16),
             _ExportOption(
               icon: Icons.person,
               title: 'Profile Data',
               subtitle: 'Personal information and preferences',
               onTap: () => _showExportProgress(context, 'Profile Data'),
             ),
             const SizedBox(height: 16),
             _ExportOption(
               icon: Icons.trending_up,
               title: 'Learning Progress',
               subtitle: 'Learning activities and achievements',
               onTap: () => _showExportProgress(context, 'Learning Progress'),
             ),
             const SizedBox(height: 16),
             _ExportOption(
               icon: Icons.data_usage,
               title: 'All Data',
               subtitle: 'Complete app data export',
               onTap: () => _showExportProgress(context, 'All Data'),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Cancel',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ),
         ],
       ),
     );
   }
   
   void _showExportProgress(BuildContext context, String dataType) {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => AlertDialog(
         title: Text(
           'Exporting $dataType',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             CircularProgressIndicator(
               color: colorScheme.primary,
             ),
             const SizedBox(height: 16),
             Text(
               'Preparing your data for export...',
               style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ],
         ),
       ),
     );
     
     // Simulate export process
     Future.delayed(const Duration(seconds: 2), () {
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('$dataType exported successfully!'),
           backgroundColor: colorScheme.primary,
         ),
       );
     });
   }
  
  // Account Deletion functionality removed - accounts are automatically deleted after 10 minutes if unverified
  // void _deleteAccount() {
  //   final themeProvider = context.read<ThemeProvider>();
  //   final colorScheme = themeProvider.colorScheme;
  //   
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Row(
  //         children: [
  //           Icon(
  //             Icons.warning,
  //             color: colorScheme.error,
  //             size: 28,
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: Text(
  //               'Delete Account',
  //               style: AppTextStyles.textTheme.titleLarge?.copyWith(
  //                 color: colorScheme.error,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Are you sure you want to delete your account?',
  //             style: AppTextStyles.textTheme.bodyMedium?.copyWith(
  //               color: colorScheme.onSurface,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             'This action cannot be undone. All your data, progress, and settings will be permanently deleted.',
  //             style: AppTextStyles.textTheme.bodyMedium?.copyWith(
  //               color: colorScheme.error,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           Container(
  //             padding: const EdgeInsets.all(16),
  //             decoration: BoxDecoration(
  //               color: colorScheme.error.withOpacity(0.1),
  //               borderRadius: BorderRadius.circular(12),
  //               border: Border.all(color: colorScheme.error),
  //             ),
  //             child: Row(
  //               children: [
  //                 Icon(
  //                   Icons.info_outline,
  //                   color: colorScheme.error,
  //                   size: 20,
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Text(
  //                     'Please export your data before deleting your account if you want to keep any information.',
  //                     style: AppTextStyles.textTheme.bodySmall?.copyWith(
  //                       color: colorScheme.error,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text(
  //             'Cancel',
  //             style: AppTextStyles.textTheme.titleMedium?.copyWith(
  //               color: colorScheme.onSurface.withOpacity(0.7),
  //             ),
  //           ),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             _confirmAccountDeletion();
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: colorScheme.error,
  //             foregroundColor: colorScheme.onError,
  //           ),
  //           child: Text(
  //             'Delete Account',
  //             style: AppTextStyles.textTheme.titleMedium?.copyWith(
  //               color: colorScheme.onError,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // 
  // void _confirmAccountDeletion() {
  //   final themeProvider = context.read<ThemeProvider>();
  //   final colorScheme = themeProvider.colorScheme;
  //   
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Row(
  //         children: [
  //           Icon(
  //             Icons.delete_forever,
  //             color: colorScheme.error,
  //             size: 28,
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: Text(
  //               'Final Confirmation',
  //               style: AppTextStyles.textTheme.titleLarge?.copyWith(
  //                 color: colorScheme.error,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'This is your final warning. Your account will be permanently deleted.',
  //             style: AppTextStyles.textTheme.bodyMedium?.copyWith(
  //               color: colorScheme.onSurface,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             'Type "DELETE" to confirm:',
  //             style: AppTextStyles.textTheme.bodyMedium?.copyWith(
  //               color: colorScheme.onSurface.withOpacity(0.7),
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           TextField(
  //             decoration: InputDecoration(
  //               hintText: 'Type DELETE here',
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //             ),
  //             onChanged: (value) {
  //               if (value == 'DELETE') {
  //                 Navigator.pop(context);
  //                 _processAccountDeletion();
  //               }
  //             },
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text(
  //             'Cancel',
  //             style: AppTextStyles.textTheme.titleMedium?.copyWith(
  //               color: colorScheme.onSurface.withOpacity(0.7),
  //             ),
  //           ),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             _processAccountDeletion();
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: colorScheme.error,
  //             foregroundColor: colorScheme.onError,
  //           ),
  //           child: Text(
  //             'Delete Forever',
  //             style: AppTextStyles.textTheme.titleMedium?.copyWith(
  //               color: colorScheme.onError,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // 
  // Future<void> _processAccountDeletion() async {
  //  final themeProvider = context.read<ThemeProvider>();
  //  final colorScheme = themeProvider.colorScheme;
  //  
  //  showDialog(
  //    context: context,
  //    barrierDismissible: false,
  //    builder: (context) => AlertDialog(
  //      title: Text(
  //        'Deleting Account',
  //        style: AppTextStyles.textTheme.titleLarge?.copyWith(
  //          color: colorScheme.error,
  //          fontWeight: FontWeight.bold,
  //        ),
  //      ),
  //      content: Column(
  //        mainAxisSize: MainAxisSize.min,
  //        children: [
  //          CircularProgressIndicator(
  //            color: colorScheme.error,
  //          ),
  //          const SizedBox(height: 16),
  //          Text(
  //            'Processing account deletion...',
  //            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
  //              color: colorScheme.onSurface.withOpacity(0.7),
  //            ),
  //          ),
  //        ],
  //      ),
  //    ),
  //  );
  //  
  //  try {
  //    // Use the enhanced account deletion functionality
  //    final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //    final success = await authProvider.deleteAccount();
  //    
  //    // Close the progress dialog
  //    if (mounted) Navigator.pop(context);
  //    
  //    if (success) {
  //      if (mounted) {
  //        ScaffoldMessenger.of(context).showSnackBar(
  //          SnackBar(
  //            content: Text('Your account has been permanently deleted'),
  //            backgroundColor: colorScheme.error,
  //            duration: Duration(seconds: 3),
  //          ),
  //        );
  //        
  //        // Navigate directly to login screen with a hard reload effect
  //        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  //      }
  //    } else {
  //      if (mounted) {
  //        ScaffoldMessenger.of(context).showSnackBar(
  //          SnackBar(
  //            content: Text('Failed to delete account. Please try again.'),
  //            backgroundColor: colorScheme.error,
  //            duration: Duration(seconds: 3),
  //          ),
  //        );
  //      }
  //    }
  //  } catch (e) {
  //    // Close the progress dialog
  //    if (mounted) Navigator.pop(context);
  //    
  //    if (mounted) {
  //      ScaffoldMessenger.of(context).showSnackBar(
  //        SnackBar(
  //          content: Text('Error: ${e.toString()}'),
  //          backgroundColor: colorScheme.error,
  //          duration: Duration(seconds: 3),
  //        ),
  //      );
  //    }
  //  }
  // }
   
   // Theme Debug Info
   void _showThemeDebugInfo() {
     final themeProvider = context.read<ThemeProvider>();
     final colorScheme = themeProvider.colorScheme;
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text(
           'Theme Debug Info',
           style: AppTextStyles.textTheme.titleLarge?.copyWith(
             color: colorScheme.onSurface,
             fontWeight: FontWeight.bold,
           ),
         ),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               'Current Theme Mode: ${themeProvider.currentThemeMode.name}',
               style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                 color: colorScheme.onSurface,
                 fontWeight: FontWeight.w600,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               'Is Dark Mode: ${themeProvider.isDarkMode}',
               style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                 color: colorScheme.onSurface,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               'Is Initialized: ${themeProvider.isInitialized}',
               style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                 color: colorScheme.onSurface,
               ),
             ),
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: colorScheme.primary.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: colorScheme.primary),
               ),
               child: Text(
                 'Theme Provider Status: ${themeProvider.isInitialized ? "Ready" : "Initializing..."}',
                 style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                   color: colorScheme.primary,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text(
               'Close',
               style: AppTextStyles.textTheme.titleMedium?.copyWith(
                 color: colorScheme.onSurface.withOpacity(0.7),
               ),
             ),
           ),
         ],
       ),
     );
   }
}

// Custom Widgets for Settings Dialogs



class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Text(
                flag,
                style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SoundToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SoundToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colorScheme.primary,
        ),
      ],
    );
  }
}

class _DataUsageItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DataUsageItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colorScheme.primary,
        ),
      ],
    );
  }
}

class _StorageItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _StorageItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: AppTextStyles.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Section Items
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  item,
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: colorScheme.outline,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
                         // Icon
             Container(
               width: 40,
               height: 40,
               decoration: BoxDecoration(
                 color: isLogout || isDestructive 
                     ? colorScheme.error.withOpacity(0.1)
                     : colorScheme.primary.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Icon(
                 icon,
                 color: isLogout || isDestructive ? colorScheme.error : colorScheme.primary,
                 size: 20,
               ),
             ),
            
            const SizedBox(width: 16),
            
            // Title
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: isLogout || isDestructive ? colorScheme.error : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacyToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colorScheme.primary,
        ),
      ],
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
