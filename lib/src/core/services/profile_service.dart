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

  /// Selecionar imagem da galeria
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
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  /// Selecionar imagem da câmera
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
      throw Exception('Erro ao tirar foto: $e');
    }
  }

  /// Upload da foto de perfil para Firebase Storage
  Future<String> uploadProfilePhoto(XFile image) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final file = File(image.path);
      
      // Criar referência com caminho completo
      final storageRef = _storage.ref();
      final profilePhotoRef = storageRef.child('profile_photos/${user.uid}.jpg');

      // Metadata para o arquivo
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload com metadata
      final uploadTask = await profilePhotoRef.putFile(file, metadata);

      // Obter URL de download
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Atualizar no Firebase Auth
      await user.updatePhotoURL(downloadUrl);

      // Atualizar no Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      print('❌ Erro detalhado no upload: $e');
      throw Exception('Erro ao fazer upload da foto: $e');
    }
  }

  /// Atualizar nome do usuário
  Future<void> updateDisplayName(String newName) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Validar nome
      if (newName.trim().isEmpty) {
        throw Exception('Nome não pode ser vazio');
      }

      if (newName.trim().length < 3) {
        throw Exception('Nome deve ter pelo menos 3 caracteres');
      }

      // Atualizar no Firebase Auth
      await user.updateDisplayName(newName.trim());

      // Atualizar no Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': newName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Recarregar usuário
      await user.reload();
    } catch (e) {
      throw Exception('Erro ao atualizar nome: $e');
    }
  }

  /// Atualizar email do usuário (requer reautenticação)
  Future<void> updateEmail(String newEmail, String currentPassword) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Validar email
      if (newEmail.trim().isEmpty) {
        throw Exception('Email não pode ser vazio');
      }

      if (!newEmail.contains('@')) {
        throw Exception('Email inválido');
      }

      // Reautenticar
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Atualizar email
      await user.verifyBeforeUpdateEmail(newEmail.trim());

      // Atualizar no Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': newEmail.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Recarregar usuário
      await user.reload();
    } catch (e) {
      throw Exception('Erro ao atualizar email: $e');
    }
  }

  /// Obter dados do perfil do Firestore
  Future<Map<String, dynamic>?> getProfileData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ Timeout ao obter dados do perfil');
          return _firestore.collection('_timeout_').doc('_default_').get();
        },
      );
      return doc.data();
    } catch (e) {
      print('⚠️ Erro ao obter perfil: $e');
      return null;
    }
  }

  /// Deletar foto de perfil
  Future<void> deleteProfilePhoto() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Deletar do Storage
      try {
        final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
        await ref.delete();
      } catch (e) {
        // Ignorar se não existir
      }

      // Atualizar no Firebase Auth
      await user.updatePhotoURL(null);

      // Atualizar no Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Recarregar usuário
      await user.reload();
    } catch (e) {
      throw Exception('Erro ao deletar foto: $e');
    }
  }
}
