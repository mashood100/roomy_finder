import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomy_finder/utilities/data.dart';

extension on List {
  List<T> removeDupicates<T>() {
    final newList = [];

    for (var e in this) {
      if (!newList.contains(e)) newList.add(e);
    }

    return List<T>.from(this);
  }
}

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
    this.onSubmit,
    this.autofocus = false,
    this.textInputAction,
    this.fillColor,
    this.autovalidateMode,
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
  final bool autofocus;
  final bool obscureText;
  final String? hintText;
  final String? suffixText;
  final TextStyle? labelStyle;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function()? onTap;
  final void Function(String? value)? onSubmit;
  final TextInputAction? textInputAction;
  final Color? fillColor;
  final AutovalidateMode? autovalidateMode;

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
          child: TextFormField(
            autovalidateMode: autovalidateMode,
            autofocus: autofocus,
            enabled: enabled,
            readOnly: readOnly ?? false,
            initialValue: initialValue,
            obscureText: obscureText,
            decoration: InputDecoration(
              suffixIcon: suffixIcon,
              hintText: hintText,
              suffixText: suffixText,
              fillColor: fillColor,
              filled: fillColor != null,
            ),
            onChanged: onChanged,
            controller: controller,
            validator: validator,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            onTap: onTap,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmit,
          ),
        )
      ],
    );
  }
}

class InlineDropdown<T> extends StatelessWidget {
  InlineDropdown({
    super.key,
    required List<T> items,
    this.dropDownItemBuilder,
    this.labelText,
    T? value,
    this.onChanged,
    this.labelWidth,
    this.hintText,
    this.validator,
  })  : value = items.contains(value) ? value : null,
        items = items.removeDupicates();

  final List<T> items;
  final DropdownMenuItem<T> Function(T item)? dropDownItemBuilder;
  final String? labelText;
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
          width: labelText == null
              ? 0
              : labelWidth ?? MediaQuery.of(context).size.width * 0.25,
          child: labelText != null
              ? Text(
                  labelText!,
                  style: const TextStyle(fontSize: 15),
                )
              : null,
        ),
        Expanded(
          child: DropdownButtonFormField<T>(
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(5),
            iconSize: 30,
            iconEnabledColor: ROOMY_ORANGE,
            icon: const Icon(
              Icons.keyboard_arrow_down_sharp,
              color: ROOMY_ORANGE,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: ROOMY_PURPLE),
              ),
              hintText: hintText,
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
        )
      ],
    );
  }
}

class InlineSelector<T> extends StatelessWidget {
  InlineSelector({
    super.key,
    required List<T> items,
    this.getLabel,
    this.itemBuilder,
    this.labelText,
    T? value,
    this.onChanged,
    this.labelWidth,
  })  : assert(items.isNotEmpty, "Items cannot be empty"),
        value = items.contains(value) ? value : null,
        items = items.removeDupicates();

  final List<T> items;
  final String Function(T item)? getLabel;
  final Widget Function(T item)? itemBuilder;
  final void Function(T value)? onChanged;
  final T? value;
  final String? labelText;
  final double? labelWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: ROOMY_PURPLE, width: 1),
      ),
      child: Row(
        children: items.map((e) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (onChanged != null) onChanged!(e);
              },
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: value == e ? ROOMY_PURPLE : null,
                  border: Border(
                    left: e != items.first
                        ? const BorderSide(width: 1, color: ROOMY_PURPLE)
                        : BorderSide.none,
                  ),
                ),
                child: itemBuilder != null
                    ? itemBuilder!(e)
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 5),
                        child: Text(
                          getLabel != null ? getLabel!(e) : e.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: value == e ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
