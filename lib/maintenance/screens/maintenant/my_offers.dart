import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/maintenance.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/maintenance.dart';
import 'package:roomy_finder/maintenance/screens/maintenant/repairs_submit.dart';
import 'package:roomy_finder/maintenance/screens/view_maintenance/details.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  bool _isLoading = false;

  final _maintenances = <Maintenance>[];

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);

      final res = await ApiService.getDio.get("/maintenances/my-offers");

      if (res.statusCode == 200) {
        final data = (res.data as List).map((e) {
          try {
            return Maintenance.fromMap(e);
          } catch (e) {
            Get.log("$e");
            return null;
          }
        });
        _maintenances.clear();
        _maintenances.addAll(data.whereType<Maintenance>());
      } else {
        showToast("Failed to load data");
      }
    } catch (e, trace) {
      Get.log("$trace");
      showToast("Failed to load data");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Offers"),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _fetchData,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(5),
            child: Builder(builder: (context) {
              if (_maintenances.isEmpty) {
                return const Center(child: Text("No data"));
              }
              return Column(
                children: _maintenances.map((e) {
                  return MaintenanceListItem(
                    maintenance: e,
                    actionButtonText: "Details",
                    onPressed: () {
                      Get.to(
                          () => ViewMaintenanceDetailsScreen(maintenance: e));
                    },
                    secondActionButtonText: "Repair Submits",
                    secondAction: () {
                      Get.to(() => RepairsSubmitsScreen(request: e));
                    },
                  );
                }).toList(),
              );
            }),
          ),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
