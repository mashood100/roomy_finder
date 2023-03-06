import 'package:flutter/material.dart';
import 'package:native_pdf_view/native_pdf_view.dart';

class ViewPdfScreen extends StatefulWidget {
  const ViewPdfScreen({
    super.key,
    required this.asset,
    required this.title,
  });

  final String asset;
  final String title;

  @override
  State<ViewPdfScreen> createState() => _ViewPdfScreenState();
}

class _ViewPdfScreenState extends State<ViewPdfScreen> {
  late final PdfController _controller;
  @override
  void initState() {
    _controller = PdfController(
      document: PdfDocument.openAsset(widget.asset),
      viewportFraction: 1.5,
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: PdfView(
        controller: _controller,
        scrollDirection: Axis.vertical,
        pageSnapping: false,
        loaderSwitchDuration: const Duration(seconds: 0),
      ),
    );
  }
}
