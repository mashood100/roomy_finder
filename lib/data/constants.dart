// ignore_for_file: constant_identifier_names

// const SERVER_URL = "http://192.168.43.34:3000";
const SERVER_URL = "http://roomy-finder-evennode.ap-1.evennode.com";

const API_URL = "$SERVER_URL/api/v1";

final priceRegex = RegExp(r'(^\d*\.?\d{0,2})');

final uaePhoneNumberRegex = RegExp(
  r"^(\+97[\s]{0,1}[\-]{0,1}[\s]{0,1}1|0)50[\s]{0,1}[\-]{0,1}[\s]{0,1}[1-9]{1}[0-9]{6}$",
);
final phoneNumberRegex = RegExp(
  r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]{9,16}$',
);
final threeNumbersRegex = RegExp(r'(^\d{3})');

final emailRegex = RegExp(
  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
);

// Dynamic links
const DYNAMIC_LINK_URL = "https://roomyfinder.page.link";

const PRIVACY_POLICY_LINK = "$SERVER_URL/public/privacy-policy";

const TERMS_AND_CONDITIONS_LINK = "$SERVER_URL/public/terms-and-conditions";

const FEED_BACK_LINK = "$SERVER_URL/public/feedback";

const SHARE_APP_LINK = "https://roomyfinder.page.link/share";

// Notification
const FINE_ROOM_PERFECT_ROOM_MATCH = "FINE_ROOM_PERFECT_ROOM_MATCH";
