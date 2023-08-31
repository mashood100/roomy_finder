// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';

const ROOMY_ORANGE = Color(0xFFE49429);
const ROOMY_PURPLE = Color(0xFF711785);

const shadowedBoxDecoration = BoxDecoration(
  borderRadius: BorderRadius.all(
    Radius.circular(10),
  ),
  boxShadow: [
    BoxShadow(
      blurRadius: 3,
      blurStyle: BlurStyle.outer,
      color: Colors.black54,
      spreadRadius: -1,
    ),
  ],
);

const DELETE_ACCOUNT_MESSAGE =
    "By deleting your account, all your personal information"
    " and your ads will be deleted without possibility of been"
    " recovered. It's recommended that you withdraw all the money "
    "in your account before perfomming this action because "
    "we(Roomy Finder) will not refund any money to deleted accounts.";

final urlRegex = RegExp(
  r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
);

final roomyFinderDynamicLinkDomainRegex1 = RegExp(
  r"(https?:\/\/(.+?\.)?((roomyfinder.page.link)|(roomyfinder.com))(\/[A-Za-z0-9\-\._~:\/\?#\[\]@!$&'\(\)\*\+,;\=]*)?)",
  multiLine: true,
);

const DEFAULT_ROOM_FIREBASE_LINK =
    "https://firebasestorage.googleapis.com/v0/b/"
    "roomy-finder.appspot.com/o/files%2Fdefault_room.png?"
    "alt=media&token=bea37726-a601-40e1-a734-b8ab2c663331";

const DOCUMENT_EXTENSIONS = [
  '.doc',
  '.docx',
  '.odt',
  '.rtf',
  '.txt',
  '.wpd',
  '.wps',
  '.pdf',
  '.xps',
  '.djvu',
  '.epub',
  '.mobi',
  '.fb2',
  '.xls',
  '.xlsx',
  '.ods',
  '.csv',
  '.tsv',
  '.numbers',
  '.pages',
  '.ppt',
  '.pptx',
  '.odp',
  '.key',
  '.impress',
  '.html',
  '.htm',
  '.xml',
  '.xhtml',
  '.php',
  '.asp',
  '.aspx',
  '.css',
  '.js',
  '.json',
];

const OTHER_EXTENSIONS = [
  '.zip',
  '.rar',
  '.tar',
  '.gz',
  '.7z',
  '.iso',
  '.bin',
  '.exe',
  '.msi',
  '.jar',
  '.deb',
  '.rpm',
  '.pkg',
  '.apk',
  '.sh',
  '.bat',
  '.cmd',
  '.ps1',
  '.vbs',
  '.bat',
];

const PROPERTY_ADS_NUMBERS_OF_PEOPLES = [
  "1 to 5",
  "5 to 10",
  "10 to 15",
  "15 to 20",
  "+20"
];

/// ["Male", "Female"]
const ALL_GENDERS = ["Male", "Female"];

/// ["Male", "Female", "Mix"]
const ALL_GENDERS_WITH_MIX = ["Male", "Female", "Mix"];

/// ["Monthly", "Weekly", "Daily"]
const RENT_TYPES = ["Monthly", "Weekly", "Daily"];

/// ["Early Bird", "Night Owl"]
const ALL_LIFE_STYLES = ["Early Bird", "Night Owl"];

///  ["Professional", "Student", "Other"]
const ALL_OCCUPATIONS = [
  "Working full-time",
  "Working part-time",
  "Unemployed",
  "Student",
  "Traveller",
  "Freelancer",
  "Other",
];
