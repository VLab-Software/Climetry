import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? get currentUser => _auth.currentUser;

  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Error ao selecionar imagem: $e');
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Error ao tirar foto: $e');
    }
  }

  Future<String> uploadProfilePhoto(XFile image) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final file = File(image.path);
      
      final storageRef = _storage.ref();
      final profilePhotoRef = storageRef.child('profile_photos/${user.uid}.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = await profilePhotoRef.putFile(file, metadata);

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);

      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      print('❌ Error detalhado no upload: $e');
      throw Exception('Error ao fazer upload da foto: $e');
    }
  }

  Future<void> updateDisplayName(String newName) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (newName.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      if (newName.trim().length < 3) {
        throw Exception('Nome deve ter pelo menos 3 caracteres');
      }

      await user.updateDisplayName(newName.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'displayName': newName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.reload();
    } catch (e) {
      throw Exception('Error ao atualizar nome: $e');
    }
  }

  Future<void> updateEmail(String newEmail, String currentPassword) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (newEmail.trim().isEmpty) {
        throw Exception('Email cannot be empty');
      }

      if (!newEmail.contains('@')) {
        throw Exception('Email inválido');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      await user.verifyBeforeUpdateEmail(newEmail.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'email': newEmail.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.reload();
    } catch (e) {
      throw Exception('Error ao atualizar email: $e');
    }
  }

  Future<Map<String, dynamic>?> getProfileDate() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ Timeout obtaining data do perfil');
          return _firestore.collection('_timeout_').doc('_default_').get();
        },
      );
      return doc.data();
    } catch (e) {
      print('⚠️ Error obtaining perfil: $e');
      return null;
    }
  }

  Future<void> deleteProfilePhoto() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      try {
        final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
        await ref.delete();
      } catch (e) {
      }

      await user.updatePhotoURL(null);

      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.reload();
    } catch (e) {
      throw Exception('Error ao deletar foto: $e');
    }
  }
}
