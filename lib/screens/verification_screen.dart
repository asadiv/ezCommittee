import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _frontCnic;
  XFile? _backCnic;
  XFile? _selfie;
  bool _termsAccepted = false;
  bool _submitting = false;
  bool _showStoredImages = false;

  Future<void> _pickImage({
    required bool fromCamera,
    required ValueChanged<XFile> onPicked,
  }) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 75,
    );
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      onPicked(file);
    });
  }

  Future<void> _submit() async {
    if (_frontCnic == null || _backCnic == null || _selfie == null) {
      _snack('Please provide CNIC front, CNIC back, and selfie.');
      return;
    }
    if (!_termsAccepted) {
      _snack('You must accept terms of service.');
      return;
    }
    final controller = context.read<AppController>();
    setState(() {
      _submitting = true;
    });
    await controller.submitVerification(
      cnicFront: File(_frontCnic!.path),
      cnicBack: File(_backCnic!.path),
      selfie: File(_selfie!.path),
      termsAccepted: _termsAccepted,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
    });
    if (controller.errorMessage != null) {
      _snack(controller.errorMessage!);
      return;
    }
    _snack('Verification submitted. Awaiting admin approval.');
  }

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<AppController>().appUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Upload CNIC front/back, capture live selfie, and accept terms. '
            'Status remains pending until manual admin approval.',
          ),
          const SizedBox(height: 16),
          _UploadCard(
            title: 'CNIC Front',
            value: _frontCnic,
            onGallery: () => _pickImage(
              fromCamera: false,
              onPicked: (picked) => _frontCnic = picked,
            ),
            onCamera: () => _pickImage(
              fromCamera: true,
              onPicked: (picked) => _frontCnic = picked,
            ),
          ),
          _UploadCard(
            title: 'CNIC Back',
            value: _backCnic,
            onGallery: () => _pickImage(
              fromCamera: false,
              onPicked: (picked) => _backCnic = picked,
            ),
            onCamera: () => _pickImage(
              fromCamera: true,
              onPicked: (picked) => _backCnic = picked,
            ),
          ),
          _UploadCard(
            title: 'Live Selfie',
            value: _selfie,
            onGallery: () => _pickImage(
              fromCamera: false,
              onPicked: (picked) => _selfie = picked,
            ),
            onCamera: () => _pickImage(
              fromCamera: true,
              onPicked: (picked) => _selfie = picked,
            ),
          ),
          CheckboxListTile(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
            title: const Text('I agree to Terms of Service'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Verification'),
          ),
          if (appUser != null) ...[
            const SizedBox(height: 16),
            Text(
              'Current status: ${appUser.verificationStatus.name.toUpperCase()}',
            ),
            if (appUser.cnicFrontUrl.isNotEmpty ||
                appUser.cnicBackUrl.isNotEmpty ||
                appUser.selfieUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showStoredImages = !_showStoredImages;
                    });
                  },
                  icon: Icon(
                    _showStoredImages
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  label: Text(
                    _showStoredImages
                        ? 'Hide uploaded previews'
                        : 'View uploaded previews',
                  ),
                ),
              ),
              if (_showStoredImages) ...[
                _StoredImageCard(
                  title: 'CNIC Front (Stored)',
                  base64Data: appUser.cnicFrontUrl,
                ),
                _StoredImageCard(
                  title: 'CNIC Back (Stored)',
                  base64Data: appUser.cnicBackUrl,
                ),
                _StoredImageCard(
                  title: 'Selfie (Stored)',
                  base64Data: appUser.selfieUrl,
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.title,
    required this.value,
    required this.onGallery,
    required this.onCamera,
  });

  final String title;
  final XFile? value;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final previewFile = value == null ? null : File(value!.path);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(value == null ? 'No file selected' : value!.name),
            if (previewFile != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  previewFile,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 170,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onGallery,
                  child: const Text('Pick from gallery'),
                ),
                OutlinedButton(
                  onPressed: onCamera,
                  child: const Text('Capture now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoredImageCard extends StatelessWidget {
  const _StoredImageCard({required this.title, required this.base64Data});

  final String title;
  final String base64Data;

  @override
  Widget build(BuildContext context) {
    final isLegacyUrl = base64Data.startsWith('http://') ||
        base64Data.startsWith('https://');
    final bytes = isLegacyUrl ? null : _decodeSafe(base64Data);
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (isLegacyUrl)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  base64Data,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                ),
              )
            else if (bytes == null)
              Text(
                'Unable to decode image preview.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Uint8List? _decodeSafe(String encoded) {
    if (encoded.isEmpty) {
      return null;
    }
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
