// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:violet/component/hitomi/shielder.dart';
import 'package:violet/database/user/download.dart';
import 'package:violet/log/log.dart';
import 'package:violet/settings/device_type.dart';

class Settings {
  // Color Settings
  static late Color themeColor; // default light
  static late bool themeWhat; // default false == light
  static late Color majorColor; // default purple
  static late Color majorAccentColor;
  static late int
      searchResultType; // 0: 3 Grid, 1: 2 Grid, 2: Big Line, 3: Detail
  static late int downloadResultType;
  static late int downloadAlignType;
  static late bool themeFlat;
  static late bool themeBlack; // default false
  static late bool useTabletMode;

  // Tag Settings
  static late String includeTags;
  static late List<String> excludeTags;
  static late List<String> blurredTags;
  static late String? language; // System Language
  static late bool translateTags;

  // Like this Hitomi.la => e-hentai => exhentai => nhentai
  static late List<String> routingRule; // image routing rule
  static late List<String> searchRule;
  static late bool searchNetwork;

  // Global? English? Korean?
  static late String databaseType;

  // Reader Option
  static late bool rightToLeft;
  static late bool isHorizontal;
  static late bool scrollVertical;
  static late bool animation;
  static late bool padding;
  static late bool disableOverlayButton;
  static late bool disableFullScreen;
  static late bool enableTimer;
  static late double timerTick;
  static late bool moveToAppBarToBottom;
  static late bool showSlider;
  static late int imageQuality;
  static late int thumbSize;
  static late bool enableThumbSlider;
  static late bool showPageNumberIndicator;
  static late bool showRecordJumpMessage;

  // Download Options
  static late bool useInnerStorage;
  static late String downloadBasePath;
  static late String downloadRule;

  static late String searchMessageAPI;
  static late bool useVioletServer;

  static late bool useDrawer;

  static late bool useOptimizeDatabase;

  static late bool useLowPerf;

  // View Option
  static late bool showArticleProgress;

  // Search Option
  static late bool searchUseFuzzy;
  static late bool searchTagTranslation;
  static late bool searchUseTranslated;
  static late bool searchShowCount;
  static late bool searchPure;

  static late String userAppId;

  static late bool autobackupBookmark;

  // Lab
  static late bool simpleItemWidgetLoadingIcon;
  static late bool showNewViewerWhenArtistArticleListItemTap;
  static late bool enableViewerFunctionBackdropFilter;
  static late bool usingPushReplacementOnArticleRead;
  static late bool downloadEhRawImage;
  static late bool bookmarkScrollbarPositionToLeft;

  static late bool useLockScreen;
  static late bool useSecureMode;

  static Future<void> initFirst() async {
    final prefs = await SharedPreferences.getInstance();

    var mc = await _getInt('majorColor', Colors.purple.value);
    var mac = await _getInt('majorAccentColor', Colors.purpleAccent.value);

    majorColor = Color(mc);
    majorAccentColor = Color(mac);

    themeWhat = await _getBool('themeColor');
    themeColor = !themeWhat ? Colors.white : Colors.black;
    themeFlat = await _getBool('themeFlat');
    themeBlack = await _getBool('themeBlack');

    language = prefs.getString('language');

    useLockScreen = await _getBool('useLockScreen');
    useSecureMode = await _getBool('useSecureMode');
    await _setSecureMode();

    await _getInt('thread_count', 4);
  }

  static Future<void> _setSecureMode() async {
    if (Platform.isAndroid) {
      if (Settings.useSecureMode) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } else {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    }
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    searchResultType = await _getInt('searchResultType');
    downloadResultType = await _getInt('downloadResultType', 3);
    downloadAlignType = await _getInt('downloadAlignType', 0);

    var includetags = prefs.getString('includetags');
    var excludetags = prefs.getString('excludetags');
    var blurredtags = prefs.getString('blurredtags');

    if (includetags == null) {
      var language = 'lang:english';
      var langcode = Platform.localeName.split('_')[0];
      if (langcode == 'ko') {
        language = 'lang:korean';
      } else if (langcode == 'ja') {
        language = 'lang:japanese';
      } else if (langcode == 'zh') {
        language = 'lang:chinese';
      }
      includetags = '($language)';
      await prefs.setString('includetags', includetags);
    }
    if (excludetags == null ||
        excludetags == MinorShielderFilter.tags.join('|')) {
      excludetags = '';
      await prefs.setString('excludetags', excludetags);
    }
    includeTags = includetags;
    excludeTags = excludetags.split('|').toList();
    blurredTags = blurredtags != null ? blurredtags.split(' ').toList() : [];
    translateTags = await _getBool('translatetags');

    routingRule = (await _getString(
            'routingrule', 'Hitomi|EHentai|ExHentai|Hiyobi|NHentai'))
        .split('|');
    searchRule =
        (await _getString('searchrule', 'Hitomi|EHentai|ExHentai|NHentai'))
            .split('|');
    searchNetwork = await _getBool('searchnetwork');

    if (!routingRule.contains('Hiyobi')) {
      routingRule.add('Hiyobi');
      await prefs.setString('routingrule', routingRule.join('|'));
    }

    var databasetype = prefs.getString('databasetype');
    if (databasetype == null) {
      var langcode = Platform.localeName.split('_')[0];
      var acclc = ['ko', 'ja', 'en', 'ru', 'zh'];

      if (!acclc.contains(langcode)) langcode = 'global';

      databasetype = langcode;

      await prefs.setString('databasetype', langcode);
    }
    databaseType = databasetype;

    rightToLeft = await _getBool('right2left', true);
    isHorizontal = await _getBool('ishorizontal');
    scrollVertical = await _getBool('scrollvertical');
    animation = await _getBool('animation');
    padding = await _getBool('padding');
    disableOverlayButton = await _getBool('disableoverlaybutton');
    disableFullScreen = await _getBool('disablefullscreen');
    enableTimer = await _getBool('enabletimer');
    timerTick = await _getDouble('timertick', 1.0);
    moveToAppBarToBottom =
        await _getBool('movetoappbartobottom', Platform.isIOS);
    showSlider = await _getBool('showslider');
    imageQuality = await _getInt('imagequality', 3);
    thumbSize = await _getInt('imageQuality', 0);
    enableThumbSlider = await _getBool('enableThumbSlider');
    showPageNumberIndicator = await _getBool('showPageNumberIndicator', true);
    showRecordJumpMessage = await _getBool('showRecordJumpMessage', true);

    var tUseInnerStorage = prefs.getBool('useinnerstorage');
    if (tUseInnerStorage == null) {
      tUseInnerStorage = Platform.isIOS;
      if (Platform.isAndroid) {
        var deviceInfoPlugin = DeviceInfoPlugin();
        final androidInfo = await deviceInfoPlugin.androidInfo;
        if (androidInfo.version.sdkInt! >= 30) tUseInnerStorage = true;
      }

      await prefs.setBool('userinnerstorage', tUseInnerStorage);
    }
    useInnerStorage = tUseInnerStorage;

    String? tDownloadBasePath;
    if (Platform.isAndroid) {
      tDownloadBasePath = prefs.getString('downloadbasepath');
      final String path = await ExtStorage.getExternalStorageDirectory();

      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var sdkInt = androidInfo.version.sdkInt!;

      if (sdkInt >= 30 && prefs.getBool('android30downpath') == null) {
        await prefs.setBool('android30downpath', true);
        var ext = await getExternalStorageDirectory();
        tDownloadBasePath = ext!.path;
        await prefs.setString('downloadbasepath', tDownloadBasePath);
      }

      if (tDownloadBasePath == null) {
        tDownloadBasePath = join(path, '.violet');
        await prefs.setString('downloadbasepath', tDownloadBasePath);
      }

      if (sdkInt < 30 &&
          tDownloadBasePath == join(path, 'Violet') &&
          prefs.getBool('downloadbasepathcc1') == null) {
        tDownloadBasePath = join(path, '.violet');
        await prefs.setString('downloadbasepath', tDownloadBasePath);
        await prefs.setBool('downloadbasepathcc1', true);

        try {
          if (await Permission.storage.isGranted) {
            var prevDir = Directory(join(path, 'Violet'));
            if (await prevDir.exists()) {
              await prevDir.rename(join(path, '.violet'));
            }

            var downloaded =
                await (await Download.getInstance()).getDownloadItems();
            for (var download in downloaded) {
              Map<String, dynamic> result =
                  Map<String, dynamic>.from(download.result);
              if (download.files() != null) {
                result['Files'] =
                    download.files()!.replaceAll('/Violet/', '/.violet/');
              }
              if (download.path() != null) {
                result['Path'] =
                    download.path()!.replaceAll('/Violet/', '/.violet/');
              }
              download.result = result;
              await download.update();
            }
          }
        } catch (e, st) {
          Logger.error('[Settings] E: $e\n'
              '$st');
          FirebaseCrashlytics.instance.recordError(e, st);
        }
      }
    } else if (Platform.isIOS) {
      tDownloadBasePath = await _getString('downloadbasepath', 'not supported');
    }
    downloadBasePath = tDownloadBasePath!;

    downloadRule = await _getString(
        'downloadrule', '%(extractor)s/%(id)s/%(file)s.%(ext)s');
    searchMessageAPI = await _getString(
        'searchmessageapi', 'https://koromo.xyz/api/search/msg');

    useVioletServer = await _getBool('usevioletserver');
    useDrawer = await _getBool('usedrawer');
    showArticleProgress = await _getBool('showarticleprogress');
    useOptimizeDatabase = await _getBool('useoptimizedatabase', true);

    useLowPerf = await _getBool('uselowperf', true);

    searchUseFuzzy = await _getBool('searchusefuzzy');
    searchTagTranslation = await _getBool('searchtagtranslation');
    searchUseTranslated = await _getBool('searchusetranslated');
    searchShowCount = await _getBool('searchshowcount', true);
    searchPure = await _getBool('searchPure');

    // main에서 셋팅됨
    userAppId = prefs.getString('fa_userid')!;

    autobackupBookmark = await _getBool('autobackupbookmark', false);

    useTabletMode = await _getBool('usetabletmode', Device.get().isTablet);

    simpleItemWidgetLoadingIcon =
        await _getBool('simpleItemWidgetLoadingIcon', true);
    showNewViewerWhenArtistArticleListItemTap =
        await _getBool('showNewViewerWhenArtistArticleListItemTap', true);
    enableViewerFunctionBackdropFilter =
        await _getBool('enableViewerFunctionBackdropFilter');
    usingPushReplacementOnArticleRead =
        await _getBool('usingPushReplacementOnArticleRead', true);
    downloadEhRawImage = await _getBool('downloadEhRawImage');
    bookmarkScrollbarPositionToLeft =
        await _getBool('bookmarkScrollbarPositionToLeft');

    await regacy1_20_2();
  }

  static Future regacy1_20_2() async {
    if (await _checkLegacyExists('regacy1_20_2')) return;

    if (!simpleItemWidgetLoadingIcon) {
      await setSimpleItemWidgetLoadingIcon(true);
    }
    if (!showNewViewerWhenArtistArticleListItemTap) {
      await setShowNewViewerWhenArtistArticleListItemTap(true);
    }
  }

  static Future<bool> _checkLegacyExists(String name) async {
    final prefs = await SharedPreferences.getInstance();
    var nn = prefs.getBool(name);
    if (nn == null) {
      await prefs.setBool(name, true);
      return false;
    }
    return true;
  }

  static Future<bool> _getBool(String key, [bool defaultValue = false]) async {
    final prefs = await SharedPreferences.getInstance();
    var nn = prefs.getBool(key);
    if (nn == null) {
      nn = defaultValue;
      await prefs.setBool(key, nn);
    }
    return nn;
  }

  static Future<int> _getInt(String key, [int defaultValue = 0]) async {
    final prefs = await SharedPreferences.getInstance();
    var nn = prefs.getInt(key);
    if (nn == null) {
      nn = defaultValue;
      await prefs.setInt(key, nn);
    }
    return nn;
  }

  static Future<String> _getString(String key,
      [String defaultValue = '']) async {
    final prefs = await SharedPreferences.getInstance();
    var nn = prefs.getString(key);
    if (nn == null) {
      nn = defaultValue;
      await prefs.setString(key, nn);
    }
    return nn;
  }

  static Future<double> _getDouble(String key,
      [double defaultValue = 0.0]) async {
    final prefs = await SharedPreferences.getInstance();
    var nn = prefs.getDouble(key);
    if (nn == null) {
      nn = defaultValue;
      await prefs.setDouble(key, nn);
    }
    return nn;
  }

  static Future<String> getDefaultDownloadPath() async {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    var sdkInt = androidInfo.version.sdkInt!;

    if (sdkInt >= 30) {
      var ext = await getExternalStorageDirectory();
      downloadBasePath = ext!.path;
    }

    if (downloadBasePath == null) {
      final String path = await ExtStorage.getExternalStorageDirectory();
      downloadBasePath = join(path, '.violet');
    }

    return downloadBasePath;
  }

  static Future<void> setThemeWhat(bool wh) async {
    themeWhat = wh;
    if (!themeWhat) {
      themeColor = Colors.white;
    } else {
      themeColor = Colors.black;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('themeColor', themeWhat);
  }

  static Future<void> setThemeBlack(bool wh) async {
    themeBlack = wh;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('themeBlack', themeBlack);
  }

  static Future<void> setThemeFlat(bool nn) async {
    themeFlat = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('themeFlat', nn);
  }

  static Future<void> setMajorColor(Color color) async {
    if (majorColor == color) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('majorColor', color.value);
    majorColor = color;

    Color? accent;
    for (int i = 0; i < Colors.primaries.length - 2; i++) {
      if (color.value == Colors.primaries[i].value) {
        accent = Colors.accents[i];
        break;
      }
    }

    if (accent == null) {
      if (color == Colors.grey) {
        accent = Colors.grey.shade700;
      } else if (color == Colors.brown) {
        accent = Colors.brown.shade700;
      } else if (color == Colors.blueGrey) {
        accent = Colors.blueGrey.shade700;
      } else if (color == Colors.black) {
        accent = Colors.black;
      }
    }

    await prefs.setInt('majorAccentColor', accent!.value);
    majorAccentColor = accent;
  }

  static Future<void> setSearchResultType(int wh) async {
    searchResultType = wh;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('searchResultType', searchResultType);
  }

  static Future<void> setDownloadResultType(int wh) async {
    downloadResultType = wh;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('downloadResultType', downloadResultType);
  }

  static Future<void> setDownloadAlignType(int wh) async {
    downloadAlignType = wh;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('downloadAlignType', downloadAlignType);
  }

  static Future<void> setLanguage(String lang) async {
    language = lang;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  static Future<void> setIncludeTags(String nn) async {
    includeTags = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('includetags', includeTags);
  }

  static Future<void> setExcludeTags(String nn) async {
    excludeTags = nn.split(' ').toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('excludetags', excludeTags.join('|'));
  }

  static Future<void> setBlurredTags(String nn) async {
    blurredTags = nn.split(' ').toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('blurredtags', blurredTags.join('|'));
  }

  static Future<void> setTranslateTags(bool nn) async {
    translateTags = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('translatetags', translateTags);
  }

  static Future<void> setRightToLeft(bool nn) async {
    rightToLeft = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('right2left', rightToLeft);
  }

  static Future<void> setIsHorizontal(bool nn) async {
    isHorizontal = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ishorizontal', isHorizontal);
  }

  static Future<void> setScrollVertical(bool nn) async {
    scrollVertical = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scrollvertical', scrollVertical);
  }

  static Future<void> setAnimation(bool nn) async {
    animation = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animation', animation);
  }

  static Future<void> setPadding(bool nn) async {
    padding = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('padding', padding);
  }

  static Future<void> setDisableOverlayButton(bool nn) async {
    disableOverlayButton = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disableoverlaybutton', disableOverlayButton);
  }

  static Future<void> setDisableFullScreen(bool nn) async {
    disableFullScreen = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disablefullscreen', disableFullScreen);
  }

  static Future<void> setEnableTimer(bool nn) async {
    enableTimer = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enabletimer', enableTimer);
  }

  static Future<void> setTimerTick(double nn) async {
    timerTick = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('timertick', timerTick);
  }

  static Future<void> setMoveToAppBarToBottom(bool nn) async {
    moveToAppBarToBottom = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('movetoappbartobottom', nn);
  }

  static Future<void> setImageQuality(int nn) async {
    imageQuality = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('imagequality', imageQuality);
  }

  static Future<void> setThumbSize(int nn) async {
    thumbSize = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('thumbSize', thumbSize);
  }

  static Future<void> setEnableThumbSlider(bool nn) async {
    enableThumbSlider = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableThumbSlider', enableThumbSlider);
  }

  static Future<void> setShowPageNumberIndicator(bool nn) async {
    showPageNumberIndicator = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPageNumberIndicator', showPageNumberIndicator);
  }

  static Future<void> setShowRecordJumpMessage(bool nn) async {
    showRecordJumpMessage = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showRecordJumpMessage', showRecordJumpMessage);
  }

  static Future<void> setShowSlider(bool nn) async {
    showSlider = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showslider', nn);
  }

  static Future<void> setSearchOnWeb(bool nn) async {
    searchNetwork = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('searchnetwork', nn);
  }

  static Future<void> setSearchPure(bool nn) async {
    searchPure = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('searchPure', nn);
  }

  static Future<void> setUseVioletServer(bool nn) async {
    useVioletServer = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usevioletserver', nn);
  }

  static Future<void> setUseDrawer(bool nn) async {
    useDrawer = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usedrawer', nn);
  }

  static Future<void> setBaseDownloadPath(String nn) async {
    downloadBasePath = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloadbasepath', nn);
  }

  static Future<void> setDownloadRule(String nn) async {
    downloadRule = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloadrule', nn);
  }

  static Future<void> setSearchMessageAPI(String nn) async {
    searchMessageAPI = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchmessageapi', nn);
  }

  static Future<void> setUserInnerStorage(bool nn) async {
    useInnerStorage = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useinnerstorage', nn);
  }

  static Future<void> setShowArticleProgress(bool nn) async {
    showArticleProgress = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showarticleprogress', nn);
  }

  static Future<void> setUseOptimizeDatabase(bool nn) async {
    useOptimizeDatabase = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useoptimizedatabase', nn);
  }

  static Future<void> setUseLowPerf(bool nn) async {
    useLowPerf = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('uselowperf', nn);
  }

  static Future<void> setSearchUseFuzzy(bool nn) async {
    searchUseFuzzy = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('searchusefuzzy', nn);
  }

  static Future<void> setSearchTagTranslation(bool nn) async {
    searchTagTranslation = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('searchtagtranslation', nn);
  }

  static Future<void> setSearchUseTranslated(bool nn) async {
    searchUseTranslated = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('searchusetranslated', nn);
  }

  static Future<void> setSearchShowCount(bool nn) async {
    searchShowCount = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('searchshowcount', nn);
  }

  static Future<void> setAutoBackupBookmark(bool nn) async {
    autobackupBookmark = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autobackupbookmark', nn);
  }

  static Future<void> setUseTabletMode(bool nn) async {
    useTabletMode = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usetabletmode', nn);
  }

  static Future<void> setSimpleItemWidgetLoadingIcon(bool nn) async {
    simpleItemWidgetLoadingIcon = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('simpleItemWidgetLoadingIcon', nn);
  }

  static Future<void> setShowNewViewerWhenArtistArticleListItemTap(
      bool nn) async {
    showNewViewerWhenArtistArticleListItemTap = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showNewViewerWhenArtistArticleListItemTap', nn);
  }

  static Future<void> setEnableViewerFunctionBackdropFilter(bool nn) async {
    enableViewerFunctionBackdropFilter = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableViewerFunctionBackdropFilter', nn);
  }

  static Future<void> setUsingPushReplacementOnArticleRead(bool nn) async {
    usingPushReplacementOnArticleRead = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usingPushReplacementOnArticleRead', nn);
  }

  static Future<void> setDownloadEhRawImage(bool nn) async {
    downloadEhRawImage = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloadEhRawImage', nn);
  }

  static Future<void> setBookmarkScrollbarPositionToLeft(bool nn) async {
    bookmarkScrollbarPositionToLeft = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bookmarkScrollbarPositionToLeft', nn);
  }

  static Future<void> setUseLockScreen(bool nn) async {
    useLockScreen = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useLockScreen', nn);
  }

  static Future<void> setUseSecureMode(bool nn) async {
    useSecureMode = nn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSecureMode', nn);
  }
}
