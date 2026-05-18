import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _user = await AuthService.getSavedUser();
    if (_user != null) {
      _nameCtrl.text    = _user!.name;
      _phoneCtrl.text   = _user!.phone;
      _addressCtrl.text = _user!.address;
      setState(() {});
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiService.put('customer/profile.php', {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(_user?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            Text(_user?.email ?? '', style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
            const SizedBox(height: 28),

            if (_editing) ...[
              AppTextField(label: 'Full Name', hint: 'John Doe', controller: _nameCtrl, prefixIcon: Icons.person_outline),
              const SizedBox(height: 14),
              AppTextField(label: 'Phone', hint: '+1 555 0000', controller: _phoneCtrl, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              AppTextField(label: 'Address', hint: '123 Main St', controller: _addressCtrl, prefixIcon: Icons.location_on_outlined, maxLines: 2),
              const SizedBox(height: 20),
              AppButton(label: 'Save Changes', onPressed: _save, isLoading: _loading, icon: Icons.save),
            ] else ...[
              _infoCard([
                _infoRow(Icons.email_outlined, 'Email', _user?.email ?? ''),
                _infoRow(Icons.phone_outlined, 'Phone', _user?.phone?.isNotEmpty == true ? _user!.phone : 'Not set'),
                _infoRow(Icons.location_on_outlined, 'Address', _user?.address?.isNotEmpty == true ? _user!.address : 'Not set'),
              ]),
            ],

            const SizedBox(height: 32),
            AppButton(label: 'Sign Out', onPressed: _logout, outline: true, icon: Icons.logout),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
