import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final bool readOnly;
  final String? helperText;
  final List<TextInputFormatter>? inputFormatters;
  final bool isAutoFilled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    required this.prefixIcon,
    this.readOnly = false,
    this.helperText,
    this.inputFormatters,
    this.isAutoFilled = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      readOnly: widget.readOnly,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        prefixIcon: Icon(widget.prefixIcon, color: Colors.blueAccent),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.readOnly && widget.isAutoFilled
            ? Icon(Icons.check_circle_rounded, color: Colors.green.shade600)
            : widget.readOnly
            ? const Icon(Icons.lock_outline, color: Colors.grey)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.isAutoFilled
                ? Colors.green.shade300
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.isAutoFilled
                ? Colors.green.shade300
                : Colors.grey.shade300,
          ),
        ),
        filled: true,
        fillColor: widget.readOnly
            ? (widget.isAutoFilled
                  ? Colors.green.shade50
                  : Colors.grey.shade100)
            : Colors.grey.shade50,
      ),
    );
  }
}
