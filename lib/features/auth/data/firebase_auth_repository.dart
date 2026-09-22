import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_exception.dart';
import '../domain/auth_repository.dart';
import 'auth_error_mapper.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<void> cadastrar({required String email, required String senha}) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final uid = credencial.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      try {
        await credencial.user!.sendEmailVerification();
      } catch (_) {
        // Falha no envio do e-mail de verificação não bloqueia o cadastro (UC01).
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapearErroAutenticacao(e));
    }
  }

  @override
  Future<void> entrar({required String email, required String senha}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapearErroAutenticacao(e));
    }
  }

  @override
  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Nunca revela se a conta existe: mesma resposta (sucesso silencioso).
      if (e.code == 'user-not-found' || e.code == 'invalid-email') return;
      throw AuthException(mapearErroAutenticacao(e));
    }
  }
}
