import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';
import 'dart:ui' as UI;
import 'fixture_model.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(new MyApp());

class Position {
  Offset start = new Offset(0.0, 0.0);
  Offset end = new Offset(0.0, 0.0);
}

class UrlImage {
  String url = "";
  UI.Image image;
  int id = 0;
}

class FixturePainter extends CustomPainter {
  final double value;
  final double fixtureBorderWidth = 2.0;
  final double shelfBorderWidth = 3.0;
  final double ratioToShow = 0.8;
  final double fixtureStep = 10.0;
  final double productOffset = 1.0;

  final List<FixtureModel> fixtures;

  const FixturePainter({this.value, this.fixtures});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(value, 0.0);
    for (int i = 0; i < fixtures.length; i++) {
      var rect = new Offset(
              fixtureBorderWidth * 2.0 + (fixtures[i].width + fixtureStep) * i,
              size.height - fixtures[i].height - fixtureBorderWidth / 2.0) &
          new Size(fixtures[i].width, fixtures[i].height);
      drawFixture(canvas, rect, fixtures[i]);
    }
  }

  void drawFixture(Canvas canvas, Rect rect, FixtureModel fixture) {
    drawShelfBack(canvas, rect);
    drawShelves(canvas, rect, fixture);
  }

  void drawShelfBack(Canvas canvas, Rect rect) {
    RRect roundedRect = new RRect.fromRectAndCorners(rect,
        topLeft: new Radius.circular(5.0), topRight: new Radius.circular(5.0));
    canvas.drawRRect(
        roundedRect,
        new Paint()
          ..strokeWidth = fixtureBorderWidth
          ..style = PaintingStyle.stroke
          ..color = Colors.black);
    canvas.drawRRect(
        roundedRect,
        new Paint()
          ..color = Colors.grey[200]
          ..style = PaintingStyle.fill);
  }

  void drawShelves(Canvas canvas, Rect rect, FixtureModel fixture) {
    if (fixture.p.length > 0) {
      double heightForShelf = rect.height / (fixture.p.length + 1);
      for (int i = 0; i < fixture.p.length; i++) {
        for (int j = 0; j < fixture.p[i].length; j++) {
          double widthForProducts = (rect.width -
                  productOffset -
                  fixture.p[i].length * productOffset) /
              fixture.p[i].length;
          Rect productRect = new Rect.fromLTWH(
              rect.bottomLeft.dx +
                  productOffset +
                  j * (widthForProducts + productOffset),
              rect.bottomLeft.dy -
                  heightForShelf * i -
                  (heightForShelf * ratioToShow + shelfBorderWidth),
              widthForProducts,
              heightForShelf * ratioToShow);
          paintImage(
              canvas: canvas,
              image: fixture.p[i][j].image,
              rect: productRect,
              alignment: Alignment.bottomCenter);
          if (fixture.p[i][j].shouldBeUpdated) {
            canvas.drawCircle(productRect.center, productRect.width * 0.5,
                new Paint()..color = Color(0x70ff0000));
          }
        }
        Position position = new Position()
          ..start = new Offset(rect.bottomLeft.dx,
              rect.bottomLeft.dy - heightForShelf * i - shelfBorderWidth / 2.0)
          ..end = new Offset(rect.bottomRight.dx,
              rect.bottomLeft.dy - heightForShelf * i - shelfBorderWidth / 2.0);
        canvas.drawLine(
            position.start,
            position.end,
            new Paint()
              ..strokeWidth = shelfBorderWidth
              ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      var rect = Offset.zero & size;
      var width = size.shortestSide * 0.4;
      rect = const Alignment(0.8, -0.9).inscribe(new Size(width, width), rect);
      return [
        new CustomPainterSemantics(
          rect: rect,
          properties: new SemanticsProperties(
            label: 'FixturePainter',
            textDirection: TextDirection.ltr,
          ),
        ),
      ];
    };
  }

  bool shouldRepaint(FixturePainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(FixturePainter oldDelegate) => false;
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(),
      home: new MyHomePage(title: 'Flutter Demo Homes Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int _counter = 0;
  Animation<double> animation;
  AnimationController controller;
  UI.Image bkImage;

  FixtureModel fixture;
  List<FixtureModel> fixtures = List<FixtureModel>();

  initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 10000), vsync: this);
    animation = Tween(begin: 0.0, end: -4000.0).animate(controller);
    controller.stop();
  }

  Future<UrlImage> getImage(String url, int id) async {
    print(url);
    Completer<UrlImage> completer = new Completer<UrlImage>();
    new NetworkImage(url)
        .resolve(new ImageConfiguration())
        .addListener((ImageInfo info, bool _) async {
      UrlImage urlImage = new UrlImage()
        ..url = url
        ..image = info.image
        ..id = id;
      completer.complete(urlImage);
    });
    return completer.future;
  }

  //currenlty using temp data
  Future<List<FixtureModel>> initImageManager() async {
    List<String> urls = [
      "https://cdn7.bigcommerce.com/s-ib3khtau/images/stencil/1280x1280/products/76/30/New_bag_SILO_sm__17143.1490799842.png",
    ];
    fixtures.clear();
    List<Future<UrlImage>> futures = [];
    for (int i = 0; i < 3; i++) {
      FixtureModel fixtureModel = new FixtureModel()
        ..height = 300.0
        ..width = 200.0;
      for (int j = 0; j < 4; j++) {
        List<Product> products = List<Product>();
        for (int k = 0; k < 5; k++) {
          print(i + j + k);
          Product product = new Product()
            ..id = i + j + k
            ..url = urls[0];
          futures.add(getImage(urls[0], i + j + k));
          products.add(product);
        }
        fixtureModel.p.add(products);
      }
      fixtures.add(fixtureModel);
    }
    List<UrlImage> urlImages = await Future.wait(futures);
    //fixtures
    for (int i = 0; i < fixtures.length; i++) {
      //products on shelf
      for (int j = 0; j < fixtures[i].p.length; j++) {
        //product on shelf
        for (int k = 0; k < fixtures[i].p[j].length; k++) {
          //find and update product with loaded image
          for (int m = 0; m < urlImages.length; m++) {
            if (urlImages[m].id == fixtures[i].p[j][k].id) {
              Product product = new Product()
                ..id = fixtures[i].p[j][k].id
                ..url = urlImages[m].url
                ..image = urlImages[m].image;
              if (fixtures[i].p[j][k].id % 5 == 0) {
                product.shouldBeUpdated = true;
              }
              fixtures[i].p[j][k] = product;
            }
          }
        }
      }
    }
    return fixtures;
  }

  void _handleTapDown(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject();
    print(referenceBox.globalToLocal(details.globalPosition));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Center(
            child: new FutureBuilder(
                future: initImageManager(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return new AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget child) {
                          return new Container(
                              width: MediaQuery.of(context).size.width,
                              height: 800.0,
                              color: Colors.white,
                              child: ClipRect(
                                  child: new GestureDetector(
                                      child: CustomPaint(
                                          painter: FixturePainter(
                                              value: animation.value,
                                              fixtures: snapshot.data)),
                                      onTapDown: _handleTapDown)));
                        });
                  } else {
                    return new Text("No Images");
                  }
                })));
  }
}
