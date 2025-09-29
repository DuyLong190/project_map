import 'package:flutter/material.dart';
import 'dart:io';
import '../models/place_suggestion.dart';
import '../services/places_service.dart';
import '../services/android_places_service.dart';

class PlaceSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(PlaceSuggestion) onPlaceSelected;
  final String hintText;
  final IconData prefixIcon;

  const PlaceSearchField({
    super.key,
    required this.controller,
    required this.onPlaceSelected,
    this.hintText = 'Nhập địa chỉ điểm đến...',
    this.prefixIcon = Icons.location_on,
  });

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  final PlacesService _placesService = PlacesService(
    apiKey: 'AIzaSyBJecgZLfDTdBejPAUVKtZIotX036OvIdA',
  );
  
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    debugPrint('Text changed: "$query"');
    
    if (query.length >= 2) {
      _searchPlaces(query);
    } else {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
      });
    }
  }

  // Method để mở Android Places Autocomplete
  Future<void> _openAndroidPlaces() async {
    if (Platform.isAndroid) {
      try {
        final result = await AndroidPlacesService.openPlacesAutocomplete();
        if (result != null) {
          final place = PlaceSuggestion(
            placeId: result['id'] ?? '',
            description: result['address'] ?? result['name'] ?? '',
            mainText: result['name'],
            latitude: result['latitude']?.toDouble(),
            longitude: result['longitude']?.toDouble(),
          );
          _selectPlace(place);
        }
      } catch (e) {
        debugPrint('Error opening Android Places: $e');
      }
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Searching for: $query');
      
      // Ưu tiên gọi API thật trước
      try {
        final realSuggestions = await _placesService.searchPlaces(query);
        debugPrint('Found ${realSuggestions.length} real suggestions');
        
        if (mounted) {
          setState(() {
            _suggestions = realSuggestions;
            _showSuggestions = realSuggestions.isNotEmpty;
            _isLoading = false;
          });
        }
        
        // Nếu API thật có kết quả, không cần mock data
        if (realSuggestions.isNotEmpty) {
          return;
        }
      } catch (e) {
        debugPrint('API error: $e');
      }
      
      // Chỉ dùng mock data nếu API thật không hoạt động
      final mockSuggestions = _createMockSuggestions(query);
      
      if (mounted) {
        setState(() {
          _suggestions = mockSuggestions;
          _showSuggestions = mockSuggestions.isNotEmpty;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      debugPrint('Error in _searchPlaces: $e');
      if (mounted) {
        setState(() {
          _suggestions.clear();
          _showSuggestions = false;
          _isLoading = false;
        });
      }
    }
  }

  List<PlaceSuggestion> _createMockSuggestions(String query) {
    final queryLower = query.toLowerCase();
    
    // Tạo danh sách địa điểm thật ở Việt Nam
    final mockData = [
      // Hồ Chí Minh
      PlaceSuggestion(
        placeId: 'mock1',
        description: 'Vincom Center Đồng Khởi, 72 Lê Thánh Tôn, Quận 1, TP.HCM',
        mainText: 'Vincom Center Đồng Khởi',
        secondaryText: '72 Lê Thánh Tôn, Quận 1, TP.HCM',
      ),
      PlaceSuggestion(
        placeId: 'mock2',
        description: 'Vincom Mega Mall Royal City, 72A Nguyễn Trãi, Thanh Xuân, Hà Nội',
        mainText: 'Vincom Mega Mall Royal City',
        secondaryText: '72A Nguyễn Trãi, Thanh Xuân, Hà Nội',
      ),
      PlaceSuggestion(
        placeId: 'mock3',
        description: 'Vincom Plaza Đà Nẵng, 910A Ngô Quyền, Sơn Trà, Đà Nẵng',
        mainText: 'Vincom Plaza Đà Nẵng',
        secondaryText: '910A Ngô Quyền, Sơn Trà, Đà Nẵng',
      ),
      PlaceSuggestion(
        placeId: 'mock4',
        description: 'Vincom Center Bà Triệu, 191 Bà Triệu, Hai Bà Trưng, Hà Nội',
        mainText: 'Vincom Center Bà Triệu',
        secondaryText: '191 Bà Triệu, Hai Bà Trưng, Hà Nội',
      ),
      PlaceSuggestion(
        placeId: 'mock5',
        description: 'Vincom Plaza Lê Văn Việt, 50 Lê Văn Việt, Quận 9, TP.HCM',
        mainText: 'Vincom Plaza Lê Văn Việt',
        secondaryText: '50 Lê Văn Việt, Quận 9, TP.HCM',
      ),
      // Các địa điểm khác
      PlaceSuggestion(
        placeId: 'mock6',
        description: 'Chợ Bến Thành, Lê Lợi, Quận 1, TP.HCM',
        mainText: 'Chợ Bến Thành',
        secondaryText: 'Lê Lợi, Quận 1, TP.HCM',
      ),
      PlaceSuggestion(
        placeId: 'mock7',
        description: 'Hồ Gươm, Hoàn Kiếm, Hà Nội',
        mainText: 'Hồ Gươm',
        secondaryText: 'Hoàn Kiếm, Hà Nội',
      ),
      PlaceSuggestion(
        placeId: 'mock8',
        description: 'Cầu Rồng, Nguyễn Văn Linh, Sơn Trà, Đà Nẵng',
        mainText: 'Cầu Rồng',
        secondaryText: 'Nguyễn Văn Linh, Sơn Trà, Đà Nẵng',
      ),
    ];
    
    // Lọc theo từ khóa tìm kiếm
    return mockData.where((item) => 
      (item.mainText?.toLowerCase().contains(queryLower) ?? false) ||
      (item.secondaryText?.toLowerCase().contains(queryLower) ?? false) ||
      item.description.toLowerCase().contains(queryLower)
    ).take(5).toList(); // Chỉ hiển thị tối đa 5 kết quả
  }

  void _selectPlace(PlaceSuggestion place) {
    widget.controller.text = place.description;
    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
    });
    widget.onPlaceSelected(place);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (Platform.isAndroid)
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _openAndroidPlaces,
                    tooltip: 'Tìm kiếm địa chỉ',
                  ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (widget.controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {
                        _showSuggestions = false;
                        _suggestions.clear();
                      });
                    },
                  ),
              ],
            ),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          onTap: () {
            if (_suggestions.isNotEmpty) {
              setState(() {
                _showSuggestions = true;
              });
            }
          },
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),
                  title: Text(
                    suggestion.mainText ?? suggestion.description,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: suggestion.secondaryText != null
                      ? Text(
                          suggestion.secondaryText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  onTap: () => _selectPlace(suggestion),
                  dense: true,
                );
              },
            ),
          ),
      ],
    );
  }
}
