import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'choose_artists_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Privacy Policy')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential;
      try {
        // 1. Create User in Firebase
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // 2. Send Verification Email
        await userCredential.user?.sendEmailVerification();

        setState(() {
          _isLoading = false;
        });

        // 3. Show Verification Dialog
        if (!mounted) return;
        _showVerificationDialog();
        return; // wait for dialog
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Attempt to login instead
          userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          if (userCredential.user != null && !userCredential.user!.emailVerified) {
             // Resend verification email and show dialog
             await userCredential.user?.sendEmailVerification();
             setState(() {
               _isLoading = false;
             });
             if (!mounted) return;
             _showVerificationDialog();
             return; // wait for dialog
          } else {
             // They are verified and logged in!
             _registerWithBackend();
             return;
          }
        } else {
          rethrow; // let outer catch handle it
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isChecking = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2D36),
              title: const Text('Verify Your Email', style: TextStyle(color: Colors.white)),
              content: const Text(
                'A verification link has been sent to your email address. Please check your inbox and click the link to verify. Then click the button below.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
                  onPressed: isChecking ? null : () async {
                    setDialogState(() => isChecking = true);
                    
                    User? user = FirebaseAuth.instance.currentUser;
                    await user?.reload();
                    user = FirebaseAuth.instance.currentUser;

                    if (user != null && user.emailVerified) {
                      Navigator.pop(context);
                      _registerWithBackend();
                    } else {
                      setDialogState(() => isChecking = false);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email not verified yet. Please check your inbox or spam folder.')),
                      );
                    }
                  },
                  child: isChecking 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('I\'ve Verified', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _registerWithBackend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://music-app-api-1.onrender.com/api/checkRegister'),
        body: {
          "grant_type": "password",
          "client_id": "saalai_app",
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
          "userMobile": _emailController.text.trim(),
          "deviceID": "a43c5951b27652d123",
          "mobileType": "A",
          "deviceToken": "your_device_token_here",
          "name": _nameController.text,
          "referalCode": _referralController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          // Success
          final prefs = await SharedPreferences.getInstance();
          if (data['response'] != null && data['response']['access_token'] != null) {
            await prefs.setString('access_token', data['response']['access_token']);
          }
          await prefs.setString('userEmail', _emailController.text.trim());
          await prefs.setString('userName', _nameController.text);
          
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChooseArtistsScreen()));
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Registration failed: ${response.body}')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error ${response.statusCode}: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20), // darkGray
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0), // padding 10dp
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50), // layout_marginTop 50dp
              // Logo
              Container(
                width: 350,
                height: 150,
                padding: const EdgeInsets.all(20.0), // padding 20dp
                child: Image.asset(
                  'assets/images/arivumusiclogo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0), // 350dp width container in Android
                child: Column(
                  children: [
                    _buildTextField('Name', _nameController),
                    const SizedBox(height: 20),

                    _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),

                    _buildPasswordField(),
                    const SizedBox(height: 20),

                    _buildTextField('Referral Code (optional)', _referralController),
                    const SizedBox(height: 20),

                    // Checkbox and Terms
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (val) {
                              setState(() {
                                _agreedToTerms = val ?? false;
                              });
                            },
                            activeColor: const Color(0xFFEB1C24),
                            checkColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF828993)),
                          ),
                        ),
                        const SizedBox(width: 5), // marginLeft 5dp
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2.0), // rough padding adjustment
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Color(0xFF828993), // gray1
                                  fontSize: 13, // 13sp
                                  height: 1.3, // lineSpacingExtra 4dp
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  const TextSpan(text: 'By signing in, you are agreeing to our '),
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: const TextStyle(color: Color(0xFF828993), fontWeight: FontWeight.bold),
                                    recognizer: TapGestureRecognizer()..onTap = () {},
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(color: Color(0xFF828993), fontWeight: FontWeight.bold),
                                    recognizer: TapGestureRecognizer()..onTap = () {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    InkWell(
                      onTap: _isLoading ? null : _submit,
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: double.infinity,
                        height: 45, // 45dp
                        decoration: BoxDecoration(
                          color: const Color(0xFFEB1C24), // @drawable/onboardbtnbg
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _isLoading 
                            ? const [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              ]
                            : const [
                                Text(
                                  'Submit',
                                  style: TextStyle(
                                    fontSize: 24, // 24sp
                                    fontWeight: FontWeight.w500, // circularstdmedium
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF828993)), // gray1
        filled: true,
        fillColor: const Color(0xFF1F222A), // lightGray
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(13.0), // padding 13dp
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: const TextStyle(color: Color(0xFF828993)),
        filled: true,
        fillColor: const Color(0xFF1F222A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(13.0),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF828993),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }
}
