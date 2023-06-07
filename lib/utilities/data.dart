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

const DELETE_ACCOUNT_MESSAGE =
    """By deleting your account, all your personal information and your ads will be deleted without possibility of been recovered. It's recommended that you withdraw all the money in your account before perfomming this action because we(Roomy Finder) will not refund any money to deleted accounts.""";
