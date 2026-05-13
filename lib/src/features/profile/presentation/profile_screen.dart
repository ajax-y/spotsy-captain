import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common_widgets/glass_container.dart';
import '../../../services/storage_service.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../models/user_model.dart';
import '../../../models/bank_account.dart';
import '../data/profile_providers.dart';
import '../../auth/data/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _aadhaarC = TextEditingController();
  final _businessC = TextEditingController();
  final _emailC = TextEditingController();
  
  final _picker = ImagePicker();
  final _storage = StorageService();
  
  bool _isVerifying = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingProfile = false;

  @override
  void dispose() {
    _aadhaarC.dispose();
    _businessC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  Future<void> _updateProfilePicture() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    setState(() => _isUploadingProfile = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await _storage.uploadProfilePhoto(bytes)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw 'Timeout');
      
      if (url != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'photoUrl': url,
          });
          _snack('Profile picture updated!', Colors.green);
        }
      }
    } catch (e) {
      _snack('Warning: Profile picture upload failed ($e).', Colors.orange);
    } finally {
      if (mounted) setState(() => _isUploadingProfile = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'businessName': _businessC.text.trim(),
          'email': _emailC.text.trim(),
        });
        setState(() => _isEditing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _verifyKyc(UserModel currentUser) async {
    final aadhaar = _aadhaarC.text.trim();
    if (aadhaar.length != 12) {
      _snack('Enter valid 12-digit Aadhaar number');
      return;
    }
    setState(() => _isVerifying = true);

    // Simulate API call to fetch Aadhaar data
    await Future.delayed(const Duration(seconds: 2));

    // Simulated "Real" Aadhaar Data
    // In a real app, this would come from a secure government API
    String linkedName = 'Captain Owner'; 
    String linkedPhone = currentUser.loginId; // Simulating a match for demo

    // Logic: If user types "123412341234", we simulate a failure
    if (aadhaar == '123412341234') {
      linkedName = 'Mismatch Name';
      linkedPhone = '9999999999';
    }

    if (linkedPhone != currentUser.loginId) {
      _snack('Verification Failed: Aadhaar linked mobile number does not match your registered number');
      setState(() => _isVerifying = false);
      return;
    }

    if (linkedName.toLowerCase() != currentUser.name.toLowerCase()) {
      _snack('Verification Failed: Name on Aadhaar does not match your profile name');
      setState(() => _isVerifying = false);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'kycStatus': 'VERIFIED',
          'dob': '01/01/1990',
          'gender': 'Male',
          'address': '123, Brigade Road, Bangalore, Karnataka - 560001',
          'aadhaarLast4': aadhaar.substring(8),
        });
        _snack('KYC Verified Successfully!', Colors.green);
      }
    } catch (e) {
      if (mounted) _snack('KYC Error: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _snack(String msg, [Color? color]) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
    }
  }

  void _addBankAccount() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 32,
          opacity: 0.1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Bank Account', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              _editField('Account Holder Name', TextEditingController(), Icons.person_outline_rounded),
              const SizedBox(height: 16),
              _editField('Account Number', TextEditingController(), Icons.account_balance_rounded),
              const SizedBox(height: 16),
              _editField('IFSC Code', TextEditingController(), Icons.code_rounded),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ADD'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Blobs
          Positioned(top: -100, right: -50, child: _GlowBlob(color: theme.colorScheme.primary.withValues(alpha: 0.1))),
          
          userAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (user) {
              if (user == null) return const Center(child: Text('No user data'));
              
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => context.go('/dashboard'),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          Text('Profile', style: theme.textTheme.titleLarge),
                          IconButton(
                            onPressed: () {
                              _businessC.text = user.businessName ?? '';
                              _emailC.text = user.email ?? '';
                              setState(() => _isEditing = !_isEditing);
                            },
                            icon: Icon(_isEditing ? Icons.close_rounded : Icons.settings_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Avatar Section
                      GestureDetector(
                        onTap: _isUploadingProfile ? null : _updateProfilePicture,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, 
                            border: Border.all(color: theme.colorScheme.primary, width: 2),
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                                child: user.photoUrl == null ? Icon(Icons.person, size: 50, color: theme.colorScheme.primary) : null,
                              ),
                              if (_isUploadingProfile)
                                const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user.name, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(user.loginId, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      
                      // Premium Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded, color: theme.colorScheme.primary, size: 16),
                            const SizedBox(width: 8),
                            Text('Premium Captain', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      if (_isEditing) ...[
                        _sectionHeader('Edit Business Profile'),
                        const SizedBox(height: 16),
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 24,
                          child: Column(
                            children: [
                              _editField('Business Name', _businessC, Icons.business_rounded),
                              const SizedBox(height: 16),
                              _editField('Email Address', _emailC, Icons.email_rounded),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                child: _isSaving 
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : const Text('Update Profile'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Account Section
                        _ProfileMenuSection(
                          title: 'Account',
                          items: [
                            _ProfileMenuItem(
                              icon: Icons.verified_user_rounded, 
                              title: 'KYC Status', 
                              trailing: user.kycStatus,
                              trailingColor: user.kycStatus == 'VERIFIED' ? theme.colorScheme.primary : Colors.orange,
                              onTap: () => _showKycDialog(user),
                            ),
                            _ProfileMenuItem(
                              icon: Icons.account_balance_rounded, 
                              title: 'Bank Accounts', 
                              onTap: _addBankAccount,
                            ),
                            _ProfileMenuItem(
                              icon: Icons.history_rounded, 
                              title: 'Activity History', 
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Support Section
                        _ProfileMenuSection(
                          title: 'Support & Settings',
                          items: [
                            _ProfileMenuItem(icon: Icons.help_outline_rounded, title: 'Help Center', onTap: () {}),
                            _ProfileMenuItem(icon: Icons.policy_outlined, title: 'Privacy Policy', onTap: () {}),
                            _ProfileMenuItem(
                              icon: Icons.logout_rounded, 
                              title: 'Sign Out', 
                              titleColor: Colors.redAccent,
                              onTap: () async {
                                final auth = FirebaseAuthService();
                                await auth.logout();
                                if (mounted) context.go('/login');
                              },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showKycDialog(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 24, right: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Aadhaar KYC', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Verify your identity to list more spaces', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 24),
              if (user.kycStatus == 'VERIFIED') ...[
                _kycDetail('Status', 'Verified', color: Colors.green),
                _kycDetail('Aadhaar', 'XXXX XXXX ${user.aadhaarLast4}'),
                _kycDetail('Address', user.address ?? '-'),
                const SizedBox(height: 32),
              ] else ...[
                TextField(
                  controller: _aadhaarC,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  decoration: const InputDecoration(hintText: '12-digit Aadhaar Number'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isVerifying ? null : () {
                    _verifyKyc(user);
                    Navigator.pop(context);
                  },
                  child: const Text('Verify Now'),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: controller, decoration: InputDecoration(prefixIcon: Icon(icon, size: 20))),
      ],
    );
  }

  Widget _sectionHeader(String text) => Align(alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white38, fontSize: 13, letterSpacing: 1.2)));

  Widget _kycDetail(String label, String value, {Color? color}) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.white)),
    ]),
  );
}

class _ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<_ProfileMenuItem> items;

  const _ProfileMenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        GlassContainer(
          padding: EdgeInsets.zero,
          borderRadius: 24,
          opacity: 0.03,
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Color? trailingColor;
  final Color? titleColor;
  final VoidCallback onTap;

  const _ProfileMenuItem({required this.icon, required this.title, this.trailing, this.trailingColor, this.titleColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
        child: Icon(icon, color: titleColor ?? Colors.white70, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            Text(trailing!, style: TextStyle(color: trailingColor ?? Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white12),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, this.size = 300});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)));
  }
}
