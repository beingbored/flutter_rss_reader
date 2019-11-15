import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rss_reader/pages/custom_web_view.dart';
import 'package:flutter_rss_reader/pages/home.dart';
import 'package:flutter_rss_reader/pages/html_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FeedPage extends StatefulWidget {
  final Feed feed;

  FeedPage(this.feed);

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feed.title),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return Future.value(0);
        },
        child: ListView.builder(
          itemCount: widget.feed.items.length,
          itemBuilder: (BuildContext context, int index) {
            FeedItem item = widget.feed.items[index];
            return ListTile(
              title: Text(item.title),
              subtitle: Text("${item.author} - ${item.publishedAt}"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => HtmlViewPage(
                      title: item.title,
                      url: item.link,
                      content: item.content,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
