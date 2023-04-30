import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/utilities/data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  // int _currentPageIndex = 0;

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Center(
      child: Image.asset(
        "assets/images/logo.png",
        height: 70,
        width: 70,
      ),
    );

    const roonyFinderText = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Roomy',
            style: TextStyle(color: ROOMY_ORANGE),
          ),
          TextSpan(text: ' '),
          TextSpan(
            text: 'FINDER',
            style: TextStyle(color: ROOMY_PURPLE),
          ),
        ],
      ),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        fontFamily: "Avro",
      ),
      textAlign: TextAlign.center,
    );

    Widget createCircle({bool hollow = true}) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: 10,
        width: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ROOMY_ORANGE, width: 1),
          color: hollow ? null : ROOMY_ORANGE,
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: PageView(
            controller: _pageController,
            // onPageChanged: (index) => setState(() => _currentPageIndex = index),
            children: [
              Column(
                children: [
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Get.offNamed("/welcome"),
                      child: const Text(
                        "Skip >>",
                        style: TextStyle(color: ROOMY_ORANGE),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  logo,
                  roonyFinderText,
                  const SizedBox(height: 20),
                  Expanded(
                    child: Image.asset(
                      "assets/images/onboarding/onboarding_1.png",
                      width: Get.width,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Looking for a room? Say no more!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Find budget friendly rooms\n easily without brokers",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      createCircle(hollow: false),
                      createCircle(),
                      createCircle(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: ROOMY_ORANGE,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        side: const BorderSide(color: ROOMY_ORANGE),
                      ),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        "Next",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Get.offNamed("/welcome"),
                      child: const Text(
                        "Skip >>",
                        style: TextStyle(color: ROOMY_ORANGE),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  logo,
                  roonyFinderText,
                  const SizedBox(height: 20),
                  Expanded(
                    child: Image.asset(
                      "assets/images/onboarding/onboarding_2.png",
                      width: Get.width,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Need a roommate? We got you!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Browse through hundreds of properties and\n find suitable roommates",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      createCircle(),
                      createCircle(hollow: false),
                      createCircle(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: ROOMY_ORANGE,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        side: const BorderSide(color: ROOMY_ORANGE),
                      ),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        "Next",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Get.offNamed("/welcome"),
                      child: const Text(
                        "Skip >>",
                        style: TextStyle(color: ROOMY_ORANGE),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // logo,
                  // roonyFinderText,
                  // const SizedBox(height: 20),
                  Expanded(
                    child: Image.asset(
                      "assets/images/onboarding/onboarding_3.png",
                      width: Get.width,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Let's find your perfect space and\n a roommate now!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  // const SizedBox(height: 10),
                  // const Text(
                  //   "Browse through hundreds of properties and\n find suitable roommates",
                  //   style: TextStyle(color: Colors.grey),
                  //   textAlign: TextAlign.center,
                  // ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      createCircle(),
                      createCircle(),
                      createCircle(hollow: false),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: ROOMY_ORANGE,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        side: const BorderSide(color: ROOMY_ORANGE),
                      ),
                      onPressed: () => Get.offNamed("/welcome"),
                      child: const Text(
                        "Get Started",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
