String getCategoryIconsAsset(String category) {
  final String asset;

  switch (category) {
    case "Air Conditioner":
      asset = "assets/maintenance/ac_1.png";

      break;
    case "Plumbing":
      asset = "assets/maintenance/plumbing_7.png";
      break;
    case "Electrical":
      asset = "assets/maintenance/electric_1.png";
      break;
    case "Cleaning":
      asset = "assets/maintenance/cleaning_1.png";
      break;
    case "Painting":
      asset = "assets/maintenance/painting_1.png";
      break;
    case "Handy Man":
      asset = "assets/maintenance/hm_1.png";
      break;
    default:
      asset = "assets/maintenance/maintenance.jpg";
  }

  return asset;
}

String? getSubCategoryIconsAsset(String category, String subCategory) {
  final String? asset;

  switch (category) {
    case "Air Conditioner":
      switch (subCategory) {
        case "Central AC":
          asset = "assets/maintenance/ac_2.png";
          break;
        case "Split AC":
          asset = "assets/maintenance/ac_1.png";
          break;
        default:
          asset = null;
          break;
      }
      break;
    case "Plumbing":
      switch (subCategory) {
        case "Sink":
          asset = "assets/maintenance/plumbing_1.png";
          break;
        case "Shower":
          asset = "assets/maintenance/plumbing_2.png";
          break;
        case "Toilet":
          asset = "assets/maintenance/plumbing_6.png";
          break;
        case "Boiler":
          asset = "assets/maintenance/plumbing_4.png";
          break;
        case "Clogged Drains":
          asset = "assets/maintenance/plumbing_3.png";
          break;
        default:
          asset = null;
          break;
      }
      break;
    case "Electrical":
      switch (subCategory) {
        case "Distribution Board":
          asset = "assets/maintenance/electric_4.png";
          break;
        case "Lighting":
          asset = "assets/maintenance/electric_3.png";
          break;
        case "Switch and power outlets":
          asset = "assets/maintenance/electric_2.png";
          break;
        default:
          asset = null;
          break;
      }
      break;
    case "Cleaning":
    case "Painting":
      asset = null;
      break;
    case "Handy Man":
      switch (subCategory) {
        case "Partition building":
          asset = "assets/maintenance/hm_3.png";
          break;
        case "Locksmith":
          asset = "assets/maintenance/hm_2.png";
          break;
        default:
          asset = null;
          break;
      }
      break;
    default:
      asset = "assets/maintenance/maintenance.jpg";
  }

  return asset;
}
