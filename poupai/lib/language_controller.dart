import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  Locale _locale = const Locale('pt', 'BR');
  Locale get locale => _locale;

  LanguageController() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('idioma') ?? 'Português';

    switch (lang) {
      case 'English':
        _locale = const Locale('en', 'US');
        break;
      case 'Español':
        _locale = const Locale('es', 'ES');
        break;
      default:
        _locale = const Locale('pt', 'BR');
    }

    notifyListeners();
  }

  Future<void> changeLanguage(String langName) async {
    switch (langName) {
      case 'English':
        _locale = const Locale('en', 'US');
        break;
      case 'Español':
        _locale = const Locale('es', 'ES');
        break;
      default:
        _locale = const Locale('pt', 'BR');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idioma', langName);

    notifyListeners();
  }
}