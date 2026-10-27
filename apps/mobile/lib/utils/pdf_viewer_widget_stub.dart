import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

Widget getPdfViewer(String url) {
  final isAsset = url.startsWith('assets/') || !url.startsWith('http');
  return Scaffold(
    appBar: AppBar(
      title: const Text("PDF Viewer"),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    body: isAsset
        ? const PDF().fromAsset(url)
        : const PDF().cachedFromUrl(
            url,
            placeholder: (progress) => Center(child: Text('$progress %')),
            errorWidget: (error) => Center(child: Text(error.toString())),
          ),
  );
}
