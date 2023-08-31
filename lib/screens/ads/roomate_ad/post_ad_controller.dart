part of './post_roommate_ad.dart';

class _PostRoomAdController extends LoadingController {
  final RoommateAd? oldData;
  final String action;

  _PostRoomAdController({this.oldData, required this.action});

  final _movingDateController = TextEditingController();

  late final PageController _pageController;
  final _pageIndex = 0.obs;

  // Information
  final oldImages = <String>[].obs;
  final images = <XFile>[].obs;

  final oldVideos = <String>[].obs;
  final videos = <XFile>[].obs;
  final interests = <String>[].obs;
  final languages = <String>[].obs;

  final amenities = <String>[].obs;

  final information = <String, Object?>{
    "rentType": "Monthly",
    "billIncluded": false,
  }.obs;

  final aboutYou = <String, Object?>{
    // "nationality": "Arab",
    // "astrologicalSign": "ARIES",
    // "gender": AppController.me.gender,
    // "age": "",
    // "occupation": "Professional",
    // "lifeStyle": "Early Bird",
  }.obs;

  final address = <String, String?>{
    "countryCode": AppController.instance.country.value.code,
  }.obs;

  final socialPreferences = <String, Object?>{
    "grouping": "Single",
    "nationality": "Mix",
    "smoking": false,
    "cooking": false,
    "drinking": false,
    "swimming": false,
    "friendParty": false,
    "gym": false,
    "wifi": false,
    "tv": false,
    "pet": false,
  }.obs;

  @override
  void onInit() {
    information["action"] = action;
    if (oldData != null) {
      oldImages.addAll(oldData!.images);
      oldVideos.addAll(oldData!.videos);

      information["type"] = oldData!.type;
      information["rentType"] = oldData!.rentType;
      information["action"] = oldData!.action;
      information["budget"] = oldData!.budget.toString();
      information["description"] = oldData!.description;
      information["billIncluded"] = oldData!.billIncluded;

      if (oldData!.movingDate != null) {
        _movingDateController.text = _movingDateController.text =
            Jiffy.parseFromDateTime(oldData!.movingDate!).toLocal().yMEd;
      }
      if (oldData!.movingDate != null) {
        information["movingDate"] = oldData!.movingDate?.toIso8601String();
      }

      address["city"] = oldData!.address["city"] as String;
      address["location"] = oldData!.address["location"] as String;
      address["countryCode"] = oldData!.address["countryCode"] as String;

      aboutYou["nationality"] = oldData!.aboutYou["nationality"] as String?;
      aboutYou["astrologicalSign"] =
          oldData!.aboutYou["astrologicalSign"] as String?;
      aboutYou["gender"] = oldData!.aboutYou["gender"] as String?;
      if (oldData!.aboutYou["age"] != null) {
        aboutYou["age"] = oldData!.aboutYou["age"].toString();
      }
      aboutYou["occupation"] = oldData!.aboutYou["occupation"] as String?;
      aboutYou["lifeStyle"] = oldData!.aboutYou["lifeStyle"] as String?;

      languages.value =
          List<String>.from(oldData!.aboutYou["languages"] as List);
      amenities.value = List<String>.from(oldData!.amenities);
      interests.value = List<String>.from(oldData!.interests);

      socialPreferences.value = oldData!.socialPreferences;
    }
    super.onInit();
    _pageController = PageController();
  }

  @override
  void onClose() {
    _pageController.dispose();
    _movingDateController.dispose();
    super.onClose();
  }

  void _moveToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  void _moveToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  Future<void> _pickPicture({bool gallery = true}) async {
    if (images.length >= 10) return;

    try {
      final ImagePicker picker = ImagePicker();

      if (gallery) {
        final data = await picker.pickMultiImage();
        final sumImages = [...images, ...data];
        images.clear();
        if (sumImages.length <= 10) {
          images.addAll(sumImages);
        } else {
          images.addAll(sumImages.sublist(0, 9));
        }
      } else {
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) images.add(image);
      }
    } catch (e) {
      Get.log("$e");
      showGetSnackbar('someThingWhenWrong'.tr, severity: Severity.error);
    } finally {
      isLoading(false);
      update();
    }
  }

  Future<void> _pickVideo() async {
    if (videos.length >= 10) return;

    try {
      final ImagePicker picker = ImagePicker();

      final data = await picker.pickVideo(source: ImageSource.gallery);
      if (data != null) {
        videos.add(data);
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      showGetSnackbar('someThingWhenWrong'.tr, severity: Severity.error);
    } finally {
      isLoading(false);
      update();
    }
  }

  void _playVideo(String source, bool isAsset) {
    Get.to(() => PlayVideoScreen(source: source, isAsset: isAsset));
  }

  bool _validateDescription() {
    final description = information["description"];
    if (description == null) return true;

    if (uaePhoneNumberRegex.firstMatch(description.toString()) != null) {
      showToast("Description cannot contain phone number");
      return false;
    }
    if (phoneNumberRegex.firstMatch(description.toString()) != null) {
      showToast("Description cannot contain phone number");
      return false;
    }
    if (emailRegex.firstMatch(description.toString()) != null) {
      showToast("Description cannot contain emai");
      return false;
    }

    return true;
  }

  Future<void> saveAd() async {
    if (!_validateDescription()) return;

    isLoading(true);
    update();

    List<String> imagesUrls = [];
    List<String> videosUrls = [];
    try {
      aboutYou["languages"] = languages;

      final data = {
        ...information,
        "address": address,
        "aboutYou": aboutYou,
        "socialPreferences": socialPreferences,
        "amenities": amenities,
        "interests": interests,
      };

      final imagesTaskFuture = images.map((e) async {
        final index = images.indexOf(e);
        final imgRef = FirebaseStorage.instance.ref().child('images').child(
            '/${createDateTimeFileName(index)}${path.extension(e.path)}');

        final uploadTask = imgRef.putData(await File(e.path).readAsBytes());

        final imageUrl = await (await uploadTask).ref.getDownloadURL();

        return imageUrl;
      }).toList();

      imagesUrls = await Future.wait(imagesTaskFuture);

      final videoTaskFuture = videos.map((e) async {
        final index = images.indexOf(e);
        final imgRef = FirebaseStorage.instance.ref().child('videos').child(
            '/${createDateTimeFileName(index)}${path.extension(e.path)}');

        final uploadTask = imgRef.putData(await File(e.path).readAsBytes());

        final videoUrl = await (await uploadTask).ref.getDownloadURL();

        return videoUrl;
      }).toList();

      videosUrls = await Future.wait(videoTaskFuture);

      data["images"] = [...imagesUrls, ...oldImages];
      data["videos"] = videosUrls;

      if (data["description"] == null ||
          "${data["description"]}".trim().isEmpty) data.remove("description");

      if (oldData == null) {
        final res =
            await ApiService.getDio.post("/ads/roommate-ad", data: data);

        _log(res.statusCode);

        if (res.statusCode != 200) {
          deleteManyFilesFromUrl(imagesUrls);
          deleteManyFilesFromUrl(videosUrls);
        }

        switch (res.statusCode) {
          case 200:
            isLoading(false);

            await showSuccessDialog("Your Ad is posted.", isAlert: true);
            Get.offNamedUntil(
              "/my-roommate-ads",
              ModalRoute.withName('/home'),
            );
            break;
          case 500:
            showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
            break;
          default:
            showToast("Something went wrong. Please trye again");
        }
      } else {
        final res = await ApiService.getDio
            .put("/ads/roommate-ad/${oldData?.id}", data: data);
        // print(res.data["details"]);
        if (res.statusCode != 200) {
          deleteManyFilesFromUrl(imagesUrls);
          deleteManyFilesFromUrl(videosUrls);
        }

        _log(res.statusCode);

        switch (res.statusCode) {
          case 200:
            isLoading(false);
            await showSuccessDialog("Ad updated successfully.", isAlert: true);

            deleteManyFilesFromUrl(
              oldData!.images.where((e) => !oldImages.contains(e)).toList(),
            );
            deleteManyFilesFromUrl(
              oldData!.videos.where((e) => !oldVideos.contains(e)).toList(),
            );
            Get.offNamedUntil(
              "/my-roommate-ads",
              ModalRoute.withName('/home'),
            );
            break;
          case 500:
            showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
            break;
          default:
            showToast("someThingWentWrong".tr);
        }
      }
    } catch (e, trace) {
      _log(e);
      _log(trace);
      deleteManyFilesFromUrl(imagesUrls);
      deleteManyFilesFromUrl(videosUrls);
    } finally {
      isLoading(false);
      update();
    }
  }

  Future<void> addLangues() async {
    final lang = await showModalBottomSheet<String>(
      context: Get.context!,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            children: ALL_LANGUAGUES
                .where((e) => !languages.contains(e))
                .map(
                  (e) => GestureDetector(
                    onTap: () {
                      Get.back(result: e);
                    },
                    child: Card(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber.shade900,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        height: 100,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          e,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (lang == null) return;

    languages.add(lang);
  }

  Future<void> pickMovingDate() async {
    final currentValue = DateTime.tryParse("${information['movingDate']}");
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 100)),
    );

    if (date != null) {
      information["movingDate"] = date.toIso8601String();

      _movingDateController.text = Jiffy.parseFromDateTime(date).yMEd;
    }
  }
}
