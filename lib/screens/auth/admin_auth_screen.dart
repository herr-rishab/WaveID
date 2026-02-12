import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/gradient_background.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  static const String _adminInviteCode = 'PRESENTSIR_ADMIN_2026';

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupConfirmController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;
  bool _showSignupPassword = false;
  bool _showSignupConfirm = false;
  int _modeIndex = 0;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (error) {
      setState(() {
        _error = 'Admin login failed. Check your credentials.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (_inviteController.text.trim() != _adminInviteCode) {
      setState(() {
        _loading = false;
        _error = 'Invalid admin access code.';
      });
      return;
    }

    if (_signupPasswordController.text.trim() != _signupConfirmController.text.trim()) {
      setState(() {
        _loading = false;
        _error = 'Passwords do not match.';
      });
      return;
    }

    try {
      final credential = await _authService.register(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text.trim(),
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Unable to create admin account.');
      }
      await _userService.createAdminUser(
        uid: user.uid,
        name: _nameController.text.trim(),
        adminCode: _inviteController.text.trim(),
      );
    } on FirebaseAuthException catch (error) {
      setState(() {
        _error = error.message ?? 'Admin signup failed. Check email/password.';
      });
    } on FirebaseException catch (error) {
      setState(() {
        _error = error.message ?? 'Admin signup failed. Check Firestore rules.';
      });
    } catch (error) {
      setState(() {
        _error = 'Admin signup failed. ${error.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Admin Access',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage placement drives and attendance.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<int>(
                        segments: const <ButtonSegment<int>>[
                          ButtonSegment<int>(value: 0, label: Text('Sign in')),
                          ButtonSegment<int>(value: 1, label: Text('Sign up')),
                        ],
                        selected: <int>{_modeIndex},
                        onSelectionChanged: (Set<int> selection) {
                          setState(() {
                            _modeIndex = selection.first;
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _modeIndex == 0 ? _buildSignIn(context) : _buildSignUp(context),
                      ),
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignIn(BuildContext context) {
    return Column(
      key: const ValueKey('signin'),
      children: <Widget>[
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Admin Email',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _signIn,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sign in as admin'),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUp(BuildContext context) {
    return Column(
      key: const ValueKey('signup'),
      children: <Widget>[
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Admin Email',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _signupPasswordController,
          obscureText: !_showSignupPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_showSignupPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showSignupPassword = !_showSignupPassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _signupConfirmController,
          obscureText: !_showSignupConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_showSignupConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showSignupConfirm = !_showSignupConfirm),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _inviteController,
          decoration: const InputDecoration(
            labelText: 'Admin Access Code',
            prefixIcon: Icon(Icons.security),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _signUp,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create admin account'),
          ),
        ),
      ],
    );
  }
}
