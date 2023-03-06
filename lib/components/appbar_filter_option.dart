import 'package:flutter/material.dart';

class AppBarFilterOptionData<T> {
  AppBarFilterOptionData({required this.value, required this.label});
  final T value;
  final String label;
}

class AppBarFilterOptions<T> extends StatefulWidget {
  const AppBarFilterOptions({
    super.key,
    required this.options,
    required this.onChange,
    this.initialIndex = 0,
    this.selectedColor = const Color.fromARGB(255, 124, 119, 119),
  }) : assert(options.length > 0);

  final List<AppBarFilterOptionData<T>> options;
  final void Function(T value) onChange;
  final int initialIndex;
  final Color selectedColor;

  @override
  State<AppBarFilterOptions<T>> createState() => _AppBarFilterOptionsState<T>();
}

class _AppBarFilterOptionsState<T> extends State<AppBarFilterOptions<T>> {
  var _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return _OptionsWrapper(
      children: [
        for (int i = 0; i < widget.options.length; i++)
          Builder(builder: (context) {
            return GestureDetector(
              onTap: () {
                _currentIndex = i;
                widget.onChange(widget.options[i].value);
                setState(() {});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(50),
                  color: i == _currentIndex
                      ? widget.selectedColor
                      : widget.selectedColor.withOpacity(0.1),
                ),
                child: Text(widget.options[i].label),
              ),
            );
          })
      ],
    );
  }
}

class _OptionsWrapper extends StatelessWidget {
  const _OptionsWrapper({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.length < 5) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: children,
      ),
    );
  }
}
