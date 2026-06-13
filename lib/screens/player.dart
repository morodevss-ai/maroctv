import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import '../models/channel.dart';
import '../services/channels.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> playlist;
  final int index;
  const PlayerScreen({super.key, required this.channel, required this.playlist, required this.index});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late BetterPlayerController _ctrl;
  late int _idx;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _idx = widget.index;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _play(_idx);
  }

  Channel get _ch => widget.playlist[_idx];

  void _play(int idx) {
    setState(() { _loading = true; _error = false; _idx = idx; });

    // ── Inject bypass headers here ──────────────────────────
    final headers = Map<String, String>.from(kBypassHeaders)
      ..addAll(widget.playlist[idx].headers);

    final src = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.playlist[idx].url,
      headers: headers,
      liveStream: true,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 2000, maxBufferMs: 8000,
        bufferForPlaybackMs: 1000, bufferForPlaybackAfterRebufferMs: 2000,
      ),
    );

    final cfg = BetterPlayerConfiguration(
      autoPlay: true,
      looping: false,
      allowedScreenSleep: false,
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        enableSkips: false,
        controlBarColor: Colors.black87,
        iconsColor: Colors.white,
        progressBarPlayedColor: const Color(0xFFC8102E),
        progressBarHandleColor: const Color(0xFFC8102E),
        loadingColor: const Color(0xFFC8102E),
        playerTheme: BetterPlayerTheme.material,
      ),
      eventListener: (e) {
        if (!mounted) return;
        switch (e.betterPlayerEventType) {
          case BetterPlayerEventType.initialized:
          case BetterPlayerEventType.play:
          case BetterPlayerEventType.bufferingEnd:
            setState(() => _loading = false);
            break;
          case BetterPlayerEventType.bufferingStart:
            setState(() => _loading = true);
            break;
          case BetterPlayerEventType.exception:
            setState(() { _loading = false; _error = true; });
            break;
          default:
            break;
        }
      },
    );

    try { _ctrl.dispose(); } catch (_) {}
    _ctrl = BetterPlayerController(cfg)..setupDataSource(src);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          Expanded(
            child: Row(children: [
              Expanded(child: _player()),
              _sidebar(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _topBar() => Container(
        height: 46,
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(_ch.name,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          _liveBadge(),
          IconButton(
            icon: Icon(Icons.skip_previous,
                color: _idx > 0 ? Colors.white : Colors.white24),
            onPressed: _idx > 0 ? () => _play(_idx - 1) : null,
          ),
          IconButton(
            icon: Icon(Icons.skip_next,
                color: _idx < widget.playlist.length - 1 ? Colors.white : Colors.white24),
            onPressed: _idx < widget.playlist.length - 1 ? () => _play(_idx + 1) : null,
          ),
        ]),
      );

  Widget _liveBadge() => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFC8102E),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, color: Colors.white, size: 7),
          SizedBox(width: 4),
          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _player() => Stack(alignment: Alignment.center, children: [
        AspectRatio(aspectRatio: 16 / 9, child: BetterPlayer(controller: _ctrl)),
        if (_loading && !_error)
          const CircularProgressIndicator(color: Color(0xFFC8102E)),
        if (_error)
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4,
                color: Colors.white54, size: 52),
            const SizedBox(height: 12),
            const Text('تعذّر تحميل البث', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC8102E)),
              onPressed: () => _play(_idx),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ]),
      ]);

  Widget _sidebar() => Container(
        width: 160,
        color: const Color(0xFF111111),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Text('القنوات',
                style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 0.8)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.playlist.length,
              itemBuilder: (_, i) {
                final ch = widget.playlist[i];
                final sel = i == _idx;
                return GestureDetector(
                  onTap: () => _play(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFC8102E).withOpacity(0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: sel ? Border.all(color: const Color(0xFFC8102E)) : null,
                    ),
                    child: Text(ch.name,
                        style: TextStyle(
                            color: sel ? Colors.white : Colors.white54,
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                );
              },
            ),
          ),
        ]),
      );
}
