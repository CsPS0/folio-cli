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
      else if (value < 4.0) color = '\x1B[36m'; // Cyan
      else color = '\x1B[32m'; // Green
      
      final valStr = value.toStringAsFixed(2).padLeft(4);
      buffer.writeln('$paddedLabel | $color${bar.padRight(width)}\x1B[0m | $valStr');
    });

    return buffer.toString();
  }
}
