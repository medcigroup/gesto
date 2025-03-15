import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PaymentWebView extends StatelessWidget {
  final String url;

  PaymentWebView({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: Uri.parse(url)),
        onWebViewCreated: (InAppWebViewController controller) {
          // Additional actions you can do with the controller
        },
        onLoadStart: (InAppWebViewController controller, Uri? url) {
          print('Loading started: $url');
        },
        onLoadStop: (InAppWebViewController controller, Uri? url) async {
          print('Loading stopped: $url');
        },
        onProgressChanged: (InAppWebViewController controller, int progress) {
          // Display the loading progress
          print('Loading progress: $progress%');
        },
      ),
    );
  }
}


