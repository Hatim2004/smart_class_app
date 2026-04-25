import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 // --- STRICT EMAIL LOGIN (NO REGISTRATION) ---
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Attempt to log in. This will throw an error if the account doesn't exist.
      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Verify they actually have a profile in your database
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // They have an Auth account, but no database profile. Kick them out.
        await FirebaseAuth.instance.signOut();
        _showError('حسابك غير مسجل في قاعدة البيانات. تواصل مع الإدارة.');
        setState(() => _isLoading = false);
        return;
      }

      await _routeUser(credential.user!.uid);

    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showError('حدث خطأ في الاتصال بقاعدة البيانات');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- STRICT GOOGLE SIGN IN (NO REGISTRATION) ---
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      // 1. Firebase automatically signs them in (and creates an Auth account if new)
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // 2. Check if this user actually exists in your Firestore database
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // 3. If they don't exist, destroy the session and delete the unauthorized account
      if (!userDoc.exists) {
        await userCredential.user!.delete(); // Deletes the auto-generated Firebase Auth account
        await GoogleSignIn.instance.signOut(); // Clears the Google cache on the phone
        
        _showError('عذراً، هذا البريد الإلكتروني غير مصرح له بالدخول.');
        setState(() => _isLoading = false);
        return;
      }

      // 4. If they do exist, route them normally
      await _routeUser(userCredential.user!.uid);

    } catch (e) {
      _showError('حدث خطأ أثناء التحقق من حساب Google');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // --- SHARED ROUTING LOGIC ---
  Future<void> _routeUser(String uid) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) {
      _showError('بيانات المستخدم غير موجودة في قاعدة البيانات');
      await FirebaseAuth.instance.signOut();
      return;
    }

    // Extract the data safely
    final data = userDoc.data() as Map<String, dynamic>;
    String roleString = data['role'] ?? 'student';
    UserRole role = roleString == 'teacher'
        ? UserRole.teacher
        : UserRole.student;

    // Safely extract the name, falling back to a default if the field is missing
    String userName = data.containsKey('name') ? data['name'] : 'مستخدم';

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            role: role,
            userName: userName, // Pass the new variable here
          ),
        ),
      );
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage = 'حدث خطأ أثناء تسجيل الدخول';
    _showError('System Error: ${e.code}');
    if (e.code == 'user-not-found' ||
        e.code == 'wrong-password' ||
        e.code == 'invalid-credential') {
      errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'صيغة البريد الإلكتروني غير صحيحة';
    }
    _showError(errorMessage);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.recording),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleEmailLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'تسجيل الدخول بالبريد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.textSecondary,
                      thickness: 0.5,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'أو',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.textSecondary,
                      thickness: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(
                  Icons.g_mobiledata,
                  size: 28,
                  color: Colors.blue,
                ), // Placeholder for Google icon
                label: const Text(
                  'تسجيل باستخدام Google',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
