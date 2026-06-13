import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/proxy.dart';
import '../services/channels.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const SettingsScreen({super.key, required this.onSaved});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _proxyCtrl    = TextEditingController();
  final _playlistCtrl = TextEditingController();
  bool _saving = false;
  bool _proxyOn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final proxy    = await ProxyService.getProxyUrl();
    final playlist = await ChannelService.getSavedUrl();
    setState(() {
      _proxyCtrl.text    = proxy;
      _playlistCtrl.text = playlist;
      _proxyOn = proxy.isNotEmpty;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ProxyService.saveProxyUrl(_proxyOn ? _proxyCtrl.text : '');
    await ChannelService.saveUrl(_playlistCtrl.text);
    setState(() => _saving = false);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _proxyCtrl.dispose();
    _playlistCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC8102E)))
                : const Text('حفظ', style: TextStyle(color: Color(0xFFC8102E), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Cloudflare Proxy ──────────────────────────────
          _sectionTitle('🔐 تجاوز حجب *6 — Cloudflare Proxy'),
          const SizedBox(height: 6),
          _infoBox(
            'يمر البث عبر Cloudflare (غير محجوب من *6) بدل الاتصال المباشر.',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 10),

          SwitchListTile(
            value: _proxyOn,
            onChanged: (v) => setState(() => _proxyOn = v),
            title: const Text('تفعيل Proxy', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              _proxyOn ? 'مفعّل — سيُستخدم للتجاوز' : 'معطّل — اتصال مباشر',
              style: TextStyle(color: _proxyOn ? Colors.greenAccent : Colors.white38, fontSize: 12),
            ),
            activeColor: const Color(0xFFC8102E),
            tileColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

          if (_proxyOn) ...[
            const SizedBox(height: 10),
            _field(
              controller: _proxyCtrl,
              label: 'رابط Cloudflare Worker',
              hint: 'https://maroctv.YOUR-NAME.workers.dev',
              icon: Icons.cloud_outlined,
            ),
            const SizedBox(height: 8),
            _howToCard(),
          ],

          const SizedBox(height: 24),

          // ── Playlist ──────────────────────────────────────
          _sectionTitle('📺 قائمة قنوات M3U'),
          const SizedBox(height: 6),
          _infoBox('ضع رابط M3U لإضافة قنوات إضافية. اتركه فارغاً لاستخدام القنوات الافتراضية.'),
          const SizedBox(height: 10),
          _field(
            controller: _playlistCtrl,
            label: 'رابط M3U Playlist',
            hint: 'https://example.com/playlist.m3u',
            icon: Icons.playlist_play_rounded,
          ),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2A2A2A)),
              foregroundColor: Colors.white54,
            ),
            icon: const Icon(Icons.paste, size: 16),
            label: const Text('لصق من الحافظة'),
            onPressed: () async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                setState(() => _playlistCtrl.text = data!.text!.trim());
              }
            },
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC8102E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded),
            label: const Text('حفظ وتطبيق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15));

  Widget _infoBox(String text, {IconData icon = Icons.lightbulb_outline}) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.amber, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5))),
      ]));

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) => TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFFC8102E), size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC8102E)),
        ),
      ),
    );

  Widget _howToCard() => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8102E).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('كيف تنشئ Worker مجاني؟',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        ..._steps([
          'افتح dash.cloudflare.com وسجّل مجاناً',
          'اضغط Workers & Pages ← Create',
          'اختار Hello World ← Deploy',
          'اضغط Edit Code والصق كود worker.js من المجلد cloudflare-worker/',
          'اضغط Deploy واحتفظ بالرابط',
          'الصق الرابط هنا وفعّل الـ Proxy',
        ]),
      ]));

  List<Widget> _steps(List<String> steps) {
    return steps.asMap().entries.map((e) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFC8102E), shape: BoxShape.circle),
          child: Text('${e.key + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(e.value,
            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4))),
      ]),
    )).toList();
  }
}
