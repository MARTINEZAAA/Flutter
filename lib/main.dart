import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const _red = Color(0xFFE94343);
const _ink = Color(0xFF202A3B);
const _paper = Color(0xFFF5F2E9);
const _green = Color(0xFF55B879);

void main() {
  runApp(const PokemonApp());
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _red),
        scaffoldBackgroundColor: _paper,
        useMaterial3: true,
      ),
      home: const PokemonPage(),
    );
  }
}

class PokemonPage extends StatefulWidget {
  const PokemonPage({
    super.key,
    this.loadPokemon,
    this.loadPokemonPage,
    this.searchPokemon,
    this.playPokemonSound,
  });

  final Future<Pokemon> Function(int id)? loadPokemon;
  final Future<PokemonPageResult> Function(int offset)? loadPokemonPage;
  final Future<Pokemon> Function(String query)? searchPokemon;
  final Future<void> Function(int id)? playPokemonSound;

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  final _service = PokemonService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _pokemon = <PokemonSummary>[];

  late Future<Pokemon> _selectedPokemon;
  int _selectedId = 1;
  int _nextOffset = 0;
  bool _loadingFirstPage = false;
  bool _loadingMore = false;
  bool _musicPlaying = false;
  bool _musicLoading = false;
  bool _soundsEnabled = true;
  AudioPlayer? _musicPlayer;
  AudioPlayer? _effectPlayer;
  bool _hasMore = true;
  String? _listError;
  String? _searchMessage;

  @override
  void initState() {
    super.initState();
    _selectedPokemon = _loadPokemon(1);
    _loadNextPage();
    _scrollController.addListener(_onScroll);
  }

  Future<Pokemon> _loadPokemon(int id) {
    return widget.loadPokemon?.call(id) ?? _service.fetchPokemon(id);
  }

  Future<PokemonPageResult> _loadPokemonPage(int offset) {
    return widget.loadPokemonPage?.call(offset) ??
        _service.fetchPokemonPage(offset);
  }

  Future<void> _loadNextPage() async {
    if (_loadingFirstPage || _loadingMore || !_hasMore) return;
    setState(() {
      if (_pokemon.isEmpty) {
        _loadingFirstPage = true;
      } else {
        _loadingMore = true;
      }
      _listError = null;
    });

    try {
      final page = await _loadPokemonPage(_nextOffset);
      if (!mounted) return;
      setState(() {
        _pokemon.addAll(page.pokemon);
        _nextOffset += page.pokemon.length;
        _hasMore = page.hasNext;
        _loadingFirstPage = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingFirstPage = false;
        _loadingMore = false;
        _listError = 'No se pudo cargar la Pokédex. $error';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 250) {
      _loadNextPage();
    }
  }

  void _selectPokemon(int id) {
    if (id != _selectedId) {
      unawaited(_playPokemonSound(id));
    }
    setState(() {
      _selectedId = id;
      _selectedPokemon = _loadPokemon(id);
    });
  }

  Future<void> _playPokemonSound(int id) async {
    if (!_soundsEnabled) return;

    try {
      if (widget.playPokemonSound != null) {
        await widget.playPokemonSound!(id);
        return;
      }
      final player = _effectPlayer ??= AudioPlayer();
      await player.play(BytesSource(_createPokemonCry(id)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo reproducir el efecto: $error')),
        );
      }
    }
  }

  void _toggleSounds() {
    setState(() => _soundsEnabled = !_soundsEnabled);
  }

  Future<void> _search() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _searchMessage = null);
      return;
    }

    setState(() => _searchMessage = null);
    try {
      final result =
          widget.searchPokemon?.call(query) ?? _service.searchPokemon(query);
      final pokemon = await result;
      if (!mounted) return;
      final summary = PokemonSummary(
        id: pokemon.id,
        name: pokemon.name,
        imageUrl: pokemon.imageUrl,
      );
      setState(() {
        if (!_pokemon.any((entry) => entry.id == summary.id)) {
          _pokemon.insert(0, summary);
        }
        _selectedId = pokemon.id;
        _selectedPokemon = Future.value(pokemon);
        _searchMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchMessage =
            'No encontramos ese Pokémon. Prueba con su nombre o número.';
      });
    }
  }

  Future<void> _toggleMusic() async {
    if (_musicLoading) return;
    setState(() => _musicLoading = true);

    try {
      final player = _musicPlayer ??= AudioPlayer();
      if (_musicPlaying) {
        await player.pause();
      } else {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('audio/retro_dex_theme.wav'));
      }
      if (mounted) {
        setState(() {
          _musicPlaying = !_musicPlaying;
          _musicLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _musicLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo reproducir la música: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    unawaited(_musicPlayer?.dispose());
    unawaited(_effectPlayer?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DexHeader(
              musicPlaying: _musicPlaying,
              musicLoading: _musicLoading,
              onMusicToggle: _toggleMusic,
              soundsEnabled: _soundsEnabled,
              onSoundsToggle: _toggleSounds,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: _SearchBox(
                controller: _searchController,
                message: _searchMessage,
                onSubmitted: (_) => _search(),
                onSearch: _search,
                onChanged: (_) => setState(() => _searchMessage = null),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 850) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 330, child: _buildCatalog()),
                        Expanded(child: _buildDetails()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(child: _buildDetails()),
                      SizedBox(height: 12, child: ColoredBox(color: _paper)),
                      Expanded(child: _buildCatalog()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalog() {
    final query = _searchController.text.trim().toLowerCase();
    final visiblePokemon = query.isEmpty
        ? _pokemon
        : _pokemon
              .where(
                (pokemon) =>
                    pokemon.name.contains(query) ||
                    pokemon.id.toString() == query,
              )
              .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 12, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E3D8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Icon(Icons.catching_pokemon, color: _red),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'POKÉMON',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Text(
                  _pokemon.isEmpty ? '...' : '${_pokemon.length} vistos',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEFECE5)),
          Expanded(
            child: _loadingFirstPage && _pokemon.isEmpty
                ? const Center(child: CircularProgressIndicator(color: _red))
                : _listError != null && _pokemon.isEmpty
                ? _CatalogError(message: _listError!, onRetry: _loadNextPage)
                : visiblePokemon.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        query.isEmpty
                            ? 'Cargando Pokémon...'
                            : 'Pulsa buscar para encontrar "$query".',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount:
                        visiblePokemon.length +
                        (_loadingMore || _hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= visiblePokemon.length) {
                        if (_loadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _red,
                              ),
                            ),
                          );
                        }
                        if (_listError != null) {
                          return TextButton.icon(
                            onPressed: _loadNextPage,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar carga'),
                          );
                        }
                        return const SizedBox(height: 44);
                      }
                      final pokemon = visiblePokemon[index];
                      return _PokemonTile(
                        pokemon: pokemon,
                        selected: pokemon.id == _selectedId,
                        onTap: () => _selectPokemon(pokemon.id),
                      );
                    },
                  ),
          ),
          if (!_hasMore && _pokemon.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                '¡Has llegado al final!',
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return FutureBuilder<Pokemon>(
      future: _selectedPokemon,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _red));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 42, color: _red),
                const SizedBox(height: 10),
                const Text('No se pudo cargar la ficha.'),
                TextButton(
                  onPressed: () => _selectPokemon(_selectedId),
                  child: const Text('Intentar de nuevo'),
                ),
              ],
            ),
          );
        }
        final pokemon = snapshot.data;
        return pokemon == null
            ? const Center(child: Text('Elige un Pokémon'))
            : _PokemonDetails(pokemon: pokemon);
      },
    );
  }
}

class _DexHeader extends StatelessWidget {
  const _DexHeader({
    required this.musicPlaying,
    required this.musicLoading,
    required this.onMusicToggle,
    required this.soundsEnabled,
    required this.onSoundsToggle,
  });

  final bool musicPlaying;
  final bool musicLoading;
  final VoidCallback onMusicToggle;
  final bool soundsEnabled;
  final VoidCallback onSoundsToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
      decoration: const BoxDecoration(
        color: _red,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF7ED8EE),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x553B2020),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.catching_pokemon, color: Colors.white),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POKÉDEX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Tu guía para atraparlos a todos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFFFFE5E2), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: soundsEnabled ? 'Silenciar efectos' : 'Activar efectos',
            onPressed: onSoundsToggle,
            color: Colors.white,
            icon: Icon(
              soundsEnabled ? Icons.volume_up : Icons.volume_off,
              size: 24,
            ),
          ),
          IconButton(
            tooltip: musicPlaying ? 'Pausar música' : 'Reproducir música',
            onPressed: musicLoading ? null : onMusicToggle,
            color: Colors.white,
            icon: musicLoading
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    musicPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: 30,
                  ),
          ),
          const Icon(Icons.circle, size: 13, color: Color(0xFFFFCF58)),
          const SizedBox(width: 7),
          const Icon(Icons.circle, size: 13, color: Color(0xFF8BE09A)),
          const SizedBox(width: 7),
          const Icon(Icons.circle, size: 13, color: Color(0xFF8BD8ED)),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.message,
    required this.onSubmitted,
    required this.onSearch,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? message;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearch;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Busca por nombre o número...',
            prefixIcon: const Icon(Icons.search, color: _red),
            suffixIcon: IconButton(
              tooltip: 'Buscar Pokémon',
              onPressed: onSearch,
              icon: const Icon(Icons.arrow_forward, color: _red),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Color(0xFFE8E3D8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Color(0xFFE8E3D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _red, width: 1.5),
            ),
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 5),
            child: Text(
              message!,
              style: const TextStyle(color: _red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _PokemonTile extends StatelessWidget {
  const _PokemonTile({
    required this.pokemon,
    required this.selected,
    required this.onTap,
  });

  final PokemonSummary pokemon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFFEFEC) : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: pokemon.imageUrl == null
                      ? const Icon(Icons.catching_pokemon, color: _red)
                      : Image.network(
                          pokemon.imageUrl!,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.catching_pokemon, color: _red),
                        ),
                ),
                const SizedBox(width: 9),
                Text(
                  '#${pokemon.id.toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _capitalize(pokemon.name),
                    style: TextStyle(
                      color: _ink,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.chevron_right, color: _red, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokemonDetails extends StatelessWidget {
  const _PokemonDetails({required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(pokemon.types.firstOrNull ?? '');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 20, 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 265),
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [typeColor, Color.lerp(typeColor, _ink, 0.12)!],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  top: -30,
                  child: Icon(
                    Icons.catching_pokemon,
                    size: 190,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'N.º ${pokemon.id.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _capitalize(pokemon.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Wrap(
                      spacing: 7,
                      children: pokemon.types
                          .map(
                            (type) => Chip(
                              label: Text(_capitalize(_typeName(type))),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.22,
                              ),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
                    Center(
                      child: SizedBox(
                        height: 175,
                        child: pokemon.imageUrl == null
                            ? const Icon(
                                Icons.catching_pokemon,
                                size: 120,
                                color: Colors.white,
                              )
                            : Image.network(
                                pokemon.imageUrl!,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.catching_pokemon,
                                      size: 120,
                                      color: Colors.white,
                                    ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8E3D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATOS DEL POKÉMON',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        label: 'ALTURA',
                        value: '${(pokemon.height / 10).toStringAsFixed(1)} m',
                      ),
                    ),
                    Container(width: 1, height: 38, color: _paper),
                    Expanded(
                      child: _InfoItem(
                        label: 'PESO',
                        value: '${(pokemon.weight / 10).toStringAsFixed(1)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'ESTADÍSTICAS BASE',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ...pokemon.stats.map((stat) => _StatBar(stat: stat)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Datos proporcionados por PokéAPI',
              style: TextStyle(color: Colors.black45, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.stat});

  final PokemonStat stat;

  @override
  Widget build(BuildContext context) {
    final progress = (stat.value / 150).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              _statName(stat.name),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '${stat.value}',
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                color: progress > 0.65 ? _green : _red,
                backgroundColor: const Color(0xFFF0EDE6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PokemonService {
  PokemonService()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

  final Dio _dio;
  static const _baseUrl = 'https://pokeapi.co/api/v2/pokemon';
  static const _pageSize = 24;

  Future<PokemonPageResult> fetchPokemonPage(int offset) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _baseUrl,
      queryParameters: {'limit': _pageSize, 'offset': offset},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('La API devolvió una respuesta vacía.');
    }
    final results = data['results'] as List<dynamic>;
    return PokemonPageResult(
      pokemon: results
          .map(
            (entry) => PokemonSummary.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
      hasNext: data['next'] != null,
    );
  }

  Future<Pokemon> fetchPokemon(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_baseUrl/$id/');
    final data = response.data;
    if (data == null) {
      throw const FormatException('La API devolvió una respuesta vacía.');
    }
    return Pokemon.fromJson(data);
  }

  Future<Pokemon> searchPokemon(String query) async {
    final normalized = query.toLowerCase().replaceAll(' ', '-');
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/$normalized/',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('La API devolvió una respuesta vacía.');
    }
    return Pokemon.fromJson(data);
  }
}

class PokemonPageResult {
  const PokemonPageResult({required this.pokemon, required this.hasNext});

  final List<PokemonSummary> pokemon;
  final bool hasNext;
}

class PokemonSummary {
  const PokemonSummary({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String? imageUrl;

  factory PokemonSummary.fromJson(Map<String, dynamic> json) {
    final uri = Uri.parse(json['url'] as String);
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    final id = int.parse(segments.last);
    return PokemonSummary(
      id: id,
      name: json['name'] as String,
      imageUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
    );
  }
}

class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.imageUrl,
    required this.types,
    required this.stats,
  });

  final int id;
  final String name;
  final int height;
  final int weight;
  final String? imageUrl;
  final List<String> types;
  final List<PokemonStat> stats;

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] as Map<String, dynamic>;
    final otherSprites = sprites['other'] as Map<String, dynamic>;
    final officialArtwork =
        otherSprites['official-artwork'] as Map<String, dynamic>;
    final rawTypes = json['types'] as List<dynamic>;
    final rawStats = json['stats'] as List<dynamic>;

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
      imageUrl:
          (officialArtwork['front_default'] as String?) ??
          sprites['front_default'] as String?,
      types: rawTypes
          .map(
            (entry) =>
                (entry as Map<String, dynamic>)['type']['name'] as String,
          )
          .toList(),
      stats: rawStats
          .map((entry) => PokemonStat.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PokemonStat {
  const PokemonStat({required this.name, required this.value});

  final String name;
  final int value;

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      name: json['stat']['name'] as String,
      value: json['base_stat'] as int,
    );
  }
}

Uint8List _createPokemonCry(int pokemonId) {
  const sampleRate = 22050;
  const noteDuration = 0.095;
  const noteCount = 4;
  final frameCount = (sampleRate * noteDuration * noteCount).round();
  final bytes = Uint8List(44 + frameCount * 2);
  final header = ByteData.sublistView(bytes);

  void writeText(int offset, String value) {
    bytes.setRange(offset, offset + value.length, value.codeUnits);
  }

  writeText(0, 'RIFF');
  header.setUint32(4, 36 + frameCount * 2, Endian.little);
  writeText(8, 'WAVE');
  writeText(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  writeText(36, 'data');
  header.setUint32(40, frameCount * 2, Endian.little);

  final baseFrequency = 330 + (pokemonId * 13 % 280);
  final intervals = [1.0, 1.26, 1.5, 1.12];
  for (var frame = 0; frame < frameCount; frame++) {
    final time = frame / sampleRate;
    final noteIndex = (time / noteDuration).floor();
    final noteTime = time - noteIndex * noteDuration;
    final frequency = baseFrequency * intervals[noteIndex];
    final phase = (noteTime * frequency) % 1;
    final tone = phase < 0.35 ? 1.0 : -1.0;
    final attack = math.min(1.0, noteTime / 0.008);
    final release = math.max(0.0, 1.0 - noteTime / noteDuration);
    final sample = (tone * attack * release * 0.22 * 32767).round();
    header.setInt16(44 + frame * 2, sample, Endian.little);
  }

  return bytes;
}

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

String _typeName(String type) {
  const names = {
    'bug': 'bicho',
    'dark': 'siniestro',
    'dragon': 'dragón',
    'electric': 'eléctrico',
    'fairy': 'hada',
    'fighting': 'lucha',
    'fire': 'fuego',
    'flying': 'volador',
    'ghost': 'fantasma',
    'grass': 'planta',
    'ground': 'tierra',
    'ice': 'hielo',
    'normal': 'normal',
    'poison': 'veneno',
    'psychic': 'psíquico',
    'rock': 'roca',
    'steel': 'acero',
    'water': 'agua',
  };
  return names[type] ?? type;
}

String _statName(String name) {
  const names = {
    'hp': 'PS',
    'attack': 'Ataque',
    'defense': 'Defensa',
    'special-attack': 'At. especial',
    'special-defense': 'Def. especial',
    'speed': 'Velocidad',
  };
  return names[name] ?? name;
}

Color _typeColor(String type) {
  const colors = {
    'bug': Color(0xFF91A832),
    'dark': Color(0xFF66584D),
    'dragon': Color(0xFF7460D5),
    'electric': Color(0xFFE3B72E),
    'fairy': Color(0xFFD875A5),
    'fighting': Color(0xFFC65B4B),
    'fire': Color(0xFFE87945),
    'flying': Color(0xFF8297D7),
    'ghost': Color(0xFF7969A8),
    'grass': Color(0xFF61AC69),
    'ground': Color(0xFFD0A35B),
    'ice': Color(0xFF66BFC4),
    'normal': Color(0xFF9A9A82),
    'poison': Color(0xFF9A68A8),
    'psychic': Color(0xFFE3657B),
    'rock': Color(0xFFA89456),
    'steel': Color(0xFF8290A5),
    'water': Color(0xFF568DD5),
  };
  return colors[type] ?? _red;
}
