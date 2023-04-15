import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:roomy_finder/utilities/data.dart';

class AdvertisingWidget extends StatefulWidget {
  const AdvertisingWidget({super.key});

  @override
  State<AdvertisingWidget> createState() => _AdvertisingWidgetState();
}

class _AdvertisingWidgetState extends State<AdvertisingWidget> {
  static const _list = [
    "assets/images/roommates_1.jpg",
    "assets/images/roommates_2.jpg",
    "assets/images/roommates_3.jpg",
  ];

  int _carouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CarouselSlider(
              items: _list.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.asset(
                      e,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                autoPlayInterval: const Duration(seconds: 10),
                pageSnapping: true,
                autoPlay: true,
                // viewportFraction: 1,
                onPageChanged: (index, reason) {
                  setState(() => _carouselIndex = index);
                },
                enlargeCenterPage: true,
              ),
              disableGesture: true,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_list.length, (ind) {
              return Container(
                height: 10,
                width: 10,
                margin: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ind == _carouselIndex ? ROOMY_PURPLE : Colors.grey,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
