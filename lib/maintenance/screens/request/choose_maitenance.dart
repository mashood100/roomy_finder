import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/maintenance_button.dart';
import 'package:roomy_finder/maintenance/all_maintenances.dart';
import 'package:roomy_finder/maintenance/helpers/get_sub_category_icon.dart';
import 'package:roomy_finder/utilities/data.dart';

class ChooseMaintenanceScreen extends StatefulWidget {
  const ChooseMaintenanceScreen({
    super.key,
    required this.category,
    required this.onFinished,
  });

  final String category;
  final void Function(String subCategory, String maintenance) onFinished;

  @override
  State<ChooseMaintenanceScreen> createState() =>
      _ChooseMaintenanceScreenState();
}

class _ChooseMaintenanceScreenState extends State<ChooseMaintenanceScreen> {
  String? subCategory;

  String? maintenance;

  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    _pageController = PageController(initialPage: _currentIndex);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex == 0) return true;

        _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.linear,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: _currentIndex == 0
              ? const Text("Unit Type")
              : Text(subCategory!.toUpperCase()),
          bottom: _currentIndex != 0
              ? null
              : PreferredSize(
                  preferredSize: Size(Get.width, 150),
                  child: Builder(builder: (context) {
                    final String asset;
                    switch (widget.category) {
                      case "Air Conditioner":
                        asset =
                            "assets/maintenance/repair_man_air_conditioner.png";
                        break;
                      case "Plumbing":
                        asset = "assets/maintenance/repair_man_plumbing.png";
                        break;
                      case "Electrical":
                        asset = "assets/maintenance/repair_man_electric.png";
                        break;
                      case "Cleaning":
                        asset = "assets/maintenance/repair_man_cleaning.png";
                        break;
                      case "Painting":
                        asset = "assets/maintenance/repair_man_painting.png";
                        break;
                      case "Handy Man":
                        asset = "assets/maintenance/repair_man_handy_man.png";
                        break;
                      default:
                        asset = "assets/maintenance/maintenance.jpg";
                    }
                    return Image.asset(
                      asset,
                      fit: BoxFit.fitWidth,
                      height: 150,
                      width: Get.width,
                    );
                  }),
                ),
          actions: [
            if (_currentIndex == 1)
              Image.asset(
                getCategoryIconsAsset(widget.category),
                height: 40,
              ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: allMaintenances
                    .where((e) => e["category"] == widget.category)
                    .map((e) => e["subCategory"].toString())
                    .toSet()
                    .map((e) {
                  return Builder(builder: (context) {
                    if (widget.category == "Cleaning" ||
                        widget.category == "Painting") {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black54),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              offset: Offset(0, 3),
                              blurRadius: 3,
                              blurStyle: BlurStyle.normal,
                              color: Colors.black38,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        child: RadioListTile(
                          value: e,
                          onChanged: (val) {
                            setState(() => subCategory = e);
                          },
                          groupValue: subCategory,
                          title: Text(e),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 0,
                          ),
                        ),
                      );
                    }
                    return ListTile(
                      onTap: () => setState(() => subCategory = e),
                      title: Text(e),
                      leading: Image.asset(
                        getSubCategoryIconsAsset(widget.category, e) ??
                            "assets/icons/info.png",
                        height: 30,
                      ),
                      trailing: subCategory == e
                          ? const Icon(
                              Icons.check_circle,
                              color: ROOMY_ORANGE,
                            )
                          : null,
                      // leading: CircleAvatar(
                      //   backgroundColor: Colors.transparent,
                      //   backgroundImage: AssetImage(
                      //     getSubCategoryIconsAsset(category, e) ??
                      //         "assets/icons/info.png",
                      //   ),
                      // ),
                    );
                  });
                }).toList(),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: allMaintenances.where((e) {
                  return e["category"] == widget.category &&
                      e["subCategory"] == subCategory;
                }).map((e) {
                  final String description;
                  if (e["description"] != null) {
                    description = e["description"].toString();
                  } else if (e["materialIncluded"] == true) {
                    description = "Material included";
                  } else {
                    description = "Material not included";
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        maintenance = e["name"].toString();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.black54),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 3,
                            blurStyle: BlurStyle.outer,
                            color: Colors.black54,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 5,
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Radio(
                                value: e["name"],
                                groupValue: maintenance,
                                onChanged: (val) {
                                  setState(() {
                                    maintenance = e["name"].toString();
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  e["name"].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              )
                            ],
                          ),
                          Text(description),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: MaintenanceButton(
          width: double.infinity,
          onPressed:
              (_currentIndex == 0 ? subCategory == null : maintenance == null)
                  ? null
                  : () {
                      if (_currentIndex == 0) {
                        if (widget.category == "Cleaning" ||
                            widget.category == "Painting") {
                          Navigator.of(context).pop();
                          widget.onFinished(subCategory!, subCategory!);
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.linear,
                          );
                        }
                      } else {
                        Navigator.of(context).pop();
                        widget.onFinished(subCategory!, maintenance!);
                      }
                    },
          label: "Continue",
        ),
      ),
    );
  }
}
