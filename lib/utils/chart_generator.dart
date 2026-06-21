import '../app/theme.dart';

class ChartGenerator {
  static String generateBarChart(Map<String, double> data, {int width = 30}) {
    if (data.isEmpty) return '';

    double maxVal = 5.0;
    for (var val in data.values) {
      if (val > maxVal) maxVal = val;
    }

    final buffer = StringBuffer();
    final blocks = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█'];

    int maxLabelLen = 0;
    for (var key in data.keys) {
      if (key.length > maxLabelLen) maxLabelLen = key.length;
    }

    // Limit label length
    if (maxLabelLen > 25) maxLabelLen = 25;

    data.forEach((label, value) {
      final percentage = value / maxVal;
      final totalBlocks = percentage * width;
      final fullBlocks = totalBlocks.floor();
      final remainder = totalBlocks - fullBlocks;
      final partialBlockIdx = (remainder * 8).round();
      
      final bar = '█' * fullBlocks + (partialBlockIdx > 0 && partialBlockIdx < 9 ? blocks[partialBlockIdx] : '');
      
      String displayLabel = label;
      if (displayLabel.length > 25) {
        displayLabel = displayLabel.substring(0, 22) + '...';
      }
      final paddedLabel = displayLabel.padRight(maxLabelLen);
      
      String color = '\x1B[0m'; // Default
      if (value < 2.0) color = '\x1B[31m'; // Red
      else if (value < 3.0) color = '\x1B[33m'; // Yellow
      else if (value < 4.0) color = FolioTheme.primary; // Cyan
      else color = '\x1B[32m'; // Green
      
      final valStr = value.toStringAsFixed(2).padLeft(4);
      buffer.writeln('$paddedLabel | $color${bar.padRight(width)}\x1B[0m | $valStr');
    });

    return buffer.toString();
  }

  static String generateLineChart(List<double> values, {List<String>? labels}) {
    if (values.isEmpty) return 'Nincs elég adat a grafikonhoz.';
    
    int height = 10;
    int width = values.length;
    if (width > 40) {
      // Sample or take last 40 to fit terminal
      values = values.sublist(values.length - 40);
      if (labels != null && labels.length > 40) {
        labels = labels.sublist(labels.length - 40);
      }
      width = values.length;
    }

    // Find range and scale dynamically
    double minVal = values.reduce((a, b) => a < b ? a : b).clamp(1.0, 5.0);
    double maxVal = values.reduce((a, b) => a > b ? a : b).clamp(1.0, 5.0);
    
    double range = maxVal - minVal;
    double padding = range * 0.15;
    if (padding < 0.1) padding = 0.15;
    
    double yMin = (minVal - padding).clamp(1.0, 5.0);
    double yMax = (maxVal + padding).clamp(1.0, 5.0);
    
    if ((yMax - yMin).abs() < 0.2) {
      yMin = (yMin - 0.2).clamp(1.0, 5.0);
      yMax = (yMax + 0.2).clamp(1.0, 5.0);
    }

    // Map each value to the closest Y row to prevent scaling artifacts
    final dotRows = List<int>.generate(width, (x) {
      final val = values[x];
      int bestY = 0;
      double minDiff = 999.0;
      for (int y = 0; y <= height; y++) {
        double currentY = yMin + (y / height) * (yMax - yMin);
        double diff = (val - currentY).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestY = y;
        }
      }
      return bestY;
    });

    final buffer = StringBuffer();
    
    for (int y = height; y >= 0; y--) {
      double currentY = yMin + (y / height) * (yMax - yMin);
      final yLabel = currentY.toStringAsFixed(2).padLeft(4);
      buffer.write('\x1B[90m$yLabel │\x1B[0m');
      for (int x = 0; x < width; x++) {
        String color = '\x1B[0m';
        if (values[x] < 2.0) color = '\x1B[31m'; // Red
        else if (values[x] < 2.5) color = '\x1B[38;5;208m'; // Orange
        else if (values[x] < 3.0) color = '\x1B[33m'; // Yellow
        else if (values[x] < 3.5) color = '\x1B[38;5;154m'; // Yellow-Green
        else if (values[x] < 4.0) color = '\x1B[38;5;112m'; // Light Green
        else if (values[x] < 4.5) color = '\x1B[32m'; // Green
        else color = '\x1B[1;32m'; // Bright Green

        if (dotRows[x] == y) {
          buffer.write('$color ● \x1B[0m');
        } else {
          buffer.write('   ');
        }
      }
      buffer.writeln();
    }
    buffer.write('\x1B[90m─────┼');
    for (int x = 0; x < width; x++) {
      buffer.write('───');
    }
    buffer.writeln('\x1B[0m');
    
    if (labels != null && labels.length == width) {
      buffer.write('     │');
      for (int x = 0; x < width; x++) {
        final lbl = labels[x];
        final displayLbl = lbl.length > 3 ? lbl.substring(0, 3) : lbl.padRight(3);
        buffer.write(displayLbl);
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  static String generateHeatmap(Map<DateTime, double> dailyAverages, {int weeksToShow = 25}) {
    if (dailyAverages.isEmpty) return 'Nincs elég adat a heatmaphoz.';

    final buffer = StringBuffer();
    final now = DateTime.now();
    // Normalize to midnight
    final today = DateTime(now.year, now.month, now.day);
    
    // Find the Monday of the current week
    final currentDayOfWeek = today.weekday; // 1 = Monday, 7 = Sunday
    final currentMonday = today.subtract(Duration(days: currentDayOfWeek - 1));
    
    // Start date is N weeks ago
    final startDate = currentMonday.subtract(Duration(days: weeksToShow * 7));

    // Weekday labels
    final labels = ['Hét', 'Ked', 'Sze', 'Csü', 'Pén', 'Szo', 'Vas'];

    // Map the incoming dates to midnight for exact matching
    final normalizedData = <DateTime, double>{};
    dailyAverages.forEach((date, value) {
      normalizedData[DateTime(date.year, date.month, date.day)] = value;
    });

    for (int row = 0; row < 7; row++) {
      buffer.write('\x1B[90m${labels[row]} │ \x1B[0m');
      
      for (int col = 0; col <= weeksToShow; col++) {
        final currentDay = startDate.add(Duration(days: col * 7 + row));
        
        // Don't render future days beyond today
        if (currentDay.isAfter(today)) {
          buffer.write('   ');
          continue;
        }

        final avg = normalizedData[currentDay];
        
        if (avg == null) {
          // Empty day
          buffer.write('\x1B[38;5;236m■ \x1B[0m'); // Very dark grey
        } else {
          String color = '\x1B[0m';
          if (avg < 2.0) color = '\x1B[31m'; // Red
          else if (avg < 2.5) color = '\x1B[38;5;208m'; // Orange
          else if (avg < 3.0) color = '\x1B[33m'; // Yellow
          else if (avg < 3.5) color = '\x1B[38;5;154m'; // Yellow-Green
          else if (avg < 4.0) color = '\x1B[38;5;112m'; // Light Green
          else if (avg <= 4.5) color = '\x1B[32m'; // Green
          else color = '\x1B[1;32m'; // Bright Green
          
          buffer.write('$color■ \x1B[0m');
        }
      }
      buffer.writeln();
    }
    
    buffer.write('\x1B[90m    └─');
    for (int col = 0; col <= weeksToShow; col++) {
      buffer.write('──');
    }
    buffer.writeln('\x1B[0m');
    
    return buffer.toString();
  }
}
