import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/custom_button.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/booking/my_bookings.dart';
import 'package:roomy_finder/utilities/data.dart';
// import 'package:url_launcher/url_launcher.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final PropertyAd ad;

  const BookingConfirmationScreen({super.key, required this.ad});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isLoading = false;
  late final PageController _pageController;
  int _currentPaage = 0;

  // late final PropertyBooking booking;

  PropertyAd get ad => widget.ad;

  final int _quantity = 1;

  String _paymentService = "STRIPE";

  late DateTime _checkIn;
  late DateTime _checkOut;
  late String _rentType;
  num vatPercentage = AppController.me.VAT ?? 5;

  String? bookedId;

  /// The total renting fee of the booking (depends on the quantity
  /// booked and rent duration)
  num get _rentFee {
    final num fee;
    switch (_rentType) {
      case "Monthly":
        fee = ad.monthlyPrice! * _quantity * _rentPeriod;
        break;
      case "Weekly":
        fee = ad.weeklyPrice! * _quantity * _rentPeriod;
        break;
      case "Daily":
        fee = ad.dailyPrice! * _quantity * _rentPeriod;
        break;
      default:
        fee = 0;
    }
    return fee;
  }

  /// Commission fee (10% of rent fee[_rentFee])
  num get _commissionFee {
    final num fee;
    switch (_rentType) {
      case "Monthly":
        fee = ad.monthlyCommission! * _quantity * _rentPeriod;
        break;
      case "Weekly":
        fee = ad.weeklyCommission! * _quantity * _rentPeriod;
        break;
      default:
        fee = ad.dailyCommission! * _quantity * _rentPeriod;
    }
    return fee;
  }

  /// The number of periods(days,weeks,monyhs) the rent will last
  int get _rentPeriod {
    // The difference in milliseconds between the checkout and the checkin date
    final checkOutCheckInMillisecondsDifference =
        _checkOut.millisecondsSinceEpoch - _checkIn.millisecondsSinceEpoch;

    final int period;

    switch (_rentType) {
      case "Monthly":
        const oneMothDuration = 1000 * 3600 * 24 * 30;
        period =
            (checkOutCheckInMillisecondsDifference / oneMothDuration).ceil();

        break;
      case "Weekly":
        const oneWeekDuration = 1000 * 3600 * 24 * 7;
        period =
            (checkOutCheckInMillisecondsDifference / oneWeekDuration).ceil();
        break;
      default:
        const oneDayDuration = 1000 * 3600 * 24;
        period =
            (checkOutCheckInMillisecondsDifference / oneDayDuration).ceil();
        break;
    }

    return period;
  }

  num calculateFee(num percentage) {
    return (_rentFee + _commissionFee + vatPercentage) * percentage;
  }

  @override
  void initState() {
    _pageController = PageController();
    _rentType = ad.preferedRentType;
    final now = DateTime.now();

    final firstDate = DateTime(now.year, now.month, now.day);

    _checkIn = firstDate;
    _checkOut = firstDate;

    _resetDates();

    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _moveToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.decelerate,
    );
  }

  Future<DateTime?> _pickDate({bool isCheckIn = false}) async {
    final DateTime? date;

    final context = Get.context!;
    final lastDate = DateTime.now().add(const Duration(days: 365 * 100));
    final now = DateTime.now();

    final firstDate = DateTime(now.year, now.month, now.day);

    switch (_rentType) {
      case "Monthly":
        final initialDate =
            isCheckIn ? firstDate : _checkIn.add(const Duration(days: 30));
        date = await showDatePicker(
          context: context,
          lastDate: lastDate,
          firstDate:
              isCheckIn ? firstDate : _checkIn.add(const Duration(days: 30)),
          initialDate: initialDate,
          selectableDayPredicate: (day) {
            if (isCheckIn) return true;
            final difference = day.difference(_checkIn);

            return difference.inDays % 30 == 0;
          },
        );
        break;
      case "Weekly":
        final initialDate =
            isCheckIn ? firstDate : _checkIn.add(const Duration(days: 7));
        date = await showDatePicker(
          context: context,
          lastDate: lastDate,
          firstDate:
              isCheckIn ? firstDate : _checkIn.add(const Duration(days: 7)),
          initialDate: initialDate,
          selectableDayPredicate: (day) {
            if (isCheckIn) return true;
            final difference = day.difference(_checkIn);
            return difference.inDays % 7 == 0;
          },
        );
        break;
      default:
        final initialDate =
            isCheckIn ? firstDate : _checkIn.add(const Duration(days: 1));
        date = await showDatePicker(
          context: context,
          lastDate: lastDate,
          firstDate:
              isCheckIn ? firstDate : _checkIn.add(const Duration(days: 1)),
          initialDate: initialDate,
        );
    }

    return date;
  }

  void _resetDates() {
    switch (_rentType) {
      case "Monthly":
        _checkOut = (_checkIn.add(const Duration(days: 30)));
        break;
      case "Weekly":
        _checkOut = (_checkIn.add(const Duration(days: 7)));
        break;
      case "Daily":
        _checkOut = (_checkIn.add(const Duration(days: 1)));
        break;
      default:
    }

    setState(() {});
  }

  Future<void> _bookProperty() async {
    if (AppController.me.isGuest) {
      RoomyNotificationHelper.showRegistrationRequiredToBook();
      return;
    }

    try {
      setState(() => _isLoading = true);

      var data2 = {
        'adId': ad.id,
        'checkIn': _checkIn.toIso8601String(),
        'checkOut': _checkOut.toIso8601String(),
        "rentType": _rentType,
        "quantity": _quantity,
        "paymentService": _paymentService,
      };

      final res =
          await ApiService.getDio.post("/bookings/property-ad/", data: data2);

      if (res.statusCode == 200) {
        bookedId = res.data["bookingId"]?.toString();
        setState(() => _isLoading = false);

        await showConfirmDialog(
          'Your request has been send to landlord. Please go to "My Bookings" '
          'and follow on with the status of the request.',
          isAlert: true,
        );

        Get.off(() => const MyBookingsCreen());
      } else if (res.statusCode == 400) {
        setState(() => _isLoading = false);

        if (res.data['code'] == "quantity-not-enough" ||
            res.data["code"] == "quantity-not-available-within-period") {
          await RoomyNotificationHelper.showUnavailableOptonAtBooking();
        } else if (res.data["code"] == "rent-type-not-allowed") {
          RoomyNotificationHelper.showOops(
            "$_rentType is not allowed on this property",
          );
        } else {
          await RoomyNotificationHelper.showOops("Something when wrong");
        }
      } else if (res.statusCode == 404) {
        _isLoading = false;
        showToast("Ad not found. It may just been deleted by the poster");
      } else if (res.statusCode == 409) {
        _isLoading = false;
        await RoomyNotificationHelper.showOops(
          "You have already book this AD. Wait for the landlord reply",
        );
      } else {
        showToast(
          "Failed to book ad. Please try again",
          severity: Severity.error,
        );
      }
    } catch (e) {
      Get.log("$e");
      showToast(
        "Failed to book ad. Please try again",
        severity: Severity.error,
      );
    } finally {
      _isLoading = false;
      setState(() {});
    }
  }

  Future<void> cancelBooking() async {
    if (bookedId == null) return;

    final shouldContinue = await showConfirmDialog(
      "Please confirm",
    );
    if (shouldContinue != true) return;
    try {
      setState(() => _isLoading = true);

      final res = await ApiService.getDio.post(
        "/bookings/property-ad/cancel",
        data: {'bookingId': bookedId},
      );

      if (res.statusCode == 200) {
        bookedId = null;
        await showConfirmDialog(
          "Booking cancelled",
          isAlert: true,
        );
      } else if (res.statusCode == 400) {
        showToast(
          res.data["message"]?.toString() ?? "Can't cancel booking now",
          severity: Severity.error,
        );
      } else {
        showToast(
          "Failed to cancel booking. Please try again",
          severity: Severity.error,
        );
      }
    } catch (e) {
      Get.log("$e");
      showToast(
        "Failed to cancel booking. Please try again",
        severity: Severity.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentPaage == 0) return true;

        _moveToPage(_currentPaage - 1);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Booking confirmation"),
          backgroundColor: ROOMY_PURPLE,
        ),
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (ind) => _currentPaage = ind,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "When would you like to move?",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      const Text("Choose rent type", style: TextStyle()),
                      InlineDropdown<String>(
                        labelWidth: 0,
                        value: _rentType,
                        items: [
                          if (ad.monthlyPrice != null) "Monthly",
                          if (ad.weeklyPrice != null) "Weekly",
                          if (ad.dailyPrice != null) "Daily",
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _rentType = (val);
                            _resetDates();
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Check in", style: TextStyle()),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () async {
                                  final date = await _pickDate(isCheckIn: true);

                                  if (date != null) {
                                    _checkIn = (date);
                                    _resetDates();
                                  }
                                  setState(() {});
                                },
                                icon: const Icon(
                                  CupertinoIcons.calendar,
                                  color: Colors.grey,
                                ),
                                label: Text(
                                  Jiffy.parseFromDateTime(_checkIn).yMd,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Check out", style: TextStyle()),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onPressed: () async {
                                  final date = await _pickDate();

                                  if (date != null) {
                                    _checkOut = (date);
                                  }
                                  setState(() {});
                                },
                                icon: const Icon(
                                  CupertinoIcons.calendar,
                                  color: Colors.grey,
                                ),
                                label: Text(
                                  Jiffy.parseFromDateTime(_checkOut).yMd,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        "How will you like to pay?",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          (
                            label: "Pay by card",
                            value: "STRIPE",
                            asset: AssetImages.visaMasterCardPNG,
                            message:
                                "Money will be held by Roomy FINDER until you "
                                "view the apartment and confirm your booking.",
                          ),
                          (
                            label: "PayPal",
                            value: "PAYPAL",
                            asset: AssetImages.paypalBookingPNG,
                            message:
                                "Make secure payments directly through your PayPal account.",
                          ),
                          (
                            label: "Pay by cash",
                            value: "PAY CASH",
                            asset: AssetIcons.dollarBanknotePNG,
                            message:
                                "View the property first and pay in cash at "
                                "the property when you decide to book it."
                          ),
                        ].map((e) {
                          var isSelected = _paymentService == e.value;
                          return GestureDetector(
                            onTap: () {
                              _paymentService = (e.value);
                              setState(() {});
                            },
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(width: 2, color: ROOMY_PURPLE)
                                    : null,
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                                leading: Image.asset(
                                  e.asset,
                                  width: 60,
                                  color: e.value == "PAY CASH"
                                      ? Colors.green
                                      : null,
                                ),
                                title: Text(
                                  e.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  e.message,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                      CustomButton(
                        "Proceed with booking",
                        width: double.infinity,
                        onPressed: () => _moveToPage(1),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Property details
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Image.asset(
                          AssetIcons.homePNG,
                          height: 30,
                        ),
                        title: const Text(
                          "Property Details",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          (label: "Property", value: ad.type),
                          (
                            label: "Location",
                            value: ad.location,
                          ),
                          (
                            label: "Building",
                            value: ad.address["buildingName"],
                          ),
                        ]
                            .map((e) => _Label(label: e.label, value: e.value))
                            .toList(),
                      ),
                      const Divider(height: 40),

                      // Booking details
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Image.asset(
                              AssetIcons.calenderPNG,
                              height: 25,
                            ),
                            title: const Text(
                              "Booking Details",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _Label(
                            label: "Quantity booked",
                            value: "$_quantity",
                          ),
                          _Label(
                            label: "Booking date",
                            value: Jiffy.now().toLocal().yMMMd,
                          ),
                          _Label(
                            label: "Check In",
                            value: Jiffy.parseFromDateTime(_checkIn)
                                .toLocal()
                                .yMMMd,
                          ),
                          _Label(
                            label: "Check Out",
                            value: Jiffy.parseFromDateTime(_checkOut)
                                .toLocal()
                                .yMMMd,
                          ),
                        ],
                      ),

                      const Divider(height: 40),

                      // Payment details
                      Builder(builder: (context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Image.asset(
                                AssetIcons.payServicePNG,
                                height: 25,
                              ),
                              title: const Text(
                                "Payment Details",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            _Label(
                              label: "Rent price",
                              value: formatMoney(
                                (_rentFee + _commissionFee) *
                                    AppController.convertionRate,
                              ),
                            ),
                            if (ad.hasDeposit)
                              _Label(
                                label: "Deposit fee",
                                value: " ${formatMoney(
                                  ad.depositPrice! *
                                      _quantity *
                                      AppController.convertionRate,
                                )}",
                              ),
                            _Label(
                              label: "VAT",
                              value:
                                  "(${AppController.me.VAT ?? 5}%)  ${formatMoney(
                                vatPercentage * AppController.convertionRate,
                              )}",
                            ),
                            Builder(builder: (context) {
                              final serviceFee =
                                  AppController.me.serviceFee ?? 3;
                              return _Label(
                                label: "Service fee",
                                value: "($serviceFee%)  ${formatMoney(
                                  calculateFee(serviceFee / 100) *
                                      AppController.convertionRate,
                                )}",
                              );
                            }),
                            Builder(builder: (context) {
                              String paymentService;
                              switch (_paymentService) {
                                case "STRIPE":
                                  paymentService = "Credit/Debit card";
                                  break;
                                case "PAYPAL":
                                  paymentService = "Paypal";
                                  break;
                                default:
                                  paymentService = "Pay by cash";
                              }
                              return _Label(
                                label: "Payment method",
                                value: paymentService,
                              );
                            }),
                          ],
                        );
                      }),

                      const SizedBox(height: 20),

                      const Text(
                        "Please note that NO PAYMENT required "
                        "until you view the room and approve it.",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),

                      const SizedBox(height: 20),

                      if (bookedId == null)
                        ElevatedButton(
                          onPressed: _bookProperty,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ROOMY_ORANGE,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            "Confirm booking",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        OutlinedButton(
                          onPressed: cancelBooking,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text("Cancel booking"),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading) const LoadingPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.value});
  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "$value",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
