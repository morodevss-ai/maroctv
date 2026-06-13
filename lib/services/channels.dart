import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import 'proxy.dart';

const String kPrefPlaylistUrl = 'playlist_url';

const Map<String, String> kSafeHeaders = {
  'User-Agent': 'Mozilla/5.0 (Linux; Android 13; SM-S918B) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Mobile Safari/537.36',
  'Accept': '*/*',
  'Connection': 'keep-alive',
};

const List<Channel> kBuiltinChannels = [
  Channel(
    id: 'al_aoula',
    name: 'الأولى',
    url: 'https://cdn-01.live2.tv/streamers/al-aoula/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Al_Aoula_logo.svg/200px-Al_Aoula_logo.svg.png',
    category: 'Moroccan',
  ),
  Channel(
    id: '2m',
    name: '2M Maroc',
    url: 'https://d2qh3gh0k5vp3v.cloudfront.net/v1/master/3722c60a815c199d9c0ef36c5b73da68a62b09d1/cc-n6pess5lwbghr/2M_ES.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/2M_logo.svg/200px-2M_logo.svg.png',
    category: 'Moroccan',
  ),
  Channel(
    id: 'medi1',
    name: 'Medi1 TV',
    url: 'https://cdn-01.live2.tv/streamers/medi1tv/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Medi1tv_logo.svg/200px-Medi1tv_logo.svg.png',
    category: 'Moroccan',
  ),
  Channel(
    id: 'laayoune',
    name: 'Laâyoune TV',
    url: 'https://cdn-01.live2.tv/streamers/laayoune-tv/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/61/Laayoune_TV_logo.svg/200px-Laayoune_TV_logo.svg.png',
    category: 'Moroccan',
  ),
  Channel(
    id: 'arryadia',
    name: 'Arryadia',
    url: 'https://cdn-01.live2.tv/streamers/arryadia/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Arryadia_logo.svg/200px-Arryadia_logo.svg.png',
    category: 'Sports',
  ),
  Channel(
    id: 'aljazeera',
    name: 'Al Jazeera',
    url: 'https://live-hls-web-aja.getaj.net/AJA/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Aljazeera_Logo.svg/200px-Aljazeera_Logo.svg.png',
    category: 'News',
  ),
  Channel(
    id: 'france24ar',
    name: 'France 24 عربي',
    url: 'https://f24hls-i.akamaihd.net/hls/live/221147/F24_AR_HI_HLS/master.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/France_24_logo.svg/200px-France_24_logo.svg.png',
    category: 'News',
  ),
];

class ChannelService {
  static Future<String> getSavedUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(kPrefPlaylistUrl) ?? '';
  }

  static Future<void> saveUrl(String url) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kPrefPlaylistUrl, url.trim());
  }

  static Future<List<Channel>> load() async {
    final playlistUrl = await getSavedUrl();
    final all = <Channel>[];

    if (playlistUrl.isNotEmpty) {
      try {
        final fetchUrl = await ProxyService.wrapM3uUrl(playlistUrl);
        final res = await http
            .get(Uri.parse(fetchUrl), headers: kSafeHeaders)
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final body = res.body.trim();
          if (body.startsWith('[')) {
            all.addAll((json.decode(body) as List).map((e) => Channel.fromJson(e)));
          } else if (body.startsWith('#EXTM3U')) {
            all.addAll(_parseM3u(body));
          }
        }
      } catch (_) {}
    }

    if (all.isEmpty) all.addAll(kBuiltinChannels);

    // Wrap stream URLs through proxy if enabled
    final proxyUrl = await ProxyService.getProxyUrl();
    return all.map((ch) {
      final h = Map<String, String>.from(kSafeHeaders)..addAll(ch.headers);
      final streamUrl = proxyUrl.isNotEmpty
          ? '${proxyUrl.endsWith('/') ? proxyUrl : '$proxyUrl/'}?url=${Uri.encodeComponent(ch.url)}'
          : ch.url;
      return Channel(
        id: ch.id, name: ch.name, url: streamUrl,
        logo: ch.logo, category: ch.category, headers: h,
      );
    }).toList();
  }

  static List<Channel> _parseM3u(String body) {
    final result = <Channel>[];
    final lines = body.split('\n');
    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXTINF')) continue;
      final next = lines[i + 1].trim();
      if (next.isEmpty || next.startsWith('#')) continue;
      final name = RegExp(r',(.+)$').firstMatch(line)?.group(1)?.trim() ?? 'CH';
      final logo = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line)?.group(1)?.trim() ?? '';
      final cat  = RegExp(r'group-title="([^"]*)"').firstMatch(line)?.group(1)?.trim() ?? 'General';
      result.add(Channel(id: 'm3u_$i', name: name, url: next, logo: logo, category: cat));
    }
    return result;
  }
}
