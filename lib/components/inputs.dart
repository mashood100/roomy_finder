import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomy_finder/utilities/data.dart';

class InlineTextField extends StatelessWidget {
  const InlineTextField({
    super.key,
    this.labelText,
    this.onChanged,
    this.labelWidth,
    this.controller,
    this.initialValue,
    this.suffixIcon,
    this.validator,
    this.enabled = true,
    this.obscureText = false,
    this.hintText,
    this.suffixText,
    this.labelStyle,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly,
    this.onTap,
    this.minLines,
    this.maxLines,
  });

  final String? labelText;
  final String? initialValue;
  final void Function(String value)? onChanged;
  final double? labelWidth;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool? readOnly;
  final bool obscureText;
  final String? hintText;
  final String? suffixText;
  final TextStyle? labelStyle;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function()? onTap;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth ??
              (labelText == null
                  ? 0
                  : MediaQuery.of(context).size.width * 0.25),
          child: labelText == null
              ? null
              : Text(
                  labelText!,
                  style: labelStyle ?? const TextStyle(fontSize: 15),
                ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TextFormField(
              enabled: enabled,
              readOnly: readOnly ?? false,
              initialValue: initialValue,
              obscureText: obscureText,
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixIcon: suffixIcon,
                hintText: hintText,
                suffixText: suffixText,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey
                    : Colors.grey.shade200,
              ),
              onChanged: onChanged,
              controller: controller,
              validator: validator,
              inputFormatters: inputFormatters,
              keyboardType: keyboardType,
              onTap: onTap,
              minLines: minLines,
              maxLines: maxLines,
            ),
          ),
        )
      ],
    );
  }
}

class InlineDropdown<T> extends StatelessWidget {
  const InlineDropdown({
    super.key,
    required this.items,
    this.dropDownItemBuilder,
    required this.labelText,
    this.value,
    this.onChanged,
    this.labelWidth,
    this.hintText,
    this.validator,
  });

  final List<T> items;
  final DropdownMenuItem<T> Function(T item)? dropDownItemBuilder;
  final String labelText;
  final T? value;
  final void Function(T? value)? onChanged;
  final double? labelWidth;
  final String? hintText;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth ?? MediaQuery.of(context).size.width * 0.25,
          child: Text(
            labelText,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: DropdownButtonFormField<T>(
              borderRadius: BorderRadius.circular(10),
              iconSize: 30,
              iconEnabledColor: ROOMY_ORANGE,
              icon: const Icon(
                Icons.keyboard_arrow_down_sharp,
                color: ROOMY_ORANGE,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey
                    : Colors.grey.shade200,
              ),
              value: value,
              items: items.map((e) {
                if (dropDownItemBuilder != null) {
                  return dropDownItemBuilder!(e);
                }
                return DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    "$e",
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              validator: validator,
            ),
          ),
        )
      ],
    );
  }
}
