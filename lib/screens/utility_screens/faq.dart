import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/utilities/data.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int? _currentIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQ"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                AssetImagesFaq.faqPNG,
                height: 80,
              ),
            ),
            const SizedBox(height: 10),
            _HidableBox(
              title: "What is Roomy FINDER?",
              isOpen: _currentIndex == 3,
              onToggle: () => setState(() {
                if (_currentIndex == 3) {
                  _currentIndex = null;
                } else {
                  _currentIndex = 3;
                }
              }),
              child: const Padding(
                padding: EdgeInsets.all(5.0),
                child: Text(
                  "Roomy FINDER app connects potential ROOMMATES and LANDLORDS, "
                  "offering a convenient platform for renting rooms, discovering compatible "
                  "roommates, and listing property ads.",
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _DecoratedTitle(label: "ROOMMATES"),
            ..._roommateData.map((e) {
              var index = _roommateData.indexOf(e);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: _HidableBox(
                  title: e.question,
                  isOpen: _currentIndex == index,
                  onToggle: () {
                    setState(() {
                      if (_currentIndex == index) {
                        _currentIndex = null;
                      } else {
                        _currentIndex = index;
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: e.images.map((e) {
                      return Image.asset(e);
                    }).toList(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            const _DecoratedTitle(label: "LANDLORD"),
            ..._landlordData.map((e) {
              var index = _roommateData.length + _landlordData.indexOf(e);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: _HidableBox(
                  title: e.question,
                  isOpen: _currentIndex == index,
                  onToggle: () {
                    setState(() {
                      if (_currentIndex == index) {
                        _currentIndex = null;
                      } else {
                        _currentIndex = index;
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: e.images.map((e) {
                      return Image.asset(e);
                    }).toList(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            const _DecoratedTitle(label: "OTHER QUESTIONS"),
            ..._otherQuestionsData.map((e) {
              var index = _roommateData.length +
                  _landlordData.length +
                  _otherQuestionsData.indexOf(e);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: _HidableBox(
                  title: e.question,
                  isOpen: _currentIndex == index,
                  onToggle: () {
                    setState(() {
                      if (_currentIndex == index) {
                        _currentIndex = null;
                      } else {
                        _currentIndex = index;
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: e.images.map((e) {
                      return Image.asset(e);
                    }).toList(),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DecoratedTitle extends StatelessWidget {
  const _DecoratedTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    var width = label.replaceAll(" ", "").length * 11.8;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ROOMY_PURPLE,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Container(
          height: 4,
          color: ROOMY_ORANGE,
          width: width,
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: const Offset(0, -15),
            child: const Icon(
              Icons.arrow_drop_down,
              color: ROOMY_ORANGE,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }
}

class _HidableBox extends StatelessWidget {
  const _HidableBox({
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });
  final bool isOpen;
  final String title;
  final void Function() onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Colors.grey),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  isOpen ? CupertinoIcons.minus : CupertinoIcons.add,
                ),
              )
            ],
          ),
          if (isOpen) ...[
            const Divider(color: Colors.grey, thickness: 2),
            child,
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

const _roommateData = [
  (
    question: "How to make a booking?",
    images: [
      AssetImagesFaq.howToMakeBooking1PNG,
      AssetImagesFaq.howToMakeBooking2PNG,
    ],
  ),
  (
    question: "How to make payment?",
    images: [AssetImagesFaq.howToPayRoomyFinderPNG],
  ),
  (
    question: "How to cancel booking?",
    images: [AssetImagesFaq.howToCancelBookingPNG],
  ),
  (
    question: "How to post a Roommate Ad?",
    images: [
      AssetImagesFaq.howToPostRoommateAd1PNG,
      AssetImagesFaq.howToPostRoommateAd2PNG,
      AssetImagesFaq.howToPostRoommateAd3PNG,
    ],
  ),
  (
    question: "What is Have Room/Need Room?",
    images: [AssetImagesFaq.whatIsHaveNeedRoomPNG],
  ),
  (
    question: "How do I contact landlord before booking?",
    images: [AssetImagesFaq.howToContactLandlordForBookin],
  ),
];

const _landlordData = [
  (
    question: "How to post property?",
    images: [
      AssetImagesFaq.howToPostProperty1PNG,
      AssetImagesFaq.howToPostProperty2PNG,
      AssetImagesFaq.howToPostProperty3PNG,
      AssetImagesFaq.howToPostProperty4PNG,
    ],
  ),
  (
    question: "How to accept booking?",
    images: [AssetImagesFaq.howToAcceptBookingPNG],
  ),
  (
    question: "How to receive rent payment?",
    images: [AssetImagesFaq.howToRecievePaymentPNG],
  ),
  (
    question: "How to pay Roomy FINDER?",
    images: [AssetImagesFaq.howToPayRoomyFinderPNG],
  ),
];

const _otherQuestionsData = [
  (
    question: "What is premium Ad?",
    images: [AssetImagesFaq.whatIsPremiumAdPNG],
  ),
  (
    question: "What is not allowed to post?",
    images: [AssetImagesFaq.whatIsNotAllowedToPostPNG],
  ),
  (
    question: "What is VAT?",
    images: [AssetImagesFaq.whatIsVatPNG],
  ),
  (
    question: "Which services will be subject to VAT?",
    images: [AssetImagesFaq.whichServicesWillBeSubjectedT],
  ),
  (
    question: "Will VAT charges show on the invoice?",
    images: [AssetImagesFaq.willVatChargesShowOnInvoicePNG],
  ),
  (
    question: "SCAM alert:",
    images: [AssetImagesFaq.scamAlertPNG],
  ),
  (
    question: "How can I protect myself?",
    images: [AssetImagesFaq.howCanIProtectMyseltPNG],
  ),
];
