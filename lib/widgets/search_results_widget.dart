import 'package:flutter/material.dart';
import '../models/search_result_model.dart';
import '../constants/app_constants.dart';

class SearchResultsWidget extends StatelessWidget {
  final List<SearchResultModel> results;
  final Function(SearchResultModel) onResultTap;
  final bool isLoading;

  const SearchResultsWidget({
    super.key,
    required this.results,
    required this.onResultTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppConstants.searchResultsTitle, style: AppConstants.titleStyle),
          const SizedBox(height: AppConstants.smallPadding),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                ? Center(
                    child: Text(
                      AppConstants.noResultsText,
                      style: AppConstants.subtitleStyle,
                    ),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return _buildResultCard(result);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(SearchResultModel result) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: const Icon(
          Icons.location_on,
          color: AppConstants.endLocationColor,
        ),
        title: Text(
          result.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(result.address),
        onTap: () => onResultTap(result),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
