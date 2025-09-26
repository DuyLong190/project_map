import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

class OsmSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final void Function(double lat, double lon, String label) onPick;

  const OsmSearchBar({
    super.key,
    required this.controller,
    required this.onPick,
  });

  @override
  State<OsmSearchBar> createState() => _OsmSearchBarState();
}

class _OsmSearchBarState extends State<OsmSearchBar> {
  final FocusNode _focusNode = FocusNode();
  final SuggestionsController<Map<String, dynamic>> _suggCtrl = SuggestionsController();

  Future<List<Map<String, dynamic>>> _search(String q) async {
    // Tránh làm mới gợi ý khi đang nhập dấu (IME composing) để không mất ký tự
    final isComposing = widget.controller.value.composing.isValid;
    if (isComposing) return [];
    final query = q.trim();
    if (query.isEmpty) return [];
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}&format=jsonv2&limit=8'
    );

    final res = await http.get(
      uri,
      headers: {
        'User-Agent': 'your-app-name/1.0 (contact: you@example.com)',
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
      },
    );

    if (res.statusCode != 200) return [];

    final String bodyUtf8 = utf8.decode(res.bodyBytes);
    final List data = jsonDecode(bodyUtf8);

    return data
        .map((e) => {
      'label': e['display_name'] as String,
      'lat': double.tryParse(e['lat'] ?? ''),
      'lon': double.tryParse(e['lon'] ?? ''),
    })
        .where((m) => m['lat'] != null && m['lon'] != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _suggCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: TypeAheadField<Map<String, dynamic>>(
        controller: widget.controller,
        focusNode: _focusNode,
        suggestionsController: _suggCtrl,

        debounceDuration: const Duration(milliseconds: 450),
        suggestionsCallback: _search,

        builder: (context, textEditingController, focusNode) => TextField(
          controller: textEditingController,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Tìm địa điểm… (OSM)',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),

        itemBuilder: (context, item) => ListTile(
          title: Text(item['label'], maxLines: 2, overflow: TextOverflow.ellipsis),
        ),

        onSelected: (item) {
          final composing = widget.controller.value.composing;
          if (!composing.isValid) {
            widget.controller.text = item['label'] as String;
          }
          _focusNode.unfocus();
          widget.onPick(
            item['lat'] as double,
            item['lon'] as double,
            item['label'] as String,
          );
        },

        // Giữ các tuỳ chọn còn lại
        hideOnEmpty: true,
        hideOnLoading: false,
        hideOnError: false,
        emptyBuilder: (context) => const ListTile(title: Text('Không có gợi ý')),
        errorBuilder: (context, error) => ListTile(title: Text('Lỗi: $error')),
      ),
    );
  }
}
