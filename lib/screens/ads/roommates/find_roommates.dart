import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/advertising.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/ads/roommates/filter.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
import 'package:roomy_finder/screens/user/public_profile.dart';
import 'package:roomy_finder/utilities/data.dart';

class FindRoommateUsersScreen extends StatefulWidget {
  const FindRoommateUsersScreen({super.key, this.initialSkip});

  final int? initialSkip;

  @override
  State<FindRoommateUsersScreen> createState() =>
      _FindRoommateUsersScreenState();
}

class _FindRoommateUsersScreenState extends State<FindRoommateUsersScreen> {
  bool _isLoading = true;
  var _hasFechError = false;
  final Map<String, dynamic> filter = <String, dynamic>{};

  final List<User> _roommates = [];

  @override
  void initState() {
    _fetchRoommates();
    super.initState();
  }

  Future<void> _showFilter() async {
    final result =
        await Get.to(() => RoommateUsersFilterScreen(oldFilter: filter));
    if (result is Map<String, dynamic>) {
      filter.clear();
      filter.addAll(result);
      _fetchRoommates(isRefresh: true);
    }
  }

  Future<void> _fetchRoommates({bool isRefresh = false}) async {
    try {
      _hasFechError = false;
      setState(() => _isLoading = true);

      var map = {
        "skip": isRefresh ? 0 : _roommates.length,
        "limit": 100,
        ...filter,
      };

      if (filter["withProfilePicture"] != null) {
        if (filter["withProfilePicture"] == "With picture") {
          map["profilePicture"] = true;
        } else {
          map["profilePicture"] = false;
        }
      }

      final res = await Dio().get(
        "$API_URL/ads/roommates",
        data: map,
      );

      // Roommate users
      final roommateUsers = (res.data as List).map((e) {
        try {
          var user = User.fromMap(e);
          return user;
        } catch (e) {
          return null;
        }
      });

      if (isRefresh) _roommates.clear();
      _roommates.addAll(roommateUsers.whereType<User>());
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");

      _hasFechError = true;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300;
    return RefreshIndicator(
      onRefresh: () => _fetchRoommates(isRefresh: true),
      child: Scaffold(
        appBar: AppBar(title: const Text("Roommates")),
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  backgroundColor: Colors.white,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 0,
                  collapsedHeight: 0,
                  expandedHeight: AppController.me.isGuest ? 330 : 280,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Column(
                      children: [
                        if (AppController.me.isGuest)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Get.offAllNamed("/login");
                                },
                                child: const Text(
                                  "REGISTER",
                                  style: TextStyle(
                                    color: ROOMY_PURPLE,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.offAllNamed("/login");
                                },
                                child: const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    color: ROOMY_ORANGE,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const Expanded(child: AdvertisingWidget()),
                        Container(
                          color: Get.theme.scaffoldBackgroundColor,
                          padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                          child: TextField(
                            readOnly: true,
                            onTap: _showFilter,
                            decoration: InputDecoration(
                              fillColor: Get.theme.scaffoldBackgroundColor,
                              hintText: "Filter by gender, budget",
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                  onTap: _showFilter,
                                  child: Image.asset(
                                    "assets/icons/filter.png",
                                    height: 30,
                                    width: 30,
                                  ),
                                ),
                              ),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(12, 10, 12, 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        Container(color: Colors.white, height: 10),
                      ],
                    ),
                  ),
                ),
                if (_hasFechError)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          const Text("Failed to fetch data"),
                          OutlinedButton(
                            onPressed: () {
                              _fetchRoommates(isRefresh: true);
                            },
                            child: const Text("Refresh"),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_roommates.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          const Text("No data."),
                          OutlinedButton(
                            onPressed: () {
                              _fetchRoommates(isRefresh: true);
                            },
                            child: const Text("Refresh"),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.25,
                  ),
                  itemBuilder: (context, index) {
                    final user = _roommates[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: RoommateUser(
                          user: user,
                          onChat: () {
                            if (AppController.me.isGuest) {
                              RoomyNotificationHelper
                                  .showRegistrationRequiredToChat();
                            } else {
                              moveToChatRoom(AppController.me, user);
                            }
                          },
                          onTap: () async {
                            if (AppController.me.isGuest) {
                              showToast("Please register to see ad details");
                              return;
                            }
                            Get.to(() => UserPublicProfile(user: user));
                          }),
                    );
                  },
                  itemCount: _roommates.length,
                ),
                if (_roommates.isNotEmpty)
                  SliverToBoxAdapter(
                    child: GetMoreButton(
                      getMore: _fetchRoommates,
                    ),
                  )
              ],
            ),
            if (_isLoading) const LoadingPlaceholder()
          ],
        ),
      ),
    );
  }
}
