import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

// ════════════════════════════════════════════════════════════
//  كيفاش تضيف قنواتك (HOW TO ADD YOUR CHANNELS)
// ════════════════════════════════════════════════════════════
//
//  ① زيد قناة في القائمة kChannels هنا تحت (الأسهل)
//  ② أو حط رابط JSON/M3U في kPlaylistUrl
//
//  شكل القناة:
//  Channel(
//    id:       'اسم فريد بدون مسافات',
//    name:     'اسم القناة',
//    url:      'https://example.com/stream.m3u8',
//    logo:     'https://example.com/logo.png',
//    category: 'Moroccan | Sports | News | Entertainment | Kids',
//    headers:  {},   ← {} = يستخدم bypass headers تلقائياً
//  ),
//
// ════════════════════════════════════════════════════════════

// رابط playlist خارجي (JSON أو M3U) — اتركه فارغاً إذا ما عندكش
const String kPlaylistUrl = '';

// ── Bypass Headers لـ *6 Maroc Telecom ──────────────────────
const Map<String, String> kBypassHeaders = {
  'Host': 'facebook.com',
  'User-Agent': 'Mozilla/5.0 (Linux; Android 13; SM-S918B) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Mobile Safari/537.36',
  'Connection': 'keep-alive',
  'Accept': '*/*',
  'Referer': 'https://www.facebook.com/',
  'Origin': 'https://www.facebook.com',
};

// ── قائمة القنوات ────────────────────────────────────────────
const List<Channel> kChannels = [
  // ── مغربية ──────────────────────────────────────────────
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
    url: 'https://cdn-01.live2.tv/streamers/2m/index.m3u8',
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
    id: 'arrabia',
    name: 'Al Arrabia',
    url: 'https://cdn-01.live2.tv/streamers/al-arrabia/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Al_Arabiya_logo.svg/200px-Al_Arabiya_logo.svg.png',
    category: 'Moroccan',
  ),

  // ── رياضة ────────────────────────────────────────────────
  Channel(
    id: 'arryadia',
    name: 'Arryadia',
    url: 'https://cdn-01.live2.tv/streamers/arryadia/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Arryadia_logo.svg/200px-Arryadia_logo.svg.png',
    category: 'Sports',
  ),
  Channel(
    id: 'bein1',
    name: 'beIN Sports 1',
    url: 'https://YOUR_PROVIDER/bein1/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png',
    category: 'Sports',
  ),
  Channel(
    id: 'bein2',
    name: 'beIN Sports 2',
    url: 'https://YOUR_PROVIDER/bein2/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png',
    category: 'Sports',
  ),

  // ── أخبار ────────────────────────────────────────────────
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

  // ── ترفيه ────────────────────────────────────────────────
  Channel(
    id: 'mbc1',
    name: 'MBC 1',
    url: 'https://YOUR_PROVIDER/mbc1/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/MBC1_logo.svg/200px-MBC1_logo.svg.png',
    category: 'Entertainment',
  ),
  Channel(
    id: 'mbc3',
    name: 'MBC 3',
    url: 'https://YOUR_PROVIDER/mbc3/index.m3u8',
    logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/MBC3_Logo.svg/200px-MBC3_Logo.svg.png',
    category: 'Kids',
  ),
];

// ── Service ──────────────────────────────────────────────────
class ChannelService {
  static Future<List<Channel>> load() async {
    final all = <Channel>[...kChannels];

    if (kPlaylistUrl.isNotEmpty) {
      try {
        final res = await http
            .get(Uri.parse(kPlaylistUrl), headers: kBypassHeaders)
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final body = res.body.trim();
          if (body.startsWith('[')) {
            final list = json.decode(body) as List;
            all.insertAll(0, list.map((e) => Channel.fromJson(e)));
          } else if (body.startsWith('#EXTM3U')) {
            all.insertAll(0, _parseM3u(body));
          }
        }
      } catch (_) {}
    }

    // Apply bypass headers to every channel
    return all.map((ch) {
      final h = Map<String, String>.from(kBypassHeaders)..addAll(ch.headers);
      return Channel(
        id: ch.id, name: ch.name, url: ch.url,
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
