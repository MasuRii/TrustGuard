import 'package:flutter/material.dart';
import 'package:trustguard/src/generated/app_localizations.dart';

Widget wrapWithLocalization(Widget widget) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: widget,
  );
}

List<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
    AppLocalizations.localizationsDelegates;

List<Locale> get supportedLocales => AppLocalizations.supportedLocales;
