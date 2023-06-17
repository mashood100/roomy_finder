import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/components/maintenance_button.dart';
import 'package:roomy_finder/models/maintenance.dart';
import 'package:roomy_finder/maintenance/screens/request/add_location.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';

class SelectDateAndTimeScreen extends StatefulWidget {
  const SelectDateAndTimeScreen({super.key, required this.request});

  final PostMaintenanceRequest request;

  @override
  State<SelectDateAndTimeScreen> createState() =>
      _SelectDateAndTimeScreenState();
}

class _SelectDateAndTimeScreenState extends State<SelectDateAndTimeScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
        appBar: AppBar(title: Text(_currentIndex == 0 ? "Date" : "Time")),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  Jiffy.parseFromDateTime(widget.request.date)
                      .format(pattern: "MMM.d")
                      .toUpperCase(),
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  Jiffy.parseFromDateTime(widget.request.date)
                      .EEEE
                      .toUpperCase(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                // TableCalendar(
                //   lastDay: DateTime.now()..add(const Duration(days: 365)),
                //   firstDay: DateTime.now()..subtract(const Duration(days: 365)),
                //   focusedDay: widget.request.date,
                //   onDaySelected: (selectedDay, focusedDay) {
                //     setState(() {
                //       widget.request.date = selectedDay;
                //     });
                //   },
                //   onFormatChanged: (format) {},
                //   startingDayOfWeek: StartingDayOfWeek.monday,
                //   onPageChanged: (focusedDay) {
                //     // No need to call `setState()` here
                //     widget.request.date = focusedDay;
                //   },
                // ),

                TableCalendar(
                  firstDay: kFirstDay,
                  lastDay: kLastDay,
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        widget.request.date = selectedDay;
                        _selectedDay = selectedDay;
                        _focusedDay = selectedDay;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    // No need to call `setState()` here
                    _focusedDay = focusedDay;
                  },
                  headerStyle: const HeaderStyle(formatButtonVisible: false),
                )
              ],
            ),
            Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  Jiffy.parseFromDateTime(widget.request.date)
                      .format(pattern: "MMM.dd")
                      .toUpperCase(),
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  Jiffy.parseFromDateTime(widget.request.date)
                      .EEEE
                      .toUpperCase(),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const Text("Please select Time"),
                const Divider(),
                TimePickerSpinner(
                  time: widget.request.date,
                  is24HourMode: false,
                  itemHeight: 80,
                  normalTextStyle: const TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                  highlightedTextStyle: const TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                  ),
                  isForce2Digits: true,
                  onTimeChange: (time) {
                    setState(() {
                      final d = widget.request.date;
                      widget.request.date = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                ),
                const Divider(),
                const Spacer(),
              ],
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: MaintenanceButton(
          width: double.infinity,
          label: "Continue",
          onPressed: () {
            if (_currentIndex == 0) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.linear,
              );
            } else {
              Get.to(() => AddLocationScreen(
                    request: widget.request,
                  ));
            }
          },
        ),
      ),
    );
  }
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month, kToday.day);
final kLastDay = DateTime(kToday.year + 1);
