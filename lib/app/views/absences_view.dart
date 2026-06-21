part of '../cli_app.dart';

extension FolioCliAppAbsencesView on FolioCliApp {
  Future<void> _showAbsences() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
        final action = Select(
          prompt: 'Mulasztások',
          options: ['Legutóbbi 10 mulasztás', 'Összes mulasztás', 'Veszélyzóna Kalkulátor', 'Vissza'],
        ).interact();
  
        if (action == 3) return;
        _clearScreen();
        
        final absences = await _client!.getAbsences();
        if (absences == null) {
          print('Nem sikerült lekérdezni a mulasztásokat.');
          print('');
          continue;
        }

        if (action == 2) {
          print('\n--- 🚨 Veszélyzóna Kalkulátor 🚨 ---');
          print('Kiszámoljuk, mennyire vagy közel a kritikus 250 órás (vagy 30%-os) határhoz.');
          int totalAbsences = absences.length;
          double percent = (totalAbsences / 250.0) * 100;
          print('Összes mulasztott órád: \x1B[1;36m$totalAbsences / 250\x1B[0m (\x1B[1;33m${percent.toStringAsFixed(1)}%\x1B[0m)');
          
          if (totalAbsences >= 250) {
            print('\x1B[1;31m[!] FIGYELEM: Átlépted a 250 órás határt! Osztályozóvizsgára kötelezhetnek!\x1B[0m');
          } else if (totalAbsences >= 200) {
            print('\x1B[1;31m[!] KÖZEL A HATÁR: Nagyon vigyázz, majdnem elérted a 250 órát!\x1B[0m');
          } else if (totalAbsences >= 150) {
            print('\x1B[1;33m[!] FIGYELMEZTETÉS: Kezd felgyűlni a hiányzásod.\x1B[0m');
          } else {
            print('\x1B[1;32m[OK] Biztonságos zónában vagy.\x1B[0m');
          }

          final Map<String, int> missedBySubject = {};
          for (var a in absences) {
            final s = AppState.instance.applyAlias(a.subject);
            missedBySubject[s] = (missedBySubject[s] ?? 0) + 1;
          }
          print('\nTantárgyak szerinti mulasztások (Figyelj a 30%-os szabályra!):');
          final sortedMissed = missedBySubject.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          for (var e in sortedMissed.take(5)) {
            print(' - ${e.key}: \x1B[1;33m${e.value} óra\x1B[0m');
          }
          print('');
          _pause();
          continue;
        }

        print('\n--- Mulasztások ---');
        if (absences.isEmpty) {
          print('Nincsenek mulasztások.');
        } else {
          absences.sort((a, b) {
            final dateA = a.date ?? DateTime(2000);
            final dateB = b.date ?? DateTime(2000);
            return dateB.compareTo(dateA); // Legújabb elöl
          });
  
          final limit = action == 0 ? 10 : absences.length;
          for (var absence in absences.take(limit)) {
            final dateStr = absence.date?.toString().split(' ').first.split('T').first ?? '';
            final subject = absence.subject;
            final status = absence.status;
            
            String coloredStatus = status;
            final sLower = status.toLowerCase();
            final tLower = absence.type?.toLowerCase() ?? '';
            
            if (tLower == 'késés' || sLower == 'késés') {
              coloredStatus = '\x1B[38;5;208m$status\x1B[0m';
            } else if (sLower == 'igazolt') {
              coloredStatus = '\x1B[92m$status\x1B[0m';
            } else if (sLower == 'igazolando' || sLower == 'igazolandó') {
              coloredStatus = '\x1B[33m$status\x1B[0m';
            } else if (sLower == 'igazolatlan') {
              coloredStatus = '\x1B[31m$status\x1B[0m';
            }
            
            print('[$dateStr] $subject ($coloredStatus)');
          }
          if (action == 0 && absences.length > 10) {
            print('  ... és még ${absences.length - 10} régebbi mulasztás.');
          }
        }
        _pause();
      }
    }

  Future<void> _showAverages() async {
      while (true) {
        if (!await _ensureClientReady()) return;
        _clearScreen();
        _showMainMenuBanner();
        
        final action = Select(
          prompt: 'Tantárgyi átlagok',
          options: [
            'Átlagok részletesen (Táblázat)',
            'Átlagok grafikonon (Oszlopdiagram)',
            'Célátlag kalkulátor',
            'Bizonyítvány Tervező (Minden tárgy célzása)',
            'Jegy-trendek (Éves Grafikon)',
            'Vissza'
          ],
        ).interact();
  
        if (action == 5) return;
        if (action == 2) {
          await _showTargetAverageCalculator();
          continue;
        }
        if (action == 3) {
          await _showBulkGradeTargeter();
          continue;
        }
        
        if (action == 4) {
          _clearScreen();
          print('\n--- Jegy-trendek (Éves Grafikon) ---');
          print('Adatok lekérése...');
          final grades = await _client!.getGrades();
          if (grades != null && grades.isNotEmpty) {
            // 1. Generate weekly cumulative average trend data
            final now = DateTime.now();
            final currentYear = now.month >= 9 ? now.year : now.year - 1;
            final schoolStart = DateTime(currentYear, 9, 1);
            
            final values = <double>[];
            final labels = <String>[];
            
            DateTime currentWeekStart = schoolStart;
            while (currentWeekStart.isBefore(now)) {
              final cutoff = currentWeekStart.add(const Duration(days: 7));
              
              final gradesUpToWeek = grades.where((g) =>
                  g.date != null &&
                  g.date!.isBefore(cutoff) &&
                  g.numericValue != null &&
                  g.numericValue! >= 1 &&
                  g.numericValue! <= 5 &&
                  !g.isSummaryGrade
              ).toList();
              
              if (gradesUpToWeek.isNotEmpty) {
                double wSum = 0.0;
                double valSum = 0.0;
                for (var g in gradesUpToWeek) {
                  double w = g.weight;
                  if (w == 0) w = 100;
                  valSum += g.numericValue! * w;
                  wSum += w;
                }
                if (wSum > 0) {
                  values.add(valSum / wSum);
                  
                  final weekMonth = currentWeekStart.month;
                  final monthNamesShort = {
                    9: 'Sze', 10: 'Okt', 11: 'Nov', 12: 'Dec',
                    1: 'Jan', 2: 'Feb', 3: 'Már', 4: 'Ápr',
                    5: 'Máj', 6: 'Jún', 7: 'Júl', 8: 'Aug'
                  };
                  
                  // Label only the first week of each month
                  final isFirstOfMonth = values.length == 1 || 
                      currentWeekStart.month != currentWeekStart.subtract(const Duration(days: 7)).month;
                  
                  if (isFirstOfMonth) {
                    labels.add(monthNamesShort[weekMonth] ?? '   ');
                  } else {
                    labels.add('   ');
                  }
                }
              }
              currentWeekStart = currentWeekStart.add(const Duration(days: 7));
            }

            // 2. Grade distribution calculations
            final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
            int validGradesCount = 0;
            double sum = 0.0;
            double weightSum = 0.0;
            
            for (var g in grades) {
              if (g.numericValue != null &&
                  g.numericValue! >= 1 &&
                  g.numericValue! <= 5 &&
                  !g.isSummaryGrade) {
                final val = g.numericValue!.toInt();
                distribution[val] = (distribution[val] ?? 0) + 1;
                validGradesCount++;
                
                double w = g.weight;
                if (w == 0) w = 100;
                sum += g.numericValue! * w;
                weightSum += w;
              }
            }

            // 3. Best/Worst month calculations (non-cumulative)
            final monthNamesLong = {
              9: 'Szeptember', 10: 'Október', 11: 'November', 12: 'December',
              1: 'Január', 2: 'Február', 3: 'Március', 4: 'Április',
              5: 'Május', 6: 'Június', 7: 'Július', 8: 'Augusztus'
            };
            
            final monthlySums = <int, double>{};
            final monthlyWeightSums = <int, double>{};
            for (var g in grades) {
              if (g.date != null &&
                  g.numericValue != null &&
                  g.numericValue! >= 1 &&
                  g.numericValue! <= 5 &&
                  !g.isSummaryGrade) {
                final m = g.date!.month;
                double w = g.weight;
                if (w == 0) w = 100;
                monthlySums[m] = (monthlySums[m] ?? 0.0) + g.numericValue! * w;
                monthlyWeightSums[m] = (monthlyWeightSums[m] ?? 0.0) + w;
              }
            }
            
            int? bestMonth;
            double bestMonthAvg = 0.0;
            int? worstMonth;
            double worstMonthAvg = 99.0;
            
            monthlySums.forEach((m, sumVal) {
              final wSum = monthlyWeightSums[m] ?? 0.0;
              if (wSum > 0) {
                final avg = sumVal / wSum;
                if (avg > bestMonthAvg) {
                  bestMonthAvg = avg;
                  bestMonth = m;
                }
                if (avg < worstMonthAvg) {
                  worstMonthAvg = avg;
                  worstMonth = m;
                }
              }
            });

            int modeGrade = 5;
            int modeCount = 0;
            distribution.forEach((grade, count) {
              if (count > modeCount) {
                modeCount = count;
                modeGrade = grade;
              }
            });

            // 4. Render Dashboard
            if (values.isNotEmpty) {
              print('\nAz év során így változott a kumulatív átlagod (hetente követve):');
              print(ChartGenerator.generateLineChart(values, labels: labels));
            } else {
              print('Nincsenek számítható jegyek a grafikonhoz.');
            }

            print('\n\x1B[1mTanulmányi statisztikák:\x1B[0m');
            final currentAvgStr = weightSum > 0 ? (sum / weightSum).toStringAsFixed(2) : '-';
            final bestMonthStr = bestMonth != null ? '${monthNamesLong[bestMonth]} (${bestMonthAvg.toStringAsFixed(2)})' : '-';
            final worstMonthStr = worstMonth != null ? '${monthNamesLong[worstMonth]} (${worstMonthAvg.toStringAsFixed(2)})' : '-';
            final modeName = {5: '5-ös', 4: '4-es', 3: '3-as', 2: '2-es', 1: '1-es'};
            final modeStr = modeCount > 0 ? '${modeName[modeGrade]} ($modeCount db)' : '-';
            
            print('  • Jelenlegi átlag: \x1B[1;36m$currentAvgStr\x1B[0m');
            print('  • Összes jegy száma: \x1B[1m$validGradesCount db\x1B[0m');
            print('  • Leggyakoribb jegy: \x1B[1m$modeStr\x1B[0m');
            if (bestMonth != null) {
              print('  • Legjobb hónap: \x1B[92m$bestMonthStr\x1B[0m');
            }
            if (worstMonth != null) {
              print('  • Leggyengébb hónap: \x1B[91m$worstMonthStr\x1B[0m');
            }

            print('\n\x1B[1mJegyek eloszlása:\x1B[0m');
            final gradeLabels = {
              5: '5 (Kiváló)   ',
              4: '4 (Jó)       ',
              3: '3 (Közepes)  ',
              2: '2 (Elégséges)',
              1: '1 (Elégtelen)',
            };
            
            final gradeColors = {
              5: '\x1B[94m', // Blue
              4: '\x1B[92m', // Green
              3: '\x1B[93m', // Yellow
              2: '\x1B[38;5;208m', // Orange
              1: '\x1B[91m', // Red
            };
            
            for (int grade = 5; grade >= 1; grade--) {
              final count = distribution[grade] ?? 0;
              final percent = validGradesCount > 0 ? (count / validGradesCount * 100) : 0.0;
              
              int barWidth = 0;
              if (validGradesCount > 0) {
                barWidth = ((count / validGradesCount) * 30).round();
              }
              final bar = '█' * barWidth;
              final color = gradeColors[grade] ?? '\x1B[0m';
              
              final label = gradeLabels[grade]!;
              final countStr = '$count db'.padLeft(5);
              final pctStr = '${percent.toStringAsFixed(1)}%'.padLeft(6);
              
              print('  $label | $color$bar\x1B[0m${" " * (30 - barWidth)} | $countStr ($pctStr)');
            }
          } else {
            print('Nincs elég adat a grafikonhoz.');
          }
          _pause();
          continue;
        }

        if (action == 1) {
          _clearScreen();
          print('\n--- Átlagok grafikonon ---');
          print('Adatok lekérése...');
          final averages = await _client!.getAverages();
          if (averages != null) {
            if (averages.isEmpty) {
              print('Nincsenek átlagok.');
            } else {
              final Map<String, double> chartData = {};
              for (var avg in averages) {
                final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
                final valueStr = avg['Ertek']?.toString() ?? '0';
                final value = double.tryParse(valueStr.replaceAll(',', '.')) ?? 0.0;
                if (value > 0) {
                  chartData[subject] = value;
                }
              }
              if (chartData.isNotEmpty) {
                print(ChartGenerator.generateBarChart(chartData));
              } else {
                for (var avg in averages) {
                  final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
                  final value = avg['Ertek']?.toString() ?? '-';
                  print('$subject: $value');
                }
              }
            }
          } else {
            print('Nem sikerült lekérdezni az átlagokat.');
          }
          _pause();
          continue;
        }
        
        _clearScreen();
        print('\n--- Tantárgyi átlagok részletesen ---');
        print('Adatok lekérése...');
        
        final results = await Future.wait([
          _client!.getAverages(),
          _client!.getGroupAverages(),
          _client!.getGrades(),
        ]);
        
        final List<dynamic>? averages = results[0];
        final List<dynamic>? classAverages = results[1];
        final List<Grade>? grades = results[2] as List<Grade>?;

        if (averages != null) {
          if (averages.isEmpty) {
            print('Nincsenek átlagok.');
          } else {
            final Map<String, double> classAvgMap = {};
            if (classAverages != null) {
              for (var item in classAverages) {
                if (item is Map) {
                  final subject = item['Tantargy']?['Nev'] ?? 'Ismeretlen';
                  final valStr = (item['OsztalyAtlag'] ?? item['Atlag'] ?? item['Ertek'] ?? '0').toString();
                  final val = double.tryParse(valStr.replaceAll(',', '.')) ?? 0.0;
                  if (val > 0) {
                    classAvgMap[subject.toLowerCase()] = val;
                  }
                }
              }
            }

            print('\n--------------------------------------------------------------------------------');
            print('Tantárgy                     | Saját | Osztály | Eltérés | Trend | Határhelyzet');
            print('--------------------------------------------------------------------------------');
            for (var avg in averages) {
              final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
              final valStr = avg['Ertek']?.toString() ?? '0';
              final val = double.tryParse(valStr.replaceAll(',', '.')) ?? 0.0;
              if (val <= 0) continue;

              final classAvg = classAvgMap[subject.toLowerCase()] ?? 0.0;
              
              String classAvgStr = classAvg > 0 ? classAvg.toStringAsFixed(2) : ' - ';
              String devStr = ' - ';
              if (classAvg > 0) {
                final dev = val - classAvg;
                final devSign = dev >= 0 ? '+' : '';
                final devColor = dev >= 0 ? '\x1B[92m' : '\x1B[31m';
                devStr = '$devColor$devSign${dev.toStringAsFixed(2)}\x1B[0m';
              }

              final subjGrades = (grades ?? []).where((g) =>
                  g.subject.toLowerCase() == subject.toLowerCase() &&
                  g.numericValue != null &&
                  g.numericValue! >= 1 &&
                  g.numericValue! <= 5 &&
                  !g.isSummaryGrade
              ).toList();
              subjGrades.sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));
              String trendStr = '→';
              if (subjGrades.isNotEmpty) {
                final last3 = subjGrades.take(3).toList();
                final last3Avg = last3.map((g) => g.numericValue!).reduce((a, b) => a + b) / last3.length;
                if (last3Avg > val + 0.1) {
                  trendStr = '\x1B[92m↗\x1B[0m';
                } else if (last3Avg < val - 0.1) {
                  trendStr = '\x1B[31m↘\x1B[0m';
                }
              }

              String warningStr = '';
              for (double boundary in [1.5, 2.5, 3.5, 4.5]) {
                if ((val - boundary).abs() <= 0.101) {
                  final targetInt = boundary.ceil();
                  if (val < boundary) {
                    warningStr = '\x1B[33mKözel a $targetInt-eshez!\x1B[0m';
                  } else {
                    warningStr = '\x1B[31mVeszélyben a $targetInt-es!\x1B[0m';
                  }
                }
              }

              final displaySubj = subject.length > 28 ? '${subject.substring(0, 25)}...' : subject;
              
              final pSubj = displaySubj.padRight(28);
              final pSajat = val.toStringAsFixed(2).padRight(5);
              final pClass = classAvgStr.padRight(7);
              
              final devLen = classAvg > 0 ? 5 : 3;
              final pDev = devStr + ' ' * (7 - devLen);
              
              final pTrend = trendStr + '   ';

              print('$pSubj | $pSajat | $pClass | $pDev | $pTrend | $warningStr');
            }
            print('--------------------------------------------------------------------------------');
          }
        } else {
          print('Nem sikerült lekérdezni az átlagokat.');
        }
        _pause();
      }
    }

  Future<void> _showBulkGradeTargeter() async {
    if (!await _ensureClientReady()) return;
    
    _clearScreen();
    print('\n--- 🎯 Bizonyítvány Tervező (Minden tárgy célzása) 🎯 ---');
    print('Adatok lekérése...');
    
    final grades = await _client!.getGrades();
    if (grades == null || grades.isEmpty) {
      print('Nincsenek elérhető jegyek a tervezéshez.');
      _pause();
      return;
    }

    // Group grades by subject
    final Map<String, List<Grade>> subjectGrades = {};
    for (var g in grades) {
      if (g.isSummaryGrade) continue;
      if (g.numericValue == null || g.numericValue! < 1 || g.numericValue! > 5) continue;
      
      final subj = g.subject;
      subjectGrades.putIfAbsent(subj, () => []);
      subjectGrades[subj]!.add(g);
    }

    if (subjectGrades.isEmpty) {
      print('Nincsenek érdemi (1-5) jegyeid a tervezéshez.');
      _pause();
      return;
    }

    final subjects = subjectGrades.keys.toList()..sort();
    
    print('\n--------------------------------------------------------------------------------');
    print('Tantárgy                     | Jelenlegi | Cél | Szükséges 100%-os 5-ösök száma');
    print('--------------------------------------------------------------------------------');
    
    for (var subj in subjects) {
      final items = subjectGrades[subj]!;
      double sum = 0.0;
      double weightSum = 0.0;
      for (var g in items) {
        double w = g.weight;
        if (w == 0) w = 100.0;
        sum += g.numericValue! * w;
        weightSum += w;
      }
      
      final currentAvg = sum / weightSum;
      
      // Determine the target and target average threshold
      double targetThreshold = 4.5;
      int targetInt = 5;
      
      if (currentAvg >= 4.5) {
        targetInt = 5;
        targetThreshold = 5.0;
      } else if (currentAvg >= 3.5) {
        targetInt = 5;
        targetThreshold = 4.5;
      } else if (currentAvg >= 2.5) {
        targetInt = 4;
        targetThreshold = 3.5;
      } else if (currentAvg >= 1.5) {
        targetInt = 3;
        targetThreshold = 2.5;
      } else {
        targetInt = 2;
        targetThreshold = 1.5;
      }

      String resultStr = '';
      if (currentAvg >= 4.5) {
        resultStr = '\x1B[92mElérted az 5-öst! 🎉\x1B[0m';
      } else {
        final requiredFives = (targetThreshold * weightSum - sum) / (500 - targetThreshold * 100);
        final count = requiredFives.ceil();
        if (count <= 0) {
          resultStr = '\x1B[92mMegvan a cél! 🎉\x1B[0m';
        } else {
          resultStr = '\x1B[1;36m$count db 5-ös\x1B[0m';
        }
      }
      
      final displaySubj = subj.length > 28 ? '${subj.substring(0, 25)}...' : subj;
      final pSubj = AppState.instance.applyAlias(displaySubj).padRight(28);
      final pAvg = currentAvg.toStringAsFixed(2).padRight(9);
      final pTarget = targetInt.toString().padRight(3);
      
      print('$pSubj | $pAvg | $pTarget | $resultStr');
    }
    print('--------------------------------------------------------------------------------');
    _pause();
  }
}
