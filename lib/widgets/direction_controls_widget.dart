import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class DirectionControlsWidget extends StatelessWidget {
  final VoidCallback onSetStart;
  final VoidCallback onSetEnd;
  final VoidCallback onGetRoute;
  final VoidCallback onClearRoute;
  final bool canGetRoute;
  final bool isGettingRoute;
  final bool hasStartLocation;
  final bool hasEndLocation;

  const DirectionControlsWidget({
    super.key,
    required this.onSetStart,
    required this.onSetEnd,
    required this.onGetRoute,
    required this.onClearRoute,
    required this.canGetRoute,
    required this.isGettingRoute,
    required this.hasStartLocation,
    required this.hasEndLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppConstants.directionTitle, style: AppConstants.titleStyle),
          const SizedBox(height: AppConstants.smallPadding),

          // Start and End buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSetStart,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(AppConstants.setStartButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.startLocationColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, AppConstants.buttonHeight),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSetEnd,
                  icon: const Icon(Icons.flag, color: Colors.white),
                  label: const Text(AppConstants.setEndButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.endLocationColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, AppConstants.buttonHeight),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.smallPadding),

          // Route and Clear buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canGetRoute && !isGettingRoute ? onGetRoute : null,
                  icon: isGettingRoute
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.directions, color: Colors.white),
                  label: const Text(AppConstants.findRouteButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, AppConstants.buttonHeight),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onClearRoute,
                  icon: const Icon(Icons.clear, color: Colors.white),
                  label: const Text(AppConstants.clearRouteButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.warningColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, AppConstants.buttonHeight),
                  ),
                ),
              ),
            ],
          ),

          // Status indicators
          if (hasStartLocation || hasEndLocation) ...[
            const SizedBox(height: AppConstants.smallPadding),
            _buildStatusIndicator(
              hasStartLocation
                  ? '✓ Điểm xuất phát đã chọn'
                  : 'Chưa chọn điểm xuất phát',
              hasStartLocation ? AppConstants.successColor : Colors.grey,
            ),
            _buildStatusIndicator(
              hasEndLocation ? '✓ Điểm đến đã chọn' : 'Chưa chọn điểm đến',
              hasEndLocation ? AppConstants.successColor : Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
