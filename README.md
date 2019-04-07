# bubbled_navigation_bar
[pub package](https://pub.dartlang.org/packages/bubbled_navigation_bar)

A Flutter package for easy implementation of bubbled navigation bar. 

![Gif](https://github.com/Lapskaus/bubbled_navigation_bar/blob/master/example.gif "Fancy Gif")

### Add dependency

```yaml
dependencies:
  bubbled_navigation_bar: ^0.1.1 #latest version
```

### Easy to use

```dart
home: Scaffold(
bottomNavigationBar: BubbledNavigationBar(
  defaultBubbleColor: Colors.blue,
  onTap: (index) {
    // handle tap
  },
  items: <BubbledNavigationBarItem>[
    BubbledNavigationBarItem(
      icon:       Icon(CupertinoIcons.home, size: 30, color: Colors.red),
      activeIcon: Icon(CupertinoIcons.home, size: 30, color: Colors.white),
      title: Text('Home', style: TextStyle(color: Colors.white, fontSize: 12),),
    ),
    BubbledNavigationBarItem(
      icon:       Icon(CupertinoIcons.phone, size: 30, color: Colors.purple),
      activeIcon: Icon(CupertinoIcons.phone, size: 30, color: Colors.white),
      title: Text('Phone', style: TextStyle(color: Colors.white, fontSize: 12),),
    ),
    BubbledNavigationBarItem(
      icon:       Icon(CupertinoIcons.info, size: 30, color: Colors.teal),
      activeIcon: Icon(CupertinoIcons.info, size: 30, color: Colors.white),
      title: Text('Info', style: TextStyle(color: Colors.white, fontSize: 12),),
    ),
    BubbledNavigationBarItem(
      icon:       Icon(CupertinoIcons.profile_circled, size: 30, color: Colors.cyan),
      activeIcon: Icon(CupertinoIcons.profile_circled, size: 30, color: Colors.white),
      title: Text('Profile', style: TextStyle(color: Colors.white, fontSize: 12),),
    ),
  ],
),
body: Container(color: Colors.blue,),
)
```

### Easy to use
Way of use with PageView and sliding animation from example.gif you can see in example folder.

### Attributes

items: List of Widgets  
initialIndex: Initial index of Curve  
color: Color of NavigationBar, default Colors.white  
defaultBubbleColor: background color of floating bubble
onTap: Function handling taps on items  
animationCurve: Curves interpolating button change animation, default Curves.easeInOutQuad  
animationDuration: Duration of button change animation, default Duration(milliseconds: 500)
