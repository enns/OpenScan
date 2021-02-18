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
  Size imageBitmapSize = Size(600.0, 600.0);
  bool hasWidgetLoaded = false;
  Offset tl, tr, bl, br;
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
    /// The reason this is called recursively is to ensure that the dimesions
    /// are obtained even in cases where the build time of widgets is longer.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => getImageSize(false),
    );
  }

  void getImageSize(isRenderBoxValuesCorrect) async {
    RenderBox imageBox = key.currentContext.findRenderObject();
    width = imageBox.size.width;
    height = imageBox.size.height;

    if (width == 0 && height == 0) {
      Timer(Duration(milliseconds: 200), () => getImageSize(false));
    } else {
      isRenderBoxValuesCorrect = true;
    }

    List imageSize = await channel.invokeMethod("getImageSize", {
      "path": imageFile.path,
    });

    imageSize = [imageSize[0].toDouble(), imageSize[1].toDouble()];
    imageBitmapSize = Size(imageSize[0], imageSize[1]);

    tl = Offset(0, 0);
    tr = Offset(width, 0);
    bl = Offset(0, height);
    br = Offset(width, height);

    setState(() {
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
    if (sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2)) < 20 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        tl = points.localPosition;
      });
    } else if (sqrt(pow((x3 - x1), 2) + pow((y3 - y1), 2)) < 20 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        tr = points.localPosition;
      });
    } else if (sqrt(pow((x4 - x1), 2) + pow((y4 - y1), 2)) < 20 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        bl = points.localPosition;
      });
    } else if (sqrt(pow((x5 - x1), 2) + pow((y5 - y1), 2)) < 20 &&
        y1 >= 0 &&
        y1 <= height &&
        x1 < width &&
        x1 >= 0) {
      setState(() {
        br = points.localPosition;
      });
    }
  }

  void crop() async {
    setState(() {
      isLoading = true;
    });
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Crop',
        ),
        elevation: 0.0,
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Stack(
              children: <Widget>[
                GestureDetector(
                  onPanDown: (points) => updatePolygon(points),
                  onPanUpdate: (points) => updatePolygon(points),
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    color: primaryColor,
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 20,
                    ),
                    child: CustomPaint(
                      child: Image.file(
                        imageFile,
                        key: key,
                      ),
                    ),
                  ),
                ),
                hasWidgetLoaded
                    ? Container(
                        padding: EdgeInsets.all(8.0),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 20,
                        ),
                        child: CustomPaint(
                          painter: PolygonPainter(
                            tl: tl,
                            tr: tr,
                            bl: bl,
                            br: br,
                          ),
                        ),
                      )
                    : Container(
                        color: secondaryColor,
                      )
              ],
            ),
            bottomSheet(),
          ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
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
                setState(() {
                  // tempImageFile.copySync(imageFile.path);
                  imageFile = File(tempImageFile.path);
                });
                // tempImageFile.deleteSync();
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: FlatButton(
              color: secondaryColor,
              child: Text('Rotate left'),
              onPressed: () async {
                File tempImageFile = File(imageFile.path
                        .substring(0, imageFile.path.lastIndexOf('.')) +
                    'r.jpg');
                imageFile.copySync(tempImageFile.path);
                await channel.invokeMethod("rotateImage", {
                  'path': tempImageFile.path,
                  'degree': -90,
                });
                setState(() {
                  // tempImageFile.copySync(imageFile.path);
                  imageFile = File(tempImageFile.path);
                });
                // tempImageFile.deleteSync();
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4.0,
            ),
            child: Container(
              child: isLoading
                  ? Container(
                      width: 60.0,
                      height: 20.0,
                      child: Center(
                        child: Container(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : hasWidgetLoaded
                      ? FlatButton(
                          onPressed: () => crop(),
                          color: secondaryColor,
                          child: Text(
                            "Continue",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : Container(
                          width: 60.0,
                          height: 20.0,
                          child: Center(
                            child: Container(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
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
