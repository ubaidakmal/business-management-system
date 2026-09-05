abstract final class Formatters {
  static String money(num value) {
    return value.toStringAsFixed(2);
  }

  static String quantity(num value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(3);
  }

  static String date(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String dateTime(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final date = Formatters.date(local);
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$date $h:$min';
  }
}
