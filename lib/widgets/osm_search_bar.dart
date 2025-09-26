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
  
  // Khi người dùng đang gõ dấu (ví dụ gõ 'f' để tạo 'à'), tạm thời
  // giữ việc gọi API cho đến khi họ nhấn ký tự commit (theo yêu cầu là '_').
  bool _holdUntilCommitChar = false;

  Future<List<Map<String, dynamic>>> _search(String q) async {
    // 1) Nếu đang IME composing (ví dụ vừa gõ 'f' để tạo dấu), không tìm ngay
    final isComposing = widget.controller.value.composing.isValid;
    if (isComposing) {
      _holdUntilCommitChar = true;
      return [];
    }

    // 2) Nếu trước đó có hold, chỉ tiếp tục khi người dùng gõ ký tự commit '_'
    String working = q;
    if (_holdUntilCommitChar) {
      if (working.isEmpty || !working.endsWith('_')) {
        return [];
      }
      // Bỏ '_' ra khỏi truy vấn, và bỏ hold
      working = working.substring(0, working.length - 1);
      _holdUntilCommitChar = false;
    }

    final query = working.trim();
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
          // Người dùng yêu cầu dùng '_' để commit chuỗi sau khi gõ dấu.
          // Không cập nhật gợi ý trong onChanged; logic nằm ở _search qua composing/hold.
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
