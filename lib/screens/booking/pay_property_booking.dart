// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
// import 'package:get/get.dart';
// import 'package:roomy_finder/classes/api_service.dart';
// import 'package:roomy_finder/components/label.dart';
// import 'package:roomy_finder/controllers/loadinding_controller.dart';
// import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
// import 'package:roomy_finder/functions/snackbar_toast.dart';
// import 'package:roomy_finder/models/property_booking.dart';

// class _PayPropertyBookingController extends LoadingController {
//   final PropertyBooking booking;

//   _PayPropertyBookingController(this.booking);

//   Future<void> initPaymentSheet() async {
//     try {
//       // 1. create payment intent on the server
//       final res = await ApiService.getDio.post(
//         "/create-pay-property-intent",
//         data: {"bookingId": booking.id},
//       );

//       if (res.statusCode != 200) {
//         showConfirmDialog("Something when wrong");
//         Get.log("${res.data}}");
//         return;
//       }

//       final data = res.data;

//       // 2. initialize the payment sheet
//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           // Enable custom flow
//           customFlow: true,
//           // Main params
//           merchantDisplayName: 'Roomy Finder Property Payment',
//           paymentIntentClientSecret: data['paymentIntent'],
//           // Customer keys
//           customerEphemeralKeySecret: data['ephemeralKey'],
//           customerId: data['customer'],
//           // Extra options
//           style: Get.isDarkMode ? ThemeMode.dark : ThemeMode.light,
//         ),
//       );

//       await Stripe.instance.presentPaymentSheet();
//     } catch (e) {
//       showGetSnackbar('Error: $e');
//       rethrow;
//     }
//   }
// }

// class PayProperyBookingScreen extends StatelessWidget {
//   const PayProperyBookingScreen({
//     super.key,
//     required this.booking,
//   });
//   final PropertyBooking booking;

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(_PayPropertyBookingController(booking));
//     return Scaffold(
//       appBar: AppBar(title: const Text("Pay rent")),
//       body: Obx(() {
//         return SingleChildScrollView(
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               Column(
//                 children: [
//                   Row(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(5),
//                         child: Image.network(
//                           booking.ad.images[0],
//                           // width: double.infinity,
//                           width: 100,
//                           height: 100,
//                           fit: BoxFit.cover,
//                           errorBuilder: (ctx, e, trace) {
//                             return const SizedBox(
//                               width: 200,
//                               height: 200,
//                               child: Icon(
//                                 Icons.broken_image,
//                                 size: 50,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 20),
//                       Card(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Label(label: "Property", value: booking.ad.type),
//                             Label(label: "Rent type", value: booking.rentType),
//                             Label(
//                               label: "Rent price/${booking.ad.type}",
//                               value: "${booking.adPricePerRentype}",
//                             ),
//                             Label(
//                               label: "Quantity",
//                               value: "${booking.quantity}",
//                             ),
//                             Label(
//                               label: "Total price",
//                               value: "${booking.budget} AED",
//                             ),
//                           ],
//                         ),
//                       )
//                     ],
//                   ),
//                   const SizedBox(height: 50),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 5),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Get.back();
//                             },
//                             child: const Text("Cancel"),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: controller.initPaymentSheet,
//                             child: const Text("Pay now"),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//               if (controller.isLoading.isTrue)
//                 Card(
//                   color: Colors.purple.withOpacity(0.5),
//                   child: Container(
//                     alignment: Alignment.center,
//                     height: 200,
//                     width: 200,
//                     child: const CupertinoActivityIndicator(
//                       color: Colors.white,
//                       radius: 30,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }
