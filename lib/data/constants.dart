// ignore_for_file: constant_identifier_names

// const SERVER_URL = "http://192.168.43.34:39005";
const SERVER_URL = "http://roomyfinder.ap-1.evennode.com";

const API_URL = "$SERVER_URL/api/v1";

final passwordRegex =
    RegExp(r"^(?=.*\d)(?=.*[a-zA-Z])(?=.*[!@#$%^&*~_ ]).{6,15}$");

final userNameRegex = RegExp(r'^(?=[a-zA-Z_\- #\d]*[a-z]).{6,15}$');

final priceRegex = RegExp(r'(^\d*\.?\d{0,2})');

// Logo
const FIRE_STORE_LOGO_URL = "";

// Dynamic links
const DYNAMIC_LINK_URL = "";

const PRIVACY_POLICY_LINK = "$SERVER_URL/public/privacy-policy";
const TERMS_AND_CONDITIONS_LINK = "$SERVER_URL/public/terms-and-conditions";

const FEED_BACK_LINK = "$SERVER_URL/public/feedback";

const SHARE_APP_LINK = "https://roomfinder.page.link/share";
