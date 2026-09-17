import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

/// Screen for buyers to view and edit their profile details:
/// Name, Email, Phone, Delivery Address, Business/Org Name.
class BuyerProfileDetailsScreen extends StatefulWidget {
  const BuyerProfileDetailsScreen({super.key});

  @override
  State<BuyerProfileDetailsScreen> createState() => _BuyerProfileDetailsScreenState();
}

class _BuyerProfileDetailsScreenState extends State<BuyerProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deliveryAddressCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppAuthProvider>().userModel;
      if (user != null) {
        _nameCtrl.text = user.name;
        _emailCtrl.text = user.email;
        _phoneCtrl.text = user.phone;
        _deliveryAddressCtrl.text = user.deliveryAddress;
        _businessNameCtrl.text = user.businessName;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    _businessNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = context.read<AppAuthProvider>();
    final uid = auth.userModel?.uid ?? auth.firebaseUser?.uid ?? auth.currentArtisanId;

    final updatedFields = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      'delivery_address': _deliveryAddressCtrl.text.trim(),
      'business_name': _businessNameCtrl.text.trim(),
      'role': 'buyer',
    };

    try {
      // 1. Persist to Firestore / Backend
      await ProfileService.instance.saveProfile(uid, updatedFields);
      try {
        await AuthService().updateUserProfile(uid, updatedFields);
      } catch (_) {}

      // 2. Update local state
      if (auth.userModel != null) {
        final updatedUser = auth.userModel!.copyWith(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          deliveryAddress: _deliveryAddressCtrl.text.trim(),
          businessName: _businessNameCtrl.text.trim(),
        );
        auth.updateUserModel(updatedUser);
      }

      // Re-fetch to ensure 100% sync
      await auth.refreshUser();

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buyer profile updated successfully!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: AppTheme.warningRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgParchment,
      appBar: AppBar(
        title: Text(
          lang.getText('buyer_profile_title'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkIndigo,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryOchre.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_pin_rounded,
                        color: AppTheme.secondaryOchre,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.getText('buyer_profile_title'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkIndigo,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            lang.getText('buyer_profile_sub'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name Field
              _buildFieldLabel('Full Name', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 18),

              // Email Field (Read-only from Auth)
              _buildFieldLabel('Email Address', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl,
                readOnly: true,
                decoration: _inputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icons.email_outlined,
                  suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 18),

              // Phone Number Field
              _buildFieldLabel('Phone Number', isRequired: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  hintText: '+91 98765 43210',
                  prefixIcon: Icons.phone_outlined,
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 18),

              // Delivery Address Field
              _buildFieldLabel(lang.getText('delivery_address_label'), isRequired: false),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deliveryAddressCtrl,
                maxLines: 3,
                decoration: _inputDecoration(
                  hintText: 'Street address, Apartment/Suite, City, State, PIN code',
                  prefixIcon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 18),

              // Business / Organization Name Field (Optional for B2B)
              _buildFieldLabel(lang.getText('business_name_label'), isRequired: false),
              const SizedBox(height: 6),
              TextFormField(
                controller: _businessNameCtrl,
                decoration: _inputDecoration(
                  hintText: 'Company or Store Name (optional for retail buyers)',
                  prefixIcon: Icons.storefront_outlined,
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Profile Details',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTerracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkIndigo,
          ),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(color: AppTheme.warningRed, fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: AppTheme.primaryTerracotta, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.8),
      ),
    );
  }
}
