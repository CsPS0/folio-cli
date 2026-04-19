import 'package:intl/intl.dart';

class KretaAPI {
  // IDP API
  static const login = BaseKreta.kretaIdp + KretaApiEndpoints.token;
  static const logout = BaseKreta.kretaIdp + KretaApiEndpoints.revoke;
  static const nonce = BaseKreta.kretaIdp + KretaApiEndpoints.nonce;
  static const clientId = "kreta-ellenorzo-student-mobile-ios";

  // ELLENORZO API
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
  static String averages(String iss, String uid) =>
      "${BaseKreta.kreta(iss)}${KretaApiEndpoints.averages}?oktatasiNevelesiFeladatUid=$uid";
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
}
