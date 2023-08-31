part of "./post_property_ad.dart";

class _PostPropertyAdController extends LoadingController {
  // Input controller
  final _informationFormKey = GlobalKey<FormState>();
  final _agentBrokerFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();

  final _cityController = TextEditingController();
  final _locationController = TextEditingController();

  late final PageController _pageController;
  final _pageIndex = 0.obs;
  final needsPhotograph = false.obs;

  final PropertyAd? oldData;
  _PostPropertyAdController({this.oldData});

  // Information
  final oldImages = <String>[].obs;
  final images = <XFile>[].obs;

  final oldVideos = <String>[].obs;
  final videos = <XFile>[].obs;

  final amenities = <String>[].obs;

  PhoneNumber agentPhoneNumber = PhoneNumber();

  final information = <String, Object?>{
    "type": "Bed",
    "quantity": "1",
    "deposit": false,
    "depositPrice": null,
    "posterType": "Landlord",
    "description": "",
    "quantityGreaterThan10": false,
    "billIncluded": false,
  }.obs;

  final address = <String, String?>{
    "city": "",
    "location": "",
    "buildingName": "",
    "floorNumber": "",
    "countryCode": AppController.instance.country.value.code,
  }.obs;

  final socialPreferences = <String, Object?>{
    "numberOfPeople": "1",
    "peopleGreaterThan10": false,
    "gender": "Mix",
    "nationality": "Mix",
    "smoking": false,
    "cooking": false,
    "drinking": false,
    "visitors": false,
  }.obs;

  final agentBrokerInformation = {
    "firstName": "",
    "lastName": "",
    "email": "",
    "phone": "",
  }.obs;

  @override
  void onInit() {
    _pageController = PageController();

    if (oldData != null) {
      oldImages.addAll(oldData!.images);
      oldVideos.addAll(oldData!.videos);

      information["type"] = oldData!.type;
      information["quantity"] = oldData!.quantity.toString();
      // information["preferedRentType"] = oldData!.preferedRentType;
      if (oldData!.monthlyPrice != null) {
        information["monthlyPrice"] = oldData!.monthlyPrice.toString();
        information["monthlyPrice-selected"] = true;
      }
      if (oldData!.weeklyPrice != null) {
        information["weeklyPrice"] = oldData!.weeklyPrice.toString();
        information["weeklyPrice-selected"] = true;
      }
      if (oldData!.dailyPrice != null) {
        information["dailyPrice"] = oldData!.dailyPrice.toString();
        information["dailyPrice-selected"] = true;
      }
      information["deposit"] = oldData!.hasDeposit;
      information["depositPrice"] = oldData!.depositPrice;

      information["description"] = oldData!.description;
      information["posterType"] = oldData!.posterType;

      information["billIncluded"] = oldData!.billIncluded;

      _cityController.text =
          address["city"] = oldData!.address["city"].toString();
      _locationController.text =
          address["location"] = oldData!.address["location"].toString();
      address["buildingName"] = oldData!.address["buildingName"].toString();
      address["floorNumber"] = oldData!.address["floorNumber"].toString();
      address["countryCode"] = oldData!.address["countryCode"].toString();
      address["appartmentNumber"] =
          oldData!.address["appartmentNumber"].toString();
      amenities.value = oldData!.amenities;
    }
    super.onInit();
  }

  @override
  void onClose() {
    _pageController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    super.onClose();
  }

  void _moveToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
  }

  void _moveToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 100),
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
    } catch (e) {
      Get.log("$e");
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

    final (isValid, message) = validateAdsDescription(description.toString());

    if (message != null) showToast(message);

    return isValid;
  }

  Future<void> _savePropertyAd() async {
    if (!_validateDescription()) return;

    isLoading(true);

    List<String> imagesUrls = [];
    List<String> videosUrls = [];
    try {
      if (information["description"] == null ||
          "${information["description"]}".trim().isEmpty) {
        information.remove("description");
      }
      final data = {
        ...information,
        "address": address,
        "amenities": amenities,
        "agentInfo": agentBrokerInformation,
        "socialPreferences": socialPreferences,
        "needsPhotograph": needsPhotograph.value,
      };

      if (data["deposit"] != true) data.remove("depositPrice");

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

      data["images"] = imagesUrls;
      data["videos"] = videosUrls;

      if (data["posterType"] != "Landlord") {
        data.remove("agentInfo");
      }

      final res = await ApiService.getDio.post("/ads/property-ad", data: data);

      if (res.statusCode != 200) {
        deleteManyFilesFromUrl(imagesUrls);
        deleteManyFilesFromUrl(videosUrls);
      }

      switch (res.statusCode) {
        case 200:
          await showSuccessDialog("Your property is added.", isAlert: true);

          Get.offNamedUntil(
            "/my-property-ads",
            ModalRoute.withName('/home'),
          );

          break;
        default:
          showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
      }
    } catch (e) {
      Get.log("$e");
      deleteManyFilesFromUrl(imagesUrls);
      deleteManyFilesFromUrl(videosUrls);
    } finally {
      isLoading(false);
    }
  }

  Future<void> _upatePropertyAd() async {
    if (!_validateDescription()) return;

    isLoading(true);

    List<String> imagesUrls = [];
    List<String> videosUrls = [];

    if (information["description"] == null ||
        "${information["description"]}".trim().isEmpty) {
      information.remove("description");
    }
    try {
      final data = {
        ...information,
        "address": address,
        "amenities": amenities,
        "agentInfo": agentBrokerInformation,
        "socialPreferences": socialPreferences,
      };

      if (data["deposit"] != true) data.remove("depositPrice");

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

      data["images"] = [...oldImages, ...imagesUrls];
      data["videos"] = [...oldVideos, ...videosUrls];

      final res = await ApiService.getDio
          .put("/ads/property-ad/${oldData?.id}", data: data);

      // print(res.data["details"]);

      if (res.statusCode != 200) {
        deleteManyFilesFromUrl(imagesUrls);
        deleteManyFilesFromUrl(videosUrls);
      }

      switch (res.statusCode) {
        case 200:
          isLoading(false);
          await showSuccessDialog("Ad updated successfully. ", isAlert: true);

          deleteManyFilesFromUrl(
            oldData!.images.where((e) => !oldImages.contains(e)).toList(),
          );
          deleteManyFilesFromUrl(
            oldData!.videos.where((e) => !oldVideos.contains(e)).toList(),
          );
          Get.offNamedUntil(
            "/my-property-ads",
            ModalRoute.withName('/home'),
          );
          break;
        case 500:
          showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
          break;
        default:
          showToast("someThingWentWrong".tr);
      }
    } catch (e) {
      Get.log("$e");
      deleteManyFilesFromUrl(imagesUrls);
      deleteManyFilesFromUrl(videosUrls);
    } finally {
      isLoading(false);
    }
  }
}
