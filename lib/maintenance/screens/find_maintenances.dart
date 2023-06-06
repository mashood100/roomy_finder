import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/maintenance.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/maintenance/helpers/maintenance.dart';
import 'package:roomy_finder/maintenance/screens/view_maintenance/view_maintenance.dart';

class FindMaintenancesScreen extends StatefulWidget {
  const FindMaintenancesScreen({super.key});

  @override
  State<FindMaintenancesScreen> createState() => _FindMaintenancesScreenState();
}

class _FindMaintenancesScreenState extends State<FindMaintenancesScreen> {
  bool _isLoading = false;

  final _maintenances = <Maintenance>[];

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);

      final data = {
        "countryCode": AppController.instance.country.value.code,
      };

      final res = await ApiService.getDio.get(
        "/maintenances/available",
        queryParameters: data,
      );

      if (res.statusCode == 200) {
        final data = (res.data as List).map((e) {
          try {
            return Maintenance.fromMap(e);
          } catch (e) {
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

    FirebaseMessaging.onMessage.asBroadcastStream().listen((event) async {
      final data = event.data;
      switch (data["event"]) {
        case "maintenance-request-new":
          final m = await ApiService.fetchMaitenance(data["maintenanceId"]);
          if (m == null) return;

          setState(() => _maintenances.insert(0, m));
          showToast("New Maintenance request");

          break;

        default:
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Maintenances"),
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
            padding: const EdgeInsets.all(10),
            child: Column(
              children: _maintenances.map((e) {
                return MaintenanceListItem(
                  maintenance: e,
                  onPressed: () {
                    Get.to(() => ViewMaintenance(maintenance: e));
                  },
                );
              }).toList(),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
