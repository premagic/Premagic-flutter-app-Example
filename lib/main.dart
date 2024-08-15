import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

final regex = RegExp(r"""filename\*?=['"]?(?:UTF-\d['"]*)?([^;\r\n"']*)['"]?;?""");

void main() {
  runApp(const PremagicWebViewDemoApp());
}

class PremagicWebViewDemoApp extends StatelessWidget {
  const PremagicWebViewDemoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premagic Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Premagic Demo"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'View all your photos by clicking the button below',
              ),
              Builder(builder: (context) {
                return ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WebViewPage(
                        initialUrl:
                            'https://images-group.premagic.com/guest/D-peFVRhQ7WOEGb-EllANQ/#/gallery/public/?focus=Q86iqlAmsVVIJjzg',
                      ),
                    ),
                  ),
                  child: const Text('Get My Photos'),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class WebViewPage extends StatefulWidget {
  final String initialUrl;

  const WebViewPage({super.key, required this.initialUrl});

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.initialUrl))
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: (NavigationRequest request) async {
          final fileExtension = request.url.split('.').last.toLowerCase();
          if (['jpeg', 'jpg', 'png'].contains(fileExtension)) {
            await _downloadImage(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        }),
      );
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Photos'),
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }

  Future<void> _downloadImage(String url) async {
    // Request storage permissions.
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      await Gal.requestAccess();
    }
    // Fetch the image data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading image...')),
    );
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // Get filename from the header or generate a random string.
      final filename = tryDecodeFileName(response) ?? "${generateRandomString(10)}.JPG";
      await Gal.putImageBytes(response.bodyBytes, name: filename);

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image downloaded: $filename')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download image.')),
      );
    }
  }

  String? tryDecodeFileName(http.Response response) {
    final String? headerValue = response.headers['content-disposition'];
    if (headerValue != null) {
      String filename = Uri.decodeFull(headerValue);
      final matches = regex.firstMatch(filename);
      return matches?.group(1);
    }
    return null;
  }

  String generateRandomString(int len) {
    final random = Random();
    return String.fromCharCodes(List.generate(len, (index) => random.nextInt(33) + 89));
  }
}
