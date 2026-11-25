import 'package:flutter/material.dart';
import 'pdf_viewer_widget_stub.dart' if (dart.library.html) 'pdf_viewer_widget_web.dart' as impl;

Widget getPdfViewerWidget(String url) {
  return impl.getPdfViewer(url);
}
