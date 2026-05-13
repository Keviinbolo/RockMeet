import 'package:flutter/material.dart';

import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/config/Theme/constants/text_styles.dart';


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
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando...',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
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
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error, width: 2),
            ),
            child: Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            errorMessage ?? 'Algo salió mal',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.error,
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
                backgroundColor: AppColors.error,
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
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success, width: 2),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            successMessage ?? '¡Éxito!',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}