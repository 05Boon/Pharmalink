import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavLink {
  final String label;
  final String path;
  final bool active;

  NavLink({
    required this.label,
    required this.path,
    this.active = false,
  });
}

class AppNav extends StatelessWidget {
  final List<NavLink> links;

  const AppNav({
    super.key,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFB4B2A9),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Text(
            'PharmNet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A18),
            ),
          ),
          const Spacer(),
          ...links.map((link) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: () => context.go(link.path),
                  child: Text(
                    link.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: link.active
                          ? const Color(0xFF0F6E56)
                          : const Color(0xFF5F5E5A),
                      fontWeight:
                          link.active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
