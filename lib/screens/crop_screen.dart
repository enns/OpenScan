import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/Widgets/polygon_painter.dart';

class CropImage extends StatefulWidget {
  final File file;

  CropImage({this.file});

  _CropImageState createState() => _CropImageState();
}

class _CropImageState extends State<CropImage> {
  final GlobalKey key = GlobalKey();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  double width, height;
  double prevWidth, prevHeight = 0;
  Size imageBitmapSize = Size(600.0, 600.0);
  bool hasWidgetLoaded = false;
  Offset tl, tr, bl, br, t, l, b, r;
  bool isLoading = false;
  File imageFile;

  MethodChannel channel = new MethodChannel('com.ethereal.openscan/cropper');

  @override
  void initState() {
    super.initState();
    imageFile = widget.file;

    /// Waiting for the widget to finish rendering so that we can get
    /// the size of the canvas. This is supposed to return the correct size
    /// of the desired widget. But it doesn't. Which is why the getImageSize()
    /// is called recursively (every 200 milliseconds until the height and
    /// width are not equal to zero).
    ///
    /// The reason this is called recursively is to ensure that the dimensions
    /// are obtained even in cases where the build time of widgets is longer.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => getImageSize(false),
    );
  }

  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
      print('Rebuilding');
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => getImageSize(false),
      );
    }

    (context as Element).visitChildren(rebuild);
  }

  void getImageSize(isRenderBoxValuesCorrect) async {
    setState(() {
      isLoading = true;
    });
    RenderBox imageBox = key.currentContext.findRenderObject();
    width = imageBox.size.width;
    height = imageBox.size.height;

    //TODO: Doesn't work for square images
    if ((width == 0 && height == 0) ||
        (width == prevWidth && height == prevHeight)) {
      Timer(Duration(milliseconds: 100), () => getImageSize(false));
    } else {
      isRenderBoxValuesCorrect = true;
      prevHeight = height;
      prevWidth = width;
    }

    t = Offset(width / 2, 0);
    b = Offset(width / 2, height);
    l = Offset(0, height / 2);
    r = Offset(width, height / 2);
    tl = Offset(0, 0);
    tr = Offset(width, 0);
    bl = Offset(0, height);
    br = Offset(width, height);

    setState(() {
      isLoading = false;
      hasWidgetLoaded = true;
    });

    if (isRenderBoxValuesCorrect) return;
  }

  void updatePolygon(points) {
    double x1 = points.localPosition.dx;
    double y1 = points.localPosition.dy;
    double x2 = tl.dx;
    double y2 = tl.dy;
    double x3 = tr.dx;
    double y3 = tr.dy;
    double x4 = bl.dx;
    double y4 = bl.dy;
    double x5 = br.dx;
    double y5 = br.dy;
    double x6 = t.dx;
    double y6 = t.dy;
    double x7 = b.dx;
    double y7 = b.dy;
    double x8 = l.dx;
    double y8 = l.dy;
    double x9 = r.dx;
    double y9 = r.dy;

    if (sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        if(tl.dx + 10 < tr.dx)
          tl = points.localPosition;
      });
    } else if (sqrt(pow((x3 - x1), 2) + pow((y3 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        tr = points.localPosition;
      });
    } else if (sqrt(pow((x4 - x1), 2) + pow((y4 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        bl = points.localPosition;
      });
    } else if (sqrt(pow((x5 - x1), 2) + pow((y5 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        br = points.localPosition;
      });
    } else if (sqrt(pow((x6 - x1), 2) + pow((y6 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        double displacement = y1 - y6;
        t = points.localPosition;
        if(tl.dy + displacement > 0)
          tl = Offset(tl.dx, tl.dy + displacement);
        if(tr.dy + displacement > 0)
          tr = Offset(tr.dx, tr.dy + displacement);
      });
    } else if (sqrt(pow((x7 - x1), 2) + pow((y7 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        double displacement = y7 - y1;
        b = points.localPosition;
        if(bl.dy - displacement < height)
          bl = Offset(bl.dx, bl.dy - displacement);
        if(br.dy + displacement < height)
          br = Offset(br.dx, br.dy - displacement);
      });
    } else if (sqrt(pow((x8 - x1), 2) + pow((y8 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        double displacement = x1 - x8;
        l = points.localPosition;
        if(tl.dx + displacement > 0)
          tl = Offset(tl.dx + displacement, tl.dy);
        if(bl.dx + displacement > 0)
          bl = Offset(bl.dx + displacement, bl.dy);
      });
    } else if (sqrt(pow((x9 - x1), 2) + pow((y9 - y1), 2)) < 15 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        double displacement = x9 - x1;
        r = points.localPosition;
        if(tr.dx - displacement < width)
          tr = Offset(tr.dx - displacement, tr.dy);
        if(br.dx - displacement < width)
          br = Offset(br.dx - displacement, br.dy);
      });
    }
    t = Offset((tr.dx + tl.dx) / 2, (tr.dy + tl.dy) / 2);
    l = Offset((tl.dx + bl.dx) / 2, (tl.dy + bl.dy) / 2);
    b = Offset((br.dx + bl.dx) / 2, (br.dy + bl.dy) / 2);
    r = Offset((tr.dx + br.dx) / 2, (tr.dy + br.dy) / 2);
  }

  void crop() async {
    setState(() {
      isLoading = true;
    });

    List imageSize = await channel.invokeMethod("getImageSize", {
      "path": imageFile.path,
    });

    imageSize = [imageSize[0].toDouble(), imageSize[1].toDouble()];
    imageBitmapSize = Size(imageSize[0], imageSize[1]);

    double tlX = (imageBitmapSize.width / width) * tl.dx;
    double trX = (imageBitmapSize.width / width) * tr.dx;
    double blX = (imageBitmapSize.width / width) * bl.dx;
    double brX = (imageBitmapSize.width / width) * br.dx;

    double tlY = (imageBitmapSize.height / height) * tl.dy;
    double trY = (imageBitmapSize.height / height) * tr.dy;
    double blY = (imageBitmapSize.height / height) * bl.dy;
    double brY = (imageBitmapSize.height / height) * br.dy;
    await channel.invokeMethod('cropImage', {
      'path': imageFile.path,
      'tl_x': tlX,
      'tl_y': tlY,
      'tr_x': trX,
      'tr_y': trY,
      'bl_x': blX,
      'bl_y': blY,
      'br_x': brX,
      'br_y': brY,
    });

    print('cropper: ${imageFile.path}');
    Navigator.pop(context, imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: (){
          Navigator.pop(context,null);
          return ;
        },
        child: Scaffold(
          backgroundColor: primaryColor,
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              'Crop Image',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            elevation: 0.0,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
          ),
          body: Container(
            padding: EdgeInsets.all(20),
            alignment: Alignment.center,
            child: !isLoading
                ? GestureDetector(
                    onPanDown: (points) => updatePolygon(points),
                    onPanUpdate: (points) => updatePolygon(points),
                    child: Stack(
                      children: <Widget>[
                        Container(
                          color: primaryColor,
                          child: CustomPaint(
                            child: Image.file(
                              imageFile,
                              key: key,
                            ),
                          ),
                        ),
                        hasWidgetLoaded
                            ? Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width - 20,
                                ),
                                child: CustomPaint(
                                  painter: PolygonPainter(
                                    tl: tl,
                                    tr: tr,
                                    bl: bl,
                                    br: br,
                                    t: t,
                                    l: l,
                                    b: b,
                                    r: r,
                                  ),
                                ),
                              )
                            : Container()
                      ],
                    ),
                  )
                : CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation(
                      secondaryColor,
                    ),
                  ),
          ),
          bottomNavigationBar: bottomSheet(),
        ),
      ),
    );
  }

  Widget bottomSheet() {
    return Container(
      color: primaryColor,
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FlatButton(
            color: secondaryColor,
            child: Text('Rotate left'),
            onPressed: () async {
              File tempImageFile = File(
                  imageFile.path.substring(0, imageFile.path.lastIndexOf('.')) +
                      'r.jpg');
              imageFile.copySync(tempImageFile.path);
              await channel.invokeMethod("rotateImage", {
                'path': tempImageFile.path,
                'degree': -90,
              });
              print('Rotated left');
              setState(() {
                // tempImageFile.copySync(imageFile.path);
                imageFile = File(tempImageFile.path);
              });
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => getImageSize(false),
              );
              // tempImageFile.deleteSync();
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: FlatButton(
              child: Text('Rotate right'),
              color: secondaryColor,
              onPressed: () async {
                File tempImageFile = File(imageFile.path
                        .substring(0, imageFile.path.lastIndexOf('.')) +
                    'r.jpg');
                imageFile.copySync(tempImageFile.path);
                await channel.invokeMethod("rotateImage", {
                  'path': tempImageFile.path,
                  'degree': 90,
                });
                print('Rotated right');
                setState(() {
                  // tempImageFile.copySync(imageFile.path);
                  imageFile = File(tempImageFile.path);
                });
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => getImageSize(false),
                );
                // rebuildAllChildren(context);
                // tempImageFile.deleteSync();
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4.0,
            ),
            child: Container(
              child: FlatButton(
                onPressed: () => crop(),
                color: hasWidgetLoaded || !isLoading
                    ? secondaryColor
                    : secondaryColor.withOpacity(0.6),
                disabledColor: secondaryColor.withOpacity(0.5),
                disabledTextColor: Colors.white.withOpacity(0.5),
                child: Text(
                  "Continue",
                  style: TextStyle(
                    color: hasWidgetLoaded || !isLoading
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
