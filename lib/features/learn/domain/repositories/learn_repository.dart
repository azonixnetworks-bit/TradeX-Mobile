typedef JsonMap = Map<String, dynamic>;

abstract interface class LearnRepository {
  Future<JsonMap> overview();
  Future<JsonMap> languages();
  Future<void> updateLanguage(String languageCode);
  Future<JsonMap> courses({String search = '', String access = ''});
  Future<JsonMap> course(String uuid);
  Future<JsonMap> module(String uuid);
  Future<JsonMap> lesson(String uuid);
  Future<JsonMap> myLearning(String view);
  Future<JsonMap> progress();
  Future<JsonMap> products();
  Future<JsonMap> paymentActivationStatus();
  Future<JsonMap> premiumAccess();
  Future<JsonMap> assignments(String status);
  Future<JsonMap> assignment(String uuid);
  Future<JsonMap> askAi(String question, {String? lessonUuid});
  Future<void> updateProgress(
    String lessonUuid, {
    required String status,
    String? videoUuid,
    int positionSeconds = 0,
  });
  Future<void> setBookmark(String lessonUuid, bool bookmarked);
  Future<JsonMap> playbackToken(String videoUuid);
  Future<JsonMap> whatsappAction(String assignmentUuid);

  dynamic get paymentGateway;

  String get courseLanguage;
  bool get learnLanguageSelected;
  String get themeModeName;
  Future<void> setThemeModeName(String value);

  static JsonMap map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  static List<dynamic> list(Object? value) => value is List ? value : const [];
  static String text(Object? value, [String fallback = '']) =>
      value?.toString().trim().isNotEmpty == true ? value.toString() : fallback;
  static int number(Object? value) => value is num ? value.toInt() : 0;
  static bool flag(Object? value) => value == true;
}
