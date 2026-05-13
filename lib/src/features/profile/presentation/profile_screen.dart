import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/storage_service.dart';
import '../../../models/user_model.dart';
import '../../../models/bank_account.dart';
import '../data/profile_providers.dart';

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
      builder: (context) => AlertDialog(
        title: const Text('Add Bank Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Account Holder Name')),
            TextField(decoration: const InputDecoration(labelText: 'Account Number'), keyboardType: TextInputType.number),
            TextField(decoration: const InputDecoration(labelText: 'IFSC Code')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () { Navigator.pop(context); }, child: const Text('ADD')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProfileProvider);
    final bankAsync = ref.watch(bankAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isEditing) 
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {
              final user = userAsync.value;
              if (user != null) {
                _businessC.text = user.businessName ?? '';
                _emailC.text = user.email ?? '';
                setState(() => _isEditing = true);
              }
            })
          else
            TextButton(onPressed: _isSaving ? null : _saveProfile, child: _isSaving 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('No user data'));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(children: [
              const SizedBox(height: 16),
              // Avatar
              GestureDetector(
                onTap: _isUploadingProfile ? null : _updateProfilePicture,
                child: Stack(
                  children: [
                    Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      border: Border.all(color: theme.colorScheme.primary, width: 3),
                      image: user.photoUrl != null ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover) : null),
                      child: user.photoUrl == null ? Icon(Icons.person, size: 54, color: theme.colorScheme.primary) : null),
                    if (_isUploadingProfile)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                    Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.black))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Owner Account', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 32),

              // Business Info
              _sectionHeader('Business Details'),
              const SizedBox(height: 12),
              if (_isEditing) ...[
                _editField('Business Name', _businessC, Icons.business),
                const SizedBox(height: 12),
                _editField('Email Address', _emailC, Icons.email_outlined),
                const SizedBox(height: 12),
              ] else ...[
                _tile(Icons.business, 'Business Name', user.businessName ?? 'Not set'),
                _tile(Icons.phone, 'Phone Number', user.loginId),
                _tile(Icons.email_outlined, 'Email', user.email ?? 'Not set'),
              ],

              const SizedBox(height: 24),
              _sectionHeader('Aadhaar KYC'),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Verification Status', style: TextStyle(fontWeight: FontWeight.w600)),
                    _kycBadge(user.kycStatus),
                  ]),
                  const SizedBox(height: 16),
                  if (user.kycStatus == 'VERIFIED') ...[
                    _kycDetail('Full Name', user.name),
                    _kycDetail('Date of Birth', user.dob ?? '-'),
                    _kycDetail('Gender', user.gender ?? '-'),
                    _kycDetail('Address', user.address ?? '-'),
                    _kycDetail('Aadhaar', 'XXXX XXXX ${user.aadhaarLast4 ?? 'XXXX'}'),
                  ] else ...[
                    TextField(controller: _aadhaarC, keyboardType: TextInputType.number, maxLength: 12,
                      decoration: const InputDecoration(hintText: 'Enter 12-digit Aadhaar number', prefixIcon: Icon(Icons.credit_card), counterText: '')),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: ElevatedButton(
                      onPressed: _isVerifying ? null : () => _verifyKyc(user),
                      child: _isVerifying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('VERIFY AADHAAR'))),
                  ],
                ])),

              const SizedBox(height: 24),
              _sectionHeader('Bank Accounts'),
              const SizedBox(height: 12),
              bankAsync.when(
                data: (banks) => Column(children: [
                  ...banks.map((b) => _tile(Icons.account_balance, b.bankName, b.maskedAccountNumber)),
                  TextButton.icon(onPressed: _addBankAccount, icon: const Icon(Icons.add), label: const Text('ADD BANK ACCOUNT')),
                ]),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Error loading banks: $e'),
              ),

              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('LOG OUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
              const SizedBox(height: 32),
            ]),
          );
        },
      ),
    );
  }

  Widget _editField(String label, TextEditingController controller, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(label),
      const SizedBox(height: 6),
      TextField(controller: controller, decoration: InputDecoration(prefixIcon: Icon(icon, size: 20))),
    ]);
  }

  Widget _sectionHeader(String text) => Align(alignment: Alignment.centerLeft,
    child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400], fontSize: 13)));

  Widget _kycBadge(String status) {
    Color c; String t;
    switch (status) {
      case 'VERIFIED': c = Colors.green; t = 'VERIFIED';
      case 'VERIFYING': c = Colors.blue; t = 'VERIFYING...';
      default: c = Colors.orange; t = 'PENDING';
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)));
  }

  Widget _kycDetail(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
    ]));

  Widget _tile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16)),
      child: ListTile(onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))));
  }

  Widget _ratingBar(String star, double fraction) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
      Text(star, style: TextStyle(fontSize: 12, color: Colors.grey[500])), const SizedBox(width: 8),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(value: fraction, minHeight: 4, backgroundColor: Colors.grey[800],
          valueColor: const AlwaysStoppedAnimation(Colors.amber)))),
    ]));
  }
}
