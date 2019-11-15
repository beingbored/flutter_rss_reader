import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rss_reader/pages/home.dart';
import 'package:flutter_rss_reader/pages/html_view.dart';
import 'package:sqflite/sqflite.dart';

class FeedPage extends StatefulWidget {
  final Feed feed;

  FeedPage(this.feed);

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<FeedItem> feedItems = [];

  @override
  void initState() {
    super.initState();
    readItems(widget.feed.id).then((items) {
      items.forEach((item) {
        feedItems.add(FeedItem.fromMap(item));
      });
      setState(() {});
    });
  }

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
          itemCount: feedItems.length,
          itemBuilder: (BuildContext context, int index) {
            FeedItem item = feedItems[index];
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

Future<List<Map>> readItems(int feedId) async {
  Database database = await getDatabase();
  List<Map> items = await database
      .query('FeedItem', where: '"feedId" = ?', whereArgs: [feedId]);
  return items;
}
