import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../constants/app_constants.dart';

class LocationInfoWidget extends StatelessWidget {
  final LocationModel? currentLocation;
  final LocationModel? selectedLocation;
  final RouteModel currentRoute;
  final VoidCallback onGetCurrentLocation;
  final bool isLoadingCurrentLocation;

  const LocationInfoWidget({
    super.key,
    this.currentLocation,
    this.selectedLocation,
    required this.currentRoute,
    required this.onGetCurrentLocation,
    this.isLoadingCurrentLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedLocation != null
                ? AppConstants.selectedLocationTitle
                : AppConstants.currentLocationTitle,
            style: AppConstants.titleStyle,
          ),
          const SizedBox(height: AppConstants.smallPadding),

          // Location address
          Text(_getDisplayAddress(), style: AppConstants.bodyStyle),

          // Selected location coordinates
          if (selectedLocation != null) ...[
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Tọa độ: ${selectedLocation!.coordinates.latitude.toStringAsFixed(6)}, '
              '${selectedLocation!.coordinates.longitude.toStringAsFixed(6)}',
              style: AppConstants.subtitleStyle,
            ),
          ],

          // Route information
          if (currentRoute.routeInfo != null &&
              currentRoute.routeInfo!.isNotEmpty) ...[
            const SizedBox(height: AppConstants.smallPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: currentRoute.isEstimated
                    ? AppConstants.warningColor.withOpacity(0.1)
                    : AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: currentRoute.isEstimated
                      ? AppConstants.warningColor.withOpacity(0.3)
                      : AppConstants.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                currentRoute.routeInfo!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: currentRoute.isEstimated
                      ? AppConstants.warningColor
                      : AppConstants.primaryColor,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppConstants.defaultPadding),

          // Get current location button
          ElevatedButton(
            onPressed: isLoadingCurrentLocation ? null : onGetCurrentLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(
                double.infinity,
                AppConstants.buttonHeight,
              ),
            ),
            child: isLoadingCurrentLocation
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(AppConstants.loadingText),
                    ],
                  )
                : const Text(AppConstants.getCurrentLocationButton),
          ),
        ],
      ),
    );
  }

  String _getDisplayAddress() {
    if (selectedLocation != null) {
      return selectedLocation!.address;
    } else if (currentLocation != null) {
      return currentLocation!.address;
    }
    return 'Không có thông tin vị trí';
  }
}
