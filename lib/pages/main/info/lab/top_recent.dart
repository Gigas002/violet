// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/database/query.dart';
import 'package:violet/log/log.dart';
import 'package:violet/model/article_list_item.dart';
import 'package:violet/pages/segment/card_panel.dart';
import 'package:violet/server/violet.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/widgets/article_item/article_list_item_widget.dart';

class LabTopRecent extends StatefulWidget {
  @override
  _LabTopRecentState createState() => _LabTopRecentState();
}

class _LabTopRecentState extends State<LabTopRecent> {
  List<Tuple2<QueryResult, int>> records = <Tuple2<QueryResult, int>>[];
  int limit = 10;
  Timer? timer;
  ScrollController _controller = ScrollController();
  bool isTop = false;
  String desc = "로딩";

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (_controller.position.atEdge) {
        if (_controller.position.pixels == 0) {
          isTop = false;
        } else {
          isTop = true;
        }
      } else
        isTop = false;
    });

    Future.delayed(Duration(milliseconds: 100)).then(updateRercord).then(
        (value) => Future.delayed(Duration(milliseconds: 100)).then((value) =>
            _controller.animateTo(0.0,
                duration: Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn)));
  }

  Future<void> updateRercord(dummy) async {
    try {
      var trecords = await VioletServer.top_recent(limit);
      if (trecords is int || trecords == null || trecords.length == 0) return;

      var xrecords = trecords as List<Tuple2<int, int>>;

      var queryRaw = HitomiManager.translate2query(Settings.includeTags +
              ' ' +
              Settings.excludeTags
                  .where((e) => e.trim() != '')
                  .map((e) => '-$e')
                  .join(' ')) +
          ' AND ';

      queryRaw += 'Id IN (' + xrecords.map((e) => e.item1).join(',') + ')';
      var query = await QueryManager.query(queryRaw);

      if (query.results!.length == 0) return;

      var qr = Map<String, QueryResult>();
      query.results!.forEach((element) {
        qr[element.id().toString()] = element;
      });

      var result = <Tuple2<QueryResult, int>>[];
      xrecords.forEach((element) {
        if (qr[element.item1.toString()] == null) {
          return;
        }
        result.add(Tuple2<QueryResult, int>(
            qr[element.item1.toString()]!, element.item2));
      });

      records = result;

      setState(() {});
      Future.delayed(Duration(milliseconds: 50)).then((x) {
        _controller.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
        );
      });

      var sts = (await VioletServer.top_ts(limit)) as DateTime;
      var cts = (await VioletServer.cur_ts()) as DateTime;

      var x = cts.difference(sts);

      setState(() {
        if (x.inHours > 0)
          desc = x.inHours.toString() + "시간";
        else if (x.inMinutes > 0)
          desc = x.inMinutes.toString() + "분";
        else if (x.inSeconds > 0)
          desc = x.inSeconds.toString() + "초";
        else
          desc = "?";
      });
    } catch (e, st) {
      Logger.error(
          '[lab-top_recent] E: ' + e.toString() + '\n' + st.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    var windowWidth = MediaQuery.of(context).size.width;
    return CardPanel.build(
      context,
      enableBackgroundColor: true,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(0),
              controller: _controller,
              physics: BouncingScrollPhysics(),
              itemCount: records.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return Align(
                  key: Key('records' +
                      index.toString() +
                      '/' +
                      records[index].item1.id().toString()),
                  alignment: Alignment.center,
                  child: Provider<ArticleListItem>.value(
                    value: ArticleListItem.fromArticleListItem(
                      queryResult: records[index].item1,
                      showDetail: true,
                      addBottomPadding: true,
                      width: (windowWidth - 4.0),
                      thumbnailTag: Uuid().v4(),
                      viewed: records[index].item2,
                    ),
                    child: ArticleListItemVerySimpleWidget(),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Container(width: 16),
              Text('Limit: $limit($desc)'),
              Expanded(
                child: ListTile(
                  dense: true,
                  title: Align(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.blue,
                        inactiveTrackColor: Color(0xffd0d2d3),
                        trackHeight: 3,
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        value: limit.toDouble(),
                        max: 30000,
                        min: 1,
                        divisions: (30000 - 1),
                        inactiveColor: Settings.majorColor.withOpacity(0.7),
                        activeColor: Settings.majorColor,
                        onChangeEnd: (value) async {
                          limit = value.toInt();
                          await updateRercord(null);
                        },
                        onChanged: (value) {
                          setState(() {
                            limit = value.toInt();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
