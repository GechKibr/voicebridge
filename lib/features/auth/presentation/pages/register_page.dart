import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/services/microsoft_auth_service.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  final MicrosoftIdentity? initialIdentity;

  const RegisterPage({super.key, this.initialIdentity});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _gmailAccountController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  MicrosoftIdentity? _microsoftIdentity;
  bool _microsoftVerified = false;

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9._-]{3,32}$');
  static final RegExp _digitsOnlyRegex = RegExp(r'^[0-9]{8,15}$');

  @override
  void initState() {
    super.initState();
    final identity = widget.initialIdentity;
    if (identity != null) {
      _applyMicrosoftIdentity(identity);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _gmailAccountController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _applyMicrosoftIdentity(MicrosoftIdentity identity) {
    _microsoftIdentity = identity;
    _microsoftVerified = true;
    _emailController.text = identity.email;
    _gmailAccountController.text = identity.email;
    _usernameController.text = identity.suggestedUsername;
    _firstNameController.text = identity.firstName;
    _lastNameController.text = identity.lastName;
  }

  Future<void> _handleMicrosoftRegister(BuildContext context) async {
    final authController = context.read<AuthController>();
    final identity = await authController.registerWithMicrosoft();

    if (!context.mounted) return;

    if (identity != null) {
      setState(() {
        _applyMicrosoftIdentity(identity);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microsoft account verified. Complete the form to finish registration.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authController.errorMessage ?? 'Microsoft verification failed',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_microsoftVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please verify with Microsoft before creating your account.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepOrange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = context.read<AuthController>();
    final success = await authController.register(
      email: _emailController.text.trim(),
      gmailAccount: _gmailAccountController.text.trim(),
      username: _usernameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authController.errorMessage ?? 'Registration failed'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Consumer<AuthController>(
            builder: (context, auth, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verify with Microsoft first, then complete your account details.',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading
                          ? null
                          : () => _handleMicrosoftRegister(context),
                      icon: const Icon(Icons.business, color: Colors.black87),
                      label: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Verify with Microsoft',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_microsoftIdentity != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Microsoft account linked',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(_microsoftIdentity!.email),
                          ],
                        ),
                      ),
                    if (_microsoftIdentity == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Text(
                          'Step 1: Verify with Microsoft.\nStep 2: Complete and submit your registration details.',
                          style: TextStyle(height: 1.35),
                        ),
                      ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      readOnly: _microsoftVerified,
                      helperText: _microsoftVerified
                          ? 'Locked to your verified Microsoft email.'
                          : null,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        if (!_emailRegex.hasMatch(value.trim())) {
                          return 'Enter a valid email';
                        }
                        if (_microsoftVerified && _microsoftIdentity != null) {
                          if (value.trim().toLowerCase() !=
                              _microsoftIdentity!.email.toLowerCase()) {
                            return 'Email must match your Microsoft account';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _gmailAccountController,
                      label: 'Gmail Account',
                      prefixIcon: Icons.alternate_email,
                      readOnly: _microsoftVerified,
                      helperText: _microsoftVerified
                          ? 'Auto-filled from verified Microsoft account.'
                          : null,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter gmail account';
                        }
                        if (!_emailRegex.hasMatch(value.trim())) {
                          return 'Enter a valid account email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Username',
                      prefixIcon: Icons.person_outline,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9._-]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter username';
                        }
                        if (!_usernameRegex.hasMatch(value.trim())) {
                          return '3-32 chars: letters, numbers, dot, underscore, hyphen';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            prefixIcon: Icons.badge_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            prefixIcon: Icons.badge_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      helperText: 'Use digits only (8-15 numbers)',
                      validator: (value) {
                        final cleaned = value?.trim() ?? '';
                        if (cleaned.isEmpty) {
                          return 'Please enter phone';
                        }
                        if (!_digitsOnlyRegex.hasMatch(cleaned)) {
                          return 'Phone must be 8-15 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      prefixIcon: Icons.lock_reset_outlined,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: _microsoftVerified
                          ? 'Create Account'
                          : 'Verify Microsoft To Continue',
                      isLoading: auth.isLoading,
                      isEnabled: _microsoftVerified,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
