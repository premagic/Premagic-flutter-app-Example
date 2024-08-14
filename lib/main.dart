import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:uuid/uuid.dart';

const uuid =  Uuid();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .inversePrimary,
            title: const Text("Premagic Demo"),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'View all your photos by clicking the button below',
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const WebViewPage(
                              initialUrl:
                              'https://images-group.premagic.com/guest/D-peFVRhQ7WOEGb-EllANQ/#/gallery/public/?focus=Q86iqlAmsVVIJjzg'),
                        ),
                      ),
                  child: const Text('Get My Photos'),
                ),
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.loadRequest(Uri.parse(widget.initialUrl));
    controller.setNavigationDelegate(
        NavigationDelegate(onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
          });
        }, onPageFinished: (String url) {
          setState(() {
            _isLoading = false;
          });
        }, onNavigationRequest: (NavigationRequest request) async {
          print("Downloading the following image ${request.url}");
          final fileExtension = request.url
              .split('.')
              .last
              .toLowerCase();
          if (['jpeg', 'jpg', 'png'].contains(fileExtension)) {
            await _downloadImage(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        }));
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Photos'),
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: controller,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
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
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // TODO: use the original final instead of random uuid.
      var fileName = "${uuid.v4()}.jpg";
      await Gal.putImageBytes(response.bodyBytes, name: fileName);

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image downloaded: $fileName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download image.')),
      );
    }
  }
}
