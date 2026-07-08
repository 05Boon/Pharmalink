import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../services/auth_service.dart';
import '../services/realtime_alert_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();

  static final RegExp _emailRegex = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  bool _isLoading = false;
  String? _errorMessage;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) return 'Password is required';
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
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

    try {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result['ok'] == true) {
        await RealtimeAlertService.instance.connect();
        if (!mounted) return;
        if (AuthService.isAdmin) {
          context.go('/admin');
        } else {
          context.go('/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = result['error']?['message'] ?? 'Login failed';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
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
            NavLink(label: 'Register', path: '/register'),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
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
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A18),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sign in to your account',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5F5E5A),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      AppTextField(
                        placeholder: 'Password',
                        obscureText: true,
                        controller: _passwordController,
                        formFieldKey: _passwordFieldKey,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.done,
                        validator: _validatePassword,
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        onTap: () {
                          if (!_validateField(_emailFieldKey)) {
                            FocusScope.of(context).requestFocus(_emailFocus);
                          }
                        },
                        onFieldSubmitted: (_) =>
                            _validateAndUnfocus(_passwordFieldKey),
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
                        text: _isLoading ? 'Signing in...' : 'Login',
                        onPressed: _isLoading ? null : _handleLogin,
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
