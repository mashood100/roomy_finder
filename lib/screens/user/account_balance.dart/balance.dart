import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/screens/user/account_balance.dart/withdraw.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:url_launcher/url_launcher.dart';

class UserBalanceScreen extends StatefulWidget {
  const UserBalanceScreen({super.key, this.initialPage, this.canSwicthPage});
  final int? initialPage;
  final bool? canSwicthPage;

  @override
  State<UserBalanceScreen> createState() => _UserBalanceScreenState();
}

class _UserBalanceScreenState extends State<UserBalanceScreen> {
  var _isLoading = false;
  String? stripeConnectId;

  late final StreamSubscription<RemoteMessage> fcmStream;
  late final PageController _pageController;

  final _roommyBalanceBookings = <PropertyBooking>[];
  final _accountBalanceBookings = <PropertyBooking>[];

  // For selection to pay
  final _selectedBookings = <PropertyBooking>{};

  // Account balance
  num? _accountBalance;

  // Roomy balance
  num? _roomyBalance;

  // view mode
  var _mode = "Rent Payments";
  bool get _isWithdrawMode => _mode == "Rent Payments";

  final _paypalEmailController = TextEditingController(
    text: AppController.me.email,
  );

  @override
  void initState() {
    Future.wait([
      _fetchAccountDetails(),
      _fetchAccountBalanceBookings(),
      _fetchRommyBalanceBookings(),
    ]);

    if (widget.initialPage == 0) _mode = "Rent Payments";
    if (widget.initialPage == 1) _mode = "Roomy Pay";

    _pageController = PageController(initialPage: widget.initialPage ?? 0);

    fcmStream = FirebaseMessaging.onMessage.asBroadcastStream().listen((event) {
      final data = event.data;
      // AppController.instance.haveNewMessage(false);
      switch (data["event"]) {
        case "withdraw-completed":
        case "withdraw-failed":
          Future.wait([
            _fetchAccountDetails(),
            _fetchAccountDetails(),
          ]);

          break;
        case "roomy-balance-payment-successfully":
          Future.wait([
            _fetchAccountDetails(),
            _fetchRommyBalanceBookings(),
          ]);

          break;
        default:
      }
    });
    super.initState();
  }

  void _setOverDueBookings() {
    for (var b in _roommyBalanceBookings) {
      if (b.isOverDue) _selectedBookings.add(b);
    }
  }

  Future<void> _moveToPage(int page) async {
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _paypalEmailController.dispose();
    fcmStream.cancel();
    super.dispose();
  }

  Future<void> _fetchAccountBalanceBookings() async {
    setState(() => _isLoading = true);
    try {
      final map = <String, dynamic>{
        "isPayed": true,
        "paymentServices": ["STRIPE", "PAYPAL"],
        "iamPoster": true,
      };

      final res =
          await ApiService.getDio.get("/bookings/my-bookings", data: map);
      if (res.statusCode == 200) {
        final data = (res.data as List).map((e) {
          try {
            var p = PropertyBooking.fromMap(e);
            return p;
          } catch (e) {
            // Get.log("$trace");
            return null;
          }
        });

        _accountBalanceBookings.clear();
        _accountBalanceBookings.addAll(data.whereType<PropertyBooking>());
      } else {
        showToast("Failed to load data");
      }
    } catch (e) {
      showToast("Failed to transactions");
      log(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRommyBalanceBookings() async {
    setState(() => _isLoading = true);
    try {
      final body = <String, dynamic>{
        "isRoomyBalancePaid": false,
        "isPayed": true,
        "paymentServices": ["PAY CASH"],
        "iamPoster": true,
      };

      final res =
          await ApiService.getDio.get("/bookings/my-bookings", data: body);

      if (res.statusCode == 200) {
        final data = (res.data as List).map((e) {
          try {
            var b = PropertyBooking.fromMap(e);
            return b;
          } catch (e) {
            // Get.log("$trace");
            return null;
          }
        });

        _roommyBalanceBookings.clear();
        _roommyBalanceBookings.addAll(data.whereType<PropertyBooking>());
      } else {
        showToast("Failed to load data");
      }
    } catch (e) {
      showToast("Failed to transactions bookings");
      log(e);
    } finally {
      _setOverDueBookings();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAccountDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getDio.get("/profile/account-details");

      if (res.statusCode == 200) {
        _accountBalance = res.data['accountBalance'];
        final data = res.data;
        stripeConnectId = data["stripeConnectId"];
        _accountBalance = data["accountBalance"];
        _roomyBalance = data["roomyBalance"];
      }
    } catch (e) {
      showToast("Failed to load balance");
      log(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleBookingSelected(PropertyBooking b) {
    if (b.isOverDue) return;
    if (_selectedBookings.contains(b)) {
      _selectedBookings.remove(b);
    } else {
      _selectedBookings.add(b);
    }

    setState(() {});
  }

  Future<void> _payRoomyBalance(List<PropertyBooking> bookings) async {
    if (bookings.isEmpty) return showToast("Please some bookings to pay");
    try {
      setState(() => _isLoading = true);

      final String endPoint;
      final Map data;

      endPoint = "/transactions/roomy-balance/stripe/"
          "create-pay-roomy-balance-checkout-session";
      data = {"bookingIds": bookings.map((e) => e.id).toList()};

      final res = await ApiService.getDio.post(endPoint, data: data);

      if (res.statusCode == 200) {
        showToast("Transaction initiated. Redirecting....");

        final uri = Uri.parse(res.data["paymentUrl"]);
        Get.back();

        if (await canLaunchUrl(uri)) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (res.statusCode == 400) {
        showToast(
          res.data["message"]?.toString() ?? "Something went wrong",
          duration: 10,
        );
      } else if (res.statusCode == 403) {
        showToast("Insufficient balance");
      } else {
        showConfirmDialog("Failed to initiate transaction", isAlert: true);
        Get.log("${res.data}}");
        return;
      }
    } catch (e, trace) {
      showToast("Something went wrong");
      Get.log('$trace');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const appBarBottomHeight = 130.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Balance"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, appBarBottomHeight),
          child: Container(
            height: appBarBottomHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [ROOMY_PURPLE, Colors.white],
                stops: [0.5, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                tileMode: TileMode.decal,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _isWithdrawMode
                        ? _rentPayHeaderMessage
                        : _roomyPayHeaderMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _isWithdrawMode ? 14 : 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    child: InlineSelector(
                      items: const [
                        ("Rent Payments", AssetIcons.payServicePNG),
                        ("Roomy Pay", AssetIcons.mobilePayPNG)
                      ],
                      itemBuilder: (item) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              item.$2,
                              height: 30,
                              width: 30,
                              color: _mode == item.$1
                                  ? ROOMY_ORANGE
                                  : Colors.black54,
                            ),
                            Text(
                              item.$1,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _mode == item.$1
                                    ? ROOMY_ORANGE
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        );
                      },
                      onChanged: (value) async {
                        if (widget.canSwicthPage == false) return;
                        if (_mode == value.$1) return;

                        if (value.$1 == "Rent Payments") {
                          await _moveToPage(0);
                        } else {
                          await _moveToPage(1);
                        }
                        setState(() => _mode = value.$1);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Accont balance
          PageView(
            physics: widget.canSwicthPage == false
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (value) {
              if (value == 0) {
                setState(() => _mode = "Rent Payments");
              } else {
                setState(() => _mode = "Roomy Pay");
              }
            },
            children: [
              RefreshIndicator.adaptive(
                onRefresh: () => Future.wait(
                    [_fetchAccountBalanceBookings(), _fetchAccountDetails()]),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.only(bottom: 80, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Recent Tenant Payments:"),
                      const SizedBox(height: 10),
                      if (_accountBalanceBookings.isEmpty)
                        const Center(
                          child: Text(
                            "No data for now",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      for (var b in _accountBalanceBookings)
                        Container(
                          decoration: shadowedBoxDecoration.copyWith(
                            color: Colors.white,
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${b.ad.type}, ${b.ad.location}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "paid by ${b.client.fullName}",
                                      style: const TextStyle(
                                          // fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      Jiffy.parseFromDateTime(b.createdAt)
                                          .yMMMMd,
                                      style: const TextStyle(
                                          // fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Text(
                                    //   b.paymentService.toString(),
                                    //   style: const TextStyle(fontSize: 12),
                                    // ),
                                    // Text(
                                    //   b.isPayed.toString(),
                                    //   style: const TextStyle(fontSize: 12),
                                    // ),
                                    Text(
                                      formatMoney(b.rentFee),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              RefreshIndicator.adaptive(
                onRefresh: () => Future.wait(
                    [_fetchRommyBalanceBookings(), _fetchAccountDetails()]),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: _selectedBookings.isNotEmpty ? 100 : 60,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Payable amounts to Roomy FINDER:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Please note these amounts won't affect your rental"
                        " earnings. They are deducted from tenant payments",
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 10),
                      if (_roommyBalanceBookings.isEmpty)
                        const Center(
                          child: Text(
                            "No data for now",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      for (var b in _roommyBalanceBookings)
                        Builder(builder: (context) {
                          var isSelected = _selectedBookings.contains(b);
                          return GestureDetector(
                            onTap: () {
                              _handleBookingSelected(b);
                            },
                            child: Container(
                              decoration: shadowedBoxDecoration.copyWith(
                                color: Colors.white,
                                border: b.isOverDue
                                    ? Border.all(color: Colors.red, width: 1.5)
                                    : isSelected
                                        ? Border.all(color: ROOMY_PURPLE)
                                        : null,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "${b.ad.type}, ${b.ad.location}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "paid by ${b.client.fullName}",
                                          style: const TextStyle(
                                              // fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          Jiffy.parseFromDateTime(b.createdAt)
                                              .yMMMMd,
                                          style: const TextStyle(
                                              // fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // const Text(
                                          //   "Roomy %",
                                          //   style: TextStyle(fontSize: 12),
                                          // ),
                                          // Text(
                                          //   b.paymentService.toString(),
                                          //   style: const TextStyle(fontSize: 12),
                                          // ),
                                          Text(
                                            formatMoney(b.commissionFee),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                    text: 'Rent price: '),
                                                TextSpan(
                                                  text: formatMoney(b.rentFee +
                                                      b.commissionFee),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isLoading) const LoadingPlaceholder(),
        ],
      ),
      bottomSheet: Builder(builder: (context) {
        var haveSelection = _selectedBookings.isNotEmpty;
        const borderRadius2 = BorderRadius.vertical(
          top: Radius.elliptical(30, 20),
        );
        const padding = EdgeInsets.symmetric(horizontal: 20, vertical: 5);
        const payButtonPadding = EdgeInsets.only(
          left: 20,
          right: 5,
          top: 5,
          bottom: 5,
        );

        if (_isWithdrawMode) {
          return Container(
            margin: const EdgeInsets.only(top: 1),
            padding: padding,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ROOMY_PURPLE,
              borderRadius: haveSelection ? null : borderRadius2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => const WithdrawScreen()),
                  child: Container(
                    padding: payButtonPadding,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Withdraw",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Image.asset(AssetIcons.fingerTouchPNG, height: 25)
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Builder(builder: (context) {
                      const textStyle = TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      );

                      return Text(
                        _accountBalance != null
                            ? formatMoney(_accountBalance!)
                            : "???",
                        textAlign: TextAlign.end,
                        style: textStyle,
                      );
                    }),
                    const Text(
                      "Amount paid by tenants",
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        var buttonLabel = "";

        if (_selectedBookings.any((e) => e.isOverDue)) buttonLabel = "Overdue";
        if (_selectedBookings.any((e) => !e.isOverDue)) {
          if (buttonLabel.isNotEmpty) {
            buttonLabel += " + Selected amount";
          } else {
            buttonLabel = "Selected amount";
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (haveSelection)
              Builder(builder: (context) {
                var amount = _selectedBookings
                    .map((e) => e.commissionFee)
                    .reduce((value, element) => value + element);

                return Container(
                  padding: padding,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: ROOMY_ORANGE,
                    borderRadius: borderRadius2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _payRoomyBalance([..._selectedBookings]);

                          _selectedBookings.clear();
                          setState(() {});
                        },
                        child: Container(
                          padding: payButtonPadding,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(
                              Radius.circular(30),
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Pay Part",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.chevron_right)
                            ],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Builder(builder: (context) {
                            const textStyle = TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            );

                            return Text(
                              formatMoney(amount),
                              textAlign: TextAlign.end,
                              style: textStyle,
                            );
                          }),
                          Text(
                            buttonLabel,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: padding,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ROOMY_PURPLE,
                borderRadius: haveSelection ? null : borderRadius2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_roommyBalanceBookings.isNotEmpty) {
                        _selectedBookings.clear();
                        setState(() {});
                        _payRoomyBalance([..._roommyBalanceBookings]);
                      } else {
                        showToast("Nothing to pay for now");
                      }
                    },
                    child: Container(
                      padding: payButtonPadding,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Pay Total",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.chevron_right)
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Builder(builder: (context) {
                        const textStyle = TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        );

                        return Text(
                          _roomyBalance != null
                              ? formatMoney(_roomyBalance!)
                              : "???",
                          textAlign: TextAlign.end,
                          style: textStyle,
                        );
                      }),
                      const Text(
                        "Total Amount",
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

const _roomyPayHeaderMessage = "Roomy FINDER applies service charges that "
    "are taken from tenant payments. We kindly ask you to send these amounts"
    " to Roomy. (only applicable if tenant pays by cash).";
const _rentPayHeaderMessage =
    "Track, manage, and withdraw your rental payments";
