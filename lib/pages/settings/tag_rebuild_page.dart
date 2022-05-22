// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/database/query.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/settings/settings.dart';

class TagRebuildPage extends StatefulWidget {
  @override
  _TagRebuildPageState createState() => _TagRebuildPageState();
}

class _TagRebuildPageState extends State<TagRebuildPage> {
  String baseString = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(Duration(milliseconds: 100)).then((value) async {
      await indexing();

      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Card(
              color:
                  Settings.themeWhat ? Color(0xFF353535) : Colors.grey.shade100,
              elevation: 100,
              child: SizedBox(
                child: SizedBox(
                  width: 280,
                  height: (56 * 4 + 16).toDouble(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: Stack(
                      children: [
                        Center(
                          child: CircularProgressIndicator(),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 33),
                            child: Text(
                              baseString,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(1)),
          boxShadow: [
            BoxShadow(
              color: Settings.themeWhat
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
      ),
    );
  }

  void insert(Map<String, int> map, dynamic qr) {
    if (qr == null) return;
    if (qr as String == "") return;
    for (var tag in (qr as String).split('|'))
      if (tag != null && tag != '') {
        if (!map.containsKey(tag)) map[tag] = 0;
        map[tag] = map[tag]! + 1;
      }
  }

  void insertSingle(Map<String, int> map, dynamic qr) {
    if (qr == null) return;
    if (qr as String == "") return;
    var str = qr as String;
    if (str != null && str != '') {
      if (!map.containsKey(str)) map[str] = 0;
      map[str] = map[str]! + 1;
    }
  }

  Future indexing() async {
    QueryManager qm;
    qm = QueryManager.queryPagination(HitomiManager.translate2query(
        Settings.includeTags +
            ' ' +
            Settings.excludeTags
                .where((e) => e.trim() != '')
                .map((e) => '-$e')
                .join(' ')));
    qm.itemsPerPage = 50000;

    var tags = Map<String, int>();
    var languages = Map<String, int>();
    var artists = Map<String, int>();
    var groups = Map<String, int>();
    var types = Map<String, int>();
    var uploaders = Map<String, int>();
    var series = Map<String, int>();
    var characters = Map<String, int>();
    var classes = Map<String, int>();

    var tagIndex = Map<String, int>();
    var tagArtist = Map<String, Map<String, int>>();
    var tagGroup = Map<String, Map<String, int>>();
    var tagUploader = Map<String, Map<String, int>>();
    var tagSeries = Map<String, Map<String, int>>();
    var tagCharacter = Map<String, Map<String, int>>();

    var seriesSeries = Map<String, Map<String, int>>();
    var seriesCharacter = Map<String, Map<String, int>>();

    var characterCharacter = Map<String, Map<String, int>>();
    var characterSeries = Map<String, Map<String, int>>();

    int i = 0;
    while (true) {
      setState(() {
        baseString = Translations.instance!.trans('dbdindexing') + '[$i/20]';
      });

      var ll = await qm.next();
      print(ll.length);
      for (var item in ll) {
        insert(tags, item.tags());
        insert(artists, item.artists());
        insert(groups, item.groups());
        insert(series, item.series());
        insert(characters, item.characters());
        insertSingle(languages, item.language());
        insertSingle(types, item.type());
        insertSingle(uploaders, item.uploader());
        insertSingle(classes, item.classname());

        if (item.tags() == null) continue;

        if (item.artists() != null) {
          for (var artist in item.artists().split('|'))
            if (artist != '') if (!tagArtist.containsKey(artist))
              tagArtist[artist] = Map<String, int>();
          for (var tag in item.tags().split('|')) {
            if (tag == null || tag == '') continue;
            if (!tagIndex.containsKey(tag)) tagIndex[tag] = tagIndex.length;
            var index = tagIndex[tag].toString();
            for (var artist in item.artists().split('|')) {
              if (artist == '') continue;
              if (!tagArtist[artist]!.containsKey(index))
                tagArtist[artist]![index] = 0;
              tagArtist[artist]![index] = tagArtist[artist]![index]! + 1;
            }
          }
        }

        if (item.groups() != null) {
          for (var artist in item.groups().split('|'))
            if (artist != '') if (!tagGroup.containsKey(artist))
              tagGroup[artist] = Map<String, int>();
          for (var tag in item.tags().split('|')) {
            if (tag == null || tag == '') continue;
            if (!tagIndex.containsKey(tag)) tagIndex[tag] = tagIndex.length;
            var index = tagIndex[tag].toString();
            for (var artist in item.groups().split('|')) {
              if (artist == '') continue;
              if (!tagGroup[artist]!.containsKey(index))
                tagGroup[artist]![index] = 0;
              tagGroup[artist]![index] = tagGroup[artist]![index]! + 1;
            }
          }
        }

        if (item.uploader() != null) {
          if (!tagUploader.containsKey(item.uploader()))
            tagUploader[item.uploader()] = Map<String, int>();
          for (var tag in item.tags().split('|')) {
            if (tag == null || tag == '') continue;
            if (!tagIndex.containsKey(tag)) tagIndex[tag] = tagIndex.length;
            var index = tagIndex[tag].toString();
            if (!tagUploader[item.uploader()]!.containsKey(index))
              tagUploader[item.uploader()]![index] = 0;
            tagUploader[item.uploader()]![index] =
                tagGroup[item.uploader()]![index]! + 1;
          }
        }

        if (item.series() != null) {
          for (var artist in item.series().split('|'))
            if (artist != '') if (!tagSeries.containsKey(artist))
              tagSeries[artist] = Map<String, int>();
          for (var tag in item.tags().split('|')) {
            if (tag == null || tag == '') continue;
            if (!tagIndex.containsKey(tag)) tagIndex[tag] = tagIndex.length;
            var index = tagIndex[tag].toString();
            for (var artist in item.series().split('|')) {
              if (artist == '') continue;
              if (!tagSeries[artist]!.containsKey(index))
                tagSeries[artist]![index] = 0;
              tagSeries[artist]![index] = tagSeries[artist]![index]! + 1;
            }
          }
        }

        if (item.characters() != null) {
          for (var artist in item.characters().split('|'))
            if (artist != '') if (!tagCharacter.containsKey(artist))
              tagCharacter[artist] = Map<String, int>();
          for (var tag in item.tags().split('|')) {
            if (tag == null || tag == '') continue;
            if (!tagIndex.containsKey(tag)) tagIndex[tag] = tagIndex.length;
            var index = tagIndex[tag].toString();
            for (var artist in item.characters().split('|')) {
              if (artist == '') continue;
              if (!tagCharacter[artist]!.containsKey(index))
                tagCharacter[artist]![index] = 0;
              tagCharacter[artist]![index] = tagCharacter[artist]![index]! + 1;
            }
          }
        }

        if (item.series() != null && item.characters() != null) {
          for (var series in item.series().split('|')) {
            if (series == '') continue;
            if (!characterSeries.containsKey(series))
              characterSeries[series] = Map<String, int>();
            for (var character in item.characters().split('|')) {
              if (character == '') continue;
              if (!characterSeries[series]!.containsKey(character))
                characterSeries[series]![character] = 0;
              characterSeries[series]![character] =
                  characterSeries[series]![character]! + 1;
            }
          }

          for (var character in item.characters().split('|')) {
            if (character == '') continue;
            if (!seriesCharacter.containsKey(character))
              seriesCharacter[character] = Map<String, int>();
            for (var series in item.series().split('|')) {
              if (series == '') continue;
              if (!seriesCharacter[character]!.containsKey(series))
                seriesCharacter[character]![series] = 0;
              seriesCharacter[character]![series] =
                  seriesCharacter[character]![series]! + 1;
            }
          }
        }

        if (item.series() != null) {
          for (var series in item.series().split('|')) {
            if (series == '') continue;
            if (!seriesSeries.containsKey(series))
              seriesSeries[series] = Map<String, int>();
            for (var series2 in item.series().split('|')) {
              if (series2 == '' || series == series2) continue;
              if (!seriesSeries[series]!.containsKey(series2))
                seriesSeries[series]![series2] = 0;
              seriesSeries[series]![series2] =
                  seriesSeries[series]![series2]! + 1;
            }
          }
        }

        if (item.characters() != null) {
          for (var character in item.characters().split('|')) {
            if (character == '') continue;
            if (!characterCharacter.containsKey(character))
              characterCharacter[character] = Map<String, int>();
            for (var character2 in item.characters().split('|')) {
              if (character2 == '' || character == character2) continue;
              if (!characterCharacter[character]!.containsKey(character2))
                characterCharacter[character]![character2] = 0;
              characterCharacter[character]![character2] =
                  characterCharacter[character]![character2]! + 1;
            }
          }
        }
      }

      if (ll.length == 0) {
        var index = {
          "tag": tags,
          "artist": artists,
          "group": groups,
          "series": series,
          "lang": languages,
          "type": types,
          "uploader": uploaders,
          "character": characters,
          "class": classes,
        };
        final subdir = Platform.isAndroid ? '/data' : '';

        final directory = await getApplicationDocumentsDirectory();
        final path1 = File('${directory.path}$subdir/index.json');
        if (path1.existsSync()) path1.deleteSync();
        path1.writeAsString(jsonEncode(index));
        print(index);

        final path2 = File('${directory.path}$subdir/tag-artist.json');
        if (path2.existsSync()) path2.deleteSync();
        path2.writeAsString(jsonEncode(tagArtist));
        final path3 = File('${directory.path}$subdir/tag-group.json');
        if (path3.existsSync()) path3.deleteSync();
        path3.writeAsString(jsonEncode(tagGroup));
        final path4 = File('${directory.path}$subdir/tag-index.json');
        if (path4.existsSync()) path4.deleteSync();
        path4.writeAsString(jsonEncode(tagIndex));
        final path5 = File('${directory.path}$subdir/tag-uploader.json');
        if (path5.existsSync()) path5.deleteSync();
        path5.writeAsString(jsonEncode(tagUploader));
        final path6 = File('${directory.path}$subdir/tag-series.json');
        if (path6.existsSync()) path6.deleteSync();
        path6.writeAsString(jsonEncode(tagSeries));
        final path7 = File('${directory.path}$subdir/tag-character.json');
        if (path7.existsSync()) path7.deleteSync();
        path7.writeAsString(jsonEncode(tagCharacter));

        final path8 = File('${directory.path}$subdir/character-series.json');
        if (path8.existsSync()) path8.deleteSync();
        path8.writeAsString(jsonEncode(characterSeries));
        final path9 = File('${directory.path}$subdir/series-character.json');
        if (path9.existsSync()) path9.deleteSync();
        path9.writeAsString(jsonEncode(seriesCharacter));
        final path10 =
            File('${directory.path}$subdir/character-character.json');
        if (path10.existsSync()) path10.deleteSync();
        path10.writeAsString(jsonEncode(characterCharacter));
        final path11 = File('${directory.path}$subdir/series-series.json');
        if (path11.existsSync()) path11.deleteSync();
        path11.writeAsString(jsonEncode(seriesSeries));

        break;
      }
      i++;
    }
  }
}
