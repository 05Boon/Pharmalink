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
  final _formKey = GlobalKey<FormState>();

  // Text field controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pharmacyNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _pharmacyNameFocus = FocusNode();
  final _licenseFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _pharmacyNameFieldKey = GlobalKey<FormFieldState<String>>();
  final _licenseFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();

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

  static final RegExp _emailRegex = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
  );
  static final RegExp _licenseRegex = RegExp(
    r'^[A-Za-z0-9\-/]{5,20}$',
  );
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[0-9]{10,15}$',
  );

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) return 'Password is required';
    if (!_passwordRegex.hasMatch(password)) {
      return 'Use 8+ chars with upper, lower, number, and symbol';
    }
    return null;
  }

  String? _validatePharmacyName(String? value) {
    if ((value?.trim() ?? '').isEmpty) return 'Pharmacy name is required';
    return null;
  }

  String? _validateLicenseNumber(String? value) {
    final license = value?.trim() ?? '';
    if (license.isEmpty) return 'License number is required';
    if (!_licenseRegex.hasMatch(license)) {
      return 'Use 5-20 chars (letters, numbers, - or /)';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required';
    if (!_phoneRegex.hasMatch(phone)) {
      return 'Enter a valid phone number (10-15 digits)';
    }
    return null;
  }

  bool _validateField(GlobalKey<FormFieldState<String>> fieldKey) {
    return fieldKey.currentState?.validate() ?? false;
  }

  void _validateAndMove(
    GlobalKey<FormFieldState<String>> fieldKey,
    FocusNode nextFocus,
  ) {
    if (_validateField(fieldKey)) {
      FocusScope.of(context).requestFocus(nextFocus);
    }
  }

  void _validateAndUnfocus(GlobalKey<FormFieldState<String>> fieldKey) {
    if (_validateField(fieldKey)) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pharmacyNameController.dispose();
    _licenseNumberController.dispose();
    _phoneNumberController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _pharmacyNameFocus.dispose();
    _licenseFocus.dispose();
    _phoneFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Runs when user taps Register button
  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _errorMessage = 'Please correct the highlighted fields';
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
                  child: Form(
                    key: _formKey,
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
                        formFieldKey: _emailFieldKey,
                        focusNode: _emailFocus,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        onFieldSubmitted: (_) => _validateAndMove(
                          _emailFieldKey,
                          _passwordFocus,
                        ),
                      ),

                      // Password field
                      AppTextField(
                        placeholder: 'Password',
                        obscureText: true,
                        controller: _passwordController,
                        formFieldKey: _passwordFieldKey,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.next,
                        validator: _validatePassword,
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        onTap: () {
                          if (!_validateField(_emailFieldKey)) {
                            FocusScope.of(context).requestFocus(_emailFocus);
                          }
                        },
                        onFieldSubmitted: (_) => _validateAndMove(
                          _passwordFieldKey,
                          _pharmacyNameFocus,
                        ),
                      ),

                      // Pharmacy name field
                      AppTextField(
                        placeholder: 'Pharmacy name',
                        controller: _pharmacyNameController,
                        formFieldKey: _pharmacyNameFieldKey,
                        focusNode: _pharmacyNameFocus,
                        textInputAction: TextInputAction.next,
                        validator: _validatePharmacyName,
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        onTap: () {
                          if (!_validateField(_passwordFieldKey)) {
                            FocusScope.of(context)
                                .requestFocus(_passwordFocus);
                          }
                        },
                        onFieldSubmitted: (_) => _validateAndMove(
                          _pharmacyNameFieldKey,
                          _licenseFocus,
                        ),
                      ),

                      // License number field
                      AppTextField(
                        placeholder: 'License number',
                        controller: _licenseNumberController,
                        formFieldKey: _licenseFieldKey,
                        focusNode: _licenseFocus,
                        textInputAction: TextInputAction.next,
                        validator: _validateLicenseNumber,
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        onTap: () {
                          if (!_validateField(_pharmacyNameFieldKey)) {
                            FocusScope.of(context)
                                .requestFocus(_pharmacyNameFocus);
                          }
                        },
                        onFieldSubmitted: (_) => _validateAndMove(
                          _licenseFieldKey,
                          _phoneFocus,
                        ),
                      ),

                      // Phone number field
                      AppTextField(
                        placeholder: 'Phone number',
                        keyboardType: TextInputType.phone,
                        controller: _phoneNumberController,
                        formFieldKey: _phoneFieldKey,
                        focusNode: _phoneFocus,
                        textInputAction: TextInputAction.done,
                        validator: _validatePhoneNumber,
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        onTap: () {
                          if (!_validateField(_licenseFieldKey)) {
                            FocusScope.of(context).requestFocus(_licenseFocus);
                          }
                        },
                        onFieldSubmitted: (_) =>
                            _validateAndUnfocus(_phoneFieldKey),
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
          ),
        ],
      ),
    );
  }
}