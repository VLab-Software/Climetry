import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Serviço de autenticação com Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream de estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuário atual
  User? get currentUser => _auth.currentUser;

  // Verificar se está autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  /// Cadastro com email e senha
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Atualizar nome do usuário
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Login com Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('Login cancelado pelo usuário');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Erro ao fazer login com Google: $e');
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw AuthException('Erro ao fazer logout: $e');
    }
  }

  /// Recuperar senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Atualizar nome do usuário
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.reload();
    } catch (e) {
      throw AuthException('Erro ao atualizar nome: $e');
    }
  }

  /// Atualizar email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Atualizar senha
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Reautenticar com email e senha (necessário para operações sensíveis)
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw AuthException('Usuário não autenticado');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Deletar conta
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Enviar email de verificação
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Tratamento de exceções do Firebase Auth
  AuthException _handleAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'weak-password':
        message = 'A senha é muito fraca. Use pelo menos 6 caracteres.';
        break;
      case 'email-already-in-use':
        message = 'Este email já está em uso por outra conta.';
        break;
      case 'invalid-email':
        message = 'Email inválido.';
        break;
      case 'operation-not-allowed':
        message = 'Operação não permitida.';
        break;
      case 'user-disabled':
        message = 'Esta conta foi desativada.';
        break;
      case 'user-not-found':
        message = 'Usuário não encontrado.';
        break;
      case 'wrong-password':
        message = 'Senha incorreta.';
        break;
      case 'invalid-credential':
        message = 'Credenciais inválidas.';
        break;
      case 'too-many-requests':
        message = 'Muitas tentativas. Tente novamente mais tarde.';
        break;
      case 'requires-recent-login':
        message =
            'Esta operação requer autenticação recente. Faça login novamente.';
        break;
      case 'network-request-failed':
        message = 'Erro de conexão. Verifique sua internet.';
        break;
      default:
        message = 'Erro de autenticação: ${e.message ?? e.code}';
    }

    return AuthException(message, code: e.code);
  }
}

/// Exceção customizada para autenticação
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}
