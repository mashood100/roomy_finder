// ignore_for_file: constant_identifier_names

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
