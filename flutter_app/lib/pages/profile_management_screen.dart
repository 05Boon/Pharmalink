import 'package:flutter/material.dart';
import '../services/network_data_service.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_button.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Read-only fields
  String _pharmacyId = '';
  String _licenseNumber = '';
  String _email = '';

  // Editable fields
  final _businessNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _generalLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneNumberController.dispose();
    _generalLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await NetworkDataService.getPharmacyProfile();
      setState(() {
        _pharmacyId = profile['pharmacy_id'] ?? '';
        _licenseNumber = profile['license_number'] ?? '';
        _email = profile['email'] ?? '';

        _businessNameController.text = profile['business_name'] ?? '';
        _phoneNumberController.text = profile['phone_number'] ?? '';
        _generalLocationController.text = profile['general_location'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updateData = {
        'business_name': _businessNameController.text.trim(),
        'phone_number': _phoneNumberController.text.trim(),
        if (_generalLocationController.text.trim().isNotEmpty)
          'general_location': _generalLocationController.text.trim()
      };

      await NetworkDataService.updatePharmacyProfile(updateData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F5E5A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8A8A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F8),
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard'),
            NavLink(label: 'Search', path: '/search'),
            NavLink(label: 'Responder', path: '/search/response'),
            NavLink(label: 'Requests', path: '/requests'),
            NavLink(label: 'History', path: '/history'),
            NavLink(label: 'Profile', path: '/profile', active: true),
            NavLink(label: 'Logout', path: '/'),
          ]),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFB4B2A9)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profile Management',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A18),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Update your pharmacy contact information. Geographic coordinates and verified identification are locked.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5F5E5A),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(color: Colors.red.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              
                              const Text(
                                'Locked Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField('Pharmacy UUID', _pharmacyId),
                              _buildReadOnlyField('License Number', _licenseNumber),
                              _buildReadOnlyField('Registered Email', _email),
                              
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              const Text(
                                'Editable Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _businessNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Business Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Business name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _phoneNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Phone number is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _generalLocationController,
                                decoration: const InputDecoration(
                                  labelText: 'General Location (e.g. Mombasa, Kenya)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: _isSaving ? 'Saving...' : 'Save Profile',
                                  onPressed: _isSaving ? null : _saveProfile,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
