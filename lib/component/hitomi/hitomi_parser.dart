// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';

class HitomiParser {
  // Extract only title and artists
  static Future<Map<String, dynamic>> parseGalleryBlock(String html) async {
    var doc = (await compute(parse, html)).querySelector('div');

    var title = doc!.querySelector('h1')!.text.trim();
    var artists = ['N/A'];
    try {
      artists = doc
          .querySelector('div.artists-list')!
          .querySelectorAll('li')
          .map((e) => e.querySelector('a')!.text.trim())
          .toList();
    } catch (_) {}

    return {'Title': title, 'Artists': artists};
  }
}
