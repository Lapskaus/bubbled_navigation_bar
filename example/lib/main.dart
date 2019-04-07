import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'package:bubbled_navigation_bar/bubbled_navigation_bar.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final titles = ['Main', 'Phone', 'Location', 'Info', 'Profile'];
  final colors = [Colors.red, Colors.purple, Colors.teal, Colors.green, Colors.cyan];
  final icons = [
    CupertinoIcons.home,
    CupertinoIcons.phone,
    CupertinoIcons.location,
    CupertinoIcons.info,
    CupertinoIcons.profile_circled
  ];

  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController _pageController;
  MenuPositionController _menuPositionController;
  bool userPageDragging = false;

  @override
  void initState() {
    _menuPositionController = MenuPositionController(initPosition: 0);

    _pageController = PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1.0
    );
    _pageController.addListener(handlePageChange);

    super.initState();
  }

  void handlePageChange() {
    _menuPositionController.absolutePosition = _pageController.page;
  }

  void checkUserDragging(ScrollNotification scrollNotification) {
    if (scrollNotification is UserScrollNotification && scrollNotification.direction != ScrollDirection.idle) {
      userPageDragging = true;
    } else if (scrollNotification is ScrollEndNotification) {
      userPageDragging = false;
    }
    if (userPageDragging) {
      _menuPositionController.findNearestTarget(_pageController.page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bubbled Navigation Bar'),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          checkUserDragging(scrollNotification);
        },
        child: PageView(
          controller: _pageController,
          children: widget.colors.map((Color c) => Container(color: c)).toList(),
          onPageChanged: (page) {
          },
        ),
      ),
      bottomNavigationBar: BubbledNavigationBar(
        controller: _menuPositionController,
        initialIndex: 0,
        backgroundColor: Colors.white,
        defaultBubbleColor: Colors.blue,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            curve: Curves.easeInOutQuad,
            duration: Duration(milliseconds: 500)
          );
        },
        items: widget.titles.map((title) {
          var index = widget.titles.indexOf(title);
          var color = widget.colors[index];
          return BubbledNavigationBarItem(
            icon: getIcon(index, color),
            activeIcon: getIcon(index, Colors.white),
            bubbleColor: color,
            title: Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        }).toList(),
      )
    );
  }

  Padding getIcon(int index, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Icon(widget.icons[index], size: 30, color: color),
    );
  }
}
