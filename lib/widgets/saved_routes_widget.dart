import 'package:flutter/material.dart';
import '../models/saved_route_model.dart';
import '../constants/app_constants.dart';

class SavedRoutesWidget extends StatelessWidget {
  final List<SavedRouteModel> routes;
  final Function(SavedRouteModel) onLoadRoute;
  final Function(String) onDeleteRoute;
  final Function(String) onToggleFavorite;
  final bool isLoading;

  const SavedRoutesWidget({
    super.key,
    required this.routes,
    required this.onLoadRoute,
    required this.onDeleteRoute,
    required this.onToggleFavorite,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppConstants.savedRoutesTitle,
                style: AppConstants.titleStyle,
              ),
              Text('${routes.length} vết', style: AppConstants.subtitleStyle),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : routes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      return _buildRouteCard(context, route);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route, size: 64, color: Colors.grey[400]),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            AppConstants.noSavedRoutes,
            style: AppConstants.subtitleStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Tìm đường đi và lưu lại để sử dụng sau',
            style: AppConstants.subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, SavedRouteModel route) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: InkWell(
        onTap: () => onLoadRoute(route),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and favorite button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onToggleFavorite(route.id),
                    icon: Icon(
                      route.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: route.isFavorite ? Colors.red : Colors.grey,
                    ),
                    iconSize: 20,
                  ),
                ],
              ),

              // Description
              if (route.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  route.description,
                  style: AppConstants.subtitleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: AppConstants.smallPadding),

              // Route info
              Row(
                children: [
                  Icon(Icons.route, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    route.displayInfo,
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Addresses
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Từ: ${_getShortAddress(route.startLocation.address)}',
                      style: AppConstants.subtitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: Colors.red[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Đến: ${_getShortAddress(route.endLocation.address)}',
                      style: AppConstants.subtitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.smallPadding),

              // Footer with date and delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(route.createdAt),
                    style: AppConstants.subtitleStyle.copyWith(fontSize: 12),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteDialog(context, route),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getShortAddress(String address) {
    if (address.length <= 30) return address;
    return '${address.substring(0, 27)}...';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(BuildContext context, SavedRouteModel route) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa vết'),
        content: Text(AppConstants.confirmDeleteRoute),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppConstants.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              onDeleteRoute(route.id);
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(AppConstants.deleteRouteButton),
          ),
        ],
      ),
    );
  }
}
