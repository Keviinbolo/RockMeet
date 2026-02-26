import 'package:flutter/material.dart';

class ValidationTextField extends StatefulWidget {
  final String label;
  final String? Function(String?)? validator;
  final bool showValidation;
  final IconData? prefixIcon;

  const ValidationTextField({
    Key? key,
    required this.label,
    this.validator,
    this.showValidation = false,
    this.prefixIcon,
  }) : super(key: key);

  @override
  State<ValidationTextField> createState() => _ValidationTextFieldState();
}

class _ValidationTextFieldState extends State<ValidationTextField> {
  late TextEditingController _controller;
  String? _errorMessage;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    if (widget.showValidation) {
      final error = widget.validator?.call(_controller.text);
      setState(() {
        _errorMessage = error;
        _isValid = error == null && _controller.text.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: (_) => _validate(),
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: widget.showValidation
                ? _isValid
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : _errorMessage != null
                        ? const Icon(Icons.error, color: Colors.red)
                        : null
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isValid
                    ? Colors.green
                    : _errorMessage != null
                        ? Colors.red
                        : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isValid ? Colors.green : Colors.blue,
                width: 2,
              ),
            ),
          ),
        ),
        if (_errorMessage != null && widget.showValidation)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}