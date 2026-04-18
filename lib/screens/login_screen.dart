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

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(AppController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSendingOtp = true;
      _localError = null;
    });
    await controller.sendOtp(_phoneController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() {
      _isSendingOtp = false;
      _localError = controller.errorMessage;
    });
  }

  Future<void> _verifyOtp(AppController controller) async {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Login / OTP')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Digital Committee Management System',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter phone number, verify OTP, and set account password.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+923001234567',
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'OTP Code'),
                    validator: (value) {
                      if ((value?.trim().length ?? 0) < 6) {
                        return 'Enter the 6-digit OTP.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) {
                      if ((value?.trim().length ?? 0) < 2) {
                        return 'Enter full name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if ((value?.trim().length ?? 0) < 6) {
                        return 'Minimum 6 characters.';
                      }
                      return null;
                    },
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isSendingOtp || _isVerifying
                            ? null
                            : () => _sendOtp(controller),
                        icon: _isSendingOtp
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sms),
                        label: const Text('Send OTP'),
                      ),
                      FilledButton.icon(
                        onPressed: _isVerifying || _isSendingOtp
                            ? null
                            : () => _verifyOtp(controller),
                        icon: _isVerifying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
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
          ),
        ),
      ),
    );
  }
}
