import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'dex_data.dart';
part 'intro.dart';
part 'studio.dart';
part 'liz.dart';
part 'motion.dart';

// Colores de la Pokédex clásica de Kanto.
const _dexRed = Color(0xFFDC0A2D);
const _dexRedDark = Color(0xFF8E0019);
const _outline = Color(0xFF161616);
const _bezel = Color(0xFFDEDEDE);
const _lcdBlack = Color(0xFF0E120E);
const _lcdText = Color(0xFF4CFF6E);
const _lcdDim = Color(0xFF1F6B2E);
const _greenScreen = Color(0xFF32CB65);
const _gbLight = Color(0xFF9BBC0F);
const _gbDark = Color(0xFF0F380F);
const _keyBlue = Color(0xFF28AAFD);
const _lensBlue = Color(0xFF3DA9FC);
const _lightRed = Color(0xFFFF2B2B);
const _lightYellow = Color(0xFFFFD733);
const _lightGreen = Color(0xFF3CE05B);

const _pixelFont = 'PressStart2P';
const _stepHeight = 100.0;

/// Alto de cada fila de la lista (sprite de 36 + márgenes).
const _tileHeight = 40.0;
const _maxPokemonId = 1025;
const _musicVolume = 0.4;
const _duckedVolume = 0.1;

/// Música de fondo: el tema de Rojo Fuego en un bucle sin cortes (10 compases
/// exactos a 139,2 bpm).
const _musicAsset = 'audio/rojo_fuego_loop.wav';

TextStyle _pixel(double size, {Color color = _lcdText, double height = 1.6}) {
  return TextStyle(
    fontFamily: _pixelFont,
    fontSize: size,
    color: color,
    height: height,
  );
}

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
        colorScheme: ColorScheme.fromSeed(seedColor: _dexRed),
        scaffoldBackgroundColor: const Color(0xFF1E2128),
        useMaterial3: true,
      ),
      home: const TrainerGate(),
    );
  }
}

class PokemonPage extends StatefulWidget {
  const PokemonPage({
    super.key,
    this.loadPokemon,
    this.loadGeneration,
    this.searchPokemon,
    this.playPokemonCry,
    this.speak,
    this.lizBlip,
    this.autoplayMusic = true,
    this.trainerName,
    this.lizIntro = LizIntro.none,
    this.onTrainerNamed,
  });

  final Future<Pokemon> Function(int id)? loadPokemon;
  final Future<List<PokemonSummary>> Function(Generation generation)?
  loadGeneration;
  final Future<Pokemon> Function(String query)? searchPokemon;
  final Future<void> Function(Pokemon pokemon)? playPokemonCry;
  final Future<void> Function(String text)? speak;

  /// Reproduce el bip de 8 bits de una letra de Liz.
  final ValueChanged<String>? lizBlip;
  final bool autoplayMusic;
  final String? trainerName;

  /// Lo que dice Liz al abrir la Pokédex.
  final LizIntro lizIntro;

  /// Registra el nombre que el entrenador le dice a Liz.
  final ValueChanged<String>? onTrainerNamed;

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  final _service = PokemonService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _pokemon = <PokemonSummary>[];

  Pokemon? _current;
  int _selectedId = 1;
  int _requestToken = 0;
  int _speechToken = 0;
  bool _loadingPokemon = false;
  String? _detailError;

  int _generation = 0;
  int _listToken = 0;
  final _generationCache = <int, List<PokemonSummary>>{};
  bool _loadingList = false;
  String? _listError;
  String? _searchMessage;
  bool _searching = false;

  bool _musicPlaying = false;
  bool _musicLoading = false;
  bool _soundsEnabled = true;
  bool _voiceEnabled = true;
  bool _speaking = false;
  // El navegador bloquea el audio hasta que el usuario interactúa; si el
  // arranque automático falla, la música empieza con el primer toque.
  bool _musicAutoplayPending = false;
  DateTime? _musicWokeAt;

  AudioPlayer? _musicPlayer;
  AudioPlayer? _effectPlayer;
  final _voice = DexVoice();
  final _blips = _LizBlips();

  // Liz: qué está mostrando y a qué partes de la Pokédex apunta.
  List<_LizStep>? _lizSteps;
  bool _lizMenu = false;
  final _lensKey = GlobalKey();
  final _mainScreenKey = GlobalKey();
  final _musicKey = GlobalKey();
  final _soundKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _dpadKey = GlobalKey();
  final _infoKey = GlobalKey();
  final _keypadKey = GlobalKey();
  final _readKey = GlobalKey();
  final _listKey = GlobalKey();
  final _generationKey = GlobalKey();
  final _lizKey = GlobalKey();
  final _trainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_showPokemon(_loadPokemon(1), announce: false));
    unawaited(_loadGeneration(0));
    if (widget.autoplayMusic) {
      if (kIsWeb) {
        // Chrome deja el audio suspendido hasta el primer toque (y el intento
        // de reanudarlo se queda colgado), así que en web arrancamos la
        // música con la primera interacción del usuario.
        _musicAutoplayPending = true;
      } else {
        unawaited(_startMusic(showErrors: false));
      }
    }
    if (widget.lizIntro == LizIntro.tour) _lizSteps = _tourSteps();
  }

  // ---------------------------------------------------------------- Liz

  /// Recorrido por los controles. Si aún no conoce al entrenador, al final
  /// le pregunta su nombre para registrarlo.
  List<_LizStep> _tourSteps() {
    final name = widget.trainerName;
    return [
      _LizStep(
        name == null
            ? '¡Hola! Soy Liz, y voy a acompañarte en esta Pokédex. Te '
                  'muestro rápido cómo funciona; toca el cuadro de texto para '
                  'seguir.'
            : '¡Bienvenido a tu Pokédex, $name! Soy Liz. Te doy un recorrido '
                  'rápido; toca el cuadro de texto para seguir.',
        art: _LizArt.liz,
        moods: name == null
            ? const [_LizMood.cheerful, _LizMood.happy, _LizMood.wink]
            : const [_LizMood.excited, _LizMood.happy, _LizMood.wink],
      ),
      _LizStep(
        'Esta es la pantalla principal: aquí ves al Pokémon, su número y el '
        'color de sus tipos. Con el botón rojo de abajo vuelves a escuchar su '
        'grito.',
        target: _mainScreenKey,
        moods: const [_LizMood.proud, _LizMood.happy],
      ),
      _LizStep(
        'En la pantalla negra tienes su ficha completa: categoría, tipos, '
        'generación, tamaño, habilidades, descripción, debilidades, '
        'estadísticas y evoluciones. Si tocas una evolución, la abres.',
        target: _infoKey,
        moods: const [_LizMood.proud, _LizMood.happy],
      ),
      _LizStep(
        'Ojo con las debilidades: ahí ves qué tipos le hacen el doble de daño, '
        'o el cuádruple si marca x4. También lo que resiste y a qué es inmune.',
        target: _infoKey,
        moods: const [_LizMood.thinking, _LizMood.proud],
      ),
      _LizStep(
        'Esta es la lista de la generación que elegiste. Desliza para ver más '
        'y toca cualquiera para abrir su ficha.',
        target: _listKey,
        moods: const [_LizMood.happy, _LizMood.wink],
      ),
      _LizStep(
        'Los Pokémon van por generaciones, según la región donde aparecieron: '
        'Kanto, Johto, Hoenn y las demás. Con estas flechas cambias de '
        'generación.',
        target: _generationKey,
        moods: const [_LizMood.thinking, _LizMood.happy],
      ),
      _LizStep(
        'Con la cruceta pasas al Pokémon anterior o al siguiente.',
        target: _dpadKey,
        moods: const [_LizMood.wink],
      ),
      _LizStep(
        '¿Buscas a alguno en especial? Escribe aquí su nombre o su número y '
        'pulsa Enter.',
        target: _searchKey,
        moods: const [_LizMood.curious, _LizMood.happy],
      ),
      _LizStep(
        'O marca el número en este teclado: OK para buscar y BORRAR para '
        'empezar de nuevo.',
        target: _keypadKey,
        moods: const [_LizMood.happy],
      ),
      _LizStep(
        'GRITO activa o silencia el sonido de cada Pokémon. VOZ hace lo mismo '
        'con la lectura de la ficha y con mis sonidos.',
        target: _soundKey,
        moods: const [_LizMood.happy, _LizMood.wink],
      ),
      _LizStep(
        'LEER vuelve a leer la ficha en voz alta y CALLAR la detiene.',
        target: _readKey,
        moods: const [_LizMood.happy],
      ),
      _LizStep(
        'Y este botón pone o pausa la música.',
        target: _musicKey,
        moods: const [_LizMood.cheerful],
      ),
      _LizStep(
        'La lente azul brilla cuando la Pokédex habla, y las luces se '
        'encienden al cargar datos, con la música y cuando el grito está '
        'activo.',
        target: _lensKey,
        moods: const [_LizMood.proud],
      ),
      _LizStep(
        name == null
            ? 'Eso es todo. Si necesitas algo, toca mi botón y aquí estaré.'
            : 'Eso es todo. Si necesitas algo, toca mi botón y aquí estaré. '
                  '¡Ahora sí, sal a descubrir Pokémon, $name!',
        target: _lizKey,
        moods: const [_LizMood.happy, _LizMood.wink, _LizMood.excited],
      ),
      if (name == null && widget.onTrainerNamed != null) _namePrompt(),
    ];
  }

  _LizStep _namePrompt() => _LizStep(
    widget.trainerName == null
        ? 'Antes de irte, registremos tu nombre en la Pokédex. ¿Cómo te llamas?'
        : '¿Cómo quieres que te llame?',
    art: _LizArt.liz,
    asksName: true,
    moods: widget.trainerName == null
        ? const [_LizMood.happy, _LizMood.curious]
        : const [_LizMood.curious],
  );

  void _registerTrainer(String name) {
    final firstTime = widget.trainerName == null;
    widget.onTrainerNamed?.call(name);
    _openLiz([
      _LizStep(
        firstTime
            ? '¡Listo, $name! Ya quedaste registrado. Ahora sí, a descubrir '
                  'Pokémon.'
            : '¡Hecho! Desde ahora te llamaré $name.',
        target: _trainerKey,
        moods: firstTime
            ? const [_LizMood.excited, _LizMood.proud]
            : const [_LizMood.happy, _LizMood.wink],
      ),
    ]);
  }

  void _openLiz(List<_LizStep> steps, {bool menu = false}) {
    unawaited(_stopVoice());
    setState(() {
      _lizSteps = steps;
      _lizMenu = menu;
    });
  }

  void _openLizMenu([
    String? text,
    bool silent = false,
    List<_LizMood>? moods,
  ]) {
    final name = widget.trainerName;
    _openLiz([
      _LizStep(
        text ??
            (name == null ? '¿En qué te ayudo?' : '¿En qué te ayudo, $name?'),
        silent: silent,
        moods: moods,
      ),
    ], menu: true);
  }

  /// Liz no tiene voz: cada letra suena como un bip de 8 bits. Se
  /// silencia con VOZ, igual que la lectura de las fichas.
  void _lizLetter(String letter) {
    if (!_voiceEnabled) return;
    if (widget.lizBlip != null) return widget.lizBlip!(letter);
    unawaited(_blips.play(letter));
  }

  void _closeLiz() {
    unawaited(_stopVoice());
    setState(() {
      _lizSteps = null;
      _lizMenu = false;
    });
  }

  // ---------------------------------------------------------------- Datos

  Future<Pokemon> _loadPokemon(int id) {
    return widget.loadPokemon?.call(id) ?? _service.fetchPokemon(id);
  }

  /// Carga la lista de una generación (una sola petición, ~150 entradas) y la
  /// guarda para no volver a pedirla.
  Future<void> _loadGeneration(int index) async {
    final token = ++_listToken;
    final cached = _generationCache[index];
    setState(() {
      _generation = index;
      _listError = null;
      _pokemon
        ..clear()
        ..addAll(cached ?? const []);
      _loadingList = cached == null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    if (cached != null) return;

    try {
      final generation = generations[index];
      final list =
          await (widget.loadGeneration?.call(generation) ??
              _service.fetchGeneration(generation));
      if (!mounted || token != _listToken) return;
      _generationCache[index] = list;
      setState(() {
        _pokemon
          ..clear()
          ..addAll(list);
        _loadingList = false;
      });
    } catch (_) {
      if (!mounted || token != _listToken) return;
      setState(() {
        _loadingList = false;
        _listError = 'ERROR DE CONEXION';
      });
    }
  }

  void _stepGeneration(int delta) {
    final next = _generation + delta;
    if (next >= 0 && next < generations.length) {
      unawaited(_loadGeneration(next));
    }
  }

  /// Desplaza la lista hasta el Pokémon elegido si no se ve.
  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_searchController.text.trim().isNotEmpty) return;
      final index = _pokemon.indexWhere((entry) => entry.id == _selectedId);
      if (index < 0) return;
      final position = _scrollController.position;
      final top = index * _tileHeight;
      final visible =
          top >= position.pixels &&
          top + _tileHeight <= position.pixels + position.viewportDimension;
      if (visible) return;
      final target = top - position.viewportDimension / 2 + _tileHeight / 2;
      unawaited(
        _scrollController.animateTo(
          target.clamp(0.0, position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  /// Acepta también ids de formas (megas: 10000+).
  void _selectPokemon(int id) {
    if (id < 1) return;
    setState(() => _selectedId = id);
    unawaited(_showPokemon(_loadPokemon(id)));
  }

  void _step(int delta) {
    // Desde una mega, la cruceta sigue desde su especie base.
    final base = _selectedId > _maxPokemonId
        ? (_current?.speciesId ?? 1)
        : _selectedId;
    final next = base + delta;
    if (next >= 1 && next <= _maxPokemonId) _selectPokemon(next);
  }

  Future<void> _showPokemon(
    Future<Pokemon> future, {
    bool announce = true,
  }) async {
    final token = ++_requestToken;
    unawaited(_stopVoice());
    setState(() {
      _loadingPokemon = true;
      _detailError = null;
    });

    final Pokemon pokemon;
    try {
      pokemon = await future;
    } catch (_) {
      if (!mounted || token != _requestToken) return;
      setState(() {
        _loadingPokemon = false;
        _detailError = 'NO SE PUDO CARGAR LA FICHA';
      });
      return;
    }
    if (!mounted || token != _requestToken) return;
    setState(() {
      _current = pokemon;
      _selectedId = pokemon.id;
      _loadingPokemon = false;
    });
    // Si llegamos a otra generación (cruceta, búsqueda, evoluciones), la
    // lista se cambia a esa generación.
    final generation = generationIndexOf(pokemon.speciesId ?? pokemon.id);
    if (generation != null && generation != _generation) {
      unawaited(_loadGeneration(generation).then((_) => _revealSelected()));
    } else {
      _revealSelected();
    }
    if (announce) await _announce(pokemon, token);
  }

  Future<void> _search() async {
    final raw = _searchController.text.trim().toLowerCase();
    if (raw.isEmpty || _searching) return;
    final query = int.tryParse(raw)?.toString() ?? raw;

    setState(() {
      _searchMessage = null;
      _searching = true;
    });
    try {
      final pokemon =
          await (widget.searchPokemon?.call(query) ??
              _service.searchPokemon(query));
      if (!mounted) return;
      setState(() => _searching = false);
      _searchController.clear();
      await _showPokemon(Future.value(pokemon));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchMessage = 'NO ENCONTRADO';
      });
    }
  }

  void _typeDigit(String digit) {
    final text = _searchController.text;
    final numeric = int.tryParse(text) != null;
    final next = numeric && text.length < 4 ? '$text$digit' : digit;
    _searchController.text = next;
    setState(() => _searchMessage = null);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchMessage = null);
  }

  // ---------------------------------------------------------------- Sonido

  Future<void> _announce(Pokemon pokemon, int token) async {
    if (_soundsEnabled) await _playCry(pokemon);
    if (!mounted || token != _requestToken) return;
    if (_voiceEnabled) await _speakPokemon(pokemon);
  }

  Future<void> _playCry(Pokemon pokemon) async {
    if (widget.playPokemonCry != null) {
      try {
        await widget.playPokemonCry!(pokemon);
      } catch (error) {
        debugPrint('No se pudo reproducir el grito: $error');
      }
      return;
    }

    final player = _effectPlayer ??= AudioPlayer();
    await _duckMusic();
    try {
      await player.stop();
      await player.setVolume(1);
      try {
        // Primero el grito "legacy" (el sonido 8 bits de los juegos
        // clásicos); si no existe o el formato no es compatible, probamos
        // los modernos y por último uno sintetizado.
        await _playFirstAvailable(player, [
          ...pokemon.cryUrls,
          // En web Showdown no envía cabeceras CORS y el audio no suena.
          if (!kIsWeb) ..._showdownCryUrls(pokemon.name),
        ]);
      } catch (_) {
        await _playToEnd(player, BytesSource(_createPokemonCry(pokemon.id)));
      }
    } catch (error) {
      debugPrint('No se pudo reproducir el grito: $error');
    } finally {
      await _restoreMusic();
    }
  }

  Future<void> _playFirstAvailable(
    AudioPlayer player,
    List<String> urls,
  ) async {
    Object? lastError;
    for (final url in urls) {
      try {
        await _playToEnd(player, UrlSource(url));
        return;
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('Sin grito disponible');
  }

  Future<void> _playToEnd(AudioPlayer player, Source source) async {
    // Escuchamos el final del sonido ignorando los errores del stream: los
    // errores reales ya los lanza play(). Antes se usaba catchError, que en
    // modo debug fallaba y cortaba el grito nada más empezar.
    final done = Completer<void>();
    final subscription = player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    }, onError: (Object _) {});
    try {
      await player.play(source).timeout(const Duration(seconds: 6));
      await done.future.timeout(const Duration(seconds: 4), onTimeout: () {});
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _speakPokemon(Pokemon pokemon) => _say(pokemon.speechText);

  /// Lee un texto con la voz de la Pokédex.
  Future<void> _say(String text) async {
    final token = ++_speechToken;
    setState(() => _speaking = true);
    await _duckMusic();
    try {
      if (widget.speak != null) {
        await widget.speak!(text);
      } else {
        await _voice.speak(text);
      }
    } catch (error) {
      debugPrint('No se pudo leer el texto: $error');
    } finally {
      if (mounted && token == _speechToken) {
        setState(() => _speaking = false);
        await _restoreMusic();
      }
    }
  }

  Future<void> _stopVoice() async {
    _speechToken++;
    if (_speaking && mounted) setState(() => _speaking = false);
    try {
      await _voice.stop();
      await _effectPlayer?.stop();
    } catch (_) {}
    await _restoreMusic();
  }

  void _readAgain() {
    final pokemon = _current;
    if (pokemon == null) return;
    unawaited(_stopVoice().then((_) => _speakPokemon(pokemon)));
  }

  void _cryAgain() {
    final pokemon = _current;
    if (pokemon == null) return;
    unawaited(_playCry(pokemon));
  }

  void _toggleSounds() => setState(() => _soundsEnabled = !_soundsEnabled);

  void _toggleVoice() {
    setState(() => _voiceEnabled = !_voiceEnabled);
    if (!_voiceEnabled) unawaited(_stopVoice());
  }

  Future<void> _duckMusic() async {
    try {
      await _musicPlayer?.setVolume(_duckedVolume);
    } catch (_) {}
  }

  Future<void> _restoreMusic() async {
    try {
      await _musicPlayer?.setVolume(_musicVolume);
    } catch (_) {}
  }

  void _wakeMusic() {
    if (!_musicAutoplayPending) return;
    _musicAutoplayPending = false;
    _musicWokeAt = DateTime.now();
    unawaited(_startMusic(showErrors: false));
  }

  Future<void> _toggleMusic() async {
    // Si este mismo toque acaba de desbloquear el audio, no lo pausamos.
    final wokeAt = _musicWokeAt;
    if (wokeAt != null &&
        DateTime.now().difference(wokeAt) < const Duration(seconds: 1)) {
      return;
    }
    _musicAutoplayPending = false;
    if (_musicPlaying) {
      await _musicPlayer?.pause();
      if (mounted) setState(() => _musicPlaying = false);
    } else {
      await _startMusic(showErrors: true);
    }
  }

  Future<void> _disposeMusic() async {
    final player = _musicPlayer;
    _musicPlayer = null;
    await player?.dispose();
  }

  Future<void> _startMusic({required bool showErrors}) async {
    if (_musicLoading || _musicPlaying) return;
    setState(() => _musicLoading = true);

    try {
      final volume = _speaking ? _duckedVolume : _musicVolume;
      final current = _musicPlayer;
      if (current != null) {
        // Tras una pausa, sigue donde se quedó.
        await current.setVolume(volume);
        await current.resume().timeout(const Duration(seconds: 8));
      } else {
        final player = _musicPlayer = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(volume);
        await player
            .play(AssetSource(_musicAsset))
            .timeout(const Duration(seconds: 8));
      }
      if (mounted) {
        setState(() {
          _musicPlaying = true;
          _musicLoading = false;
        });
      }
    } catch (error) {
      await _disposeMusic();
      if (!mounted) return;
      setState(() => _musicLoading = false);
      if (showErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo reproducir la música: $error')),
        );
      } else {
        _musicAutoplayPending = true;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    unawaited(_voice.stop());
    unawaited(_disposeMusic());
    unawaited(_effectPlayer?.dispose());
    _blips.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- Interfaz

  @override
  Widget build(BuildContext context) {
    final lizSteps = _lizSteps;
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _wakeMusic(),
        child: Stack(
          children: [
            // El paisaje de la presentación, detrás de la Pokédex.
            const Positioned.fill(child: _DexScenery()),
            Positioned.fill(child: _buildDex()),
            if (lizSteps != null)
              Positioned.fill(
                child: _LizOverlay(
                  // Una clave nueva por apertura reinicia el recorrido.
                  key: ObjectKey(lizSteps),
                  steps: lizSteps,
                  onLetter: _lizLetter,
                  onClose: _closeLiz,
                  onName: widget.onTrainerNamed == null
                      ? null
                      : _registerTrainer,
                  initialName: widget.trainerName,
                  // Quien ya está registrado puede dejar su nombre como está.
                  nameOptional: widget.trainerName != null,
                  actions: _lizMenu
                      ? [
                          _BlackPill(
                            label: 'GUIA',
                            tooltip: 'Recorrido por la Pokédex',
                            onPressed: () => _openLiz(_tourSteps()),
                          ),
                          _BlackPill(
                            label: 'POKEMON?',
                            tooltip: 'Qué son los Pokémon',
                            onPressed: () =>
                                _openLiz(_lizLessons(widget.trainerName)),
                          ),
                          if (widget.onTrainerNamed != null)
                            _BlackPill(
                              label: 'MI NOMBRE',
                              tooltip: 'Cambiar nombre de entrenador',
                              onPressed: () => _openLiz([_namePrompt()]),
                            ),
                          _BlackPill(
                            label: 'CERRAR',
                            tooltip: 'Cerrar a Liz',
                            onPressed: _closeLiz,
                          ),
                        ]
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDex() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 860) {
            final height = math.max(constraints.maxHeight - 32, 860.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: SizedBox(
                    height: height,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildLeftHalf(expand: true)),
                        const _Hinge(vertical: true),
                        Expanded(child: _buildRightHalf(expand: true)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _buildLeftHalf(expand: false),
                    const _Hinge(vertical: false),
                    _buildRightHalf(expand: false),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftHalf({required bool expand}) {
    final mainScreen = KeyedSubtree(
      key: _mainScreenKey,
      child: _MainScreen(
        pokemon: _current,
        loading: _loadingPokemon,
        error: _detailError,
        screenHeight: expand ? null : 220,
        onCry: _cryAgain,
      ),
    );
    return _Shell(
      shape: _leftShellPath,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 84,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyedSubtree(
                    key: _lensKey,
                    child: _Lens(glowing: _speaking),
                  ),
                  const SizedBox(width: 14),
                  _Light(color: _lightRed, on: _loadingPokemon || _searching),
                  const SizedBox(width: 8),
                  _Light(color: _lightYellow, on: _musicPlaying),
                  const SizedBox(width: 8),
                  _Light(color: _lightGreen, on: _soundsEnabled),
                ],
              ),
            ),
            const SizedBox(height: 26),
            if (expand) Expanded(child: mainScreen) else mainScreen,
            const SizedBox(height: 20),
            Row(
              children: [
                _RoundButton(
                  key: _musicKey,
                  tooltip: _musicPlaying
                      ? 'Pausar música'
                      : 'Reproducir música',
                  label: 'MUSICA',
                  onPressed: _musicLoading ? null : _toggleMusic,
                  icon: _musicPlaying ? Icons.pause : Icons.music_note,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        key: _soundKey,
                        children: [
                          Expanded(
                            child: _PillButton(
                              color: _lightRed,
                              label: _soundsEnabled ? 'GRITO ON' : 'GRITO OFF',
                              tooltip: _soundsEnabled
                                  ? 'Silenciar efectos'
                                  : 'Activar efectos',
                              onPressed: _toggleSounds,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PillButton(
                              color: _keyBlue,
                              label: _voiceEnabled ? 'VOZ ON' : 'VOZ OFF',
                              tooltip: _voiceEnabled
                                  ? 'Silenciar voz'
                                  : 'Activar voz',
                              onPressed: _toggleVoice,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _GreenScreen(
                        key: _searchKey,
                        controller: _searchController,
                        message: _searchMessage,
                        searching: _searching,
                        onSubmitted: (_) => _search(),
                        onChanged: (_) => setState(() => _searchMessage = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _DPad(
                  key: _dpadKey,
                  onPrevious: () => _step(-1),
                  onNext: () => _step(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightHalf({required bool expand}) {
    final info = KeyedSubtree(
      key: _infoKey,
      child: _InfoScreen(
        pokemon: _current,
        loading: _loadingPokemon,
        error: _detailError,
        onRetry: () => _selectPokemon(_selectedId),
        onSelect: _selectPokemon,
      ),
    );
    final list = KeyedSubtree(
      key: _listKey,
      child: _ListScreen(
        header: _GenerationBar(
          key: _generationKey,
          generation: generations[_generation],
          onPrevious: _generation > 0 ? () => _stepGeneration(-1) : null,
          onNext: _generation < generations.length - 1
              ? () => _stepGeneration(1)
              : null,
        ),
        child: _buildCatalog(),
      ),
    );

    return _Shell(
      shape: _rightShellPath,
      child: Stack(
        children: [
          _buildRightControls(expand: expand, info: info, list: list),
          // Liz vive en la parte alta de la tapa, junto al entrenador.
          Positioned(
            top: 18,
            left: 0,
            right: 22,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shellWidth = constraints.maxWidth + 22;
                final left = _rightNotchX(shellWidth) + _stepHeight * 0.7 + 8;
                // Botón (52) + separación: la placa solo si queda sitio.
                final roomForTag = constraints.maxWidth - left - 62 >= 84;
                return Padding(
                  padding: EdgeInsets.only(left: left),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.trainerName != null && roomForTag)
                        Flexible(
                          child: _TrainerTag(
                            key: _trainerKey,
                            name: widget.trainerName!,
                          ),
                        ),
                      const SizedBox(width: 10),
                      _LizButton(key: _lizKey, onPressed: _openLizMenu),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightControls({
    required bool expand,
    required Widget info,
    required Widget list,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, _stepHeight + 14, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (expand)
            Expanded(flex: 5, child: info)
          else
            SizedBox(height: 360, child: info),
          const SizedBox(height: 16),
          _Keypad(key: _keypadKey, onDigit: _typeDigit),
          const SizedBox(height: 14),
          Row(
            children: [
              _WhiteButton(
                label: 'BORRAR',
                tooltip: 'Borrar búsqueda',
                onPressed: _clearSearch,
              ),
              const SizedBox(width: 10),
              _WhiteButton(
                label: 'OK',
                tooltip: 'Buscar Pokémon',
                onPressed: _search,
              ),
              const Spacer(),
              Tooltip(
                message: _speaking ? 'Leyendo descripción' : 'Voz en espera',
                child: _Light(color: _lightYellow, on: _speaking, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            key: _readKey,
            children: [
              Expanded(
                child: _BlackPill(
                  label: 'LEER',
                  tooltip: 'Leer descripción',
                  onPressed: _current == null ? null : _readAgain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BlackPill(
                  label: 'CALLAR',
                  tooltip: 'Detener voz',
                  onPressed: _stopVoice,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (expand)
            Expanded(flex: 4, child: list)
          else
            SizedBox(height: 280, child: list),
        ],
      ),
    );
  }

  Widget _buildCatalog() {
    final query = _searchController.text.trim().toLowerCase();
    final number = int.tryParse(query);
    final visiblePokemon = query.isEmpty
        ? _pokemon
        : _pokemon
              .where(
                (pokemon) => number != null
                    ? pokemon.id == number
                    : pokemon.name.contains(query),
              )
              .toList();

    if (_loadingList && _pokemon.isEmpty) {
      return Center(
        child: Text('CARGANDO...', style: _pixel(9, color: _gbDark)),
      );
    }
    if (_listError != null && _pokemon.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_listError!, style: _pixel(9, color: _gbDark)),
            const SizedBox(height: 10),
            _BlackPill(
              label: 'REINTENTAR',
              tooltip: 'Reintentar carga',
              onPressed: () => _loadGeneration(_generation),
            ),
          ],
        ),
      );
    }
    if (visiblePokemon.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'PULSA OK PARA BUSCAR "${_dexText(query)}"',
            textAlign: TextAlign.center,
            style: _pixel(8, color: _gbDark),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemExtent: _tileHeight,
      itemCount: visiblePokemon.length,
      itemBuilder: (context, index) {
        final pokemon = visiblePokemon[index];
        return _PokemonTile(
          pokemon: pokemon,
          selected: pokemon.id == _selectedId,
          onTap: () => _selectPokemon(pokemon.id),
        );
      },
    );
  }
}

// -------------------------------------------------------------- Carcasa

Path _leftShellPath(Size size) {
  final w = size.width;
  final h = size.height;
  const r = 18.0;
  final cutX = math.min(math.max(w * 0.5, 230.0), w - _stepHeight);
  return Path()
    ..moveTo(r, 0)
    ..lineTo(cutX, 0)
    ..lineTo(cutX + _stepHeight * 0.7, _stepHeight)
    ..lineTo(w, _stepHeight)
    ..lineTo(w, h)
    ..lineTo(r, h)
    ..quadraticBezierTo(0, h, 0, h - r)
    ..lineTo(0, r)
    ..quadraticBezierTo(0, 0, r, 0)
    ..close();
}

double _rightNotchX(double width) => width * 0.35;

Path _rightShellPath(Size size) {
  final w = size.width;
  final h = size.height;
  const r = 18.0;
  final notchX = _rightNotchX(w);
  return Path()
    ..moveTo(0, _stepHeight)
    ..lineTo(notchX, _stepHeight)
    ..lineTo(notchX + _stepHeight * 0.7, 0)
    ..lineTo(w - r, 0)
    ..quadraticBezierTo(w, 0, w, r)
    ..lineTo(w, h - r)
    ..quadraticBezierTo(w, h, w - r, h)
    ..lineTo(0, h)
    ..close();
}

Path _bezelPath(Size size) {
  const cut = 38.0;
  const r = 8.0;
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(r, 0)
    ..lineTo(w - r, 0)
    ..quadraticBezierTo(w, 0, w, r)
    ..lineTo(w, h - r)
    ..quadraticBezierTo(w, h, w - r, h)
    ..lineTo(cut, h)
    ..lineTo(0, h - cut)
    ..lineTo(0, r)
    ..quadraticBezierTo(0, 0, r, 0)
    ..close();
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter({required this.shape, required this.color, this.bevel});

  final Path Function(Size) shape;
  final Color color;
  final Color? bevel;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape(size);
    canvas.drawPath(path, Paint()..color = color);
    if (bevel != null) {
      canvas
        ..save()
        ..clipPath(path)
        ..drawPath(
          path,
          Paint()
            ..color = bevel!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14,
        )
        ..restore();
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bevel != bevel;
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shape, required this.child});

  final Path Function(Size) shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShapePainter(
        shape: shape,
        color: _dexRed,
        bevel: _dexRedDark.withValues(alpha: 0.45),
      ),
      child: child,
    );
  }
}

class _Hinge extends StatelessWidget {
  const _Hinge({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: vertical ? Alignment.centerLeft : Alignment.topCenter,
        end: vertical ? Alignment.centerRight : Alignment.bottomCenter,
        colors: const [_dexRedDark, _dexRed, _dexRedDark],
      ),
      border: Border.all(color: _outline, width: 3),
    );
    Widget segment() => Expanded(child: Container(decoration: decoration));
    final segments = [segment(), segment(), segment()];

    if (vertical) {
      return Padding(
        padding: const EdgeInsets.only(top: _stepHeight),
        child: SizedBox(width: 26, child: Column(children: segments)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SizedBox(height: 24, child: Row(children: segments)),
    );
  }
}

class _Lens extends StatelessWidget {
  const _Lens({required this.glowing});

  final bool glowing;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: _outline, width: 3),
        boxShadow: [
          if (glowing)
            const BoxShadow(
              color: Color(0xCC6FD3FF),
              blurRadius: 22,
              spreadRadius: 4,
            ),
        ],
      ),
      padding: const EdgeInsets.all(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _outline, width: 3),
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 0.9,
            colors: glowing
                ? const [Color(0xFFE6FAFF), Color(0xFF7FDBFF), _lensBlue]
                : const [Color(0xFFB8E4FF), _lensBlue, Color(0xFF1C5FA8)],
          ),
        ),
      ),
    );
  }
}

class _Light extends StatelessWidget {
  const _Light({required this.color, required this.on, this.size = 20});

  final Color color;
  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = on ? color : Color.lerp(color, Colors.black, 0.55)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _outline, width: 2.5),
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Color.lerp(base, Colors.white, on ? 0.6 : 0.2)!, base],
        ),
        boxShadow: [
          if (on) BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Pantallas

class _MainScreen extends StatelessWidget {
  const _MainScreen({
    required this.pokemon,
    required this.loading,
    required this.error,
    required this.screenHeight,
    required this.onCry,
  });

  final Pokemon? pokemon;
  final bool loading;
  final String? error;

  /// Alto fijo de la pantalla; si es null ocupa todo el espacio disponible.
  final double? screenHeight;
  final VoidCallback onCry;

  @override
  Widget build(BuildContext context) {
    final screen = Container(
      height: screenHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6EE),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _outline, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
    return CustomPaint(
      painter: const _ShapePainter(shape: _bezelPath, color: _bezel),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 12, 30, 12),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_Dot(), SizedBox(width: 12), _Dot()],
            ),
            const SizedBox(height: 10),
            if (screenHeight == null) Expanded(child: screen) else screen,
            const SizedBox(height: 10),
            Row(
              children: [
                Tooltip(
                  message: 'Repetir grito',
                  child: _Pressable(
                    onPressed: pokemon == null ? null : onCry,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _lightRed,
                        border: Border.all(color: _outline, width: 2.5),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const _Speaker(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final pokemon = this.pokemon;
    if (error != null && !loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: _pixel(9, color: _outline),
          ),
        ),
      );
    }
    if (pokemon == null) {
      return Center(
        child: Text('CARGANDO...', style: _pixel(10, color: _outline)),
      );
    }
    final sprite = pokemon.spriteUrl ?? pokemon.imageUrl;
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
        Positioned(
          left: 10,
          top: 8,
          child: Text(
            'Nº${pokemon.id.toString().padLeft(3, '0')}',
            style: _pixel(10, color: _outline),
          ),
        ),
        Positioned(
          right: 10,
          top: 8,
          child: Row(
            children: [
              for (final type in pokemon.types)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _typeColor(type),
                      border: Border.all(color: _outline, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned.fill(
          top: 26,
          bottom: 30,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: sprite == null
                ? const Icon(Icons.catching_pokemon, size: 90, color: _outline)
                : SizedBox.expand(
                    key: ValueKey(sprite),
                    // Cada Pokémon se mueve a su manera.
                    child: _PokemonMotion(
                      pokemon: pokemon,
                      spriteUrl: sprite,
                      child: Image.network(
                        sprite,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.catching_pokemon,
                              size: 90,
                              color: _outline,
                            ),
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: _outline,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              loading ? 'CARGANDO...' : _dexText(pokemon.displayName),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pixel(10, color: Colors.white, height: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0F000000);
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) => false;
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _lightRed,
        border: Border.all(color: _outline, width: 1.5),
      ),
    );
  }
}

class _Speaker extends StatelessWidget {
  const _Speaker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 42,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: _outline,
          ),
      ],
    );
  }
}

class _InfoScreen extends StatelessWidget {
  const _InfoScreen({
    required this.pokemon,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onSelect,
  });

  final Pokemon? pokemon;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _lcdBlack,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _outline, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final pokemon = this.pokemon;
    if (error != null && !loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center, style: _pixel(9)),
            TextButton(
              onPressed: onRetry,
              child: Text('> REINTENTAR', style: _pixel(9)),
            ),
          ],
        ),
      );
    }
    if (pokemon == null || loading) {
      return Center(child: Text('BUSCANDO DATOS...', style: _pixel(9)));
    }

    final total = pokemon.stats.fold<int>(0, (sum, stat) => sum + stat.value);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _dexText(pokemon.displayName),
                  style: _pixel(13, color: Colors.white),
                ),
              ),
              Text(
                'Nº${pokemon.id.toString().padLeft(3, '0')}',
                style: _pixel(10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _dexText(pokemon.genus ?? 'Pokémon'),
            style: _pixel(9, color: _lcdText.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final type in pokemon.types)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _typeColor(type),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    _dexText(_typeName(type)),
                    style: _pixel(8, color: Colors.white, height: 1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _LcdField(
                label: 'ALT',
                value: '${(pokemon.height / 10).toStringAsFixed(1)} M',
              ),
              _LcdField(
                label: 'PESO',
                value: '${(pokemon.weight / 10).toStringAsFixed(1)} KG',
              ),
              if (pokemon.generation case final generation?)
                _LcdField(label: 'GEN', value: _dexText(generation.label)),
            ],
          ),
          if (pokemon.abilities.isNotEmpty) ...[
            const SizedBox(height: 6),
            _LcdField(
              label: 'HAB',
              value: _dexText(pokemon.abilities.join(' / ')),
            ),
          ],
          const _LcdDivider(),
          Text('RESUMEN', style: _pixel(9, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            pokemon.description ?? 'Sin datos registrados.',
            style: _pixel(9, height: 1.9),
          ),
          const _LcdDivider(),
          _TypeMatchups(types: pokemon.types),
          const _LcdDivider(),
          Text('ESTADISTICAS BASE', style: _pixel(9, color: Colors.white)),
          const SizedBox(height: 8),
          ...pokemon.stats.map((stat) => _StatBar(stat: stat)),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(width: 74, child: Text('TOTAL', style: _pixel(8))),
              Text('$total', style: _pixel(8, color: Colors.white)),
            ],
          ),
          const _LcdDivider(),
          Text('EVOLUCIONES', style: _pixel(9, color: Colors.white)),
          const SizedBox(height: 10),
          if (pokemon.evolutions.expand((level) => level).length <= 1)
            Text('NO EVOLUCIONA', style: _pixel(8))
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final (index, level) in pokemon.evolutions.indexed) ...[
                  if (index > 0) Text('▶', style: _pixel(10)),
                  for (final entry in level)
                    _EvolutionCard(
                      entry: entry,
                      selected: entry.id == (pokemon.speciesId ?? pokemon.id),
                      showCondition: index > 0,
                      onTap: () => onSelect(entry.id),
                    ),
                ],
              ],
            ),
          if (pokemon.megaForms.isNotEmpty) ...[
            const _LcdDivider(),
            Text('MEGAEVOLUCIONES', style: _pixel(9, color: Colors.white)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final entry in pokemon.megaForms)
                  _EvolutionCard(
                    entry: entry,
                    selected: entry.id == pokemon.id,
                    showCondition: true,
                    onTap: () => onSelect(entry.id),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({
    required this.entry,
    required this.selected,
    required this.showCondition,
    required this.onTap,
  });

  final EvolutionEntry entry;
  final bool selected;
  final bool showCondition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final condition = entry.condition;
    return Tooltip(
      message: 'Ver ${entry.displayName}',
      child: _Pressable(
        onPressed: onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          decoration: BoxDecoration(
            color: selected ? _lcdDim.withValues(alpha: 0.35) : null,
            border: Border.all(
              color: selected ? _lcdText : _lcdDim,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Image.network(
                  entry.spriteUrl,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.catching_pokemon, color: _lcdDim),
                ),
              ),
              Text(
                _dexText(entry.displayName),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: _pixel(7, color: Colors.white, height: 1.4),
              ),
              if (showCondition && condition != null) ...[
                const SizedBox(height: 4),
                Text(
                  _dexText(condition),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: _pixel(6, color: _lightYellow, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LcdField extends StatelessWidget {
  const _LcdField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: _pixel(8, color: _lcdDim),
          ),
          TextSpan(text: value, style: _pixel(8)),
        ],
      ),
    );
  }
}

class _LcdDivider extends StatelessWidget {
  const _LcdDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        '- - - - - - - - - - - - - - - - - - - - - - - -',
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: _pixel(8, color: _lcdDim, height: 1),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.stat});

  final PokemonStat stat;

  @override
  Widget build(BuildContext context) {
    final progress = (stat.value / 180).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(_statName(stat.name), style: _pixel(8)),
          ),
          SizedBox(
            width: 34,
            child: Text('${stat.value}', style: _pixel(8, color: Colors.white)),
          ),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                border: Border.all(color: _lcdDim, width: 1.5),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                heightFactor: 1,
                child: ColoredBox(
                  color: stat.value >= 100
                      ? _lcdText
                      : stat.value >= 60
                      ? _lightYellow
                      : _lightRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListScreen extends StatelessWidget {
  const _ListScreen({required this.header, required this.child});

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _outline, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _gbLight,
                border: Border.all(color: _outline, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de generación encima de la lista: ◀ GEN I · KANTO ▶
class _GenerationBar extends StatelessWidget {
  const _GenerationBar({
    super.key,
    required this.generation,
    required this.onPrevious,
    required this.onNext,
  });

  final Generation generation;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, String tooltip, VoidCallback? onPressed) {
      return Tooltip(
        message: tooltip,
        child: _Pressable(
          onPressed: onPressed,
          child: Container(
            width: 34,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _outline, width: 2),
            ),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
        ),
      );
    }

    return Row(
      children: [
        arrow(Icons.arrow_left, 'Generación anterior', onPrevious),
        Expanded(
          child: Column(
            children: [
              Text(
                'GEN ${generation.roman}',
                style: _pixel(9, color: _lightYellow, height: 1.2),
              ),
              Text(
                '${_dexText(generation.region)} · '
                '${generation.first}-${generation.last}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _pixel(7, color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        arrow(Icons.arrow_right, 'Generación siguiente', onNext),
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
    final foreground = selected ? _gbLight : _gbDark;
    return Material(
      color: selected ? _gbDark : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                child: Text(
                  selected ? '▶' : '',
                  style: _pixel(8, color: foreground),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: pokemon.imageUrl == null
                    ? Icon(Icons.catching_pokemon, color: foreground, size: 20)
                    : Image.network(
                        pokemon.imageUrl!,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.catching_pokemon,
                          color: foreground,
                          size: 20,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                'Nº${pokemon.id.toString().padLeft(3, '0')}',
                style: _pixel(8, color: foreground),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _dexText(pokemon.name.replaceAll('-', ' ')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pixel(9, color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- Botones

class _Pressable extends StatefulWidget {
  const _Pressable({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.6,
          child: Transform.translate(
            offset: Offset(0, _down ? 2 : 0),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.tooltip,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: tooltip,
          child: _Pressable(
            onPressed: onPressed,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A2A2A),
                border: Border.all(color: _outline, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), offset: Offset(0, 3)),
                ],
              ),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: _pixel(6, color: _outline, height: 1)),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.color,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final Color color;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _Pressable(
        onPressed: onPressed,
        child: Container(
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _outline, width: 2.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                style: _pixel(7, color: Colors.white, height: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlackPill extends StatelessWidget {
  const _BlackPill({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _Pressable(
        onPressed: onPressed,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _outline, width: 2.5),
          ),
          child: Text(
            label,
            style: _pixel(8, color: Colors.white70, height: 1),
          ),
        ),
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _Pressable(
        onPressed: onPressed,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _outline, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), offset: Offset(0, 3)),
            ],
          ),
          child: Text(label, style: _pixel(8, color: _outline, height: 1)),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({super.key, required this.onDigit});

  final ValueChanged<String> onDigit;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3', '4', '5'],
      ['6', '7', '8', '9', '0'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                for (final digit in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: _Pressable(
                        onPressed: () => onDigit(digit),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _keyBlue,
                            border: Border.all(color: _outline, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55000000),
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            digit,
                            style: _pixel(10, color: Colors.white, height: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GreenScreen extends StatelessWidget {
  const _GreenScreen({
    super.key,
    required this.controller,
    required this.message,
    required this.searching,
    required this.onSubmitted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? message;
  final bool searching;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _greenScreen,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _outline, width: 3),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        cursorColor: _outline,
        textInputAction: TextInputAction.search,
        style: _pixel(10, color: _outline, height: 1.2),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: searching ? 'BUSCANDO...' : message ?? 'NOMBRE O Nº',
          hintStyle: _pixel(
            8,
            color: message != null ? _dexRedDark : const Color(0xFF14592C),
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  const _DPad({super.key, required this.onPrevious, required this.onNext});

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const cell = 32.0;
    Widget arm(IconData icon, String tooltip, VoidCallback onPressed) {
      return Tooltip(
        message: tooltip,
        child: _Pressable(
          onPressed: onPressed,
          child: Container(
            width: cell,
            height: cell,
            color: const Color(0xFF2A2A2A),
            child: Icon(icon, color: Colors.white38, size: 18),
          ),
        ),
      );
    }

    return Container(
      width: cell * 3 + 6,
      height: cell * 3 + 6,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Contorno de la cruceta.
          Container(
            width: cell + 6,
            height: cell * 3 + 6,
            decoration: BoxDecoration(
              color: _outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: cell * 3 + 6,
            height: cell + 6,
            decoration: BoxDecoration(
              color: _outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(width: cell, height: cell, color: const Color(0xFF2A2A2A)),
          Positioned(
            top: 3,
            child: arm(Icons.arrow_drop_up, 'Anterior', onPrevious),
          ),
          Positioned(
            bottom: 3,
            child: arm(Icons.arrow_drop_down, 'Siguiente', onNext),
          ),
          Positioned(
            left: 3,
            child: arm(Icons.arrow_left, 'Anterior Pokémon', onPrevious),
          ),
          Positioned(
            right: 3,
            child: arm(Icons.arrow_right, 'Siguiente Pokémon', onNext),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- API

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

  Future<Map<String, dynamic>> _getJson(
    String url, [
    Map<String, dynamic>? query,
  ]) async {
    final response = await _dio.get<Map<String, dynamic>>(
      url,
      queryParameters: query,
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('La API devolvió una respuesta vacía.');
    }
    return data;
  }

  /// Todos los Pokémon de una generación en una sola petición.
  Future<List<PokemonSummary>> fetchGeneration(Generation generation) async {
    final data = await _getJson(_baseUrl, {
      'limit': generation.count,
      'offset': generation.first - 1,
    });
    final results = data['results'] as List<dynamic>;
    return results
        .map((entry) => PokemonSummary.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<Pokemon> fetchPokemon(int id) => _fetchFull('$id');

  Future<Pokemon> searchPokemon(String query) =>
      _fetchFull(query.trim().toLowerCase().replaceAll(' ', '-'));

  /// Carga el Pokémon y, en paralelo, su especie (descripción y categoría) y
  /// los nombres en español de sus habilidades. Si estos datos extra fallan,
  /// la ficha se muestra igualmente.
  Future<Pokemon> _fetchFull(String key) async {
    final data = await _getJson('$_baseUrl/$key/');
    final pokemon = Pokemon.fromJson(data);

    final speciesUrl = _dig(data, ['species', 'url']) as String?;
    final speciesFuture = speciesUrl == null
        ? Future<Map<String, dynamic>?>.value()
        : _orNull(_getJson(speciesUrl));

    final abilityEntries = (data['abilities'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final abilityFutures = abilityEntries.map((entry) async {
      final name = _dig(entry, ['ability', 'name']) as String? ?? '';
      final url = _dig(entry, ['ability', 'url']) as String?;
      final ability = url == null ? null : await _orNull(_getJson(url));
      return _localizedName(ability?['names'] as List<dynamic>?) ??
          _capitalize(name.replaceAll('-', ' '));
    });

    final species = await speciesFuture;
    final evolutionsFuture = _orNull(_fetchEvolutions(species));
    final abilities = await Future.wait(abilityFutures);
    final evolutions = await evolutionsFuture;
    return pokemon.copyWith(
      abilities: abilities,
      evolutions: evolutions?.stages,
      megaForms: evolutions?.megas,
      genus: _pickGenus(species?['genera'] as List<dynamic>?),
      description: _pickFlavorText(
        species?['flavor_text_entries'] as List<dynamic>?,
      ),
    );
  }

  /// Recorre la cadena evolutiva de la especie y busca las megaevoluciones
  /// de todos sus miembros (así Charmander también muestra Mega Charizard).
  Future<({List<List<EvolutionEntry>> stages, List<EvolutionEntry> megas})>
  _fetchEvolutions(Map<String, dynamic>? species) async {
    if (species == null) {
      return (stages: <List<EvolutionEntry>>[], megas: <EvolutionEntry>[]);
    }

    final chainUrl = _dig(species, ['evolution_chain', 'url']) as String?;
    final chain = chainUrl == null ? null : await _orNull(_getJson(chainUrl));

    // Primera pasada: nodos por etapa y objetos que hay que traducir.
    final nodes = <List<Map<String, dynamic>>>[];
    final itemUrls = <String>{};
    void walk(Map<String, dynamic> node, int depth) {
      if (nodes.length <= depth) nodes.add([]);
      nodes[depth].add(node);
      final detail = _firstDetail(node);
      for (final key in ['item', 'held_item']) {
        if (_dig(detail, [key, 'url']) case final String url) itemUrls.add(url);
      }
      for (final next in (node['evolves_to'] as List<dynamic>? ?? const [])) {
        walk(next as Map<String, dynamic>, depth + 1);
      }
    }

    if (chain?['chain'] case final Map<String, dynamic> root) walk(root, 0);

    final itemNames = <String, String>{};
    await Future.wait(
      itemUrls.map((url) async {
        final item = await _orNull(_getJson(url));
        final name = _localizedName(item?['names'] as List<dynamic>?);
        if (name != null) itemNames[url] = name;
      }),
    );

    final stages = [
      for (final level in nodes)
        [
          for (final node in level)
            EvolutionEntry(
              id: _idFromUrl(_dig(node, ['species', 'url']) as String),
              name: _dig(node, ['species', 'name']) as String,
              condition: _evolutionCondition(_firstDetail(node), itemNames),
            ),
        ],
    ];

    // Megaevoluciones: las "variedades" de cada especie cuyo nombre lleva
    // "-mega" (charizard-mega-x, charizard-mega-y...).
    final speciesId = species['id'] as int?;
    final memberIds = {
      for (final level in stages) ...level.map((entry) => entry.id),
    };
    if (memberIds.isEmpty && speciesId != null) memberIds.add(speciesId);
    final speciesData = await Future.wait(
      memberIds.map(
        (id) => id == speciesId
            ? Future<Map<String, dynamic>?>.value(species)
            : _orNull(
                _getJson('https://pokeapi.co/api/v2/pokemon-species/$id/'),
              ),
      ),
    );
    final megas = [
      for (final data in speciesData)
        for (final variety
            in (data?['varieties'] as List<dynamic>? ?? const []))
          if (_dig(variety, ['pokemon', 'name']) case final String name
              when name.contains('-mega'))
            EvolutionEntry(
              id: _idFromUrl(_dig(variety, ['pokemon', 'url']) as String),
              name: name,
              condition: 'Megapiedra',
            ),
    ];
    return (stages: stages, megas: megas);
  }

  static Map<String, dynamic>? _firstDetail(Map<String, dynamic> node) {
    final details = node['evolution_details'] as List<dynamic>? ?? const [];
    return details.isEmpty ? null : details.first as Map<String, dynamic>;
  }

  static String? _evolutionCondition(
    Map<String, dynamic>? detail,
    Map<String, String> itemNames,
  ) {
    if (detail == null) return null;
    String itemName(String key) {
      final url = _dig(detail, [key, 'url']) as String?;
      final fallback = _dig(detail, [key, 'name']) as String? ?? 'objeto';
      return itemNames[url] ?? _capitalize(fallback.replaceAll('-', ' '));
    }

    final parts = <String>[
      switch (_dig(detail, ['trigger', 'name'])) {
        'level-up' when detail['min_level'] != null =>
          'Nv. ${detail['min_level']}',
        'level-up' when detail['min_happiness'] != null => 'Amistad',
        'level-up' when detail['min_affection'] != null => 'Afecto',
        'level-up' when detail['known_move'] != null => 'Movimiento',
        'level-up' when detail['location'] != null => 'Lugar especial',
        'level-up' => 'Subir nivel',
        'use-item' => itemName('item'),
        'trade' => 'Intercambio',
        _ => 'Especial',
      },
      if (detail['held_item'] != null) 'con ${itemName('held_item')}',
      if (detail['time_of_day'] == 'day') 'de día',
      if (detail['time_of_day'] == 'night') 'de noche',
    ];
    return parts.join(' ');
  }

  static Future<T?> _orNull<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  /// Idiomas en orden de preferencia: español latino (es-419), español de
  /// España como respaldo y, si no hay traducción, inglés.
  static const _languages = ['es-419', 'es', 'en'];

  static List<Map<String, dynamic>> _entriesFor(
    List<Map<String, dynamic>> entries,
    String language,
  ) => entries
      .where((entry) => _dig(entry, ['language', 'name']) == language)
      .toList();

  static String? _localizedName(List<dynamic>? names) {
    if (names == null) return null;
    final entries = names.cast<Map<String, dynamic>>();
    for (final language in _languages.take(2)) {
      final match = _entriesFor(entries, language).firstOrNull;
      if (match != null) return match['name'] as String?;
    }
    return null;
  }

  static String? _pickGenus(List<dynamic>? genera) {
    if (genera == null) return null;
    final entries = genera.cast<Map<String, dynamic>>();
    for (final language in _languages) {
      final match = _entriesFor(entries, language).firstOrNull;
      if (match != null) return match['genus'] as String?;
    }
    return null;
  }

  static String? _pickFlavorText(List<dynamic>? flavorTexts) {
    if (flavorTexts == null) return null;
    final entries = flavorTexts.cast<Map<String, dynamic>>();
    String clean(Map<String, dynamic> entry) => (entry['flavor_text'] as String)
        .replaceAll('­\n', '')
        .replaceAll(RegExp(r'[\n\f\r­]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // En latino nos quedamos con la entrada más reciente.
    final latin = _entriesFor(entries, 'es-419');
    if (latin.isNotEmpty) return clean(latin.last);

    final spanish = _entriesFor(entries, 'es');
    if (spanish.isNotEmpty) return clean(spanish.first);

    final english = _entriesFor(entries, 'en');
    if (english.isEmpty) return null;
    final fireRed = english.where(
      (entry) => _dig(entry, ['version', 'name']) == 'firered',
    );
    return clean(fireRed.firstOrNull ?? english.first);
  }
}

Object? _dig(Object? json, List<String> path) {
  Object? current = json;
  for (final key in path) {
    if (current is! Map<String, dynamic>) return null;
    current = current[key];
  }
  return current;
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

/// Un Pokémon dentro de la cadena evolutiva o una de sus megaevoluciones.
class EvolutionEntry {
  const EvolutionEntry({required this.id, required this.name, this.condition});

  final int id;
  final String name;

  /// Cómo se llega a esta evolución ("Nv. 16", "Piedra Fuego"...).
  final String? condition;

  String get displayName => _formName(name);

  String get spriteUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
}

int _idFromUrl(String url) => int.parse(
  Uri.parse(url).pathSegments.where((segment) => segment.isNotEmpty).last,
);

/// "charizard-mega-x" -> "Mega Charizard X"; el resto, "mr-mime" -> "Mr mime".
String _formName(String name) {
  final parts = name.split('-');
  final mega = parts.indexOf('mega');
  if (mega > 0) {
    final base = _capitalize(parts.sublist(0, mega).join(' '));
    final suffix = parts.sublist(mega + 1).join(' ').toUpperCase();
    return suffix.isEmpty ? 'Mega $base' : 'Mega $base $suffix';
  }
  return _capitalize(parts.join(' '));
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
    this.spriteUrl,
    this.cryUrls = const [],
    this.abilities = const [],
    this.genus,
    this.description,
    this.speciesId,
    this.evolutions = const [],
    this.megaForms = const [],
  });

  final int id;
  final String name;
  final int height;
  final int weight;

  /// Ilustración oficial (alta resolución).
  final String? imageUrl;

  /// Sprite pixelado, preferiblemente el de Rojo Fuego / Verde Hoja.
  final String? spriteUrl;
  final List<String> types;
  final List<PokemonStat> stats;

  /// Gritos ordenados de más retro a más moderno.
  final List<String> cryUrls;
  final List<String> abilities;
  final String? genus;
  final String? description;

  /// Número de la especie (para formas como las megas, que tienen id 10000+).
  final int? speciesId;

  /// Cadena evolutiva por etapas; cada etapa puede tener varias ramas
  /// (por ejemplo, las evoluciones de Eevee).
  final List<List<EvolutionEntry>> evolutions;

  /// Megaevoluciones de cualquier miembro de la cadena evolutiva.
  final List<EvolutionEntry> megaForms;

  String get displayName => _formName(name);

  /// Texto que lee la voz de la Pokédex.
  String get speechText {
    // Como en el anime: "Bulbasaur, el Pokémon Semilla."
    final buffer = StringBuffer(
      genus == null ? '$displayName. ' : '$displayName, el $genus. ',
    );
    if (types.isNotEmpty) {
      buffer.write('Tipo ${types.map(_typeName).join(' y ')}. ');
    }
    if (weaknesses.isNotEmpty) {
      buffer.write(
        'Es débil contra ${_joinSpanish(weaknesses.map(_typeName))}. ',
      );
    }
    buffer.write(description ?? 'No hay datos registrados sobre este Pokémon.');
    return buffer.toString();
  }

  Pokemon copyWith({
    List<String>? abilities,
    String? genus,
    String? description,
    List<List<EvolutionEntry>>? evolutions,
    List<EvolutionEntry>? megaForms,
  }) {
    return Pokemon(
      id: id,
      name: name,
      height: height,
      weight: weight,
      imageUrl: imageUrl,
      spriteUrl: spriteUrl,
      types: types,
      stats: stats,
      cryUrls: cryUrls,
      abilities: abilities ?? this.abilities,
      genus: genus ?? this.genus,
      description: description ?? this.description,
      speciesId: speciesId,
      evolutions: evolutions ?? this.evolutions,
      megaForms: megaForms ?? this.megaForms,
    );
  }

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'];
    final rawTypes = json['types'] as List<dynamic>;
    final rawStats = json['stats'] as List<dynamic>;
    String? sprite(List<String> path) => _dig(sprites, path) as String?;

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
      imageUrl:
          sprite(['other', 'official-artwork', 'front_default']) ??
          sprite(['front_default']),
      spriteUrl:
          sprite([
            'versions',
            'generation-iii',
            'firered-leafgreen',
            'front_default',
          ]) ??
          sprite(['versions', 'generation-iii', 'emerald', 'front_default']) ??
          sprite(['front_default']),
      types: rawTypes
          .map((entry) => _dig(entry, ['type', 'name']) as String)
          .toList(),
      stats: rawStats
          .map((entry) => PokemonStat.fromJson(entry as Map<String, dynamic>))
          .toList(),
      cryUrls: [
        if (_dig(json, ['cries', 'legacy']) case final String legacy) legacy,
        if (_dig(json, ['cries', 'latest']) case final String latest) latest,
      ],
      speciesId: switch (_dig(json, ['species', 'url'])) {
        final String url => _idFromUrl(url),
        _ => null,
      },
    );
  }
}

class PokemonStat {
  const PokemonStat({required this.name, required this.value});

  final String name;
  final int value;

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      name: _dig(json, ['stat', 'name']) as String,
      value: json['base_stat'] as int,
    );
  }
}

/// Grito de respaldo estilo Game Boy (onda cuadrada con barrido de tono)
/// por si no hay conexión.
const _sampleRate = 22050;

/// Empaqueta muestras (-1..1) como un WAV mono de 16 bits.
Uint8List _encodeWav(List<double> samples) {
  final frameCount = samples.length;
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
  header.setUint32(24, _sampleRate, Endian.little);
  header.setUint32(28, _sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  writeText(36, 'data');
  header.setUint32(40, frameCount * 2, Endian.little);
  for (final (frame, sample) in samples.indexed) {
    header.setInt16(
      44 + frame * 2,
      (sample.clamp(-1.0, 1.0) * 32767).round(),
      Endian.little,
    );
  }
  return bytes;
}

Uint8List _createPokemonCry(int pokemonId) {
  const sampleRate = _sampleRate;
  const noteDuration = 0.095;
  const noteCount = 4;
  final frameCount = (sampleRate * noteDuration * noteCount).round();
  final samples = List.filled(frameCount, 0.0);

  final baseFrequency = 330 + (pokemonId * 13 % 280);
  final intervals = [1.0, 1.26, 1.5, 1.12];
  for (var frame = 0; frame < frameCount; frame++) {
    final time = frame / sampleRate;
    final noteIndex = math.min((time / noteDuration).floor(), noteCount - 1);
    final noteTime = time - noteIndex * noteDuration;
    final sweep = 1 - noteTime * 1.6;
    final frequency = baseFrequency * intervals[noteIndex] * sweep;
    final phase = (noteTime * frequency) % 1;
    final tone = phase < 0.35 ? 1.0 : -1.0;
    final attack = math.min(1.0, noteTime / 0.008);
    final release = math.max(0.0, 1.0 - noteTime / noteDuration);
    samples[frame] = tone * attack * release * 0.22;
  }

  return _encodeWav(samples);
}

/// Gritos en MP3 de Pokémon Showdown (respaldo para navegadores sin OGG,
/// como Safari). Usan el nombre sin guiones: "mr-mime" -> "mrmime".
List<String> _showdownCryUrls(String name) {
  const base = 'https://play.pokemonshowdown.com/audio/cries';
  final full = name.replaceAll(RegExp('[^a-z0-9]'), '');
  final species = name.split('-').first;
  return {'$base/$full.mp3', '$base/$species.mp3'}.toList();
}

/// Mayúsculas sin tildes, como en los juegos clásicos (la fuente pixel no
/// tiene mayúsculas acentuadas).
String _dexText(String value) {
  const plain = {'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U'};
  return value
      .toUpperCase()
      .split('')
      .map((char) => plain[char] ?? char)
      .join();
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
    'attack': 'ATQ',
    'defense': 'DEF',
    'special-attack': 'AT.ESP',
    'special-defense': 'DF.ESP',
    'speed': 'VEL',
  };
  return names[name] ?? name.toUpperCase();
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
  return colors[type] ?? _dexRed;
}
