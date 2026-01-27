import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// States
class SettingsState {
  final bool isLowDataMode;
  final String language;

  const SettingsState({this.isLowDataMode = false, this.language = 'Français'});

  SettingsState copyWith({bool? isLowDataMode, String? language}) {
    return SettingsState(
      isLowDataMode: isLowDataMode ?? this.isLowDataMode,
      language: language ?? this.language,
    );
  }
}

// Cubit
class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _prefs;

  SettingsCubit(this._prefs) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final lowData = _prefs.getBool('isLowDataMode') ?? false;
    final lang = _prefs.getString('language') ?? 'Français';
    emit(state.copyWith(isLowDataMode: lowData, language: lang));
  }

  void toggleLowDataMode(bool value) {
    _prefs.setBool('isLowDataMode', value);
    emit(state.copyWith(isLowDataMode: value));
  }

  void setLanguage(String value) {
    _prefs.setString('language', value);
    emit(state.copyWith(language: value));
  }
}
