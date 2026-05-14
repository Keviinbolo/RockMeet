import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PeerProfileScreen extends StatefulWidget {
  final String uid;
  final String username;
  final String avatarUrl;

  const PeerProfileScreen({
    super.key,
    required this.uid,
    required this.username,
    required this.avatarUrl,
  });

  @override
  State<PeerProfileScreen> createState() => _PeerProfileScreenState();
}

class _PeerProfileScreenState extends State<PeerProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      if (mounted) {
        setState(() {
          _profile = doc.data();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.username), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Avatar header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(widget.avatarUrl),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.username,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((_profile?['bio'] as String?)?.isNotEmpty == true) ...[
                          Text('Acerca de', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            _profile!['bio'] as String,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (_profile?['age'] != null) ...[
                          _buildInfoCard(
                            context,
                            Icons.cake,
                            'Edad',
                            '${_profile!['age']} años',
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (_profile?['interests'] != null &&
                            (_profile!['interests'] as List).isNotEmpty) ...[
                          Text('Intereses', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final interest in _profile!['interests'] as List)
                                Chip(
                                  label: Text(interest.toString()),
                                  backgroundColor: colorScheme.primaryContainer,
                                  labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
