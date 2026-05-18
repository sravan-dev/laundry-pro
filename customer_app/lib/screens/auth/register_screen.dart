import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        _nameCtrl.text.trim(), _emailCtrl.text.trim(),
        _phoneCtrl.text.trim(), _passwordCtrl.text, _addressCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 8),
                const Text('Join LaundryPro and enjoy hassle-free laundry', style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
                const SizedBox(height: 32),

                AppTextField(label: 'Full Name', hint: 'John Doe', controller: _nameCtrl, prefixIcon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? 'Name required' : null),
                const SizedBox(height: 14),
                AppTextField(label: 'Email', hint: 'john@example.com', controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Email required' : null),
                const SizedBox(height: 14),
                AppTextField(label: 'Phone Number', hint: '+1 555 0000', controller: _phoneCtrl,
                  prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                AppTextField(label: 'Address', hint: '123 Main St, City', controller: _addressCtrl,
                  prefixIcon: Icons.location_on_outlined, maxLines: 2),
                const SizedBox(height: 14),
                AppTextField(label: 'Password', hint: '••••••••', controller: _passwordCtrl,
                  prefixIcon: Icons.lock_outline, obscure: true,
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
                const SizedBox(height: 32),
                AppButton(label: 'Create Account', onPressed: _register, isLoading: _loading),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
