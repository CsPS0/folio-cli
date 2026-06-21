import 'package:intl/intl.dart';

class KretaAPI {
  static const login = BaseKreta.kretaIdp + KretaApiEndpoints.token;
  static const logout = BaseKreta.kretaIdp + KretaApiEndpoints.revoke;
  static const nonce = BaseKreta.kretaIdp + KretaApiEndpoints.nonce;

  static const clientId = 'kreta-ellenorzo-student-mobile-ios';
  static const codeVerifier = 'DSpuqj_HhDX4wzQIbtn8lr8NLE5wEi1iVLMtMK0jY6c';
  static const codeChallenge = 'HByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ';
  static const redirectUri = 'https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect';
  static const apiKey = '21ff6c25-d1da-4a68-a811-c881a6057463';
  static const userAgent = 'eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0';
  static const oauthNonce = 'wylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU';
  static const oauthScope = 'openid email offline_access kreta-ellenorzo-webapi.public kreta-eugyintezes-webapi.public kreta-fileservice-webapi.public kreta-mobile-global-webapi.public kreta-dkt-webapi.public kreta-ier-webapi.public';

  static String authorizeUrl({String? instituteCode}) {
    final scopeEncoded = Uri.encodeComponent(oauthScope);
    final base = '${BaseKreta.kretaIdp}/connect/authorize'
        '?prompt=login'
        '&nonce=$oauthNonce'
        '&response_type=code'
        '&code_challenge_method=S256'
        '&scope=$scopeEncoded'
        '&code_challenge=$codeChallenge'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&client_id=$clientId'
        '&state=folio_student_mobile';
    if (instituteCode != null) {
      return '$base&acr_values=institute_code:$instituteCode';
    }
    return base;
  }

  static Map<String, String> tokenRequestBody(String code) => {
        'code': code,
        'code_verifier': codeVerifier,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'grant_type': 'authorization_code',
      };

  static Map<String, String> refreshRequestBody(String refreshToken) => {
        'client_id': clientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      };

  static Map<String, String> get tokenHeaders => {
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'user-agent': userAgent,
      };

  static Map<String, String> apiHeaders(String accessToken) => {
        'authorization': 'Bearer $accessToken',
        'apiKey': apiKey,
        'user-agent': userAgent,
      };

  static String notes(String iss) =>
        BaseKreta.kreta(iss) + KretaApiEndpoints.notes;
    static String events(String iss) =>
        BaseKreta.kreta(iss) + KretaApiEndpoints.events;
    static String student(String iss) =>
        BaseKreta.kreta(iss) + KretaApiEndpoints.student;
    static String grades(String iss) =>
        BaseKreta.kreta(iss) + KretaApiEndpoints.grades;
    static String absences(String iss) =>
        BaseKreta.kreta(iss) + KretaApiEndpoints.absences;
    static String groups(String iss) =>
        BaseKreta.kreta(iss) + KretaApiEndpoints.groups;
    static String groupAverages(String iss, String uid) =>
        "${BaseKreta.kreta(iss)}${KretaApiEndpoints.groupAverages}?oktatasiNevelesiFeladatUid=$uid";
    static String averages(String iss) =>
        "${BaseKreta.kreta(iss)}${KretaApiEndpoints.averages}";
    static String timetable(String iss, {DateTime? start, DateTime? end}) =>
        BaseKreta.kreta(iss) +
        KretaApiEndpoints.timetable +
        (start != null && end != null
            ? "?datumTol=${start.toUtc().toIso8601String()}&datumIg=${end.toUtc().toIso8601String()}"
            : "");
    static String exams(String iss) =>
        BaseKreta.kreta(iss) + KretaApiEndpoints.exams;
    static String homework(String iss, {DateTime? start, String? id}) =>
        BaseKreta.kreta(iss) +
        KretaApiEndpoints.homework +
        (id != null ? "/$id" : "") +
        (id == null && start != null
            ? "?datumTol=${DateFormat('yyyy-MM-dd').format(start)}"
            : "");
    static String capabilities(String iss) =>
        BaseKreta.kreta(iss) + KretaApiEndpoints.capabilities;
    static String messages() =>
        BaseKreta.kretaAdmin + KretaApiEndpoints.messages;
}

class BaseKreta {
    static String kreta(String iss) => "https://$iss.e-kreta.hu";
    static const kretaIdp = "https://idp.e-kreta.hu";
    static const kretaAdmin = "https://eugyintezes.e-kreta.hu";
    static const kretaFiles = "https://files.e-kreta.hu";
    static const kretaNotification = "https://kretaglobalmobileapi2.ekreta.hu/api/v3";
}

class KretaApiEndpoints {
    static const token = "/connect/token";
    static const revoke = "/connect/revocation";
    static const nonce = "/nonce";
    static const notes = "/ellenorzo/V3/Sajat/Feljegyzesek";
    static const events = "/ellenorzo/V3/Sajat/FaliujsagElemek";
    static const student = "/ellenorzo/V3/Sajat/TanuloAdatlap";
    static const grades = "/ellenorzo/V3/Sajat/Ertekelesek";
    static const absences = "/ellenorzo/V3/Sajat/Mulasztasok";
    static const groups = "/ellenorzo/V3/Sajat/OsztalyCsoportok";
    static const groupAverages =
        "/ellenorzo/V3/Sajat/Ertekelesek/Atlagok/OsztalyAtlagok";
    static const averages =
        "/ellenorzo/V3/Sajat/Ertekelesek/Atlagok/TantargyiAtlagok";
    static const timetable = "/ellenorzo/V3/Sajat/OrarendElemek";
    static const exams = "/ellenorzo/V3/Sajat/BejelentettSzamonkeresek";
    static const homework = "/ellenorzo/V3/Sajat/HaziFeladatok";
    static const capabilities = "/ellenorzo/V3/Sajat/Intezmenyek";
    static const messages = "/api/v1/kommunikacio/postaladaelemek/sajat";
    static String message(int id) => "/api/v1/kommunikacio/postaladaelemek/$id";
}
