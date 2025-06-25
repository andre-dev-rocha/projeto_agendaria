// lib/app/core/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService(this._firebaseAuth);

  // Stream para ouvir o estado da autenticação (logado ou não)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Método para fazer Login
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      // Retorna o código do erro para ser tratado na UI
      return e.code;
    }
  }

  Future<String?> signUp({
    required String name, // Novo parâmetro
    required String email,
    required String password,
    required String role, // Novo parâmetro
  }) async {
    try {
      // 1. Criar usuário no Firebase Authentication
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = userCredential.user;

      if (newUser != null) {
        // 2. Criar documento no Firestore
        await _firestore.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'name': name,
          'email': email,
          'role': role, // 'client' ou 'employee'
          'createdAt': Timestamp.now(),
        });
      }

      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      return e.toString();
    }
  }

  // Método para fazer Logout
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}