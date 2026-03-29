import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class InventorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;

  const InventorySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
            )
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchInventory,
            prefixIcon: const Icon(Icons.search),

            // ✅ SAME CLEAR BUTTON LOGIC
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                  )
                : null,

            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1E4FA3),
                width: 1,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}