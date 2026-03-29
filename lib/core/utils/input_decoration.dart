import 'package:flutter/material.dart';

InputDecoration inputStyle(String label) {
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Color(0xFF2563EB),
        width: 2,
      ),
    ),
    labelStyle: const TextStyle(color: Colors.grey),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFF2563EB),
      fontWeight: FontWeight.w500,
    ),
  );
}