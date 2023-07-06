import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/models/maintenance.dart';

class MaintenanceListItem extends StatelessWidget {
  const MaintenanceListItem({
    super.key,
    required this.maintenance,
    this.onPressed,
    this.actionButtonText,
    this.secondAction,
    this.secondActionButtonText,
  });

  final Maintenance maintenance;
  final void Function()? onPressed;
  final String? actionButtonText;
  final void Function()? secondAction;
  final String? secondActionButtonText;

  @override
  Widget build(BuildContext context) {
    final address = maintenance.address;
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            if (maintenance.images.isNotEmpty)
              LoadingProgressImage(
                image: CachedNetworkImageProvider(maintenance.images[0]),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              )
            else
              Image.asset(
                "assets/maintenance/repair_2.png",
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                color: Colors.grey,
              ),
            const SizedBox(width: 10),
            DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Unit Type : ${maintenance.category}"),
                  Text("Location : ${address['location']}"),
                  Text(
                    "Status : ${maintenance.status}",
                    style: const TextStyle(color: Color(0xFFFF7B4D)),
                  ),
                  Text(
                    "Date : ${Jiffy.parseFromDateTime(maintenance.date).format(pattern: "EEE, MMM dd yyyy hh:mm aaa")}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Row(
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 30,
                        child: OutlinedButton(
                          onPressed: onPressed,
                          child: Text(actionButtonText ?? "View"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (secondAction != null)
                        SizedBox(
                          height: 30,
                          child: OutlinedButton(
                            onPressed: secondAction,
                            child: Text(secondActionButtonText ?? "Next"),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
