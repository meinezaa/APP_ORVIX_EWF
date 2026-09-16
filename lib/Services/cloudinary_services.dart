import 'dart:io';
import 'dart:developer' as developer;

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudinaryService {
  // Ganti dengan Cloud Name dan Upload Preset Anda
  static final _cloudinary = CloudinaryPublic(
    'vawznvjf',
    'fotoProfil_ORVIX',
    cache: false,
  );

  static Future<String?> uploadProfileImage(File imageFile) async {
    try {
      // 1. Unggah berkas fisik ke Cloudinary
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'orvix_profiles', // Nama folder di Cloudinary
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      String imageUrl = response.secureUrl;

      // 2. Simpan URL foto ke dokumen user di Firestore
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'foto_profil_path': imageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      return imageUrl;
    } catch (e) {
      developer.log(
        'Error uploading to Cloudinary: $e',
        name: 'CloudinaryService',
      );
      return null;
    }
  }
}
