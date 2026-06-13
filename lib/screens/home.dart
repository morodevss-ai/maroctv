import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../services/channels.dart';
import '../services/proxy.dart';
import 'player.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Channel> _all = [];
  List<Channel> _shown = [];
  Set<String> _favs = {};
  bool _loading = true;
  String _category = 'All';
  String _search = '';
  bool _proxyOn = false;

  static const _icons = <String, IconData>{
    'All':           Icons.grid_view_rounded,
    'Moroccan':      Icons.flag_rounded,
    'Sports':        Icons.sports_soccer_rounded,
    'News':          Icons.newspaper_rounded,
    'Entertainment': Icons.tv_rounded,
    'Kids':          Icons.child_care_rounded,
    'Favourites':    Icons.star_rounded,
  };

  List<String> get _cats {
    final cats = <String>{'All', 'Favourites'};
    for (final c in _all) cats.add(c.category);
    return cats.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFavs();
    _loadChannels();
    _checkProxy();
  }

  Future<void> _checkProxy() async {
    final p = await ProxyService.getProxyUrl();
    if (mounted) setState(() => _proxyOn = p.isNotEmpty);
  }

  Future<void> _loadFavs() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _favs = (p.getStringList('favs') ?? []).toSet());
  }

  Future<void> _toggleFav(String id) async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _favs.contains(id) ? _favs.remove(id) : _favs.add(id);
      p.setStringList('favs', _favs.toList());
    });
  }

  Future<void> _loadChannels() async {
    setState(() => _loading = true);
    final ch = await ChannelService.load();
    setState(() { _all = ch; _filter(); _loading = false; });
  }

  void _filter() {
    setState(() {
      _shown = _all.where((c) {
        final catOk = _category == 'All'
            ? true
            : _category == 'Favourites'
                ? _favs.contains(c.id)
                : c.category == _category;
        final srchOk = _search.isEmpty ||
            c.name.toLowerCase().contains(_search.toLowerCase());
        return catOk && srchOk;
      }).toList();
    });
  }

  void _open(Channel ch) {
    final list = _shown.isEmpty ? _all : _shown;
    final idx = list.indexWhere((c) => c.id == ch.id);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(
        channel: ch, playlist: list, index: idx < 0 ? 0 : idx,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _appBar(),
          SliverToBoxAdapter(child: _searchBar()),
          SliverToBoxAdapter(child: _catBar()),
        ],
        body: _loading ? _shimmer() : _grid(),
      ),
    );
  }

  SliverAppBar _appBar() => SliverAppBar(
        pinned: true,
        expandedHeight: 100,
        backgroundColor: const Color(0xFF0D0D0D),
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFC8102E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.live_tv, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('MarocTV',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
            const Spacer(),
            if (_proxyOn)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shield_rounded, color: Colors.greenAccent, size: 11),
                  SizedBox(width: 3),
                  Text('Proxy', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white60, size: 20),
              onPressed: _loadChannels,
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white60, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(
                  onSaved: () {
                    _checkProxy();
                    _loadChannels();
                  },
                )),
              ),
            ),
          ]),
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        child: TextField(
          onChanged: (v) { _search = v; _filter(); },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'بحث...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1C1C1C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );

  Widget _catBar() => SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: _cats.length,
          itemBuilder: (_, i) {
            final cat = _cats[i];
            final sel = cat == _category;
            return GestureDetector(
              onTap: () { setState(() => _category = cat); _filter(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFC8102E) : const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_icons[cat] ?? Icons.live_tv,
                      size: 13,
                      color: sel ? Colors.white : Colors.white54),
                  const SizedBox(width: 5),
                  Text(cat,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white54,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                ]),
              ),
            );
          },
        ),
      );

  Widget _grid() {
    if (_shown.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, color: Colors.white24, size: 56),
          SizedBox(height: 10),
          Text('لا توجد قنوات', style: TextStyle(color: Colors.white38)),
        ]),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12,
        mainAxisSpacing: 12, childAspectRatio: 1.3,
      ),
      itemCount: _shown.length,
      itemBuilder: (_, i) => _card(_shown[i]),
    );
  }

  Widget _card(Channel ch) {
    final fav = _favs.contains(ch.id);
    return GestureDetector(
      onTap: () => _open(ch),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(children: [
          Column(children: [
            Expanded(
              child: Center(child: _logo(ch)),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(ch.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8102E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ]),
          Positioned(
            top: 6, right: 6,
            child: GestureDetector(
              onTap: () { _toggleFav(ch.id); _filter(); },
              child: Icon(
                fav ? Icons.star_rounded : Icons.star_border_rounded,
                color: fav ? Colors.amber : Colors.white30,
                size: 20,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _logo(Channel ch) {
    if (ch.logo.isEmpty) return _fallback(ch.name);
    return CachedNetworkImage(
      imageUrl: ch.logo, width: 60, height: 60, fit: BoxFit.contain,
      placeholder: (_, __) => const SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC8102E))),
      errorWidget: (_, __, ___) => _fallback(ch.name),
    );
  }

  Widget _fallback(String name) => Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold)),
      );

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: const Color(0xFF1C1C1C),
        highlightColor: const Color(0xFF2A2A2A),
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
          itemCount: 12,
          itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
        ),
      );
}
