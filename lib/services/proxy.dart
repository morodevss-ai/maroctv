import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════
//  ضع رابط Cloudflare Worker الخاص بك هنا بعد نشره
//  https://dash.cloudflare.com → Workers & Pages → Create
// ══════════════════════════════════════════════════════
const String kDefaultProxyUrl = 'https://royal-night-4e89.nassrirayane93.workers.dev';

const String kPrefProxyUrl = 'cloudflare_proxy_url';

class ProxyService {
  /// يرجع proxy URL — من الإعدادات أولاً، وإلا الافتراضي من الكود
  static Future<String> getProxyUrl() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(kPrefProxyUrl) ?? '';
    if (saved.isNotEmpty) return saved;
    return kDefaultProxyUrl;
  }

  static Future<void> saveProxyUrl(String url) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kPrefProxyUrl, url.trim());
  }

  static Future<String> wrapUrl(String streamUrl) async {
    final proxy = await getProxyUrl();
    if (proxy.isEmpty) return streamUrl;
    final base = proxy.endsWith('/') ? proxy : '$proxy/';
    return '${base}?url=${Uri.encodeComponent(streamUrl)}';
  }

  static Future<String> wrapM3uUrl(String m3uUrl) async {
    return wrapUrl(m3uUrl);
  }
}
