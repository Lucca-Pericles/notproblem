DateTime saoPauloToday({DateTime? now}) {
  final utcNow = (now ?? DateTime.now()).toUtc();
  final saoPauloNow = utcNow.subtract(const Duration(hours: 3));
  return DateTime(saoPauloNow.year, saoPauloNow.month, saoPauloNow.day);
}
