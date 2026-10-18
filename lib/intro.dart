part of 'main.dart';

// Presentación: tras la pantalla de título, la Pokédex aparece cerrada sobre
// una mesa, se levanta hacia el entrenador, se abre y se enciende. Después
// llega la Pokédex de verdad, donde espera Liz.

/// Medidas de una mitad de la Pokédex de la presentación, antes de escalarla.
const _introHalfWidth = 300.0;
const _introHeight = 460.0;

const _introMillis = 7400;

/// Al final la cámara mira apenas hacia abajo (así se ve el cielo), y la
/// Pokédex se inclina lo mismo para quedar de frente.
const _finalPitch = 0.06;

double _mix(double a, double b, double t) => a + (b - a) * t;

Widget _blurred(double sigma, Widget child) => sigma < 0.1
    ? child
    : ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      );

class DexIntroPage extends StatefulWidget {
  const DexIntroPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<DexIntroPage> createState() => _DexIntroPageState();
}

class _DexIntroPageState extends State<DexIntroPage>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _introMillis),
  );
  bool _started = false;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (_started) return;
    // Sin animaciones (accesibilidad), directo a la Pokédex.
    if (MediaQuery.disableAnimationsOf(context)) return _finish();
    setState(() => _started = true);
    _controller.forward().whenComplete(_finish);
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    _controller.stop();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _started ? null : Colors.white,
      body: _started ? _buildScene() : SafeArea(child: _buildTitle()),
    );
  }

  Widget _buildTitle() {
    // Solo el logo, sobre blanco. Tocarlo empieza la presentación (y
    // desbloquea el audio en el navegador).
    return Center(child: _FloatingLogo(onPressed: _start));
  }

  Widget _buildScene() {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) =>
            _buildFrame(constraints.biggest, _controller.value),
      ),
    );
  }

  Widget _buildFrame(Size size, double t) {
    double phase(double begin, double end, [Curve curve = Curves.easeInOut]) =>
        curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

    // La toma: desde el blanco del logo aparece la mesa en el prado; la
    // cámara la rodea y baja hasta descubrir el lago, mientras la Pokédex se
    // levanta hacia el entrenador, se abre, se enciende y la cámara se acerca
    // hasta el tamaño de la Pokédex de verdad.
    final fadeIn = phase(0, 0.1, Curves.easeOut);
    final orbit = phase(0, 0.56, Curves.easeInOutSine);
    final lift = phase(0.2, 0.5, Curves.easeInOutCubic);
    final open = phase(0.52, 0.76, Curves.easeInOutCubic);
    final power = t >= 0.78;
    final flash = power ? 1 - phase(0.78, 0.88) : 0.0;
    final settle = phase(0.84, 1, Curves.easeInOutCubic);
    // La lente parpadea mientras la Pokédex despierta.
    final lensOn = power || (lift > 0 && (t * 18).floor().isOdd);

    final fit = math.min(
      (size.width - 24) / (_introHalfWidth * 2),
      (size.height - 48) / _introHeight,
    );

    // La Pokédex: acostada sobre la mesa (la tapa hacia arriba), se levanta
    // en arco hasta quedar frente a la cámara y flota un poco en el aire.
    const _V3 lying = (x: 0, y: -_baseDepth, z: 320);
    const _V3 held = (x: 0, y: -_introHeight / 2 - 90, z: 0);
    final seconds = t * _introMillis / 1000;
    final floating = lift * (1 - settle);
    final arc = math.sin(math.pi * lift) * 120;
    final position = (
      x: _mix(lying.x, held.x, lift),
      y:
          _mix(lying.y, held.y, lift) -
          arc +
          math.sin(seconds * 2.4) * 6 * floating,
      z: _mix(lying.z, held.z, lift),
    );
    final pose = Matrix4.translationValues(position.x, position.y, position.z)
      ..multiply(
        Matrix4.rotationX(
          _mix(-math.pi / 2, -_finalPitch, lift) +
              math.sin(seconds * 1.7) * 0.025 * floating,
        ),
      )
      ..multiply(Matrix4.rotationZ(math.sin(seconds * 1.3) * 0.02 * floating))
      // Cerrada, se centra la base; abierta, la Pokédex completa.
      ..multiply(
        Matrix4.translationValues(_mix(_introHalfWidth / 2, 0, open), 0, 0),
      );

    // La cámara empieza alta y de lado, rodea la mesa y baja hasta quedar
    // frente a la Pokédex, que al final se ve igual que en 2D.
    final camera = _Camera(
      // Sigue el arco de la Pokédex con un poco de retraso, como un operador.
      target: (
        x: _mix(lying.x, held.x, lift),
        y: _mix(lying.y, held.y, lift) - arc * 0.8,
        z: _mix(lying.z, held.z, lift),
      ),
      pitch: _mix(_mix(1.05, 0.8, orbit), _finalPitch, lift),
      yaw: 0.7 * (1 - orbit),
      scale: fit * (_mix(_mix(0.4, 0.5, orbit), 0.8, lift) + 0.2 * settle),
      screen: Offset(size.width / 2, size.height * _mix(0.56, 0.5, lift)),
    );

    final dex = _Dex3d(
      camera: camera,
      pose: pose,
      open: open,
      lensOn: lensOn,
      power: power,
    );
    final glow = power ? 1 - settle * 0.5 : 0.0;

    return Stack(
      children: [
        Positioned.fill(
          child: _blurred(
            2.2,
            CustomPaint(
              painter: _LandscapePainter(camera: camera, seconds: seconds),
            ),
          ),
        ),
        // El foco sigue a la Pokédex: al levantarla, la mesa se desenfoca.
        Positioned.fill(
          child: _blurred(
            2.4 * lift,
            CustomPaint(
              painter: _TableTopPainter(
                camera: camera,
                shadow: _Shadow.cast(dex.silhouettes()),
                glow: glow,
                glowAt: Offset(position.x, position.z - 120),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _AtmospherePainter(camera: camera, seconds: seconds),
          ),
        ),
        // El paisaje se queda: es el fondo de la Pokédex en 2D
        // (_DexScenery), que lo muestra igual que en esta última toma.
        Positioned.fill(
          child: IgnorePointer(child: Stack(children: dex.planes())),
        ),
        // Entra desde el blanco de la pantalla del logo.
        if (fadeIn < 1)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 1 - fadeIn),
              ),
            ),
          ),
        if (flash > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.3 * flash),
              ),
            ),
          ),
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _BlackPill(
                label: 'SALTAR',
                tooltip: 'Saltar presentación',
                onPressed: _finish,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// El prado, la mesa y el lago tal como quedan al final de la presentación,
/// de fondo para la Pokédex en 2D. Sigue vivo: pasan las nubes y su sombra,
/// el viento mueve el pasto, los pinos y el agua, y cruzan los pájaros.
class _DexScenery extends StatefulWidget {
  const _DexScenery();

  @override
  State<_DexScenery> createState() => _DexSceneryState();
}

class _DexSceneryState extends State<_DexScenery>
    with SingleTickerProviderStateMixin {
  late final _ticker = createTicker(_tick);

  /// Continúa el reloj de la presentación, para empezar donde terminó.
  final _seconds = ValueNotifier<double>(_introMillis / 1000);
  var _lastFrame = Duration.zero;

  void _tick(Duration elapsed) {
    // Unos 30 cuadros por segundo bastan para nubes y agua, y gastan la
    // mitad de batería.
    if (elapsed - _lastFrame < const Duration(milliseconds: 33)) return;
    _lastFrame = elapsed;
    _seconds.value = _introMillis / 1000 + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sin animaciones (accesibilidad), el paisaje se queda quieto.
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final fit = math.min(
            (size.width - 24) / (_introHalfWidth * 2),
            (size.height - 48) / _introHeight,
          );
          // La misma cámara que la última toma de la presentación.
          final camera = _Camera(
            target: (x: 0, y: -_introHeight / 2 - 90, z: 0),
            pitch: _finalPitch,
            yaw: 0,
            scale: fit,
            screen: Offset(size.width / 2, size.height / 2),
          );
          Widget animated(CustomPainter Function(double seconds) painter) =>
              RepaintBoundary(
                child: ValueListenableBuilder<double>(
                  valueListenable: _seconds,
                  builder: (context, seconds, _) =>
                      CustomPaint(painter: painter(seconds)),
                ),
              );
          return Stack(
            children: [
              Positioned.fill(
                child: _blurred(
                  2.2,
                  animated(
                    (seconds) =>
                        _LandscapePainter(camera: camera, seconds: seconds),
                  ),
                ),
              ),
              // La mesa no se mueve: se pinta una vez.
              Positioned.fill(
                child: RepaintBoundary(
                  child: _blurred(
                    2.4,
                    CustomPaint(
                      painter: _TableTopPainter(
                        camera: camera,
                        shadow: _Shadow(outline: Path(), height: 0),
                        glow: 0.5,
                        glowAt: const Offset(0, -120),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: animated(
                  (seconds) =>
                      _AtmospherePainter(camera: camera, seconds: seconds),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------ Logo

/// Logo de Pokémon que flota suavemente sobre su sombra. Crece un poco al
/// pasar el ratón y se hunde al pulsarlo.
class _FloatingLogo extends StatefulWidget {
  const _FloatingLogo({required this.onPressed});

  static const asset = 'assets/images/pokemon_logo.png';

  /// Proporción de la imagen (736 × 272).
  static const aspect = 736 / 272;

  final VoidCallback onPressed;

  @override
  State<_FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<_FloatingLogo>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  bool _hovered = false;
  bool _pressed = false;

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
    final width = math.min(MediaQuery.sizeOf(context).width * 0.8, 460.0);
    final height = width / _FloatingLogo.aspect;
    final scale = _pressed ? 0.94 : (_hovered ? 1.05 : 1.0);

    return Tooltip(
      message: 'Empezar',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final wave = math.sin(_controller.value * math.pi * 2);
                // Arriba: más alto y la sombra más pequeña y tenue.
                final rise = (wave + 1) / 2;
                return SizedBox(
                  width: width,
                  height: height + 34,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: CustomPaint(
                          size: Size(width, 34),
                          painter: _LogoShadowPainter(rise: rise),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, 12 - rise * 18),
                        child: Transform.rotate(
                          angle:
                              math.sin(_controller.value * math.pi * 4) * 0.015,
                          child: child,
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Image.asset(
                _FloatingLogo.asset,
                width: width,
                height: height,
                filterQuality: FilterQuality.medium,
                semanticLabel: 'Pokémon',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sombra ovalada bajo el logo: más pequeña y tenue cuanto más sube.
class _LogoShadowPainter extends CustomPainter {
  const _LogoShadowPainter({required this.rise});

  final double rise;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * _mix(0.66, 0.5, rise),
        height: 12,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: _mix(0.55, 0.3, rise))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _mix(5, 9, rise)),
    );
  }

  @override
  bool shouldRepaint(_LogoShadowPainter oldDelegate) =>
      oldDelegate.rise != rise;
}

// ------------------------------------------------------------ Pokédex en 3D

/// Grosor de la base y de la tapa.
const _baseDepth = 28.0;
const _lidDepth = 16.0;

/// Separación entre las capas que forman los bordes.
const _layerStep = 2.0;

/// Luz principal sobre la Pokédex, como en un estudio: arriba, a la
/// izquierda y delante de la cámara.
final _toLight = () {
  const x = -0.35, y = -0.55, z = -0.75;
  final length = math.sqrt(x * x + y * y + z * z);
  return (x: x / length, y: y / length, z: z / length);
}();

/// La Pokédex de la presentación como un objeto 3D sencillo. Cada cara es un
/// widget plano colocado en el espacio con su matriz; el grosor sale de capas
/// apiladas y todo se dibuja de atrás hacia delante.
///
/// Coordenadas propias: la bisagra está en x = 0, la base a la izquierda
/// (x < 0) y la tapa abierta a la derecha. La cara de delante está en z = 0 y
/// el grosor crece hacia +z. [pose] la coloca en el mundo.
class _Dex3d {
  _Dex3d({
    required this.camera,
    required this.pose,
    required this.open,
    required this.lensOn,
    required this.power,
  });

  final _Camera camera;
  final Matrix4 pose;

  /// 0 cerrada, 1 abierta.
  final double open;
  final bool lensOn;
  final bool power;

  static const _half = Size(_introHalfWidth, _introHeight);

  late final Matrix4 _view = camera.view.clone()..multiply(pose);

  late final Matrix4 _lidTurn = Matrix4.rotationY((1 - open) * math.pi);

  static Matrix4 _at(double x, double y, double z) =>
      Matrix4.translationValues(x, y, z);

  Matrix4 _lid(double z) =>
      _lidTurn.clone()..multiply(_at(0, -_introHeight / 2, z));

  static final _leftOutline = _sampleOutline(_leftShellPath);
  static final _rightOutline = _sampleOutline(_rightShellPath);

  /// Puntos a lo largo del contorno de una mitad (con su escalón).
  static List<Offset> _sampleOutline(Path Function(Size) shape) {
    final metric = shape(_half).computeMetrics().first;
    return [
      for (var i = 0; i < 64; i++)
        metric.getTangentForOffset(metric.length * i / 64)!.position,
    ];
  }

  /// Siluetas de las caras de la base y de la tapa en el mundo, para
  /// proyectar la sombra con su forma real.
  List<List<_V3>> silhouettes() {
    final lid = pose.clone()..multiply(_lidTurn);
    return [
      for (final z in [0.0, _baseDepth])
        [
          for (final p in _leftOutline)
            _transform(pose, (
              x: p.dx - _introHalfWidth,
              y: p.dy - _introHeight / 2,
              z: z,
            )),
        ],
      for (final z in [0.0, _lidDepth])
        [
          for (final p in _rightOutline)
            _transform(lid, (x: p.dx, y: p.dy - _introHeight / 2, z: z)),
        ],
    ];
  }

  /// Las caras, ordenadas de la más lejana a la más cercana.
  List<Widget> planes() {
    final planes = <({double depth, Widget widget})>[];

    void add(
      Matrix4 local,
      Size box,
      Widget child, {
      int facing = 0,
      Path Function(Size)? shape,
    }) {
      final m = _view.clone()..multiply(local);
      final s = m.storage;
      // Normal de la cara (su frente mira hacia -z) ya girada.
      final sign = facing == 0 ? 1.0 : facing.toDouble();
      final nx = -s[8] * sign, ny = -s[9] * sign, nz = -s[10] * sign;
      // Caras de un solo lado: si miran hacia atrás no se dibujan.
      if (facing != 0 && nz >= -0.01) return;

      var content = child;
      if (shape != null) {
        // Luz relativa a una cara de frente, que queda igual que en 2D.
        final light = nx * _toLight.x + ny * _toLight.y + nz * _toLight.z;
        final delta = light + _toLight.z;
        final tint = delta < 0
            ? Colors.black.withValues(alpha: math.min(0.45, -delta * 1.1))
            : Colors.white.withValues(alpha: math.min(0.16, delta * 0.7));
        content = Stack(
          fit: StackFit.expand,
          children: [
            child,
            CustomPaint(
              painter: _FillPainter(shape: shape, color: tint),
            ),
          ],
        );
      }
      final center = Offset(box.width / 2, box.height / 2);
      planes.add((
        depth: s[2] * center.dx + s[6] * center.dy + s[14],
        widget: Positioned(
          left: 0,
          top: 0,
          width: box.width,
          height: box.height,
          child: Transform(
            transform: camera.projection.clone()..multiply(m),
            child: content,
          ),
        ),
      ));
    }

    // Base: capas del borde y la cara de delante.
    for (var z = _baseDepth; z > 0; z -= _layerStep) {
      add(
        _at(-_introHalfWidth, -_introHeight / 2, z),
        _half,
        _Slab(shape: _leftShellPath, depth: z / _baseDepth),
      );
    }
    add(
      _at(-_introHalfWidth, -_introHeight / 2, 0),
      _half,
      _IntroBase(lensOn: lensOn, power: power),
      shape: _leftShellPath,
    );

    // Tapa: por dentro, sus capas y por fuera. La cara de fuera se ve desde
    // atrás (el giro la refleja), así que se dibuja volteada.
    add(
      _lid(0),
      _half,
      _IntroLid(power: power),
      facing: 1,
      shape: _rightShellPath,
    );
    for (var z = _layerStep; z < _lidDepth; z += _layerStep) {
      add(_lid(z), _half, _Slab(shape: _rightShellPath, depth: z / _lidDepth));
    }
    add(
      _lid(_lidDepth),
      _half,
      Transform.flip(flipX: true, child: const _IntroCover()),
      facing: -1,
      shape: _rightShellPath,
    );

    // Lomo con la bisagra, en el costado derecho, bajo el escalón. Cerrada
    // también cubre el grosor de la tapa.
    final spineFront = -_lidDepth * (1 - open);
    final spine = Size(_baseDepth - spineFront, _introHeight - _stepHeight);
    add(
      _at(0, _stepHeight - _introHeight / 2, spineFront)
        ..multiply(Matrix4.rotationY(-math.pi / 2)),
      spine,
      const _Spine(),
      facing: 1,
      shape: (size) => Path()..addRect(Offset.zero & size),
    );

    // Bisagra de delante, entre las dos mitades, cuando ya está abierta.
    if (open > 0.5) {
      add(
        _at(-13, -_introHeight / 2, -0.5),
        const Size(26, _introHeight),
        Opacity(opacity: (open - 0.5) * 2, child: const _Hinge(vertical: true)),
      );
    }

    planes.sort((a, b) => b.depth.compareTo(a.depth));
    return [for (final plane in planes) plane.widget];
  }
}

/// Una capa del grosor: la silueta rellena, más oscura cuanto más al fondo.
class _Slab extends StatelessWidget {
  const _Slab({required this.shape, required this.depth});

  final Path Function(Size) shape;

  /// 0 delante, 1 al fondo.
  final double depth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FillPainter(
        shape: shape,
        color: Color.lerp(_dexRedDark, _outline, 0.15 + 0.5 * depth)!,
      ),
    );
  }
}

/// Costado de la bisagra: cilindros rojos sobre fondo oscuro.
class _Spine extends StatelessWidget {
  const _Spine();

  @override
  Widget build(BuildContext context) {
    Widget segment() => Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_dexRedDark, _dexRed, _dexRedDark],
          ),
          border: Border.all(color: _outline, width: 3),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(_dexRedDark, _outline, 0.3),
        border: Border.all(color: _outline, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(children: [segment(), segment(), segment()]),
      ),
    );
  }
}

class _FillPainter extends CustomPainter {
  const _FillPainter({required this.shape, required this.color});

  final Path Function(Size) shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(shape(size), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FillPainter oldDelegate) => oldDelegate.color != color;
}

/// Mitad izquierda: lente, luces, pantalla principal y controles.
class _IntroBase extends StatelessWidget {
  const _IntroBase({required this.lensOn, required this.power});

  final bool lensOn;
  final bool power;

  @override
  Widget build(BuildContext context) {
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
                  _Lens(glowing: lensOn),
                  const SizedBox(width: 14),
                  _Light(color: _lightRed, on: power),
                  const SizedBox(width: 8),
                  _Light(color: _lightYellow, on: power),
                  const SizedBox(width: 8),
                  _Light(color: _lightGreen, on: power),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Expanded(
              child: CustomPaint(
                painter: const _ShapePainter(shape: _bezelPath, color: _bezel),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: power ? const Color(0xFFF2F6EE) : _lcdBlack,
                      border: Border.all(color: _outline, width: 3),
                    ),
                    // Al encenderse aparece el logo de Pokémon.
                    child: power
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: Image.asset(
                              _FloatingLogo.asset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) =>
                                  FittedBox(
                                    child: Text(
                                      'POKEDEX',
                                      style: _pixel(
                                        14,
                                        color: _dexRed,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 66,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2B2B2B),
                      border: Border.all(color: _outline, width: 3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _introPill(_lightRed)),
                            const SizedBox(width: 8),
                            Expanded(child: _introPill(_keyBlue)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: _greenScreen,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: _outline, width: 3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const _IntroDPad(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _introPill(Color color) => Container(
  height: 12,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: _outline, width: 2.5),
  ),
);

class _IntroDPad extends StatelessWidget {
  const _IntroDPad();

  @override
  Widget build(BuildContext context) {
    final bar = BoxDecoration(
      color: const Color(0xFF2B2B2B),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _outline, width: 3),
    );
    return SizedBox.square(
      dimension: 66,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 66, height: 22, decoration: bar),
          Container(width: 22, height: 66, decoration: bar),
        ],
      ),
    );
  }
}

/// Mitad derecha por dentro: pantalla de datos, teclado y lista.
class _IntroLid extends StatelessWidget {
  const _IntroLid({required this.power});

  final bool power;

  @override
  Widget build(BuildContext context) {
    Widget key() => Expanded(
      child: Container(
        height: 26,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _keyBlue,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _outline, width: 2),
        ),
      ),
    );
    Widget whiteKey() => Container(
      width: 54,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _outline, width: 2.5),
      ),
    );

    return _Shell(
      shape: _rightShellPath,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, _stepHeight + 14, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _lcdBlack,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _outline, width: 3),
                ),
                child: power
                    ? FittedBox(
                        alignment: Alignment.topLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'INICIANDO...\nLIZ EN LINEA',
                          style: _pixel(8, height: 2),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            for (var row = 0; row < 2; row++)
              Row(children: [for (var i = 0; i < 5; i++) key()]),
            const SizedBox(height: 10),
            Row(
              children: [
                whiteKey(),
                const SizedBox(width: 8),
                whiteKey(),
                const Spacer(),
                _Light(color: _lightYellow, on: power, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: power ? _gbLight : const Color(0xFF55660A),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _outline, width: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La tapa vista por fuera: la mitad derecha reflejada.
Path _coverPath(Size size) => _rightShellPath(size).transform(
  Matrix4(-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, size.width, 0, 0, 1).storage,
);

class _IntroCover extends StatelessWidget {
  const _IntroCover();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShapePainter(
        shape: _coverPath,
        color: _dexRed,
        bevel: _dexRedDark.withValues(alpha: 0.45),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, _stepHeight + 30, 30, 40),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: CustomPaint(
                  size: Size.square(120),
                  painter: _PokeBallPainter(),
                ),
              ),
            ),
            Text(
              'POKEDEX',
              style: _pixel(18, color: Colors.white, height: 1).copyWith(
                shadows: const [
                  Shadow(color: _dexRedDark, offset: Offset(3, 3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
