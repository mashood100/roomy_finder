import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/utils.dart';

class GetMoreButton extends StatelessWidget {
  const GetMoreButton({
    Key? key,
    this.getMore,
    this.text,
  }) : super(key: key);

  final Function()? getMore;
  final String? text;

  @override
  Widget build(BuildContext context) {
    var isGettingMore = false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: StatefulBuilder(builder: (context, setState) {
        return TextButton.icon(
          onPressed: isGettingMore
              ? null
              : () async {
                  try {
                    setState(() => isGettingMore = true);
                    if (getMore != null) await Future.value(getMore!());
                  } finally {
                    setState(() => isGettingMore = false);
                  }
                },
          label: Text(text ?? "getMore".tr),
          icon: isGettingMore
              ? const CupertinoActivityIndicator()
              : const Icon(Icons.add),
        );
      }),
    );
  }
}
