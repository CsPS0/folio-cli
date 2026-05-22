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
          var text = textHtml.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
          // HTML entitások dekódolása (pl. &#x171;, &#xE1;)
          text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
            return String.fromCharCode(int.parse(m.group(1)!, radix: 16));
          }).replaceAllMapped(RegExp(r'&#([0-9]+);'), (m) {
            return String.fromCharCode(int.parse(m.group(1)!));
          });

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
        try {
          await File('res2_debug.html').writeAsString(html);
        } catch (_) {}
        print('Hibás adatok, vagy a Kréta idp elutasított. Kimentve a res2_debug.html fájlba.');
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

  File _getCacheFile() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return File('$home/.folio_cache.json');
  }

  Map<String, dynamic> _loadCache() {
    final file = _getCacheFile();
    if (file.existsSync()) {
      try {
        return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  void _saveToCache(String url, dynamic data) {
    final cache = _loadCache();
    cache[url] = data;
    try {
      _getCacheFile().writeAsStringSync(jsonEncode(cache));
    } catch (_) {}
  }

  Future<dynamic> _getAPI(String url, {bool silent = false}) async {
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
        final data = jsonDecode(response.body);
        _saveToCache(url, data);
        return data;
      } else {
        if (!silent) {
          print('Hiba az API lekérdezés során ($url): ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (!silent) {
        print('\n[\x1B[33mOFFLINE MÓD\x1B[0m] Hálózat vagy szerver hiba, próbálkozás a gyorsítótárból...');
      }
      final cache = _loadCache();
      if (cache.containsKey(url)) {
        return cache[url];
      }
      print('Sajnos nincs elmentett adat ehhez a lekérdezéshez.');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentData({bool silent = false}) async {
    final url = KretaAPI.student(instituteCode);
    final data = await _getAPI(url, silent: silent);
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

  Future<List<dynamic>?> getTimetable(DateTime start, DateTime end) async {
    final url = KretaAPI.timetable(instituteCode, start: start, end: end);
    final data = await _getAPI(url);
    if (data is List) {
      return data;
    }
    return null;
  }

  Future<List<dynamic>?> getAbsences() async {
    final url = KretaAPI.absences(instituteCode);
    final data = await _getAPI(url);
    if (data is List) {
      return data;
    }
    return null;
  }

  Future<List<dynamic>?> getAverages() async {
    final url = KretaAPI.averages(instituteCode);
    final data = await _getAPI(url, silent: true);
    if (data is List) {
      return data;
    }

    // Fallback: Ha az API 500-as hibát dob, kiszámítjuk az átlagokat a jegyekből!
    final grades = await getGrades();
    if (grades != null) {
      final Map<String, List<Map<String, dynamic>>> subjectGrades = {};
      for (var grade in grades) {
        final tipus = grade['Tipus']?['Nev']?.toString().toLowerCase() ?? '';
        // Kizárjuk a félévi, év végi és egyéb összefoglaló jegyeket
        if (tipus.contains('vegi') || tipus.contains('felevevi') || tipus.contains('negyedevi')) {
          continue;
        }
        
        final subject = grade['Tantargy']?['Nev'];
        if (subject == null) continue;
        
        final numVal = grade['SzamErtek'];
        if (numVal == null || numVal == 0 || numVal > 5) continue;
        
        final weight = grade['SulySzazalekErteke'] ?? 100;
        
        subjectGrades.putIfAbsent(subject, () => []);
        subjectGrades[subject]!.add({
          'value': numVal is int ? numVal.toDouble() : double.parse(numVal.toString()),
          'weight': weight is int ? weight.toDouble() : double.parse(weight.toString())
        });
      }
      
      final List<dynamic> calculatedAverages = [];
      subjectGrades.forEach((subject, items) {
        double sum = 0;
        double weightSum = 0;
        for (var item in items) {
          sum += item['value'] * item['weight'];
          weightSum += item['weight'];
        }
        if (weightSum > 0) {
          calculatedAverages.add({
            'Tantargy': {'Nev': subject},
            'Ertek': (sum / weightSum).toStringAsFixed(2).replaceAll('.', ',')
          });
        }
      });
      return calculatedAverages;
    }

    return null;
  }

  Future<List<dynamic>?> getExams() async {
    final url = KretaAPI.exams(instituteCode);
    final data = await _getAPI(url);
    if (data is List) {
      return data;
    }
    return null;
  }

  Future<List<dynamic>?> getHomework({DateTime? start, String? id}) async {
    start ??= DateTime.now().subtract(Duration(days: 30));
    final url = KretaAPI.homework(instituteCode, start: start, id: id);
    final data = await _getAPI(url);
    if (data is List) {
      return data;
    }
    return null;
  }

  Future<List<dynamic>?> getMessages() async {
    final url = KretaAPI.messages();
    final data = await _getAPI(url);
    if (data is List) {
      return data;
    }
    return null;
  }

  Future<bool> refreshAccessToken() async {
    if (refreshToken == null) return false;
    
    final tokenUrl = Uri.parse(KretaAPI.login);
    try {
      final tokenRes = await http.post(tokenUrl, headers: {
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'user-agent': 'eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0',
      }, body: {
        "client_id": KretaAPI.clientId,
        "grant_type": "refresh_token",
        "refresh_token": refreshToken!,
      });
      
      if (tokenRes.statusCode == 200) {
        final data = jsonDecode(tokenRes.body);
        accessToken = data['access_token'];
        refreshToken = data['refresh_token'] ?? refreshToken;
        return true;
      }
    } catch (_) {}
    return false;
  }
}
