String compress(int n, String input) {
  if (n <= 0) return input;

  final lines = input.split('\n');
  final occurrences = <String, List<({int line, int start})>>{};

  for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
    final line = lines[lineIdx];
    final len = line.length;

    for (int start = 0; start < len; start++) {
      for (int end = start + 1; end <= len; end++) {
        final sub = line.substring(start, end);
        occurrences.putIfAbsent(sub, () => []).add((
          line: lineIdx,
          start: start,
        ));
      }
    }
  }

  final repeated = <MapEntry<String, List<({int line, int start})>>>[];
  for (var entry in occurrences.entries) {
    if (entry.value.length >= 2) {
      repeated.add(entry);
      if (repeated.length == n) break;
    }
  }

  if (repeated.isEmpty) return input;

  final metadataLines = <String>[];
  for (var entry in repeated) {
    final sub = entry.key;
    final occs = entry.value;
    final coordinates = occs
        .map((occ) => '(${occ.line + 1},${occ.start})')
        .join(' ');
    metadataLines.add('$sub: $coordinates');
  }

  // Compute the absolute start index of each line in the original string so we can delete characters by their absolute position.
  final lineStartAbs = <int>[];
  int pos = 0;
  final endsWithNewLine = input.endsWith('\n');
  for (int i = 0; i < lines.length; i++) {
    lineStartAbs.add(pos);
    pos += lines[i].length;
    if (i != lines.length - 1 || endsWithNewLine) {
      pos += 1;
    }
  }

  // Convert each (line, start) occurrence into an absolute interval (start, end) in the original string.
  final intervals = <({int start, int end})>[];
  for (var entry in repeated) {
    final sub = entry.key;
    final occs = entry.value;
    for (var occ in occs) {
      final absStart = lineStartAbs[occ.line] + occ.start;
      final absEnd = absStart + sub.length;
      intervals.add((start: absStart, end: absEnd));
    }
  }

  // Merge overlapping or touching intervals.
  // Remove "aa" from "aaa", intervals (0,2) and (1,3) overlap.
  // Removing the same character twice would break the result.
  intervals.sort((a, b) => a.start.compareTo(b.start));
  final merged = <List<int>>[];
  for (var interval in intervals) {
    if (merged.isEmpty || interval.start > merged.last[1]) {
      merged.add([interval.start, interval.end]);
    } else {
      merged.last[1] = merged.last[1] > interval.end
          ? merged.last[1]
          : interval.end;
    }
  }

  // Build the result string by copying only characters that are NOT inside any merged interval.
  final buffer = StringBuffer();
  int idx = 0;
  for (final interval in merged) {
    while (idx < interval[0]) {
      buffer.write(input[idx]);
      idx++;
    }
    idx = interval[1];
  }
  while (idx < input.length) {
    buffer.write(input[idx]);
    idx++;
  }

  String result = buffer.toString();
  if (metadataLines.isNotEmpty) {
    if (result.isNotEmpty && !result.endsWith('\n')) {
      result += '\n';
    }
    result += metadataLines.join('\n');
  }

  return result;
}
