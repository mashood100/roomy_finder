import 'package:flutter/material.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/place_autocomplete.dart';

class PlaceSearchDelegate extends SearchDelegate {
  final String? initialstring;

  PlaceSearchDelegate({this.initialstring}) {
    query = initialstring ?? "";
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

// second overwrite to pop out of search menu
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

// third overwrite to show query result
  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.done) {
          if (asyncSnapshot.hasError) {
            return const Center(
              child: Text("Failed to search"),
            );
          }
          final data = asyncSnapshot.data!.toList();

          return _dataBuilder(data);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
      future: ApiService.searchPlaceAutoComplete(input: query),
    );
  }

  ListView _dataBuilder(List<PlaceAutoCompletePredicate> data) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () {
            Navigator.of(context).pop(data[index]);
          },
          title: Text(
            data[index].mainText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            data[index].secondaryText ?? "",
            style: const TextStyle(color: Colors.grey),
          ),
        );
      },
      itemCount: data.length,
    );
  }

  // last overwrite to show the
// querying process at the runtime
  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.done) {
          if (asyncSnapshot.hasError) {
            return const Center(
              child: Text("Failed to search"),
            );
          }
          final data = asyncSnapshot.data!.toList();

          return _dataBuilder(data);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
      future: ApiService.searchPlaceAutoComplete(input: query),
    );
  }
}
