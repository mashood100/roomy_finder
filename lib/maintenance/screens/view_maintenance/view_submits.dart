import 'package:flutter/material.dart';
import 'package:roomy_finder/models/maintenance.dart';

class ViewMaintenanceSubmitsScreen extends StatefulWidget {
  const ViewMaintenanceSubmitsScreen({super.key, required this.maintenance});
  final Maintenance maintenance;

  @override
  State<ViewMaintenanceSubmitsScreen> createState() =>
      _ViewMaintenanceSubmitsScreenState();
}

class _ViewMaintenanceSubmitsScreenState
    extends State<ViewMaintenanceSubmitsScreen> {
  List<Map<String, dynamic>> get _submits => widget.maintenance.submits;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sumbmits (${widget.maintenance.submits.length})"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView.separated(
          itemBuilder: (context, index) {
            return Text("Submit ${index + 1}");
          },
          itemCount: _submits.length,
          separatorBuilder: (context, index) => const Divider(),
        ),
      ),
    );
  }
}
