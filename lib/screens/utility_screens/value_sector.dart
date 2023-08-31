import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/custom_button.dart';

class ValueSelctorScreen<T> extends StatelessWidget {
  const ValueSelctorScreen({
    super.key,
    this.title,
    required this.data,
    this.currentValue,
    this.getLabel,
    this.leadingBuilder,
    this.selectionValues,
    this.confirmButtonText,
  });
  final String? title;
  final List<T> data;
  final T? currentValue;
  final String Function(T item)? getLabel;
  final Widget Function(T item)? leadingBuilder;
  final List<T>? selectionValues;
  final String? confirmButtonText;

  @override
  Widget build(BuildContext context) {
    T? selectedValue = currentValue;
    return StatefulBuilder(builder: (context, setState) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title ?? "Choose"),
          actions: [
            if (selectionValues != null) ...[
              IconButton(
                onPressed: () {
                  selectionValues!.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
              IconButton(
                onPressed: () {
                  for (var d in data) {
                    if (!selectionValues!.contains(d)) selectionValues!.add(d);
                  }

                  setState(() {});
                },
                icon: const Icon(Icons.select_all),
              ),
              TextButton(
                onPressed: () => Get.back(result: selectionValues),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ]
          ],
        ),
        body: Builder(builder: (context) {
          if (selectionValues != null) {
            return ListView.separated(
              itemBuilder: (context, index) {
                final item = data[index];
                return Builder(
                  builder: (context) {
                    return ListTile(
                      // onTap: () => Get.back(result: item),
                      leading:
                          leadingBuilder != null ? leadingBuilder!(item) : null,
                      dense: true,
                      title: Text(
                        getLabel != null ? getLabel!(item) : item.toString(),
                        style: TextStyle(
                          fontWeight: currentValue == item
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Checkbox(
                        value: selectionValues!.contains(item),
                        onChanged: (value) {
                          if (value == true) {
                            selectionValues!.add(item);
                          } else {
                            selectionValues!.remove(item);
                          }

                          setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(),
              itemCount: data.length,
            );
          }

          return ListView.separated(
            itemBuilder: (context, index) {
              if (index == data.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: CustomButton(
                    confirmButtonText ?? "Select",
                    onPressed: () {
                      Get.back(result: selectedValue);
                    },
                  ),
                );
              }
              final item = data[index];
              return Builder(
                builder: (context) {
                  return ListTile(
                    leading:
                        leadingBuilder != null ? leadingBuilder!(item) : null,
                    onTap: () {
                      if (confirmButtonText != null) {
                        selectedValue = item;
                        setState(() {});
                      } else {
                        Get.back(result: item);
                      }
                    },
                    dense: true,
                    title: Text(
                      getLabel != null ? getLabel!(item) : item.toString(),
                      style: TextStyle(
                        fontWeight: currentValue == item
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing:
                        selectedValue == item ? const Icon(Icons.check) : null,
                  );
                },
              );
            },
            separatorBuilder: (context, index) => const Divider(),
            itemCount: data.length + (confirmButtonText == null ? 0 : 1),
          );
        }),
      );
    });
  }
}
