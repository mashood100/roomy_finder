import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:url_launcher/url_launcher.dart';

class ViewPdfScreen extends StatelessWidget {
  const ViewPdfScreen({
    super.key,
    required this.asset,
    required this.title,
  });

  final String asset;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SfPdfViewer.asset(
        asset,
        // onHyperlinkClicked: (details) async {
        //   var url = Uri.parse(details.uri);
        //   if (await canLaunchUrl(url)) {
        //     launchUrl(url, mode: LaunchMode.externalApplication);
        //   }
        // },
      ),
    );
  }
}
