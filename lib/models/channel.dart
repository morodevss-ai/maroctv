class Channel {
  final String id;
  final String name;
  final String url;
  final String logo;
  final String category;
  final Map<String, String> headers;

  const Channel({
    required this.id,
    required this.name,
    required this.url,
    required this.logo,
    required this.category,
    this.headers = const {},
  });

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        url: j['url']?.toString() ?? '',
        logo: j['logo']?.toString() ?? '',
        category: j['category']?.toString() ?? 'General',
        headers: Map<String, String>.from(j['headers'] ?? {}),
      );
}
