import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/maintenance_button.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/models/maintenance.dart';
import 'package:roomy_finder/maintenance/screens/request/confirmation.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key, required this.request});

  final PostMaintenanceRequest request;

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _addressFormKey = GlobalKey<FormState>();
  final address = <String, String>{};

  final bool _isLoading = false;

  @override
  void initState() {
    address.addAll(widget.request.address);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LOCATION")),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Form(
            key: _addressFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // City
                InlineDropdown<String>(
                  labelText: 'City',
                  hintText: AppController.instance.country.value.isUAE
                      ? 'Example : Dubai'
                      : "Example : Riyadh",
                  value: address["city"],
                  items: CITIES_FROM_CURRENT_COUNTRY,
                  onChanged: _isLoading
                      ? null
                      : (val) {
                          if (val == address["city"]) return;
                          if (val != null) {
                            address.remove("location");
                            address["city"] = val;
                            setState(() {});
                          }
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'thisFieldIsRequired'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Location
                InlineDropdown<String>(
                  labelText: 'Location',
                  hintText: "Select location",
                  value: address["location"],
                  items: getLocationsFromCity(
                    address["city"].toString(),
                  ),
                  onChanged: _isLoading
                      ? null
                      : (val) {
                          if (val == address["location"]) return;
                          if (val != null) {
                            address["location"] = val;
                            setState(() {});
                          }
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'thisFieldIsRequired'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Building Name
                InlineTextField(
                  labelText: "Tower name",
                  enabled: !_isLoading,
                  initialValue: address["buildingName"],
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      address["buildingName"] = value;
                    } else {
                      address.remove("buildingName");
                    }
                  },
                  labelStyle: const TextStyle(
                    fontSize: 15,
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'thisFieldIsRequired'.tr;
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 20),

                // Apartment number
                InlineTextField(
                  labelText: "Apartment number",
                  enabled: !_isLoading,
                  initialValue: address["appartmentNumber"],
                  onChanged: (value) {
                    if (int.tryParse(value) != null) {
                      address["appartmentNumber"] = value;
                    } else {
                      address.remove("appartmentNumber");
                    }
                  },
                  labelStyle: const TextStyle(
                    fontSize: 15,
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'thisFieldIsRequired'.tr;
                  //   }
                  //   return null;
                  // },
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*'),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Floor number
                InlineTextField(
                  labelText: "Floor number",
                  enabled: !_isLoading,
                  initialValue: address["floorNumber"],
                  onChanged: (value) {
                    if (int.tryParse(value) != null) {
                      address["floorNumber"] = value;
                    } else {
                      address.remove("floorNumber");
                    }
                  },
                  labelStyle: const TextStyle(
                    fontSize: 15,
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'thisFieldIsRequired'.tr;
                  //   }
                  //   return null;
                  // },
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*'),
                    )
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: MaintenanceButton(
        width: double.infinity,
        label: "Continue",
        onPressed: () {
          if (_addressFormKey.currentState?.validate() == true) {
            widget.request.address = address;
            Get.to(() => ConfirmationScreen(request: widget.request));
          }
        },
      ),
    );
  }
}
