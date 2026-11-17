class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isEmailConfirmed,
  });

  final String id;
  final String name;
  final String email;
  final bool isEmailConfirmed;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'AK';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
