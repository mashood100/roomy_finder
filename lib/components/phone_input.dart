import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:roomy_finder/controllers/app_controller.dart';

class InlinePhoneNumberInput extends StatelessWidget {
  const InlinePhoneNumberInput({
    super.key,
    this.onChange,
    this.initialValue,
    this.controller,
    this.labelText,
    this.hintText,
    this.suffixText,
    this.withSuffixIcon = true,
    this.labelWidth,
    this.labelStyle,
  });

  final PhoneNumber? initialValue;
  final void Function(PhoneNumber phoneNumber)? onChange;
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? suffixText;
  final bool withSuffixIcon;
  final double? labelWidth;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth ?? MediaQuery.of(context).size.width * 0.25,
          child: Text(
            labelText ?? '',
            style: labelStyle ?? const TextStyle(fontSize: 15),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: InternationalPhoneNumberInput(
              selectorConfig: const SelectorConfig(
                selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                // useEmoji: true,
                setSelectorButtonAsPrefixIcon: true,
                leadingPadding: 10,
              ),
              initialValue: initialValue,
              onInputChanged: onChange,
              onSaved: onChange,
              errorMessage: 'invalidPhoneNumber'.tr,
              locale: AppController.locale.languageLocale,
              textFieldController: controller,
              inputDecoration: InputDecoration(
                hintText: hintText ?? 'enterYourPhoneNumber'.tr,
                suffixText: suffixText,
                contentPadding: const EdgeInsets.all(5),
                border: InputBorder.none,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey
                    : Colors.grey.shade200,
              ),
              formatInput: false,
            ),
          ),
        ),
      ],
    );
  }
}

class PhoneNumberInput extends StatelessWidget {
  const PhoneNumberInput({
    super.key,
    this.onChange,
    this.initialValue,
    this.controller,
    this.labelText,
    this.hintText,
    this.suffixText,
    this.withSuffixIcon = true,
  });

  final PhoneNumber? initialValue;
  final void Function(PhoneNumber phoneNumber)? onChange;
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? suffixText;
  final bool withSuffixIcon;

  @override
  Widget build(BuildContext context) {
    return InternationalPhoneNumberInput(
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        // useEmoji: true,
        setSelectorButtonAsPrefixIcon: true,
        leadingPadding: 10,
      ),
      initialValue: initialValue,
      onInputChanged: onChange,
      onSaved: onChange,
      errorMessage: 'invalidPhoneNumber'.tr,
      locale: AppController.locale.languageLocale,
      textFieldController: controller,
      inputDecoration: InputDecoration(
        labelText: labelText,
        hintText: hintText ?? 'enterYourPhoneNumber'.tr,
        suffixText: suffixText,
        suffixIcon: withSuffixIcon ? const Icon(Icons.phone) : null,
        contentPadding: const EdgeInsets.all(5),
      ),
      formatInput: false,
    );
  }
}
