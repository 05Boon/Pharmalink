import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text field controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pharmacyNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  // Stores the location the user tapped on the map
  // Null means user hasn't picked a location yet
  LatLng? _pickedLocation;

  // Controls the map — used to move the map programmatically
  final MapController _mapController = MapController();

  // Tracks whether registration is in progress
  bool _isLoading = false;

  // Stores error message shown below the form
  String? _errorMessage;

  // Default center of the map when page loads
  // Set to Nairobi since that's your target area
  static const LatLng _nairobiCenter = LatLng(-1.2921, 36.8219);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pharmacyNameController.dispose();
    _licenseNumberController.dispose();
    _phoneNumberController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Runs when user taps Register button
  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Check all text fields are filled
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _pharmacyNameController.text.trim().isEmpty ||
        _licenseNumberController.text.trim().isEmpty ||
        _phoneNumberController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
        _isLoading = false;
      });
      return;
    }

    // Password minimum 6 characters — Supabase requirement
    if (_passwordController.text.trim().length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
        _isLoading = false;
      });
      return;
    }

    // User must tap the map to pick a location
    // PostGIS needs real coordinates to store the pharmacy
    if (_pickedLocation == null) {
      setState(() {
        _errorMessage = 'Please tap the map to set your pharmacy location';
        _isLoading = false;
      });
      return;
    }

    // All validations passed — send to Supabase
    Map<String, dynamic> result;
    try {
      result = await AuthService.register(
        name: _pharmacyNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        // Coordinates from the map tap
        latitude: _pickedLocation!.latitude,
        longitude: _pickedLocation!.longitude,
      );
    } catch (_) {
      result = {
        'ok': false,
        'error': {'message': 'Registration is currently unavailable'}
      };
    }

    if (!mounted) return;

    if (result['ok'] == true) {
      // Go to login after successful registration
      context.go('/');
    } else {
      setState(() {
        _errorMessage =
            result['error']['message'] ?? 'Registration failed';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Login', path: '/'),
          ]),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFB4B2A9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Create account',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A18),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Register your pharmacy',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5F5E5A),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Email field
                      AppTextField(
                        placeholder: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                      ),

                      // Password field
                      AppTextField(
                        placeholder: 'Password',
                        obscureText: true,
                        controller: _passwordController,
                      ),

                      // Pharmacy name field
                      AppTextField(
                        placeholder: 'Pharmacy name',
                        controller: _pharmacyNameController,
                      ),

                      // License number field
                      AppTextField(
                        placeholder: 'License number',
                        controller: _licenseNumberController,
                      ),

                      // Phone number field
                      AppTextField(
                        placeholder: 'Phone number',
                        keyboardType: TextInputType.phone,
                        controller: _phoneNumberController,
                      ),

                      const SizedBox(height: 6),

                      // Map section label
                      const Text(
                        'Pharmacy location',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A18),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Instruction text
                      const Text(
                        'Tap the map to pin your pharmacy location',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5F5E5A),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // The map widget
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 220,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _nairobiCenter,
                              initialZoom: 13,
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _pickedLocation = point;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.pharmacy_network',
                              ),
                              if (_pickedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _pickedLocation!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Color(0xFF1D9E75),
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      if (_pickedLocation != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Color(0xFF1D9E75),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Location set: '
                              '${_pickedLocation!.latitude.toStringAsFixed(4)}, '
                              '${_pickedLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF1D9E75),
                              ),
                            ),
                          ],
                        ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFA32D2D),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      AppButton(
                        text: _isLoading ? 'Registering...' : 'Register',
                        onPressed: () {
                          if (!_isLoading) {
                            _handleRegister();
                          }
                        },
                      ),

                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/'),
                          child: const Text(
                            'Already registered? Login',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF0F6E56),
                            ),
                          ),
                        ),
                      ),
                    ],
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