import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api.dart';

class KretaClient {
  String? accessToken;
  String? refreshToken;
  String instituteCode;

  KretaClient({required this.instituteCode});

  static Future<Map<String, String>> searchSchools(String query) async {
    if (query.length < 3) return {};
    try {
      final url = Uri.parse("https://intezmenykereso.e-kreta.hu/instituteSelector/${Uri.encodeComponent(query)}?showOnlyLive=true");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        // Egyszerű regex a dropdown-item elemek kinyerésére
        final regex = RegExp(r'<a[^>]*class="[^"]*dropdown-item[^"]*"[^>]*data-val="([^"]+)"[^>]*>(.*?)</a>', dotAll: true);
        final matches = regex.allMatches(body);
        final Map<String, String> results = {};
        for (var match in matches) {
          final code = match.group(1)?.trim();
          final textHtml = match.group(2) ?? '';
          // HTML tagek eltávolítása a megjelenített szövegből (pl. <br/>, <small>)
          final text = textHtml.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          if (code != null && code.isNotEmpty && text.isNotEmpty) {
            results[code] = text;
          }
        }
        return results;
      }
    } catch (e) {
      print('Hiba az intézménykeresés során: $e');
    }
    return {};
  }

  Future<bool> login(String username, String password) async {
    print('Bejelentkezés szimulálása az idp.e-kreta.hu oldalon...');
    
    final authorizeUrl = "https://idp.e-kreta.hu/connect/authorize?prompt=login&nonce=wylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU&response_type=code&code_challenge_method=S256&scope=openid%20email%20offline_access%20kreta-ellenorzo-webapi.public%20kreta-eugyintezes-webapi.public%20kreta-fileservice-webapi.public%20kreta-mobile-global-webapi.public%20kreta-dkt-webapi.public%20kreta-ier-webapi.public&code_challenge=HByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ&redirect_uri=https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect&client_id=kreta-ellenorzo-student-mobile-ios&state=folio_student_mobile";
    
    var client = http.Client();
    http.Response res1 = await client.get(Uri.parse(authorizeUrl));
    
    Map<String, String> cookieMap = {};
    void updateCookies(String? setCookieHeader) {
      if (setCookieHeader != null) {
        final parts = setCookieHeader.split(RegExp(r',(?=[a-zA-Z._\-]+=)'));
        for (var p in parts) {
          final kv = p.split(';').first.split('=');
          if (kv.length >= 2) {
            cookieMap[kv[0].trim()] = kv.sublist(1).join('=');
          }
        }
      }
    }
    
    String getCookieString() {
      return cookieMap.entries.map((e) => "${e.key}=${e.value}").join('; ');
    }
    
    updateCookies(res1.headers['set-cookie']);
    
    final body = res1.body;
    final tokenMatch = RegExp(r'name="__RequestVerificationToken"[^>]+value="([^"]+)"').firstMatch(body);
    final returnUrlMatch = RegExp(r'name="ReturnUrl"[^>]+value="([^"]+)"').firstMatch(body);
    
    if (tokenMatch == null || returnUrlMatch == null) {
      print('Nem sikerült kinyerni a bejelentkezési tokent a weblapból.');
      return false;
    }
    
    final requestToken = tokenMatch.group(1)!;
    final returnUrl = returnUrlMatch.group(1)!;
    
    final loginUrl = "https://idp.e-kreta.hu/Account/Login?ReturnUrl=${Uri.encodeComponent(returnUrl.replaceAll('&amp;', '&'))}";
    var request = http.Request('POST', Uri.parse(loginUrl));
    request.followRedirects = false;
    request.headers['cookie'] = getCookieString();
    request.headers['content-type'] = 'application/x-www-form-urlencoded';
    request.headers['user-agent'] = 'eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0';
    request.bodyFields = {
      'UserName': username,
      'Password': password,
      'InstituteCode': instituteCode,
      '__RequestVerificationToken': requestToken,
      'ReturnUrl': returnUrl.replaceAll('&amp;', '&'),
      'loginType': 'InstituteLogin',
      'button': 'login',
    };
    
    var res2 = await client.send(request);
    
    updateCookies(res2.headers['set-cookie']);
    
    String redirectUrl1 = "";
    if (res2.statusCode == 302) {
      redirectUrl1 = res2.headers['location']!;
    } else if (res2.statusCode == 200) {
      final html = await res2.stream.bytesToString();
      final btnMatch = RegExp(r'href="(/connect/authorize/callback[^"]+)"').firstMatch(html);
      if (btnMatch != null) {
        redirectUrl1 = btnMatch.group(1)!.replaceAll('&amp;', '&');
      } else {
        print('Hibás adatok, vagy a Kréta idp elutasított.');
        return false;
      }
    } else {
      print('Hiba a bejelentkezés POST kérésénél (statusCode: ${res2.statusCode}).');
      return false;
    }
    
    var req3 = http.Request('GET', Uri.parse(redirectUrl1.startsWith('http') ? redirectUrl1 : 'https://idp.e-kreta.hu$redirectUrl1'));
    req3.followRedirects = false;
    req3.headers['cookie'] = getCookieString();
    req3.headers['user-agent'] = 'eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0';
    
    var res3 = await client.send(req3);
    
    String finalRedirect = "";
    if (res3.statusCode == 302 || res3.statusCode == 301) {
      finalRedirect = res3.headers['location'] ?? res3.request!.url.toString();
    } else {
      finalRedirect = res3.request!.url.toString();
      if (!finalRedirect.contains('code=')) {
        final html = await res3.stream.bytesToString();
        final codeMatch = RegExp(r'code=([^"&\s]+)').firstMatch(html);
        final inputMatch = RegExp(r'name="code"[^>]+value="([^"]+)"').firstMatch(html);
        
        if (codeMatch != null) {
          finalRedirect = "https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect?code=${codeMatch.group(1)}";
        } else if (inputMatch != null) {
          finalRedirect = "https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect?code=${inputMatch.group(1)}";
        } else {
          try {
            await File('res3_debug.html').writeAsString(html);
          } catch (_) {}
          print('Nem kaptunk kódot a bejelentkezés végén (statusCode: ${res3.statusCode}).');
          return false;
        }
      }
    }
    
    if (!finalRedirect.contains('code=')) {
      print('Nem kaptunk kódot a bejelentkezés végén.');
      return false;
    }
    
    final code = Uri.parse(finalRedirect.replaceAll('#', '?')).queryParameters['code'];
    if (code == null) return false;
    
    final tokenUrl = Uri.parse(KretaAPI.login);
    final tokenRes = await client.post(tokenUrl, headers: {
      'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'user-agent': 'eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0',
    }, body: {
      "code": code,
      "code_verifier": "DSpuqj_HhDX4wzQIbtn8lr8NLE5wEi1iVLMtMK0jY6c",
      "redirect_uri": "https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect",
      "client_id": KretaAPI.clientId,
      "grant_type": "authorization_code",
    });
    
    if (tokenRes.statusCode == 200) {
      final data = jsonDecode(tokenRes.body);
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];
      return true;
    } else {
      print('Hiba a token lekérésekor: ${tokenRes.statusCode} - ${tokenRes.body}');
      return false;
    }
  }

  Future<bool> webLogin(String pastedUrl) async {
    final parsedUrl = Uri.tryParse(pastedUrl.replaceAll('#', '?'));
    final code = parsedUrl?.queryParameters['code'];
    
    if (code == null || code.isEmpty) {
      print('Nem található kód a megadott URL-ben.');
      return false;
    }
    
    final tokenUrl = Uri.parse(KretaAPI.login);
    final tokenRes = await http.post(tokenUrl, headers: {
      'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'user-agent': 'eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0',
    }, body: {
      "code": code,
      "code_verifier": "DSpuqj_HhDX4wzQIbtn8lr8NLE5wEi1iVLMtMK0jY6c",
      "redirect_uri": "https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect",
      "client_id": KretaAPI.clientId,
      "grant_type": "authorization_code",
    });
    
    if (tokenRes.statusCode == 200) {
      final data = jsonDecode(tokenRes.body);
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];
      return true;
    } else {
      print('Hiba a token lekérésekor: ${tokenRes.statusCode} - ${tokenRes.body}');
      return false;
    }
  }

  Future<dynamic> _getAPI(String url) async {
    if (accessToken == null) {
      throw Exception('Nincs bejelentkezve (hiányzó accessToken).');
    }

    final headers = {
      'authorization': 'Bearer $accessToken',
      'apiKey': '21ff6c25-d1da-4a68-a811-c881a6057463',
      'user-agent': 'eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Hiba az API lekérdezés során ($url): ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Kivétel az API lekérdezés során: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentData() async {
    final url = KretaAPI.student(instituteCode);
    final data = await _getAPI(url);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  Future<List<dynamic>?> getGrades() async {
    final url = KretaAPI.grades(instituteCode);
    final data = await _getAPI(url);
    if (data is List) {
      return data;
    }
    return null;
  }
}
