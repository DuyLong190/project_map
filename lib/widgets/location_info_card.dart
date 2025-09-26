import 'package:flutter/material.dart';

class LocationInfoCard extends StatelessWidget {
  final String title;
  final String address;
  final VoidCallback onRefresh;

  const LocationInfoCard({
    super.key,
    required this.title,
    required this.address,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(address.isEmpty ? "—" : address),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Get Current Location'),
          ),
        ],
      ),
    );
  }
}
