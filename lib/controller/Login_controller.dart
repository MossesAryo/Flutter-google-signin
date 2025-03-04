import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:new_firebase/screens/main_screen.dart';

class LoginController {
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        var db = FirebaseFirestore.instance;
        var userRef = db.collection("users").doc(user.uid);
        var docSnapshot = await userRef.get();

        if (!docSnapshot.exists) {
          // Jika user baru, minta input NIS dan Name
          _showNisNameDialog(context, user.uid, user.email ?? "");
        } else {
          // Jika user sudah ada, langsung masuk ke MainScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error signing in with Google: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> signIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      email = email.trim();
      password = password.trim();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(),
        ), // Mengganti SplashScreen() dengan MainScreen()
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed. Please try again.";

      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is not valid.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static void _showNisNameDialog(
    BuildContext context,
    String userId,
    String email,
  ) {
    TextEditingController nameController = TextEditingController();
    TextEditingController nisController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Lengkapi Profilmu"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Nama Lengkap"),
              ),
              TextField(
                controller: nisController,
                decoration: InputDecoration(labelText: "NIS"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String name = nameController.text.trim();
                String nis = nisController.text.trim();

                if (name.isNotEmpty && nis.isNotEmpty) {
                  var db = FirebaseFirestore.instance;

                  Map<String, dynamic> data = {
                    "name": name,
                    "nis": nis,
                    "email": email,
                    "id": userId,
                  };

                  await db.collection("users").doc(userId).set(data);

                  Navigator.pop(context); // Tutup dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Please fill in all fields"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
