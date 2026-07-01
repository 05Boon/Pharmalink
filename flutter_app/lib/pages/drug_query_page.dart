import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../services/network_data_service.dart';

class DrugQueryPage extends StatefulWidget {
  const DrugQueryPage({super.key});

  @override
  State<DrugQueryPage> createState() => _DrugQueryPageState();
}

class _DrugQueryPageState extends State<DrugQueryPage> {
  int selectedRadius = 10;
  final _drugNameController = TextEditingController();
  final _quantityController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _drugNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _handleSearchNow() async {
    setState(() {
      _errorMessage = null;
    });

    final drugName = _drugNameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim());

    if (drugName.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a drug name before searching.';
      });
      return;
    }

    if (quantity == null || quantity <= 0) {
      setState(() {
        _errorMessage = 'Enter a valid quantity greater than 0.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await NetworkDataService.createStockRequestAndBroadcast(
        requestedDrug: drugName,
        requiredQuantity: quantity,
        searchRadiusMeters: selectedRadius,
      );

      if (!mounted) return;
      final encoded = Uri.encodeQueryComponent(drugName);
      context.go('/search/results?q=$encoded');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to submit your request now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard'),
            NavLink(label: 'Search', path: '/search', active: true),
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
                      RichText(
                        text: const TextSpan(
                          style:
                              TextStyle(fontSize: 10, color: Color(0xFF5F5E5A)),
                          children: [
                            TextSpan(text: 'Dashboard / '),
                            TextSpan(
                              text: 'New query',
                              style: TextStyle(color: Color(0xFF0F6E56)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Drug query',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A18),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Find nearby stock',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5F5E5A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        placeholder: 'Drug name / generic name',
                        controller: _drugNameController,
                        enabled: !_isSubmitting,
                      ),
                      AppTextField(
                        placeholder: 'Quantity needed',
                        keyboardType: TextInputType.number,
                        controller: _quantityController,
                        enabled: !_isSubmitting,
                      ),
                      AppTextField(
                        placeholder: 'Dosage / form (optional)',
                        enabled: !_isSubmitting,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF791F1F),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Search radius',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5F5E5A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _RadiusButton(
                              label: '5 km',
                              value: 5,
                              selected: selectedRadius == 5,
                              onTap: _isSubmitting ? () {} : () => setState(() => selectedRadius = 5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _RadiusButton(
                              label: '10 km',
                              value: 10,
                              selected: selectedRadius == 10,
                              onTap: _isSubmitting ? () {} : () => setState(() => selectedRadius = 10),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _RadiusButton(
                              label: '20 km',
                              value: 20,
                              selected: selectedRadius == 20,
                              onTap: _isSubmitting ? () {} : () => setState(() => selectedRadius = 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        placeholder: 'Your location (auto-detected)',
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 4),
                      AppButton(
                        text: _isSubmitting ? 'Submitting...' : 'Search now',
                        onPressed: _isSubmitting ? null : _handleSearchNow,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => context.go('/dashboard'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1EFEA),
                            foregroundColor: const Color(0xFF1A1A18),
                            side: const BorderSide(color: Color(0xFFB4B2A9)),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 11),
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

class _RadiusButton extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _RadiusButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE1F5EE) : const Color(0xFFF1EFEA),
          border: Border.all(
            color: selected ? const Color(0xFF5DCAA5) : const Color(0xFFD3D1C7),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label ${selected ? '✓' : ''}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: selected ? const Color(0xFF085041) : const Color(0xFF888780),
          ),
        ),
      ),
    );
  }
}
