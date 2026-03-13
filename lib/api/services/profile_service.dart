// lib/api/services/profile_service.dart
// ✅ UPLOAD TO FIREBASE FIRST, THEN SEND URL TO API

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final String baseUrl = 'https://anugami.com/api/v1';

  // 🔐 Ensure Firebase login (Anonymous)
  Future<void> _ensureFirebaseLogin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("🔐 Signing in anonymously to Firebase...");
      await FirebaseAuth.instance.signInAnonymously();
      print("✅ Firebase anonymous login success");
    } else {
      print("✅ Firebase user already signed in");
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/customers/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ✅ Update Profile With Firebase Image Upload
  Future<Map<String, dynamic>> updateUserProfileWithImage(
      Map<String, dynamic> profileData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found',
        };
      }

      // Upload image if present
      if (profileData.containsKey('profile_picture') &&
          profileData['profile_picture'] is File) {
        final File imageFile = profileData['profile_picture'];
        final imageUrl = await _uploadImageToFirebase(imageFile);

        if (imageUrl == null) {
          return {
            'success': false,
            'message': 'Failed to upload image',
          };
        }

        profileData['profile_picture'] = imageUrl;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/customers/profile/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(profileData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Profile updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Update failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ✅ Upload image to Firebase Storage (FIXED)
  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      // 🔐 Ensure Firebase login
      await _ensureFirebaseLogin();

      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        print('❌ Firebase login failed');
        return null;
      }

      final uid = firebaseUser.uid;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(imageFile.path);
      final filename = 'profile_$timestamp$ext';

      print('📤 Uploading to Firebase: profile_pictures/$uid/$filename');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(uid)
          .child(filename);

      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: _getMimeType(ext),
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ Firebase upload complete: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Firebase upload error: $e');
      return null;
    }
  }

  // MIME type helper
  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Get saved auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
