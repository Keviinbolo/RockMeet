import 'package:flutter/material.dart';

enum ValidationState { idle, loading, error, success }

class ValidationStateWidget extends StatelessWidget {
  final ValidationState state;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback? onRetry;
  final Widget? child;

  const ValidationStateWidget({
    Key? key,
    required this.state,
    this.errorMessage,
    this.successMessage,
    this.onRetry,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ValidationState.idle => child ?? const SizedBox.shrink(),
      ValidationState.loading => _buildLoading(context),
      ValidationState.error => _buildError(context),
      ValidationState.success => _buildSuccess(context),
    };
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            errorMessage ?? 'Algo salió mal',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: Colors.green.shade700,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            successMessage ?? '¡Éxito!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}