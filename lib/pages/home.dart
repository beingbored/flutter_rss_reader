import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rss_reader/pages/feed.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

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
    readFeeds().then((List<Map> items) {
      items.forEach((item) {
        feeds.add(Feed.fromMap(item));
      });
      setState(() {});
    });
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
                                addFeed(normalizedFeed).then((feed) {
                                  feeds.add(feed);
                                  addFeedItems(feed).then((items) {
                                    setState(() {});
                                  });
                                });
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
              onTap: () async {
                List<Map> map = await readFeeds();
                print(map);
              },
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
  int id;
  String title;
  String link;
  String description;
  DateTime updatedAt;
  List<FeedItem> items = [];

  Feed({this.title, this.description, this.link, this.updatedAt});

  Feed.fromMap(Map<String, dynamic> map) {
    id = map["id"];
    title = map["title"];
    link = map["link"];
    description = map["description"];
    updatedAt = DateTime.parse(map["updatedAt"]);
    items = [];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      "title": title,
      "link": link,
      "description": description,
      "updatedAt": updatedAt.toString()
    };
    if (id != null) {
      map["id"] = id;
    }
    return map;
  }
}

class FeedItem {
  int id;
  int feedId;
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

  FeedItem.fromMap(Map<String, dynamic> map) {
    id = map["id"];
    feedId = map["feedId"];
    title = map["title"];
    author = map["author"];
    description = map["description"];
    link = map["link"];
    summary = map["summary"];
    content = map["content"];
    publishedAt = DateTime.parse(map["publishedAt"]);
  }

  Map<String, dynamic> toMap(int _feedId) {
    var map = <String, dynamic>{
      "title": title,
      "author": author,
      "description": description,
      "link": link,
      "publishedAt": publishedAt.toString(),
      "summary": summary,
      "content": content
    };

    if (id != null) {
      map["id"] = id;
    }
    map["feedId"] = feedId ?? _feedId;

    return map;
  }
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

Future<Database> getDatabase() async {
//  await deleteDatabase('feeds.db');
  return openDatabase('feeds.db', version: 1,
      onCreate: (Database db, int version) async {
    await db.execute(
        'CREATE TABLE Feed (id INTEGER PRIMARY KEY, title TEXT, link TEXT, description TEXT, updatedAt TEXT)');
    await db.execute(
        'CREATE TABLE FeedItem (id INTEGER PRIMARY KEY, feedId INTEGER, title TEXT, author TEXT, description TEXT, link TEXT, publishedAt TEXT, summary TEXT, content TEXT)');
  });
}

Future<List<Map>> readFeeds() async {
  Database database = await getDatabase();
  List<Map> maps = await database.query('Feed');
  await database.close();
  return Future.value(maps);
}

Future<Feed> addFeed(Feed feed) async {
  Database database = await getDatabase();
  feed.id = await database.insert('Feed', feed.toMap());
  await database.close();
  return feed;
}

Future addFeedItems(Feed feed) async {
  Database database = await getDatabase();
  await database.transaction((txn) async {

    var batch = txn.batch();
    feed.items.forEach((item) {
      batch.insert('FeedItem', item.toMap(feed.id));
    });
    await batch.commit();
  });

  await database.close();
  return feed;
}
