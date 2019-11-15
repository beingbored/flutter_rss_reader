import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rss_reader/pages/feed.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _addFormKey = GlobalKey<FormState>();
  TabController tabBarController;
  List<Feed> feeds = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("RSS Reader"),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("새 피드 추가"),
                      content: Form(
                        autovalidate: true,
                        key: _addFormKey,
                        child: TextFormField(
                          validator: (value) {
                            if (value.isEmpty) {
                              return "값이 없습니다.";
                            }

                            return null;
                          },
                          decoration: InputDecoration(hintText: "URL을 입력하세요"),
                        ),
                      ),
                      actions: <Widget>[
                        FlatButton(
                          child: Text("닫기"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        FlatButton(
                          child: Text("추가"),
                          onPressed: () {
                            if (_addFormKey.currentState.validate()) {
                              var client = http.Client();
                              client
                                  .get("https://github.blog/all.atom")
                                  .then((response) {
                                return response.body;
                              }).then((bodyString) {
                                bool hasAtom = bodyString.contains(
                                    'xmlns="http://www.w3.org/2005/Atom"');
                                bool hasRss = bodyString.contains("</rss>");
                                Feed normalizedFeed;
                                if (hasAtom) {
                                  AtomFeed feed = AtomFeed.parse(bodyString);
                                  normalizedFeed = normalizeAtom(feed);
                                } else if (hasRss) {
                                  RssFeed feed = RssFeed.parse(bodyString);
                                  normalizedFeed = normalizeRss(feed);
                                } else {
                                  print("NOTHING");
                                }

                                if (normalizedFeed == null) {
                                  return;
                                }
                                feeds.add(normalizedFeed);
                                setState(() {});
                              });
                            }
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    );
                  });
            },
            icon: Icon(Icons.add),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text("Drawer Header"),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              title: Text("Item 1"),
              onTap: () {},
            ),
            ListTile(
              title: Text("Settings"),
              onTap: () {},
            )
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: feeds.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(feeds[index].title),
            subtitle: Text(feeds[index].updatedAt.toString()),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FeedPage(feeds[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Feed {
  String title;
  String link;
  String description;
  DateTime updatedAt;
  List<FeedItem> items = [];

  Feed({this.title, this.description, this.link, this.updatedAt});
}

class FeedItem {
  String title;
  String author;
  String description;
  String link;
  DateTime publishedAt;
  String summary;
  String content;

  FeedItem({
    this.title,
    this.author,
    this.description,
    this.link,
    this.publishedAt,
    this.summary,
    this.content,
  });
}

Feed normalizeAtom(AtomFeed feed) {
  AtomLink link = feed.links
      .firstWhere((AtomLink link) => link.type == "application/atom+xml");

  Feed normalizedFeed = Feed(
    title: feed.title,
    updatedAt: DateTime.parse(feed.updated),
    link: link.href,
    description: feed.subtitle,
  );

  normalizedFeed.items = feed.items.map((AtomItem item) {
    AtomLink link =
        feed.links.firstWhere((AtomLink link) => link.type == "text/html");

    return FeedItem(
      title: item.title,
      link: link.href,
      summary: item.summary,
      description: item.summary,
      author: item.authors.first.name,
      content: item.content,
      publishedAt: DateTime.parse(item.updated),
    );
  }).toList();
  return normalizedFeed;
}

Feed normalizeRss(RssFeed feed) {
  Feed normalizedFeed = Feed(
    title: feed.title,
    updatedAt: DateTime.parse(feed.lastBuildDate),
    link: feed.link,
    description: feed.description,
  );

  normalizedFeed.items = feed.items.map((RssItem item) {
    return FeedItem(
      title: item.title,
      link: item.link,
      summary: item.description,
      description: item.comments,
      author: item.author,
      content: item.content.toString(),
      publishedAt: DateTime.parse(item.pubDate),
    );
  });
  return normalizedFeed;
}
