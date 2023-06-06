import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/maintenance.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/maintenance/helpers/maintenance.dart';
import 'package:roomy_finder/maintenance/screens/maintenant/repairs_submit.dart';
import 'package:roomy_finder/maintenance/screens/see_maintenance_offers.dart';
import 'package:roomy_finder/maintenance/screens/view_maintenance/details.dart';

class MyMaintenancesScreen extends StatefulWidget {
  const MyMaintenancesScreen({super.key});

  @override
  State<MyMaintenancesScreen> createState() => _MyMaintenancesScreenState();
}

class _MyMaintenancesScreenState extends State<MyMaintenancesScreen> {
  bool _isLoading = false;

  final _maintenances = <Maintenance>[];

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);

      final res = await ApiService.getDio.get("/maintenances/my-maintenances");

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
        case "maintenance-offer-new":
        case "maintenance-offer-submit":
        case "maintenance-paid-successfully":
          final index =
              _maintenances.indexWhere((e) => e.id == data["maintenanceId"]);

          if (index == -1) return;

          var m = _maintenances[index];

          final newM = await ApiService.fetchMaitenance(m.id);
          if (newM == null) return;

          switch (data["event"]) {
            case "maintenance-offer-new":
              setState(() => m.offers = newM.offers);
              showToast("New Maintenance offer");
              break;
            case "maintenance-offer-submit":
              setState(() => m.submits = newM.submits);
              showToast("New Maintenance submit");
              break;
            case "maintenance-paid-successfully":
              setState(() => m.isPaid = newM.isPaid);
              break;
          }

          break;

        default:
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Maintenances"),
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
            child: Column(
              children: _maintenances.map((e) {
                return MaintenanceListItem(
                  maintenance: e,
                  actionButtonText:
                      e.status == "Pending" ? 'Offers' : "Submits",
                  onPressed: () async {
                    if (e.status == "Pending") {
                      await Get.to(
                          () => SeeMaintenanceOffersScreen(request: e));
                    } else {
                      await Get.to(() => RepairsSubmitsScreen(request: e));
                    }
                    setState(() {});
                  },
                  secondAction: () => Get.to(
                      () => ViewMaintenanceDetailsScreen(maintenance: e)),
                  secondActionButtonText: 'Details',
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
