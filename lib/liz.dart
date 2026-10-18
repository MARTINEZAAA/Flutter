part of 'main.dart';

// Liz: la asistente virtual que presenta la Pokédex, explica cada control
// y registra el nombre del entrenador.

/// Lo que dice Liz al abrir la Pokédex.
enum LizIntro {
  /// Nada (se abre a Liz con su botón).
  none,

  /// Recorrido completo por los controles.
  tour,
}

/// Dibujo que acompaña a una explicación de Liz.
enum _LizArt { liz, pokemon, types, evolution, trainer, pokedex }

class _LizStep {
  const _LizStep(
    this.text, {
    this.target,
    this.art,
    this.asksName = false,
    this.silent = false,
    this.moods,
  });

  final String text;

  /// El gesto de Liz en cada frase del texto, en orden. Si faltan, las
  /// frases restantes conservan el último; sin lista, se deduce de la frase.
  final List<_LizMood>? moods;

  /// Liz no lo lee en voz alta (por ejemplo, mientras habla la Pokédex).
  final bool silent;

  /// Parte de la Pokédex que se ilumina mientras Liz la explica.
  final GlobalKey? target;
  final _LizArt? art;

  /// Este paso espera a que el entrenador escriba su nombre.
  final bool asksName;
}

/// Qué son los Pokémon y la Pokédex, contado por Liz.
List<_LizStep> _lizLessons(String? name) => [
  _LizStep(
    name == null
        ? 'Te cuento qué son los Pokémon.'
        : 'Te cuento qué son los Pokémon, $name.',
    art: _LizArt.liz,
    moods: const [_LizMood.happy],
  ),
  const _LizStep(
    'Los Pokémon son criaturas que viven en todo el mundo: bosques, mares, '
    'cuevas, ciudades... Y hay más de mil especies distintas.',
    art: _LizArt.pokemon,
    moods: [_LizMood.happy, _LizMood.surprised],
  ),
  const _LizStep(
    'Cada Pokémon tiene uno o dos tipos, como fuego, agua o planta, y de '
    'ellos dependen sus debilidades: el agua apaga el fuego, el fuego quema '
    'la planta y la planta absorbe el agua.',
    art: _LizArt.types,
    moods: [_LizMood.thinking],
  ),
  const _LizStep(
    'Muchos Pokémon evolucionan: al subir de nivel, con una piedra especial o '
    'de otras formas, se transforman en un Pokémon más fuerte.',
    art: _LizArt.evolution,
    moods: [_LizMood.excited],
  ),
  const _LizStep(
    'Los entrenadores viajan para conocerlos, hacer equipo con ellos y '
    'entrenar juntos. Igual que tú.',
    art: _LizArt.trainer,
    moods: [_LizMood.happy, _LizMood.shy],
  ),
  const _LizStep(
    'Y la Pokédex es una enciclopedia electrónica: guarda el número, los '
    'tipos, el tamaño, las habilidades, las estadísticas y las evoluciones '
    'de cada Pokémon.',
    art: _LizArt.pokedex,
    moods: [_LizMood.proud],
  ),
];

// -------------------------------------------------------------- Voz

/// Voz de la Pokédex, al estilo de la del anime: la voz de hombre latina del
/// sistema, grave, ágil y pareja, precedida de un bip electrónico. Nunca
/// usa a Pablo (España). Liz no usa voz: habla con sonidos de 8 bits.
class DexVoice {
  FlutterTts? _tts;
  bool _configured = false;
  Map<String, String>? _voice;
  AudioPlayer? _chirpPlayer;

  /// Bip-bip-bip ascendente con el que la Pokédex empieza a hablar.
  static final _chirp = _createChirp();

  Future<FlutterTts> _ensureTts() async {
    final tts = _tts ??= FlutterTts();
    if (!_configured) {
      await tts.awaitSpeakCompletion(true);
      _configured = true;
    }
    return tts;
  }

  Future<void> speak(String text) async {
    final tts = await _ensureTts();
    // En web las voces cargan tarde, así que seguimos buscando hasta
    // encontrar una y fijamos el idioma cada vez.
    final voice = _voice ??= _best(await _allVoices(tts));
    // Como la Pokédex del anime: grave, ágil y con poca entonación, para
    // que suene a máquina. Una voz de mujer se baja todavía más.
    final male = voice == null || _isMale(voice);
    await tts.setSpeechRate(kIsWeb ? 1.25 : 0.62);
    await tts.setPitch(male ? 0.72 : 0.6);
    if (voice != null) {
      await tts.setLanguage(voice['locale']!);
      await tts.setVoice({'name': voice['name']!, 'locale': voice['locale']!});
    } else {
      await tts.setLanguage(kIsWeb ? 'es' : 'es-MX');
    }
    await _playChirp();
    await tts.speak(text);
  }

  Future<void> _playChirp() async {
    try {
      final player = _chirpPlayer ??= AudioPlayer();
      await player.play(BytesSource(_chirp), volume: 0.4);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (error) {
      debugPrint('No se pudo reproducir el bip de la Pokédex: $error');
    }
  }

  static Uint8List _createChirp() {
    const notes = [1320, 1760, 2093];
    const noteDuration = 0.06;
    const gap = 0.02;
    final samples = <double>[];
    for (final frequency in notes) {
      final frames = (_sampleRate * noteDuration).round();
      for (var frame = 0; frame < frames; frame++) {
        final time = frame / _sampleRate;
        final tone = (time * frequency) % 1 < 0.5 ? 1.0 : -1.0;
        final release = 1 - time / noteDuration;
        samples.add(tone * release * 0.25);
      }
      samples.addAll(List.filled((_sampleRate * gap).round(), 0.0));
    }
    return _encodeWav(samples);
  }

  Future<void> stop() async {
    await _chirpPlayer?.stop();
    await _tts?.stop();
  }

  static Future<List<Map<String, String>>> _allVoices(FlutterTts tts) async {
    try {
      final raw = await tts.getVoices as List<dynamic>? ?? const [];
      return [
        for (final voice in raw.whereType<Map<dynamic, dynamic>>())
          {
            for (final key in ['name', 'locale', 'gender'])
              if (voice[key] != null) key: '${voice[key]}',
          },
      ].where((v) => v['name'] != null && v['locale'] != null).toList();
    } catch (_) {
      return const [];
    }
  }

  static String _region(Map<String, String> voice) =>
      voice['locale']!.replaceAll('_', '-').toLowerCase();

  static const _latinRegions = [
    'es-mx',
    'es-419',
    'es-us',
    'es-co',
    'es-ar',
    'es-cl',
  ];

  static final _pablo = RegExp(r'\bpablo\b', caseSensitive: false);

  static final _femaleNames = RegExp(
    r'\b(female|mujer|sabina|paulina|dalia|helena|laura|monica|mónica|'
    'elvira|paloma|camila|valentina|renata|salome|salomé|elena|marisol|'
    'ximena|catalina|larissa|angelica|angélica|soledad|francisca|isabela|'
    'esperanza|irene|nuria|estrella|beatriz|abril|triana|vera|lupe|marta|'
    r'carmen|lucia|lucía|andrea|google)\b',
    caseSensitive: false,
  );

  static final _maleNames = RegExp(
    r'\b(male|raul|raúl|jorge|alvaro|álvaro|alonso|gonzalo|tomas|'
    'tomás|lorenzo|mateo|emilio|gerardo|andres|andrés|federico|diego|juan|'
    'carlos|enrique|sergio|luciano|mauricio|rodrigo|nicolas|nicolás|'
    r'sebastian|sebastián|marcelo|eduardo|dario|darío|saul|saúl|jose|josé)\b',
    caseSensitive: false,
  );

  static final _naturalVoice = RegExp(
    'natural|neural|online|premium|enhanced|mejorada|wavenet',
    caseSensitive: false,
  );

  static bool _isFemale(Map<String, String> voice) =>
      voice['gender']?.toLowerCase() == 'female' ||
      _femaleNames.hasMatch(voice['name']!);

  static bool _isMale(Map<String, String> voice) =>
      voice['gender']?.toLowerCase() == 'male' ||
      _maleNames.hasMatch(voice['name']!);

  /// La voz más parecida a la del doblaje: de hombre, latina (México
  /// primero) y, a igual acento, natural. Nunca Pablo.
  static Map<String, String>? _best(List<Map<String, String>> voices) {
    int score(Map<String, String> voice) {
      final latinIndex = _latinRegions.indexOf(_region(voice));
      return (_isMale(voice) ? 100 : 0) +
          (_isFemale(voice) ? -100 : 0) +
          (_naturalVoice.hasMatch(voice['name']!) ? 8 : 0) +
          (latinIndex >= 0 ? 20 + _latinRegions.length - latinIndex : 0);
    }

    final options =
        voices
            .where((v) => _region(v).startsWith('es'))
            .where((v) => !_pablo.hasMatch(v['name']!))
            .toList()
          ..sort((a, b) => score(b).compareTo(score(a)));
    return options.firstOrNull;
  }
}

// -------------------------------------------------------------- Bips

/// La "voz" de Liz: bips de 8 bits suaves mientras escribe, como los
/// diálogos de los juegos clásicos. Cada letra tiene su tono.
class _LizBlips {
  /// Un reproductor por tono, con su bip ya cargado: así aguanta bips muy
  /// seguidos sin crear sonidos nuevos.
  final _players = <int, Future<AudioPlayer>>{};

  /// Escala de tonos (Hz) entre los que salta la voz: graves para que no
  /// canse.
  static const _tones = [523, 587, 659, 698, 784];

  Future<void> play(String letter) async {
    try {
      final tone = _tones[letter.toLowerCase().codeUnitAt(0) % _tones.length];
      final player = await (_players[tone] ??= _load(tone));
      // stop() vuelve al principio: un bip nuevo corta el anterior.
      await player.stop();
      await player.resume();
    } catch (error) {
      debugPrint('No se pudo reproducir el bip: $error');
    }
  }

  static Future<AudioPlayer> _load(int tone) async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(0.22);
    await player.setSource(BytesSource(_createBlip(tone)));
    return player;
  }

  /// Onda cuadrada corta (20 ms) con un pequeño barrido hacia abajo.
  static Uint8List _createBlip(int frequency) {
    const duration = 0.02;
    final frameCount = (_sampleRate * duration).round();
    var phase = 0.0;
    return _encodeWav([
      for (var frame = 0; frame < frameCount; frame++)
        () {
          final time = frame / _sampleRate;
          phase = (phase + frequency * (1 - time * 2) / _sampleRate) % 1;
          final attack = math.min(1.0, time / 0.004);
          final release = math.max(0.0, 1 - time / duration);
          // Ciclo al 50 %: menos armónicos agudos, suena más redondo.
          return (phase < 0.5 ? 1.0 : -1.0) * attack * release * 0.5;
        }(),
    ]);
  }

  void dispose() {
    for (final player in _players.values) {
      unawaited(player.then((player) => player.dispose()));
    }
  }
}

// -------------------------------------------------------------- Entrenador

/// Guarda el nombre del entrenador entre sesiones.
class TrainerStore {
  static const _key = 'trainer_name';

  static Future<String?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (error) {
      debugPrint('No se pudo leer el entrenador: $error');
      return null;
    }
  }

  static Future<void> save(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, name);
    } catch (error) {
      debugPrint('No se pudo guardar el entrenador: $error');
    }
  }
}

/// Muestra la presentación (la Pokédex abriéndose sobre la mesa) y luego la
/// Pokédex, donde Liz da la guía y registra al entrenador.
class TrainerGate extends StatefulWidget {
  const TrainerGate({super.key});

  @override
  State<TrainerGate> createState() => _TrainerGateState();
}

class _TrainerGateState extends State<TrainerGate> {
  bool _loading = true;
  bool _opened = false;
  String? _name;

  @override
  void initState() {
    super.initState();
    TrainerStore.load().then((name) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _name = name;
      });
    });
  }

  void _onNamed(String name) {
    unawaited(TrainerStore.save(name));
    setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    final Widget page;
    if (!_opened) {
      page = DexIntroPage(
        key: const ValueKey('intro'),
        onDone: () => setState(() => _opened = true),
      );
    } else if (_loading) {
      page = const Scaffold(key: ValueKey('loading'));
    } else {
      page = PokemonPage(
        key: const ValueKey('dex'),
        trainerName: _name,
        lizIntro: LizIntro.tour,
        onTrainerNamed: _onNamed,
      );
    }
    // La Pokédex de verdad aparece fundiéndose con la de la presentación.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: page,
    );
  }
}

// -------------------------------------------------------------- Recorrido

/// Oscurece la Pokédex, ilumina el control que explica Liz y muestra su
/// cuadro de diálogo.
class _LizOverlay extends StatefulWidget {
  const _LizOverlay({
    super.key,
    required this.steps,
    required this.onClose,
    this.onLetter,
    this.onName,
    this.initialName,
    this.nameOptional = false,
    this.actions,
  });

  final List<_LizStep> steps;
  final VoidCallback onClose;

  /// Recibe cada letra que dice Liz, para su bip de 8 bits.
  final ValueChanged<String>? onLetter;

  /// Recibe el nombre escrito en un paso que lo pregunta.
  final ValueChanged<String>? onName;
  final String? initialName;

  /// El entrenador puede cancelar la pregunta del nombre.
  final bool nameOptional;

  /// Botones del menú; si hay, el último paso no se cierra al tocarlo.
  final List<Widget>? actions;

  @override
  State<_LizOverlay> createState() => _LizOverlayState();
}

class _LizOverlayState extends State<_LizOverlay> {
  int _index = 0;
  Rect? _target;

  /// Gestos de Liz, compartidos por su retrato y su holograma.
  final _expression = _LizExpression();

  @override
  void initState() {
    super.initState();
    _expression.say(widget.steps.first);
    WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(0));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _expression.still = MediaQuery.disableAnimationsOf(context);
    // Si cambia el tamaño de la ventana, volvemos a medir el control.
    MediaQuery.sizeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _expression.dispose();
    super.dispose();
  }

  Future<void> _goTo(int index) async {
    if (!mounted) return;
    final step = widget.steps[index];
    setState(() {
      _index = index;
      if (step.target == null) _target = null;
    });
    _expression.say(step);

    final targetContext = step.target?.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    if (mounted && _index == index) _measure();
  }

  void _measure() {
    if (!mounted) return;
    final target = widget.steps[_index].target?.currentContext;
    final box = target?.findRenderObject() as RenderBox?;
    final overlay = context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null || !box.hasSize || !box.attached) {
      return;
    }
    final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    if (rect != _target) setState(() => _target = rect);
  }

  bool get _isLast => _index == widget.steps.length - 1;

  void _next() {
    if (_isLast) {
      widget.onClose();
    } else {
      unawaited(_goTo(_index + 1));
    }
  }

  /// Salta la guía, pero no la pregunta del nombre: va directo a ella.
  void _skip() {
    final ask = widget.onName == null
        ? -1
        : widget.steps.indexWhere((step) => step.asksName, _index + 1);
    if (ask == -1) return widget.onClose();
    unawaited(_goTo(ask));
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final total = widget.steps.length;
    final menu = widget.actions != null;
    final asksName = step.asksName && widget.onName != null;
    final hole = _target?.inflate(8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final dialogOnTop =
            hole != null && hole.center.dy > constraints.maxHeight / 2;
        final dialog = _LizDialog(
          text: step.text,
          expression: _expression,
          // Mientras habla la Pokédex, Liz no hace ruido.
          onLetter: step.silent ? null : widget.onLetter,
          onNext: asksName || menu && _isLast ? null : _next,
          input: asksName
              ? _NameField(
                  initialName: widget.initialName,
                  onSubmitted: widget.onName!,
                )
              : null,
          footer: asksName
              ? [
                  if (widget.nameOptional)
                    _BlackPill(
                      label: 'CANCELAR',
                      tooltip: 'Dejar el nombre como está',
                      onPressed: widget.onClose,
                    ),
                ]
              : widget.actions ??
                    [
                      if (total > 1)
                        Text(
                          '${_index + 1}/$total',
                          style: _pixel(7, color: _outline, height: 1),
                        ),
                      if (!_isLast)
                        _BlackPill(
                          label: 'SALTAR',
                          tooltip: 'Saltar la guía',
                          onPressed: _skip,
                        ),
                    ],
        );

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: menu ? widget.onClose : null,
                child: hole == null
                    ? const CustomPaint(painter: _SpotlightPainter(null))
                    // El foco se desliza de un control al siguiente.
                    : TweenAnimationBuilder<Rect?>(
                        tween: RectTween(end: hole),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        builder: (context, rect, _) =>
                            CustomPaint(painter: _SpotlightPainter(rect)),
                      ),
              ),
            ),
            if (hole == null && step.art != null)
              Positioned.fill(
                bottom: 240,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _LizArtwork(
                        key: ValueKey(step.art),
                        art: step.art!,
                        expression: _expression,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              top: dialogOnTop ? 16 : null,
              bottom: dialogOnTop ? null : 16,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: dialog,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0xB3000000);
    final hole = this.hole;
    if (hole == null) {
      canvas.drawRect(Offset.zero & size, dim);
      return;
    }
    final spot = RRect.fromRectAndRadius(hole, const Radius.circular(10));
    canvas
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addRRect(spot),
        dim,
      )
      ..drawRRect(
        spot,
        Paint()
          ..color = _lightYellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) => oldDelegate.hole != hole;
}

// -------------------------------------------------------------- Diálogo

/// Cuadro de texto al estilo de los juegos: el texto aparece letra a letra
/// y un toque lo completa o pasa al siguiente.
class _LizDialog extends StatefulWidget {
  const _LizDialog({
    required this.text,
    this.expression,
    this.onLetter,
    this.onNext,
    this.input,
    this.footer,
  });

  final String text;

  /// Recibe cada letra en cuanto se escribe.
  final ValueChanged<String>? onLetter;

  /// Gestos de Liz, que siguen la frase que se va escribiendo.
  final _LizExpression? expression;
  final VoidCallback? onNext;
  final Widget? input;
  final List<Widget>? footer;

  @override
  State<_LizDialog> createState() => _LizDialogState();
}

class _LizDialogState extends State<_LizDialog> {
  Timer? _timer;
  Timer? _letterTimer;
  int _shown = 0;
  bool _started = false;

  /// Sin animaciones (accesibilidad), el texto aparece de golpe.
  bool _instant = false;

  bool get _typing => _shown < widget.text.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _instant = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      _type();
    }
  }

  @override
  void didUpdateWidget(_LizDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _type();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _letterTimer?.cancel();
    super.dispose();
  }

  void _type() {
    _timer?.cancel();
    _letterTimer?.cancel();
    _letters = 0;
    if (_instant) {
      _shown = widget.text.length;
      _babble();
      return;
    }
    _shown = 0;
    widget.expression?.typed(0, typing: true);
    _timer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _shown++);
      widget.expression?.typed(_shown, typing: _typing);
      _sayLetter(_shown - 1);
      if (!_typing) timer.cancel();
    });
  }

  static final _letter = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Suena una de cada [_blipEvery] letras.
  static const _blipEvery = 1;
  int _letters = 0;

  /// Bip de la letra en [index]; los espacios y signos no suenan.
  void _sayLetter(int index) {
    final text = widget.text;
    if (index < 0 || index >= text.length) return;
    if (!_letter.hasMatch(text[index])) return;
    if (_letters++ % _blipEvery == 0) widget.onLetter?.call(text[index]);
  }

  /// Con el texto ya completo (sin animaciones), los bips suenan igual, uno
  /// por letra al ritmo con que se escribiría.
  void _babble() {
    if (widget.onLetter == null) return;
    var next = 0;
    _letterTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted || next >= widget.text.length) return timer.cancel();
      // Los gestos avanzan con lo que va diciendo.
      widget.expression?.typed(next, typing: false);
      _sayLetter(next++);
    });
  }

  void _onTap() {
    if (_typing) {
      _timer?.cancel();
      setState(() => _shown = widget.text.length);
      widget.expression?.typed(_shown, typing: false);
    } else {
      widget.onNext?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _pixel(10, color: _outline, height: 1.8);
    final footer = widget.footer;
    return Tooltip(
      message: widget.onNext == null ? '' : 'Toca para continuar',
      excludeFromSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _outline, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x88000000), offset: Offset(0, 4)),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: _keyBlue, width: 2.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExpressiveLiz(
                  expression: widget.expression,
                  size: 68,
                  hop: _typing && (_shown ~/ 6).isOdd,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('LIZ', style: _pixel(8, color: _dexRed, height: 1)),
                      const SizedBox(height: 8),
                      // Lo que falta por escribir va invisible: así el
                      // cuadro tiene su alto final desde la primera letra.
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: widget.text.substring(0, _shown)),
                            TextSpan(
                              text: widget.text.substring(_shown),
                              style: const TextStyle(color: Colors.transparent),
                            ),
                          ],
                        ),
                        style: style,
                      ),
                      if (widget.input != null) ...[
                        const SizedBox(height: 10),
                        widget.input!,
                      ],
                      if (footer != null && footer.isNotEmpty ||
                          widget.onNext != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: footer ?? const [],
                              ),
                            ),
                            if (widget.onNext != null)
                              Opacity(
                                opacity: _typing ? 0 : 1,
                                child: _Blink(
                                  child: Text(
                                    '▼',
                                    style: _pixel(10, color: _dexRed),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla verde donde el entrenador escribe su nombre para registrarlo.
class _NameField extends StatefulWidget {
  const _NameField({required this.onSubmitted, this.initialName});

  final ValueChanged<String> onSubmitted;
  final String? initialName;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final _controller = TextEditingController(text: widget.initialName);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'ESCRIBE TU NOMBRE');
      return;
    }
    FocusScope.of(context).unfocus();
    widget.onSubmitted(name);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _greenScreen,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: _outline, width: 3),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 12,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              cursorColor: _outline,
              style: _pixel(10, color: _outline, height: 1.2),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                counterText: '',
                hintText: _error ?? 'TU NOMBRE',
                hintStyle: _pixel(
                  8,
                  color: _error != null ? _dexRedDark : const Color(0xFF14592C),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _WhiteButton(
          label: 'OK',
          tooltip: 'Confirmar nombre',
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Parpadeo retro; se queda fijo si el sistema pide reducir animaciones.
class _Blink extends StatefulWidget {
  const _Blink({required this.child});

  final Widget child;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Opacity(opacity: _controller.value < 0.6 ? 1 : 0, child: child),
      child: widget.child,
    );
  }
}

// -------------------------------------------------------------- Liz

/// Retrato de Liz. Mientras habla se mueve un poco y, si recibe un
/// [face], se le dibujan encima los ojos, la boca y el rubor de ese gesto.
class _LizAvatar extends StatelessWidget {
  const _LizAvatar({required this.size, this.hop = false, this.face});

  static const asset = 'assets/images/liz.png';
  static const _browLeftAsset = 'assets/images/liz_brow_left.png';
  static const _browRightAsset = 'assets/images/liz_brow_right.png';

  final double size;
  final bool hop;
  final _LizFace? face;

  @override
  Widget build(BuildContext context) {
    final face = this.face;
    Widget layer(String asset) => Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => SizedBox.square(
        dimension: size,
        child: asset == _LizAvatar.asset
            ? Icon(Icons.face_3, color: _lensBlue, size: size * 0.8)
            : null,
      ),
    );
    // Cada ceja es su propia imagen (la original), así se mueve sin cambiar
    // de aspecto: sube o baja y se inclina por el extremo de dentro.
    Widget brow(String asset, double raise, Alignment pivot, double turn) =>
        Transform.translate(
          offset: Offset(0, -6 * raise * size / 595),
          child: Transform.rotate(
            angle: turn * (face?.browTilt ?? 0),
            alignment: pivot,
            child: layer(asset),
          ),
        );
    // La imagen no tiene fondo: solo Liz, con su gorra y su ropa de
    // entrenadora.
    Widget portrait = Stack(
      children: [
        layer(asset),
        brow(
          _browLeftAsset,
          face?.browLeft ?? 0,
          const Alignment(-0.16, -0.405),
          -0.14,
        ),
        brow(
          _browRightAsset,
          face?.browRight ?? 0,
          const Alignment(0.17, -0.405),
          0.14,
        ),
      ],
    );
    if (face != null) {
      portrait = Transform.rotate(
        angle: face.tilt,
        alignment: Alignment.bottomCenter,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            portrait,
            Positioned.fill(child: CustomPaint(painter: _LizFacePainter(face))),
            if (face.emote case final emote?)
              Positioned(
                top: size * 0.02,
                right: size * 0.04,
                child: Text(
                  emote,
                  style: _pixel(size * 0.14, color: _keyBlue, height: 1),
                ),
              ),
          ],
        ),
      );
    }
    return Transform.translate(
      // Un leve movimiento al hablar, no saltitos.
      offset: Offset(0, hop ? -size * 0.012 : 0),
      child: portrait,
    );
  }
}

/// Retrato de Liz que sigue los gestos de [expression] y pasa de uno a
/// otro con suavidad. Sin [expression] es el retrato de siempre.
class _ExpressiveLiz extends StatelessWidget {
  const _ExpressiveLiz({
    required this.expression,
    required this.size,
    this.hop = false,
  });

  final _LizExpression? expression;
  final double size;
  final bool hop;

  @override
  Widget build(BuildContext context) {
    final expression = this.expression;
    if (expression == null) return _LizAvatar(size: size, hop: hop);
    return _Breathing(
      child: ListenableBuilder(
        listenable: expression,
        builder: (context, _) => TweenAnimationBuilder<_LizFace>(
          tween: _LizFaceTween(end: expression.face),
          duration: const Duration(milliseconds: 90),
          builder: (context, face, _) =>
              _LizAvatar(size: size, hop: hop, face: face),
        ),
      ),
    );
  }
}

/// Respiración muy suave: el pecho y los hombros suben y bajan, para que Liz
/// no parezca una foto cuando está quieta. Se queda fija si el sistema pide
/// reducir animaciones.
class _Breathing extends StatefulWidget {
  const _Breathing({required this.child});

  final Widget child;

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final breath = (1 - math.cos(2 * math.pi * _controller.value)) / 2;
        return Transform.scale(
          scaleX: 1 + 0.004 * breath,
          scaleY: 1 + 0.012 * breath,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Un gesto de Liz. Los valores van en píxeles de la imagen original
/// (595 × 595) o de 0 a 1, y se interpolan para animar el cambio.
@immutable
class _LizFace {
  const _LizFace({
    this.lidLeft = 0,
    this.lidRight = 0,
    this.happyEyes = 0,
    this.mouthOpen = 0,
    this.mouthWidth = 1,
    this.smile = 1,
    this.mouthShift = 0,
    this.blush = 0,
    this.tilt = 0,
    this.browLeft = 0,
    this.browRight = 0,
    this.browTilt = 0,
    this.emote,
  });

  /// Cuánto se cierra cada ojo: 0 abierto, 1 cerrado.
  final double lidLeft;
  final double lidRight;

  /// Los ojos cerrados se dibujan como arcos felices (^^) en vez de rayas.
  final double happyEyes;

  /// Apertura de la boca (0 cerrada, 1 muy abierta) y su anchura relativa.
  final double mouthOpen;
  final double mouthWidth;

  /// Curva de la boca: 1 sonrisa, 0 recta, negativo hacia abajo.
  final double smile;

  /// Desplazamiento lateral de la boca (media sonrisa pensativa).
  final double mouthShift;
  final double blush;

  /// Inclinación de la cabeza, en radianes.
  final double tilt;

  /// Cuánto sube cada ceja (negativo: baja), de -1 a 1. Izquierda y derecha
  /// según se ve la imagen.
  final double browLeft;
  final double browRight;

  /// Inclinación de las cejas: positivo sube el extremo de dentro
  /// (preocupación), negativo lo baja (concentración).
  final double browTilt;

  /// Símbolo que aparece junto a la cabeza (¡!, ?...).
  final String? emote;

  _LizFace copyWith({
    double? lidLeft,
    double? lidRight,
    double? mouthOpen,
    double? mouthWidth,
    double? tilt,
  }) => _LizFace(
    lidLeft: lidLeft ?? this.lidLeft,
    lidRight: lidRight ?? this.lidRight,
    happyEyes: happyEyes,
    mouthOpen: mouthOpen ?? this.mouthOpen,
    mouthWidth: mouthWidth ?? this.mouthWidth,
    smile: smile,
    mouthShift: mouthShift,
    blush: blush,
    tilt: tilt ?? this.tilt,
    browLeft: browLeft,
    browRight: browRight,
    browTilt: browTilt,
    emote: emote,
  );

  static _LizFace lerp(_LizFace a, _LizFace b, double t) {
    double mix(double x, double y) => x + (y - x) * t;
    return _LizFace(
      lidLeft: mix(a.lidLeft, b.lidLeft),
      lidRight: mix(a.lidRight, b.lidRight),
      happyEyes: mix(a.happyEyes, b.happyEyes),
      mouthOpen: mix(a.mouthOpen, b.mouthOpen),
      mouthWidth: mix(a.mouthWidth, b.mouthWidth),
      smile: mix(a.smile, b.smile),
      mouthShift: mix(a.mouthShift, b.mouthShift),
      blush: mix(a.blush, b.blush),
      tilt: mix(a.tilt, b.tilt),
      browLeft: mix(a.browLeft, b.browLeft),
      browRight: mix(a.browRight, b.browRight),
      browTilt: mix(a.browTilt, b.browTilt),
      emote: t < 0.5 ? a.emote : b.emote,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _LizFace &&
      other.lidLeft == lidLeft &&
      other.lidRight == lidRight &&
      other.happyEyes == happyEyes &&
      other.mouthOpen == mouthOpen &&
      other.mouthWidth == mouthWidth &&
      other.smile == smile &&
      other.mouthShift == mouthShift &&
      other.blush == blush &&
      other.tilt == tilt &&
      other.browLeft == browLeft &&
      other.browRight == browRight &&
      other.browTilt == browTilt &&
      other.emote == emote;

  @override
  int get hashCode => Object.hash(
    lidLeft,
    lidRight,
    happyEyes,
    mouthOpen,
    mouthWidth,
    smile,
    mouthShift,
    blush,
    tilt,
    browLeft,
    browRight,
    browTilt,
    emote,
  );
}

class _LizFaceTween extends Tween<_LizFace> {
  _LizFaceTween({super.end});

  @override
  _LizFace lerp(double t) => _LizFace.lerp(begin ?? end!, end!, t);
}

/// Estados de ánimo de Liz. Tiene unos 20 años: gestos naturales y
/// contenidos (sonrisas, miradas, cejas, guiños) más que de caricatura.
enum _LizMood {
  happy(_LizFace()),

  /// Sonrisa amplia con la boca entreabierta, mirada viva y cejas arriba.
  excited(
    _LizFace(
      lidLeft: 0.15,
      lidRight: 0.15,
      mouthOpen: 0.3,
      mouthWidth: 1.1,
      smile: 1.2,
      blush: 0.25,
      browLeft: 0.6,
      browRight: 0.6,
      emote: '!',
    ),
  ),

  /// Una ceja arriba, cabeza un poco ladeada y labios de lado.
  curious(
    _LizFace(
      mouthWidth: 0.65,
      smile: 0.2,
      mouthShift: 5,
      tilt: 0.035,
      browRight: 0.9,
      browLeft: -0.1,
      emote: '?',
    ),
  ),

  /// Mirada algo entornada, cejas juntas y media sonrisa ladeada.
  thinking(
    _LizFace(
      lidLeft: 0.3,
      lidRight: 0.3,
      mouthWidth: 0.7,
      smile: 0.1,
      mouthShift: -6,
      tilt: -0.025,
      browLeft: 0.3,
      browRight: -0.2,
      browTilt: -0.5,
    ),
  ),
  surprised(
    _LizFace(
      mouthOpen: 0.4,
      mouthWidth: 0.6,
      smile: 0.2,
      browLeft: 1,
      browRight: 1,
      browTilt: 0.2,
    ),
  ),

  /// Guiño cómplice: la ceja del ojo cerrado baja un poco.
  wink(
    _LizFace(
      lidRight: 1,
      mouthWidth: 1.05,
      smile: 1.2,
      mouthShift: 3,
      blush: 0.1,
      tilt: 0.025,
      browLeft: 0.3,
      browRight: -0.5,
    ),
  ),

  /// Segura de sí misma: párpados relajados, sonrisa de lado y una ceja
  /// apenas arriba.
  proud(
    _LizFace(
      lidLeft: 0.25,
      lidRight: 0.25,
      mouthWidth: 1.05,
      smile: 1.15,
      mouthShift: 4,
      tilt: 0.02,
      browLeft: 0.35,
      browTilt: -0.2,
    ),
  ),

  /// Sonrisa tímida, algo de rubor y las cejas suavemente arqueadas.
  shy(
    _LizFace(
      lidLeft: 0.35,
      lidRight: 0.35,
      mouthWidth: 0.75,
      smile: 0.8,
      blush: 0.5,
      tilt: -0.025,
      browLeft: 0.1,
      browRight: 0.1,
      browTilt: 0.5,
    ),
  ),

  /// Alegre: sonrisa grande que achina un poco los ojos.
  cheerful(
    _LizFace(
      lidLeft: 0.35,
      lidRight: 0.35,
      mouthWidth: 1.1,
      smile: 1.3,
      blush: 0.2,
      browLeft: 0.4,
      browRight: 0.4,
    ),
  ),

  /// Cejas levantadas por dentro: la preocupación se nota sobre todo ahí.
  worried(
    _LizFace(
      lidLeft: 0.2,
      lidRight: 0.2,
      mouthWidth: 0.6,
      smile: -0.4,
      tilt: -0.02,
      browLeft: 0.2,
      browRight: 0.2,
      browTilt: 1,
    ),
  );

  const _LizMood(this.face);

  final _LizFace face;
}

/// Mueve el rostro de Liz: cada frase que explica trae el gesto que le
/// corresponde, la boca se mueve mientras habla y parpadea de vez en cuando.
class _LizExpression extends ChangeNotifier {
  final _random = math.Random();

  var _mood = _LizMood.happy;
  var _text = '';

  /// Dónde empieza cada frase del texto y el gesto que le toca.
  var _starts = const [0];
  var _moods = const [_LizMood.happy];

  /// Letras dichas (escritas en el cuadro de texto).
  var _shown = 0;

  var _typing = false;
  var _still = false;
  var _blinking = false;
  var _wasTalking = false;
  var _flapOpen = 0.0;
  var _flapWidth = 1.0;
  var _notifyQueued = false;
  var _disposed = false;

  Timer? _mouthTimer;
  Timer? _blinkTimer;

  _LizFace get face {
    var face = _mood.face;
    if (_typing && !_still) {
      face = face.copyWith(
        mouthOpen: math.max(face.mouthOpen * 0.5, _flapOpen),
        mouthWidth: face.mouthWidth * _flapWidth,
      );
    }
    if (_blinking && face.happyEyes < 0.5) {
      face = face.copyWith(lidLeft: 1, lidRight: 1);
    }
    return face;
  }

  /// Sin animaciones (accesibilidad) no mueve la boca ni parpadea, pero
  /// sigue poniendo el gesto de cada frase.
  set still(bool value) {
    if (_still == value) return;
    _still = value;
    _update();
  }

  /// Empieza a explicar el texto de [step].
  void say(_LizStep step) {
    _text = step.text;
    final sentences = <String>[];
    final starts = [0];
    for (final end in RegExp(r'[.!?]+\s+').allMatches(_text)) {
      sentences.add(_text.substring(starts.last, end.end));
      starts.add(end.end);
    }
    sentences.add(_text.substring(starts.last));
    final given = step.moods ?? const [];
    _starts = starts;
    _moods = [
      for (var i = 0; i < sentences.length; i++)
        given.isEmpty
            ? _moodFor(sentences[i])
            : given[math.min(i, given.length - 1)],
    ];
    _shown = 0;
    _syncSentence();
  }

  /// Por qué letra va Liz y si sigue hablando (escribiendo).
  void typed(int shown, {required bool typing}) {
    _shown = shown;
    if (_typing != typing) {
      _typing = typing;
      _update();
    }
    _syncSentence();
  }

  /// Gesto para una frase sin gesto indicado.
  static _LizMood _moodFor(String sentence) {
    final text = sentence.toLowerCase();
    if (RegExp(r'\bno (encontré|pude|hay)\b').hasMatch(text)) {
      return _LizMood.worried;
    }
    if (text.contains('?')) return _LizMood.curious;
    if (text.contains('!')) return _LizMood.excited;
    return _LizMood.happy;
  }

  void _syncSentence() {
    if (_disposed) return;
    var sentence = 0;
    while (sentence + 1 < _starts.length && _starts[sentence + 1] <= _shown) {
      sentence++;
    }
    final mood = _moods[sentence];
    if (mood != _mood) {
      _mood = mood;
      _notify();
    }
  }

  /// Arranca o para los temporizadores según si Liz está hablando.
  void _update() {
    if (_disposed) return;
    if (_still) {
      _blinkTimer?.cancel();
      _blinkTimer = null;
    } else if (_blinkTimer == null) {
      _scheduleBlink();
    }
    final talking = _typing && !_still;
    if (talking != _wasTalking) {
      _wasTalking = talking;
      _mouthTimer?.cancel();
      _mouthTimer = null;
      _flapOpen = 0;
      _flapWidth = 1;
      if (talking) {
        _mouthTimer = Timer.periodic(
          const Duration(milliseconds: 120),
          (_) => _flap(),
        );
      }
    }
    _notify();
  }

  void _flap() {
    // Al hablar abre poco la boca, como al conversar.
    const openings = [0.0, 0.1, 0.18, 0.26, 0.34];
    _flapOpen = openings[_random.nextInt(openings.length)];
    _flapWidth = 0.8 + _random.nextDouble() * 0.25;
    _notify();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2200 + _random.nextInt(2800)),
      () {
        _blinking = true;
        _notify();
        _blinkTimer = Timer(const Duration(milliseconds: 140), () {
          _blinking = false;
          _scheduleBlink();
          _notify();
        });
      },
    );
  }

  /// Avisa en una microtarea: los cambios pueden llegar mientras se
  /// construye el diálogo, y el holograma no se puede marcar en ese momento.
  void _notify() {
    if (_notifyQueued || _disposed) return;
    _notifyQueued = true;
    scheduleMicrotask(() {
      _notifyQueued = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _mouthTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }
}

/// Dibuja el gesto sobre la imagen de Liz: párpados, boca y rubor (las
/// cejas son imágenes aparte). Los párpados y el rubor van en cuadritos del
/// tamaño de los píxeles de la imagen. Las medidas son de la imagen de
/// 595 × 595.
class _LizFacePainter extends CustomPainter {
  const _LizFacePainter(this.face);

  final _LizFace face;

  /// Lado de un píxel de la imagen.
  static const _px = 6.2;

  static const _skin = Color(0xFFFCD8C4);

  static const _lash = Color(0xFF15152B);
  static const _lip = Color(0xFF8A2E3B);
  static const _leftEye = Rect.fromLTRB(218, 199, 268, 251);
  static const _rightEye = Rect.fromLTRB(332, 199, 382, 251);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 595;
    canvas
      ..save()
      ..translate(
        (size.width - 595 * scale) / 2,
        (size.height - 595 * scale) / 2,
      )
      ..scale(scale);
    _eye(canvas, _leftEye, face.lidLeft);
    _eye(canvas, _rightEye, face.lidRight);
    _blush(canvas);
    _mouth(canvas);
    canvas.restore();
  }

  /// Pinta cuadritos de la rejilla de la imagen dentro de [area], con el
  /// color que diga [colorAt] para su centro (o ninguno).
  static void _cells(
    Canvas canvas,
    Rect area,
    Color? Function(double x, double y) colorAt,
  ) {
    final paths = <Color, Path>{};
    for (
      var j = (area.top / _px).floor();
      j < (area.bottom / _px).ceil();
      j++
    ) {
      for (
        var i = (area.left / _px).floor();
        i < (area.right / _px).ceil();
        i++
      ) {
        final color = colorAt((i + 0.5) * _px, (j + 0.5) * _px);
        if (color == null) continue;
        // Un pelín más grandes para que no queden rendijas entre ellos.
        (paths[color] ??= Path()).addRect(
          Rect.fromLTWH(i * _px, j * _px, _px + 0.4, _px + 0.4),
        );
      }
    }
    for (final MapEntry(key: color, value: path) in paths.entries) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..isAntiAlias = false,
      );
    }
  }

  /// Punto de la curva que va de [a] a [c] pasando por el medio [b].
  static Offset _curve(Offset a, Offset b, Offset c, double t) {
    final control = b * 2 - (a + c) / 2;
    final u = 1 - t;
    return a * (u * u) + control * (2 * u * t) + c * (t * t);
  }

  /// Cuadrito de la rejilla que contiene el punto (x, y).
  static (int, int) _cellOf(double x, double y) =>
      ((x / _px).floor(), (y / _px).floor());

  /// Recorre la curva y devuelve los cuadritos por los que pasa, con el
  /// punto de la curva (0..1) de cada uno: una línea continua de un píxel,
  /// como se dibuja a mano en pixel art.
  static Map<(int, int), double> _trace(Offset a, Offset b, Offset c) {
    final cells = <(int, int), double>{};
    for (var k = 0; k <= 80; k++) {
      final t = k / 80;
      final p = _curve(a, b, c, t);
      cells.putIfAbsent(_cellOf(p.dx, p.dy), () => t);
    }
    return cells;
  }

  void _eye(Canvas canvas, Rect eye, double lid) {
    if (lid < 0.02) return;
    // Los párpados se juntan un poco por debajo del centro del ojo.
    final meet = eye.top + eye.height * 0.6;
    final upper = eye.top + (meet - eye.top) * lid;
    final lower = eye.bottom - (eye.bottom - meet) * lid;
    final dy = (upper - eye.center.dy) / (eye.height / 2);
    final halfWidth = eye.width / 2 * math.sqrt(math.max(0, 1 - dy * dy));
    final arc = face.happyEyes * ((lid - 0.6) / 0.4).clamp(0.0, 1.0);
    final left = Offset(eye.center.dx - halfWidth * 0.9, upper + arc * 8);
    final right = Offset(eye.center.dx + halfWidth * 0.9, upper + arc * 8);
    final middle = Offset(
      eye.center.dx,
      upper + arc * 8 - arc * 16 + (1 - arc) * 3 * lid,
    );
    final oval = eye.inflate(3);
    // Pestañas en el borde del párpado.
    final lash = _trace(left, middle, right);
    _cells(canvas, oval, (x, y) {
      if (lash.containsKey(_cellOf(x, y))) return _lash;
      final nx = (x - oval.center.dx) / (oval.width / 2);
      final ny = (y - oval.center.dy) / (oval.height / 2);
      if (nx * nx + ny * ny > 1) return null;
      if (y < upper || y > lower) return _skin;
      return null;
    });
  }

  void _blush(Canvas canvas) {
    if (face.blush < 0.01) return;
    final color = const Color(0xFFFF7F9A).withValues(alpha: 0.45 * face.blush);
    for (final center in const [Offset(237, 265), Offset(357, 265)]) {
      final area = Rect.fromCenter(center: center, width: 50, height: 20);
      _cells(canvas, area, (x, y) {
        final nx = (x - center.dx) / 25;
        final ny = (y - center.dy) / 10;
        return nx * nx + ny * ny <= 1 ? color : null;
      });
    }
  }

  void _mouth(Canvas canvas) {
    const center = Offset(297, 309);
    // Tapa la sonrisa que trae la imagen.
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 72, height: 30),
      Paint()..color = _skin,
    );

    final x = center.dx + face.mouthShift;
    final half = 28 * face.mouthWidth;
    final corner = center.dy - 9 * face.smile;
    final upperControl = center.dy + 15 * face.smile;
    final open = face.mouthOpen * 26;
    final upper = Path()
      ..moveTo(x - half, corner)
      ..quadraticBezierTo(x, upperControl, x + half, corner);
    final lip = Paint()
      ..color = _lip
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (open < 1.5) {
      canvas.drawPath(upper, lip);
      return;
    }
    final mouth = Path.from(upper)
      ..quadraticBezierTo(x, upperControl + open * 2, x - half, corner)
      ..close();
    canvas
      ..drawPath(mouth, Paint()..color = const Color(0xFF5A1626))
      ..save()
      ..clipPath(mouth)
      ..drawOval(
        Rect.fromCenter(
          center: Offset(x, (corner + upperControl) / 2 + open * 0.95),
          width: half * 1.2,
          height: open * 0.8,
        ),
        Paint()..color = const Color(0xFFE86A7A),
      )
      ..restore()
      ..drawPath(mouth, lip..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(_LizFacePainter oldDelegate) => oldDelegate.face != face;
}

/// Botón para llamar a Liz desde la Pokédex.
class _LizButton extends StatelessWidget {
  const _LizButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Hablar con Liz',
      child: _Pressable(
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _outline, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), offset: Offset(0, 3)),
                ],
              ),
              // Recortada al marco: al moverse no se sale de él.
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: const _IdleLiz(size: 42),
              ),
            ),
            const SizedBox(height: 6),
            Text('LIZ', style: _pixel(6, color: _outline, height: 1)),
          ],
        ),
      ),
    );
  }
}

/// Liz esperando en su botón: parpadea (a veces dos veces), respira, mece
/// la cabeza y de vez en cuando hace algún gesto (ladea la cabeza con una
/// ceja arriba, guiña, sonríe, se pone pensativa...). Se queda quieta si el
/// sistema pide reducir animaciones.
class _IdleLiz extends StatefulWidget {
  const _IdleLiz({required this.size});

  final double size;

  @override
  State<_IdleLiz> createState() => _IdleLizState();
}

class _IdleLizState extends State<_IdleLiz>
    with SingleTickerProviderStateMixin {
  /// Gestos sin símbolos encima (en el botón no caben).
  static const _gestures = [
    _LizFace(browRight: 0.7, tilt: 0.07, smile: 0.6, mouthShift: 3),
    _LizFace(
      lidRight: 1,
      smile: 1.2,
      mouthShift: 3,
      tilt: 0.03,
      browRight: -0.4,
    ),
    _LizFace(
      lidLeft: 0.3,
      lidRight: 0.3,
      smile: 1.35,
      mouthWidth: 1.1,
      browLeft: 0.3,
      browRight: 0.3,
    ),
    _LizFace(
      lidLeft: 0.3,
      lidRight: 0.3,
      smile: 0.1,
      mouthShift: -5,
      mouthWidth: 0.7,
      tilt: -0.04,
      browLeft: 0.3,
      browRight: -0.2,
      browTilt: -0.4,
    ),
    _LizFace(
      lidLeft: 0.35,
      lidRight: 0.35,
      smile: 0.8,
      mouthWidth: 0.75,
      blush: 0.5,
      tilt: -0.04,
      browTilt: 0.4,
    ),
    _LizFace(browLeft: 0.5, browRight: 0.5, smile: 1.1, tilt: -0.05),
  ];

  /// Cuánto dura un gesto y un parpadeo, en segundos.
  static const _gestureLength = 1.8;
  static const _blinkLength = 0.16;

  final _random = math.Random();
  late final _ticker = createTicker(_tick);
  double _time = 0;
  double _blinkAt = -1;
  double _nextBlink = 1.5;
  double _gestureAt = -10;
  double _nextGesture = 3;
  _LizFace _gesture = _gestures.first;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    if (t >= _nextBlink) {
      _blinkAt = t;
      // A veces parpadea dos veces seguidas.
      _nextBlink = _random.nextDouble() < 0.2
          ? t + 0.32
          : t + 2.2 + _random.nextDouble() * 3;
    }
    if (t >= _nextGesture) {
      _gestureAt = t;
      _gesture = _gestures[_random.nextInt(_gestures.length)];
      _nextGesture = t + _gestureLength + 3 + _random.nextDouble() * 4;
    }
    setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _LizAvatar(size: widget.size);
    }
    final t = _time;
    // Entra y sale del gesto con suavidad.
    final g = (t - _gestureAt) / _gestureLength;
    final amount = g <= 0 || g >= 1
        ? 0.0
        : Curves.easeInOut.transform(math.min(1, math.sin(g * math.pi) * 1.6));
    var face = _LizFace.lerp(const _LizFace(), _gesture, amount);
    // Mece la cabeza despacio, además del gesto.
    face = face.copyWith(tilt: face.tilt + 0.025 * math.sin(t * 0.9));
    // Parpadeo.
    final b = (t - _blinkAt) / _blinkLength;
    if (b > 0 && b < 1) {
      final blink = math.sin(b * math.pi);
      face = face.copyWith(
        lidLeft: math.max(face.lidLeft, blink),
        lidRight: math.max(face.lidRight, blink),
      );
    }
    return _Breathing(
      child: _LizAvatar(size: widget.size, face: face),
    );
  }
}

/// Placa con el nombre del entrenador en la tapa de la Pokédex.
class _TrainerTag extends StatelessWidget {
  const _TrainerTag({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: _greenScreen,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _outline, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENTRENADOR',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: _pixel(6, color: const Color(0xFF14592C), height: 1),
          ),
          const SizedBox(height: 6),
          Text(
            _dexText(name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pixel(9, color: _outline, height: 1),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Dibujos

class _LizArtwork extends StatelessWidget {
  const _LizArtwork({super.key, required this.art, this.expression});

  final _LizArt art;
  final _LizExpression? expression;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: FittedBox(fit: BoxFit.scaleDown, child: _buildArt()),
    );
  }

  Widget _buildArt() {
    switch (art) {
      case _LizArt.liz:
        return _LizHologram(size: 240, expression: expression);
      case _LizArt.pokemon:
        return SizedBox(
          width: 360,
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final id in [25, 1, 4, 7, 133, 39, 52, 143])
                _Sprite(id: id, size: 88),
            ],
          ),
        );
      case _LizArt.types:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (id, type) in [(4, 'fire'), (7, 'water'), (1, 'grass')])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    _Sprite(id: id, size: 96),
                    _TypeChip(type: type),
                  ],
                ),
              ),
          ],
        );
      case _LizArt.evolution:
        Widget arrow(String level) => Column(
          children: [
            Text(level, style: _pixel(7, color: _lightYellow)),
            Text('▶', style: _pixel(12, color: Colors.white)),
          ],
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Sprite(id: 4, size: 96),
            arrow('NV. 16'),
            const _Sprite(id: 5, size: 96),
            arrow('NV. 36'),
            const _Sprite(id: 6, size: 96),
          ],
        );
      case _LizArt.trainer:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.catching_pokemon, size: 110, color: Colors.white),
            const SizedBox(width: 12),
            const _Sprite(id: 25, size: 120),
          ],
        );
      case _LizArt.pokedex:
        return Container(
          width: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _dexRed,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _outline, width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Lens(glowing: true),
                  SizedBox(width: 8),
                  _Light(color: _lightRed, on: true, size: 14),
                  SizedBox(width: 4),
                  _Light(color: _lightYellow, on: true, size: 14),
                  SizedBox(width: 4),
                  _Light(color: _lightGreen, on: true, size: 14),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6EE),
                  border: Border.all(color: _outline, width: 3),
                ),
                child: const _Sprite(id: 25, size: 80),
              ),
            ],
          ),
        );
    }
  }
}

/// Liz se materializa como un holograma: crece desde la Pokédex con un
/// suave brillo cian detrás, sin marco.
class _LizHologram extends StatelessWidget {
  const _LizHologram({required this.size, this.expression});

  final double size;
  final _LizExpression? expression;

  @override
  Widget build(BuildContext context) {
    final instant = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: instant ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.5 + 0.5 * value,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFF4FE3E0).withValues(alpha: 0.35),
              const Color(0x004FE3E0),
            ],
          ),
        ),
        child: _ExpressiveLiz(expression: expression, size: size),
      ),
    );
  }
}

class _Sprite extends StatelessWidget {
  const _Sprite({required this.id, required this.size});

  final int id;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.network(
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
        filterQuality: FilterQuality.none,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.catching_pokemon, color: Colors.white38, size: size / 2),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _typeColor(type),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        _dexText(_typeName(type)),
        style: _pixel(8, color: Colors.white, height: 1),
      ),
    );
  }
}

/// Poké Ball dibujada (en la tapa de la Pokédex de la presentación).
class _PokeBallPainter extends CustomPainter {
  const _PokeBallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final outline = radius * 0.08;
    final ball = Rect.fromCircle(center: center, radius: radius - outline / 2);

    // Mitad roja con brillo y mitad blanca.
    canvas
      ..drawArc(
        ball,
        math.pi,
        math.pi,
        true,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 0.9,
            colors: [Color(0xFFFF5A5A), _dexRed, _dexRedDark],
          ).createShader(ball),
      )
      ..drawArc(
        ball,
        0,
        math.pi,
        true,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, 0.2),
            radius: 1,
            colors: [Colors.white, Color(0xFFDADADA)],
          ).createShader(ball),
      );

    final stroke = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = outline;
    // Franja central, contorno y botón.
    canvas
      ..drawRect(
        Rect.fromCenter(
          center: center,
          width: radius * 2 - outline,
          height: radius * 0.16,
        ),
        Paint()..color = _outline,
      )
      ..drawCircle(center, radius - outline / 2, stroke)
      ..drawCircle(center, radius * 0.3, Paint()..color = _outline)
      ..drawCircle(center, radius * 0.2, Paint()..color = Colors.white)
      ..drawCircle(
        center,
        radius * 0.13,
        Paint()
          ..color = const Color(0xFFBDBDBD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.03,
      )
      // Reflejo de luz en la parte roja.
      ..drawOval(
        Rect.fromCenter(
          center: center + Offset(-radius * 0.42, -radius * 0.55),
          width: radius * 0.34,
          height: radius * 0.18,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
  }

  @override
  bool shouldRepaint(_PokeBallPainter oldDelegate) => false;
}
