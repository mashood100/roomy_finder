import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/find_roommates.dart';
import 'package:roomy_finder/screens/booking/my_bookings.dart';
import 'package:roomy_finder/screens/booking/view_property_booking.dart';
import 'package:roomy_finder/screens/user/account_balance.dart/balance.dart';
import 'package:roomy_finder/screens/user/view_profile.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomyNotificationHelper {
  static Future<void> _payRent(PropertyBooking booking) async {
    String? service = booking.paymentService;

    if (service == null) {
      return showToast("Please choose payament service");
    }

    try {
      switch (service) {
        case "STRIPE":
        case "PAYPAL":
          final String endPoint;

          if (service == "STRIPE") {
            endPoint =
                "/bookings/property-ad/stripe/create-pay-booking-checkout-session";
          } else if (service == "PAYPAL") {
            endPoint = "/bookings/property-ad/paypal/create-payment-link";
          } else {
            return;
          }
          // 1. create payment intent on the server
          final res = await ApiService.getDio.post(
            endPoint,
            data: {"bookingId": booking.id},
          );

          if (res.statusCode == 409) {
            showToast("Rent already paid");
            booking.isPayed = true;
            Get.back();
          } else if (res.statusCode == 200) {
            showToast("Payment initiated. Redirecting....");

            final uri = Uri.parse(res.data["paymentUrl"]);

            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }

            Get.back();
          } else {
            showToast("Something went wrong");
            Get.log("${res.data}}");
            return;
          }

          break;

        case "ROOMY_FINDER_CARD":
          showGetSnackbar("Payment with Roomy Finder Card is comming soon!");
          break;
        case "PAY CASH":
          final res = await ApiService.getDio.post(
            "/bookings/property-ad/pay-cash",
            data: {"bookingId": booking.id},
          );
          if (res.statusCode == 200) {
            await showConfirmDialog(
              "Congratulations. You can now see the landlord information",
              isAlert: true,
            );
            booking.isPayed = true;
            Get.back(result: true);
            return;
          } else if (res.statusCode == 409) {
            await showConfirmDialog("Booking already paid", isAlert: true);
            booking.isPayed = true;
            Get.back(result: true);
          } else {
            showConfirmDialog("Something when wrong", isAlert: true);
            Get.log("${res.data}}");
          }
          break;
        default:
      }
    } catch (e) {
      showConfirmDialog("Something went wrong", isAlert: true);
      showGetSnackbar('Error: $e');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String message,
    String? buttonLabel,
    String? assetImage,
    void Function()? onButtonPressed,
  }) async {
    final context = Get.context;
    if (context == null) return showToast(message);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          surfaceTintColor: Colors.white,
          titlePadding: EdgeInsets.zero,
          title: Container(
            decoration: const BoxDecoration(
              color: ROOMY_PURPLE,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 50),
                const Spacer(),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Image.asset(AssetIcons.bellPNG, height: 40),
                ),
                const Spacer(),
                IconButton(
                  onPressed: Navigator.of(context).pop,
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
          ),
          buttonPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(),
                    ),
                    if (assetImage != null)
                      Image.asset(
                        assetImage,
                        height: 200,
                      )
                    else
                      const SizedBox(height: 30),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (buttonLabel != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      color: ROOMY_PURPLE,
                      height: 70,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ROOMY_ORANGE,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        side: const BorderSide(color: ROOMY_ORANGE),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onButtonPressed != null) onButtonPressed();
                      },
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  color: ROOMY_PURPLE,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// General
  static Future<void> showRegistrationRequiredToChat() async {
    return showNotification(
      title: "Registration required!",
      message: "Register now to find your perfect space!",
      buttonLabel: "REGISTER",
      onButtonPressed: () => Get.toNamed("/registration"),
      assetImage: AssetImages.registerNotificationPNG,
    );
  }

  static Future<void> showRegistrationRequiredToBook() async {
    return showNotification(
      title: "Registration required!",
      message: "Register now to start connecting people!",
      buttonLabel: "REGISTER",
      assetImage: AssetImages.registerNotificationPNG,
      onButtonPressed: () => Get.toNamed("/registration"),
    );
  }

// Landlord
  static Future<void> showLandlordWelcome() async {
    return showNotification(
      title: "Welcome to Roomy FINDER!",
      message: "Start posting your rooms for Free!",
      buttonLabel: "POST AD",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () => Get.to(() => const PostPropertyAdScreen()),
    );
  }

  static Future<void> showLandlordStartMangingYourSpace() async {
    return showNotification(
      title: "Start Managing your Account!",
      message: "Check out your account page where you can see ads,"
          " bookings, and account balance.",
      buttonLabel: "MY ACCOUNT",
      assetImage: AssetImages.createProfileNotificationPNG,
      onButtonPressed: () => Get.to(() => const ViewProfileScreen()),
    );
  }

  static Future<void> showLandlordHaveNotYetPosted() async {
    return showNotification(
      title: "Haven't posted yet?",
      message: "Post a Free ad and attract more tenants!",
      buttonLabel: "POST AD",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () => Get.to(() => const PostPropertyAdScreen()),
    );
  }

  static Future<void> showLandlordNewBooking(PropertyBooking booking) async {
    return showNotification(
      title: "Congratulations!",
      message: "You got a new booking at ${booking.ad.address["location"]}."
          " Go to My Bookings to proceed.",
      buttonLabel: "VIEW BOOKING",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () {
        Get.to(() => ViewPropertyBookingScreen(b: booking));
      },
    );
  }

  static Future<void> showLandlordBookingRemider() async {
    return showNotification(
      title: "Reminder!",
      message: "Check your Bookings and start chatting with tenants!.",
      buttonLabel: "VIEW BOOKING",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () {
        Get.to(() => const MyBookingsCreen());
      },
    );
  }

  static Future<void> showLandlordMissedBooking(PropertyBooking booking) async {
    return showNotification(
      title: "Missed Booking",
      message: "You did not accept the booking on time,"
          " so the request was rejected automatically",
      buttonLabel: "VIEW BOOKING",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () {
        Get.to(() => ViewPropertyBookingScreen(b: booking));
      },
    );
  }

  static Future<void> showLandlordMessageForPaidCashBooking(
    PropertyBooking booking,
  ) async {
    return showNotification(
      title: "Message from Tenant!",
      message: "Dear ${booking.poster.fullName}, a client "
          "at ${booking.ad.address["location"]} has chosen to pay by cash."
          " Check your Bookings and start chatting with tenants",
      buttonLabel: "VIEW BOOKING",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () {
        Get.to(() => ViewPropertyBookingScreen(b: booking));
      },
    );
  }

  static Future<void> showLandlordMessageForOnlineBookingPayment(
    PropertyBooking booking,
  ) async {
    return showNotification(
      title: "Message from Tenant!",
      message: "Dear ${booking.poster.fullName}, a client "
          "at ${booking.ad.address["location"]} has made a payment."
          " Please check your account balance to withdraw funds.",
      buttonLabel: "VIEW BOOKING",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () {
        Get.to(() => ViewPropertyBookingScreen(b: booking));
      },
    );
  }

  static Future<void> showLandlordMessageForTenantCommingSoon(
    PropertyBooking booking,
  ) async {
    return showNotification(
      title: "Tenant is coming!",
      message:
          "Tenant for ${booking.ad.type} in ${booking.ad.address["location"]} is "
          "coming today! Please make sure your room is ready.",
      buttonLabel: "VIEW BOOKING",
      assetImage: AssetImages.fineRoomNotificationPNG,
      onButtonPressed: () {
        Get.to(() => ViewPropertyBookingScreen(b: booking));
      },
    );
  }

// Roommate

  static Future<void> showRoommateWelcome() async {
    return showNotification(
      title: "Welcome to Roomy FINDER!",
      message:
          "Check out room & roommate offers and place your own ads for Free!",
      assetImage: AssetImages.fineRoomNotificationPNG,
    );
  }

  static Future<void> showStillNeedToFindRoommate() async {
    return showNotification(
      title: "Still did not find your Roommate?",
      message: "Check latest offers from NEED ROOM ads to find a perfect one!",
      assetImage: AssetImages.roommateNotificationPNG,
    );
  }

  /// In the next 24 hours after registration
  static Future<void> showTooExpensiiveToLiveAlone() async {
    return showNotification(
      title: "Too expensive to live alone?",
      message: "Find a perfect match to share the space, "
          "split bills, and create unforgettable memories!",
      buttonLabel: "FIND ROOMMATE",
      assetImage: AssetImages.roommateNotificationPNG,
      onButtonPressed: () {
        Get.to(
            () => const FindRoommateAdsScreen(filter: {"action": "NEED ROOM"}));
      },
    );
  }

  /// In 24 hours after registration and repeat every 3 days
  static Future<void> showStillDiNotFindYourPlace() async {
    return showNotification(
      title: "Still did not find your Place?",
      message: "Discover latest sharing options and find your place now!",
      buttonLabel: "FIND ROOM",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () {
        Get.to(() => const FindPropertiesAdsScreen());
      },
    );
  }

  /// In 10 minutes after registration, and repeat every 7 days
  static Future<void> showLookingForRoom() async {
    return showNotification(
      title: "Looking for Rooms?",
      message:
          "Check out our new sharing offers including beds, partitions, and rooms!",
      buttonLabel: "FIND ROOM",
      assetImage: AssetImages.roommateNotificationPNG,
      onButtonPressed: () {
        Get.to(() => const FindPropertiesAdsScreen());
      },
    );
  }

  /// Immediately
  static Future<void> showUnavailableOptonAtBooking() async {
    return showNotification(
      title: "Oops!",
      message: "All the available units at this property have been "
          "taken but keep exploring for more options nearby!",
      assetImage: AssetImages.oopsNotificationPNG,
    );
  }

  /// Immediately
  static Future<void> showDeclinedBooking() async {
    return showNotification(
      title: "Oops!",
      message: "Unfortunately, landlord declined your request."
          " Try to book another room",
      buttonLabel: "FIND ROOM",
      assetImage: AssetImages.oopsNotificationPNG,
      onButtonPressed: () {
        Get.to(() => const FindPropertiesAdsScreen());
      },
    );
  }

  /// Immediately
  static Future<void> showBookingStarted(PropertyBooking booking) async {
    return showNotification(
      title: "Booking Started!",
      message: "Dear ${booking.client.fullName}, your renting period"
          " at ${booking.ad.address["location"]} has started.",
      assetImage: AssetImages.postAdNotificationPNG,
    );
  }

  /// Immediately
  static Future<void> showBookingOffered(PropertyBooking booking) async {
    return showNotification(
      title: "Congratulations!",
      message: "Your rent request has been approved by landlord."
          " Enjoy flexible payment options - pay by card or cash."
          " See landlord details and check-in to your new place now!",
      buttonLabel: "VIEW BOOKING",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () {
        Get.to(() => ViewPropertyBookingScreen(b: booking));
      },
    );
  }

  /// On the 26, 27, 28, 29 day of the booking,
  /// in case he did not book again. One at 10 AM and second at 8 PM
  static Future<void> showGetDiscount(PropertyBooking booking) async {
    return showNotification(
      title: "Get Discount!",
      message: "Book your room again for one more month and enjoy \$ discount",
      buttonLabel: "VIEW BOOKING",
      assetImage: AssetImages.postAdNotificationPNG,
      onButtonPressed: () {
        Get.to(() => ViewPropertyBookingScreen(b: booking));
      },
    );
  }

  static showOops(String message) {
    return showNotification(
      title: "Oops!",
      message: message,
      assetImage: AssetImages.oopsNotificationPNG,
    );
  }

  static Future<void> showBookingAcceptanceDialog(
    PropertyBooking booking,
  ) async {
    final context = Get.context;
    if (context == null) return;

    String message = "Booking of ${booking.ad.type} located at "
        "${booking.ad.address['location']} have been accepted.\n";

    if (booking.paymentService == "PAY CASH") {
      message +=
          "You have selected 'Pay Cash at property' as your chosen payment method";
    } else if (booking.paymentService == null) {
      message += 'Choose a payment method';
    } else if (booking.paymentService == "STRIPE") {
      message +=
          "You have selected 'Pay via credit card' as your chosen payment method";
    } else {
      message += "You have selected 'Paypal' as your chosen payment method";
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          surfaceTintColor: Colors.white,
          titlePadding: EdgeInsets.zero,
          title: Container(
            decoration: const BoxDecoration(
              color: ROOMY_PURPLE,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 50),
                const Spacer(),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Image.asset(AssetIcons.bellPNG, height: 40),
                ),
                const Spacer(),
                IconButton(
                  onPressed: Navigator.of(context).pop,
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
          ),
          buttonPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Booking Payment",
                      style: TextStyle(),
                    ),
                    Image.asset(
                      AssetImages.postAdNotificationPNG,
                      height: 200,
                    ),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    color: ROOMY_PURPLE,
                    height: 70,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Expanded(
                      //   child: Center(
                      //     child: TextButton(
                      //       onPressed: () {
                      //         Navigator.of(context).pop();
                      //         Get.to(() =>
                      //             PayProperyBookingScreen(booking: booking));
                      //       },
                      //       child: const Text(
                      //         "Change payment method",
                      //         textAlign: TextAlign.center,
                      //         style:
                      //             TextStyle(fontSize: 12, color: ROOMY_ORANGE),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(width: 20),
                      Expanded(
                        child: Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ROOMY_ORANGE,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              side: const BorderSide(color: ROOMY_ORANGE),
                              padding: const EdgeInsets.all(12),
                            ),
                            onPressed: booking.paymentService == null
                                ? null
                                : () {
                                    Navigator.of(context).pop();

                                    if (!booking.isPayed) _payRent(booking);
                                  },
                            child: const Text(
                              "Continue",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  color: ROOMY_PURPLE,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  /// Show when dashboard is blocked
  static Future<void> showDashBoardIsBlocked() async {
    final context = Get.context;
    if (context == null) return;

    const message = "To continue using our app, please send the service fee"
        " for rent you recieved from your tenant to Roomy FINDER "
        "in the \"Roomy Pay\" section.\nThanks you for your cooperation";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          surfaceTintColor: Colors.white,
          titlePadding: EdgeInsets.zero,
          title: Container(
            decoration: const BoxDecoration(
              color: ROOMY_PURPLE,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 50),
                const Spacer(),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Image.asset(AssetIcons.bellPNG, height: 40),
                ),
                const Spacer(),
                IconButton(
                  onPressed: Navigator.of(context).pop,
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
          ),
          buttonPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "ATTENTION",
                      style: TextStyle(fontSize: 20, color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    const Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Image.asset(AssetIcons.mobilePayPNG, height: 80),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    color: ROOMY_PURPLE,
                    height: 70,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ROOMY_ORANGE,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              side: const BorderSide(color: ROOMY_ORANGE),
                              padding: const EdgeInsets.all(12),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();

                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const UserBalanceScreen(
                                    canSwicthPage: false,
                                    initialPage: 1,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "Make Payment",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  color: ROOMY_PURPLE,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
