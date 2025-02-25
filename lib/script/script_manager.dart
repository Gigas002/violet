// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';
import 'package:tuple/tuple.dart';
import 'package:violet/log/log.dart';
import 'package:violet/network/wrapper.dart' as http;
import 'package:violet/widgets/article_item/image_provider_manager.dart';

class ScriptManager {
  static const String _scriptUrl =
      'https://raw.githubusercontent.com/project-violet/scripts/main/hitomi_get_image_list_v3.js';
  static const String _scriptV4 =
      'https://github.com/project-violet/scripts/raw/main/hitomi_get_image_list_v4_model.js';
  static bool enableV4 = false;
  static String? _v4Cache;
  static String? _scriptCache;
  static late JavascriptRuntime _runtime;
  static late DateTime _latestUpdate;

  static Future<void> init() async {
    _scriptCache = (await http.get(_scriptUrl)).body;
    _v4Cache = (await http.get(_scriptV4)).body;
    _latestUpdate = DateTime.now();
    _initRuntime();
  }

  static Future<bool> refresh() async {
    if (enableV4) return false;

    if (DateTime.now().difference(_latestUpdate).inMinutes < 5) {
      return false;
    }

    var scriptTemp = (await http.get(_scriptUrl)).body;

    if (_scriptCache != scriptTemp) {
      _scriptCache = scriptTemp;
      _latestUpdate = DateTime.now();
      _initRuntime();
      ProviderManager.refresh();
      return true;
    }

    return false;
  }

  static Future<void> setV4(String gg_m, String gg_b) async {
    enableV4 = true;

    _v4Cache ??= (await http.get(_scriptV4)).body;

    var scriptTemp = _v4Cache!;
    scriptTemp = scriptTemp.replaceAll('%%gg.m%', gg_m);
    scriptTemp = scriptTemp.replaceAll('%%gg.b%', gg_b);

    if (_scriptCache != scriptTemp) {
      _scriptCache = scriptTemp;
      _latestUpdate = DateTime.now();
      _initRuntime();
      ProviderManager.refresh();
    }
  }

  static void _initRuntime() {
    _runtime = getJavascriptRuntime();
    _runtime.evaluate(_scriptCache!);
  }

  static Future<String?> getGalleryInfo(String id) async {
    var downloadUrl =
        _runtime.evaluate("create_download_url('$id')").stringResult;
    var headers = await runHitomiGetHeaderContent(id);
    var galleryInfo = await http.get(downloadUrl, headers: headers);
    if (galleryInfo.statusCode != 200) return null;
    return galleryInfo.body;
  }

  static Future<Tuple3<List<String>, List<String>, List<String>>?>
      runHitomiGetImageList(int id) async {
    if (_scriptCache == null) return null;

    try {
      var downloadUrl =
          _runtime.evaluate("create_download_url('$id')").stringResult;
      var headers = await runHitomiGetHeaderContent(id.toString());
      var galleryInfo = await http.get(downloadUrl,
          headers: headers, timeout: const Duration(milliseconds: 1000));
      if (galleryInfo.statusCode != 200) return null;
      _runtime.evaluate(galleryInfo.body);
      final jResult = _runtime.evaluate('hitomi_get_image_list()').stringResult;
      final jResultObject = jsonDecode(jResult);

      if (jResultObject is Map<dynamic, dynamic>) {
        return Tuple3<List<String>, List<String>, List<String>>(
            (jResultObject['result'] as List<dynamic>)
                .map((e) => e as String)
                .toList(),
            (jResultObject['btresult'] as List<dynamic>)
                .map((e) => e as String)
                .toList(),
            (jResultObject['stresult'] as List<dynamic>)
                .map((e) => e as String)
                .toList());
      } else {
        Logger.error('[script-HitomiGetImageList] E: JSError\n'
            'Id: $id\n'
            'Message: $jResult');
        return null;
      }
    } catch (e, st) {
      Logger.error('[script-HitomiGetImageList] E: $e\n'
          'Id: $id\n'
          '$st');
      return null;
    }
  }

  static Future<Map<String, String>> runHitomiGetHeaderContent(
      String id) async {
    if (_scriptCache == null) return <String, String>{};
    try {
      final jResult =
          _runtime.evaluate("hitomi_get_header_content('$id')").stringResult;
      final jResultObject = jsonDecode(jResult);

      if (jResultObject is Map<dynamic, dynamic>) {
        return Map<String, String>.from(jResultObject);
      } else {
        throw Exception('[script-HitomiGetHeaderContent] E: JSError\n'
            'Id: $id\n'
            'Message: $jResult');
      }
    } catch (e, st) {
      Logger.error('[script-HitomiGetHeaderContent] E: $e\n'
          'Id: $id\n'
          '$st');
      rethrow;
    }
  }
}
