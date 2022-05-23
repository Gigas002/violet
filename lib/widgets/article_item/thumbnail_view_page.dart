// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:violet/settings/settings.dart';

class ThumbnailViewPage extends StatefulWidget {
  final String thumbnail;
  final String heroKey;
  final Map<String, String> headers;
  final Size? size;

  ThumbnailViewPage({
    required this.thumbnail,
    required this.headers,
    this.size,
    required this.heroKey,
  });

  @override
  _ThumbnailViewPageState createState() => _ThumbnailViewPageState();
}

class _ThumbnailViewPageState extends State<ThumbnailViewPage> {
  double scale = 1.0;
  double latest = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.all(0),
        child: Transform.scale(
          scale: scale,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Hero(
                  tag: widget.heroKey,
                  child: CachedNetworkImage(
                    imageUrl: widget.thumbnail,
                    fit: BoxFit.cover,
                    httpHeaders: widget.headers,
                    placeholder: (b, c) {
                      if (!Settings.simpleItemWidgetLoadingIcon) {
                        return const FlareActor(
                          "assets/flare/Loading2.flr",
                          alignment: Alignment.center,
                          fit: BoxFit.fitHeight,
                          animation: "Alarm",
                        );
                      } else {
                        return Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: Settings.majorColor.withAlpha(150),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ]),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(1)),
          boxShadow: [
            BoxShadow(
              color: Settings.themeWhat
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
      ),
      onScaleStart: (detail) {
        tapCount = 2;
      },
      onScaleUpdate: (detail) {
        setState(() {
          scale = latest * detail.scale;
        });

        if (scale < 0.6) Navigator.pop(context);
      },
      onScaleEnd: (detail) {
        latest = scale;
        tapCount = 0;
      },
      onVerticalDragStart: (detail) {
        dragStart = detail.localPosition.dy;
      },
      onVerticalDragUpdate: (detail) {
        if (zooming || tapCount == 2) {
          setState(() {
            scale += (detail.delta.dy) / 100;
          });
          latest = scale;
          if (scale < 0.6) Navigator.pop(context);
        } else if (tapCount != 2 ||
            (detail.localPosition.dy - dragStart).abs() > 70)
          Navigator.pop(context);
      },
      onTapDown: (detail) {
        tapCount++;
        DateTime now = DateTime.now();
        if (currentBackPressTime == null ||
            now.difference(currentBackPressTime!) >
                Duration(milliseconds: 300)) {
          currentBackPressTime = now;
          return;
        }
        zooming = true;
      },
      onTapUp: (detail) {
        tapCount--;
        zooming = false;
      },
      onTapCancel: () {
        tapCount = 0;
      },
    );
  }

  int tapCount = 0;
  double dragStart = 0;
  bool zooming = false;
  DateTime? currentBackPressTime;
}
