import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Login', path: '/login'),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const AppTextField(placeholder: 'Full name'),
                      const AppTextField(
                        placeholder: 'Email address',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const AppTextField(
                        placeholder: 'Password',
                        obscureText: true,
                      ),
                      const AppTextField(placeholder: 'Pharmacy name'),
                      const AppTextField(placeholder: 'Location / address'),
                      const SizedBox(height: 4),
                      AppButton(
                        text: 'Register',
                        onPressed: () => context.go('/dashboard'),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
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
