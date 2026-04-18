import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isVerifying = false;
  String? _localError;
  bool _otpStepEnabled = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(AppController controller) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      setState(() {
        _localError = phone.isEmpty
            ? 'Phone number is required.'
            : 'Use international format (+92...)';
      });
      return;
    }
    setState(() {
      _isSendingOtp = true;
      _localError = null;
    });
    await controller.sendOtp(phone);
    if (!mounted) {
      return;
    }
    setState(() {
      _isSendingOtp = false;
      _localError = controller.errorMessage;
      _otpStepEnabled = controller.errorMessage == null;
    });
  }

  Future<void> _verifyOtp(AppController controller) async {
    if (!_otpStepEnabled) {
      setState(() {
        _localError = 'Request OTP first.';
      });
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isVerifying = true;
      _localError = null;
    });
    await controller.verifyOtp(
      otpCode: _otpController.text.trim(),
      fullName: _nameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isVerifying = false;
      _localError = controller.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final error = _localError ?? controller.errorMessage;
    final hasAutoRetrievedCredential = controller.hasAutoRetrievedCredential;
    return Scaffold(
      appBar: AppBar(title: const Text('Login / OTP')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Digital Committee Management System',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _otpStepEnabled
                              ? 'OTP sent. Enter code to continue signup.'
                              : 'Enter phone number to receive OTP via Firebase SMS.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _otpStepEnabled
                        ? Card(
                            key: const ValueKey('otp-step'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Step 2: Verify OTP & Complete Profile',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _otpController,
                                    enabled: _otpStepEnabled,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'OTP Code',
                                      prefixIcon: Icon(Icons.lock_outline_rounded),
                                    ),
                                    validator: (value) {
                                      if (!_otpStepEnabled) {
                                        return null;
                                      }
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty &&
                                          hasAutoRetrievedCredential) {
                                        return null;
                                      }
                                      if (text.length < 6) {
                                        return 'Enter the 6-digit OTP.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _nameController,
                                    enabled: _otpStepEnabled,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name',
                                      prefixIcon: Icon(Icons.person_outline_rounded),
                                    ),
                                    validator: (value) {
                                      if (!_otpStepEnabled) {
                                        return null;
                                      }
                                      if ((value?.trim().length ?? 0) < 2) {
                                        return 'Enter full name.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    enabled: _otpStepEnabled,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.password_rounded),
                                    ),
                                    validator: (value) {
                                      if (!_otpStepEnabled) {
                                        return null;
                                      }
                                      if ((value?.trim().length ?? 0) < 6) {
                                        return 'Minimum 6 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: _isVerifying
                                            ? null
                                            : () {
                                                setState(() {
                                                  _otpStepEnabled = false;
                                                  _otpController.clear();
                                                  _nameController.clear();
                                                  _passwordController.clear();
                                                });
                                              },
                                        icon: const Icon(Icons.arrow_back),
                                        label: const Text('Back'),
                                      ),
                                      const Spacer(),
                                      FilledButton.icon(
                                        onPressed:
                                            _isVerifying || _isSendingOtp
                                                ? null
                                                : () => _verifyOtp(controller),
                                        icon: _isVerifying
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.verified_user),
                                        label: const Text('Verify OTP'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Card(
                            key: const ValueKey('phone-step'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Step 1: Phone Number',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      hintText: '+923001234567',
                                      prefixIcon: Icon(Icons.phone_android_rounded),
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'Phone number is required.';
                                      }
                                      if (!text.startsWith('+')) {
                                        return 'Use international format (+92...)';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isSendingOtp || _isVerifying
                                          ? null
                                          : () => _sendOtp(controller),
                                      icon: _isSendingOtp
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.sms_rounded),
                                      label: const Text('Send OTP'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
