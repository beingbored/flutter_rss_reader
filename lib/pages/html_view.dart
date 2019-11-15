import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rss_reader/pages/custom_web_view.dart';

@immutable
class HtmlViewPage extends StatefulWidget {
  String title;
  String url;
  String content;

  HtmlViewPage({
    @required this.title,
    @required this.url,
    @required this.content,
  });

  @override
  _HtmlViewPageState createState() => _HtmlViewPageState();
}

class _HtmlViewPageState extends State<HtmlViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.web),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => CustomWebView(
                    title: widget.title,
                    url: widget.url,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Html(
            data: "<h1>${widget.title}</h1> ${widget.content}",
            padding: EdgeInsets.all(8.0),
            linkStyle: const TextStyle(
              color: Colors.redAccent,
              decorationColor: Colors.redAccent,
              decoration: TextDecoration.underline,
            ),
            onImageTap: (src) {
              print(src);
            },
            onLinkTap: (url) {
              print(url);
            },
          ),
        ),
      ),
    );
  }
}
