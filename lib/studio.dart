part of 'main.dart';

// El set de la presentación: una mesa de madera en un prado junto a un lago,
// en una tarde de sol, con un bosque de pinos y montañas al fondo. Todo
// comparte la cámara 3D con la Pokédex.
//
// Coordenadas del mundo (como en Flutter, y hacia abajo): la superficie de la
// mesa está en y = 0, x va a la derecha y z se aleja de la cámara.

typedef _V3 = ({double x, double y, double z});

/// Distancia de la cámara a su objetivo: cuanto menor, más perspectiva.
const _cameraDistance = 1300.0;

/// Dirección hacia el sol (unitaria): bajo, a la izquierda y al fondo, como
/// en una tarde de verano.
const _V3 _toSun = (x: -0.532, y: -0.375, z: 0.760);

/// Mesa: ancho, borde cercano, borde lejano y grosor del tablero.
const _tableHalfWidth = 1600.0;
const _tableNear = -560.0;
const _tableFar = 1500.0;
const _tableThickness = 54.0;

/// El prado (bajo la mesa), la orilla y el lago.
const _groundY = 760.0;
const _shoreZ = 4800.0;
const _farShoreZ = 16000.0;

/// Cielo: arriba y junto al horizonte (la bruma de lo lejano tira a este).
const _skyTop = Color(0xFF2F7FE0);
const _skyHorizon = Color(0xFFCDEBFF);

_V3 _transform(Matrix4 m, _V3 p) {
  final s = m.storage;
  return (
    x: s[0] * p.x + s[4] * p.y + s[8] * p.z + s[12],
    y: s[1] * p.x + s[5] * p.y + s[9] * p.z + s[13],
    z: s[2] * p.x + s[6] * p.y + s[10] * p.z + s[14],
  );
}

/// Cámara que orbita alrededor de un objetivo. La proyección deja el plano
/// del objetivo a escala [scale] y lo coloca en [screen].
class _Camera {
  _Camera({
    required this.target,
    required this.pitch,
    required this.yaw,
    required this.scale,
    required this.screen,
  });

  final _V3 target;

  /// Cuánto mira hacia abajo y cuánto gira alrededor del objetivo.
  final double pitch;
  final double yaw;
  final double scale;
  final Offset screen;

  /// Del mundo al espacio de la cámara (su objetivo en el origen).
  late final Matrix4 view = Matrix4.rotationX(pitch)
    ..multiply(Matrix4.rotationY(yaw))
    ..multiply(Matrix4.translationValues(-target.x, -target.y, -target.z));

  /// Del espacio de la cámara a la pantalla, con perspectiva.
  late final Matrix4 projection =
      Matrix4.translationValues(screen.dx, screen.dy, 0)
        ..multiply(Matrix4.diagonal3Values(scale, scale, 1))
        ..multiply(Matrix4.identity()..setEntry(3, 2, 1 / _cameraDistance));

  late final Matrix4 viewProjection = projection.clone()..multiply(view);

  /// Dónde está la cámara en el mundo.
  late final _V3 position = () {
    final back = Matrix4.rotationY(-yaw)..multiply(Matrix4.rotationX(-pitch));
    final p = _transform(back, (x: 0, y: 0, z: -_cameraDistance));
    return (x: p.x + target.x, y: p.y + target.y, z: p.z + target.z);
  }();

  /// Altura del horizonte en la pantalla.
  double get horizonY => screen.dy - scale * _cameraDistance * math.tan(pitch);

  double _w(_V3 p) {
    final s = viewProjection.storage;
    return s[3] * p.x + s[7] * p.y + s[11] * p.z + s[15];
  }

  Offset _screen(_V3 p, double w) {
    final s = viewProjection.storage;
    return Offset(
      (s[0] * p.x + s[4] * p.y + s[8] * p.z + s[12]) / w,
      (s[1] * p.x + s[5] * p.y + s[9] * p.z + s[13]) / w,
    );
  }

  /// Punto del mundo en la pantalla; null si queda detrás de la cámara.
  Offset? project(_V3 p) {
    final w = _w(p);
    return w < 0.05 ? null : _screen(p, w);
  }

  /// Escala de la pantalla en un punto (para tamaños que se alejan).
  double scaleAt(_V3 p) {
    final w = _w(p);
    return w <= 0.05 ? 0 : scale / w;
  }

  /// Un punto muy lejano en la dirección [direction], como el sol.
  Offset? projectDirection(_V3 direction) => project((
    x: position.x + direction.x * 400000,
    y: position.y + direction.y * 400000,
    z: position.z + direction.z * 400000,
  ));

  /// Proyecta un polígono del mundo; lo que queda detrás de la cámara se
  /// recorta antes, así nunca se deforma.
  List<Offset> projectPolygon(List<_V3> points) {
    const near = 0.08;
    final out = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      final wa = _w(a) - near, wb = _w(b) - near;
      if (wa >= 0) out.add(_screen(a, wa + near));
      if ((wa >= 0) != (wb >= 0)) {
        final t = wa / (wa - wb);
        final p = (
          x: a.x + (b.x - a.x) * t,
          y: a.y + (b.y - a.y) * t,
          z: a.z + (b.z - a.z) * t,
        );
        out.add(_screen(p, near));
      }
    }
    return out;
  }

  /// Dibuja en un plano del mundo: [model] lleva las coordenadas locales
  /// (x, y, con z = 0) al mundo. Solo se pinta la parte de [bounds] que queda
  /// delante de la cámara, así nada se deforma al pasar por detrás.
  void drawPlane(
    Canvas canvas,
    Matrix4 model,
    Rect bounds,
    void Function(Canvas canvas) paint,
  ) {
    final m = viewProjection.clone()..multiply(model);
    final s = m.storage;
    final visible = _clipHalfPlane([
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomRight,
      bounds.bottomLeft,
    ], (p) => s[3] * p.dx + s[7] * p.dy + s[15] - 0.08);
    if (visible.length < 3) return;
    canvas
      ..save()
      ..transform(s)
      ..clipPath(Path()..addPolygon(visible, true));
    paint(canvas);
    canvas.restore();
  }
}

/// Recorta un polígono convexo a la zona donde [inside] es positivo
/// (Sutherland–Hodgman con un solo borde).
List<Offset> _clipHalfPlane(
  List<Offset> polygon,
  double Function(Offset) inside,
) {
  final out = <Offset>[];
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    final da = inside(a), db = inside(b);
    if (da >= 0) out.add(a);
    if ((da >= 0) != (db >= 0)) out.add(Offset.lerp(a, b, da / (da - db))!);
  }
  return out;
}

/// Plano horizontal a la altura [y]: lo local (x, y) va al mundo (x, z).
Matrix4 _horizontal(double y) =>
    Matrix4.translationValues(0, y, 0)
      ..multiply(Matrix4.rotationX(math.pi / 2));

/// Dónde cae, sobre el plano horizontal [y], la sombra de [p] bajo el sol.
_V3 _sunShadow(_V3 p, double y) {
  final t = (p.y - y) / _toSun.y;
  return (x: p.x - _toSun.x * t, y: y, z: p.z - _toSun.z * t);
}

/// Sombra de la Pokédex sobre la mesa, proyectada por el sol.
class _Shadow {
  const _Shadow({required this.outline, required this.height});

  /// Silueta sobre la mesa, en coordenadas (x, z) del mundo.
  final Path outline;

  /// Altura media de la Pokédex sobre la mesa.
  final double height;

  /// Proyecta las siluetas de la Pokédex sobre la mesa; la sombra es su
  /// unión.
  factory _Shadow.cast(List<List<_V3>> silhouettes) {
    final outline = Path();
    var height = 0.0, count = 0;
    for (final silhouette in silhouettes) {
      outline.addPolygon([
        for (final p in silhouette)
          () {
            height += -p.y;
            count++;
            final s = _sunShadow(p, 0);
            return Offset(s.x, s.z);
          }(),
      ], true);
    }
    return _Shadow(
      outline: outline,
      height: count == 0 ? 0 : math.max(0, height / count),
    );
  }
}

// -------------------------------------------------------------- Texturas

/// Pinta una textura una sola vez; si el entorno no permite imágenes,
/// devuelve null y se usa un color liso.
ui.Image? _bake(ui.Picture Function() paint, Size size) {
  try {
    final picture = paint();
    final image = picture.toImageSync(size.width.toInt(), size.height.toInt());
    picture.dispose();
    return image;
  } catch (_) {
    return null;
  }
}

/// Madera de la mesa: tablones con vetas que rodean los nudos y juntas.
ui.Image? _woodTexture;
bool _woodBaked = false;

const _woodSize = Size(2048, 1318);

/// Medidas del tablero que cubre la textura (en coordenadas de la mesa).
const _woodRect = Rect.fromLTRB(
  -_tableHalfWidth,
  _tableNear,
  _tableHalfWidth,
  _tableFar,
);

void _drawWood(Canvas canvas) {
  if (!_woodBaked) {
    _woodBaked = true;
    _woodTexture = _bake(_paintWood, _woodSize);
  }
  final image = _woodTexture;
  if (image == null) {
    canvas.drawRect(_woodRect, Paint()..color = const Color(0xFF7A4C26));
    return;
  }
  canvas.drawImageRect(
    image,
    Offset.zero & _woodSize,
    _woodRect,
    Paint()..filterQuality = FilterQuality.medium,
  );
}

ui.Picture _paintWood() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final random = math.Random(11);
  final w = _woodSize.width, h = _woodSize.height;
  // Los tablones van hacia el fondo de la mesa.
  const plank = 2048 / 19;

  for (var i = 0; i * plank < w; i++) {
    final x0 = i * plank;
    final rect = Rect.fromLTWH(x0, 0, plank, h);
    canvas
      ..save()
      ..clipRect(rect)
      ..drawRect(
        rect,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF6A3E1E),
            const Color(0xFF9C6634),
            random.nextDouble(),
          )!,
      )
      // Vetas anchas de color a lo largo del tablón.
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              for (var k = 0; k < 6; k++)
                (random.nextBool() ? Colors.black : const Color(0xFFFFD9A0))
                    .withValues(alpha: random.nextDouble() * 0.1),
            ],
          ).createShader(rect),
      )
      // Más oscuro en los cantos del tablón.
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x33000000), Color(0x00000000), Color(0x2A000000)],
            stops: [0, 0.5, 1],
          ).createShader(rect),
      );

    final knots = [
      for (var k = 0; k < 2; k++)
        if (random.nextDouble() < 0.4)
          Offset(
            x0 + plank * (0.25 + random.nextDouble() * 0.5),
            random.nextDouble() * h,
          ),
    ];

    for (var g = 0; g < 18; g++) {
      final gx = x0 + random.nextDouble() * plank;
      final amplitude = 1.5 + random.nextDouble() * 4;
      final frequency = 0.003 + random.nextDouble() * 0.006;
      final phase = random.nextDouble() * math.pi * 2;
      double xAt(double y) {
        var x =
            gx +
            amplitude * math.sin(y * frequency + phase) +
            1.2 * math.sin(y * 0.033 + phase * 2);
        // Las vetas se abren alrededor de los nudos.
        for (final knot in knots) {
          final dy = (y - knot.dy) / 46;
          final dx = gx - knot.dx;
          final pull = math.exp(-dy * dy) * math.exp(-(dx * dx) / 900);
          x += (dx >= 0 ? 1 : -1) * 22 * pull;
        }
        return x;
      }

      final path = Path()..moveTo(xAt(0), 0);
      for (var y = 8.0; y <= h; y += 8) {
        path.lineTo(xAt(y), y);
      }
      final dark = random.nextDouble() < 0.78;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6 + random.nextDouble() * 1.8
          ..color = dark
              ? const Color(0xFF2A1206)
                    .withValues(alpha: 0.12 + random.nextDouble() * 0.2)
              : const Color(0xFFF0C08A)
                    .withValues(alpha: 0.05 + random.nextDouble() * 0.08),
      );
    }

    for (final knot in knots) {
      canvas.drawOval(
        Rect.fromCenter(center: knot, width: 9, height: 16),
        Paint()..color = const Color(0xCC2A1206),
      );
      for (var ring = 1; ring <= 4; ring++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: knot,
            width: 9 + ring * 6.0,
            height: 16 + ring * 11.0,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFF2A1206)
                .withValues(alpha: 0.3 - ring * 0.05),
        );
      }
    }

    // Junta transversal entre dos piezas del tablón.
    if (random.nextDouble() < 0.5) {
      final y = random.nextDouble() * h;
      canvas.drawLine(
        Offset(x0, y),
        Offset(x0 + plank, y),
        Paint()
          ..color = const Color(0xAA1A0B04)
          ..strokeWidth = 2,
      );
    }
    canvas
      ..restore()
      // Junta entre tablones, con su canto iluminado.
      ..drawLine(
        Offset(x0, 0),
        Offset(x0, h),
        Paint()
          ..color = const Color(0xDD180A03)
          ..strokeWidth = 2.6,
      )
      ..drawLine(
        Offset(x0 + 2.2, 0),
        Offset(x0 + 2.2, h),
        Paint()
          ..color = const Color(0x33FFD9A8)
          ..strokeWidth = 1,
      );
  }
  return recorder.endRecording();
}

/// Pasto del prado: una baldosa que se repite sin costuras.
ui.Image? _grassTexture;
bool _grassBaked = false;

const _grassTile = 512.0;

/// Unidades del mundo que cubre cada píxel de la baldosa.
const _grassScale = 1.7;

ui.Picture _paintGrass() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final random = math.Random(8);
  const size = _grassTile;
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0xFF5E9E3A),
  );
  // Dibuja algo también del otro lado de los bordes, para que se repita sin
  // que se note la costura.
  void wrapped(Offset at, void Function(Offset at) draw) {
    for (final dx in [-size, 0.0, size]) {
      for (final dy in [-size, 0.0, size]) {
        draw(at + Offset(dx, dy));
      }
    }
  }

  for (var i = 0; i < 46; i++) {
    final at = Offset(random.nextDouble() * size, random.nextDouble() * size);
    final radius = 30 + random.nextDouble() * 80;
    final paint = Paint()
      ..color =
          (random.nextBool()
                  ? const Color(0xFF477F28)
                  : const Color(0xFF86C24F))
              .withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    wrapped(at, (p) => canvas.drawCircle(p, radius, paint));
  }
  for (var i = 0; i < 2800; i++) {
    final at = Offset(random.nextDouble() * size, random.nextDouble() * size);
    final length = 5 + random.nextDouble() * 12;
    final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * 1.3;
    final tip = Offset(math.cos(angle), math.sin(angle)) * length;
    final paint = Paint()
      ..strokeWidth = 1.1 + random.nextDouble() * 0.8
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(
        const Color(0xFF356B1F),
        const Color(0xFFB2E06A),
        random.nextDouble(),
      )!.withValues(alpha: 0.6);
    wrapped(at, (p) => canvas.drawLine(p, p + tip, paint));
  }
  const flowers = [
    Color(0xFFFFFFFF),
    Color(0xFFFFE15A),
    Color(0xFFFFB3D1),
    Color(0xFFC7A6FF),
  ];
  for (var i = 0; i < 46; i++) {
    final at = Offset(random.nextDouble() * size, random.nextDouble() * size);
    final paint = Paint()..color = flowers[random.nextInt(flowers.length)];
    wrapped(at, (p) => canvas.drawCircle(p, 1.8, paint));
  }
  return recorder.endRecording();
}

Paint _grassPaint() {
  if (!_grassBaked) {
    _grassBaked = true;
    _grassTexture = _bake(_paintGrass, const Size(_grassTile, _grassTile));
  }
  final image = _grassTexture;
  if (image == null) return Paint()..color = const Color(0xFF5E9E3A);
  return Paint()
    ..shader = ImageShader(
      image,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.diagonal3Values(_grassScale, _grassScale, 1).storage,
      filterQuality: FilterQuality.medium,
    );
}

// -------------------------------------------------------------- Paisaje

/// Una cordillera: puntos de su cresta, a la distancia [z].
List<_V3> _ridge({
  required int seed,
  required double z,
  required double halfWidth,
  required double step,
  required double base,
  required double amplitude,
  required double frequency,
  required bool sharp,
}) {
  final random = math.Random(seed);
  final waves = [
    for (var i = 0; i < 4; i++)
      (
        f: frequency * math.pow(2.1, i) * (0.8 + random.nextDouble() * 0.4),
        p: random.nextDouble() * math.pi * 2,
        a: 1 / math.pow(1.9, i),
      ),
  ];
  final total = waves.fold(0.0, (sum, w) => sum + w.a);
  return [
    for (var x = -halfWidth; x <= halfWidth; x += step)
      () {
        var h = 0.0;
        for (final w in waves) {
          final s = math.sin(x * w.f + w.p);
          // Picos afilados para las montañas; lomas suaves para las colinas.
          h += w.a * (sharp ? math.pow(1 - s.abs(), 1.6) : (s + 1) / 2);
        }
        return (x: x, y: _groundY - (base + amplitude * h / total), z: z);
      }(),
  ];
}

final _mountains = _ridge(
  seed: 3,
  z: 70000,
  halfWidth: 260000,
  step: 2400,
  base: 4000,
  amplitude: 11000,
  frequency: 0.00004,
  sharp: true,
);

final _hills = _ridge(
  seed: 9,
  z: 36000,
  halfWidth: 160000,
  step: 2000,
  base: 600,
  amplitude: 3200,
  frequency: 0.00006,
  sharp: false,
);

/// Pinos de la orilla lejana, de atrás hacia delante.
final _pines = () {
  final random = math.Random(4);
  final pines = <({double x, double z, double height, int shade})>[];
  for (var x = -90000.0; x <= 90000; x += 420 + random.nextDouble() * 520) {
    pines.add((
      x: x,
      z: _farShoreZ + 300 + random.nextDouble() * 1600,
      height: 800 + random.nextDouble() * 1100,
      shade: random.nextInt(3),
    ));
  }
  return pines..sort((a, b) => b.z.compareTo(a.z));
}();

/// Silueta del bosque (copas y base), para rellenar huecos y para reflejarla.
final _forestSkyline = () {
  final byX = [..._pines]..sort((a, b) => a.x.compareTo(b.x));
  return <_V3>[
    (x: byX.first.x, y: _groundY + 5, z: _farShoreZ + 200),
    for (final pine in byX) ...[
      (
        x: pine.x - pine.height * 0.2,
        y: _groundY - pine.height * 0.3,
        z: pine.z,
      ),
      (x: pine.x, y: _groundY - pine.height, z: pine.z),
      (
        x: pine.x + pine.height * 0.2,
        y: _groundY - pine.height * 0.3,
        z: pine.z,
      ),
    ],
    (x: byX.last.x, y: _groundY + 5, z: _farShoreZ + 200),
  ];
}();

/// Nubes: grupos de bolas suaves a gran altura.
final _clouds = () {
  final random = math.Random(21);
  return [
    for (var i = 0; i < 16; i++)
      (
        x: -120000 + i * 15000 + random.nextDouble() * 7000,
        y: -11000 - random.nextDouble() * 7000,
        z: 45000 + random.nextDouble() * 40000,
        puffs: [
          for (var k = 0; k < 7; k++)
            (
              dx: (k - 3) * 1700 + random.nextDouble() * 900,
              dy: -random.nextDouble() * 1100 + (k - 3).abs() * 260,
              radius: 1300 + random.nextDouble() * 1400 - (k - 3).abs() * 180,
            ),
        ],
      ),
  ];
}();

/// Matas de hierba con flores alrededor de la mesa.
final _tufts = () {
  final random = math.Random(13);
  const flowers = [
    Color(0xFFFFFFFF),
    Color(0xFFFFE15A),
    Color(0xFFFF8FB8),
    Color(0xFFB892FF),
    Color(0xFFFF7A4D),
  ];
  return [
    for (var i = 0; i < 520; i++)
      (
        x: (random.nextDouble() - 0.5) * 16000,
        z: -6000 + random.nextDouble() * (_shoreZ - 300 + 6000),
        height: 50 + random.nextDouble() * 70,
        blades: 3 + random.nextInt(4),
        seed: random.nextDouble() * 100,
        flower: random.nextDouble() < 0.35
            ? flowers[random.nextInt(flowers.length)]
            : null,
      ),
  ]..sort((a, b) => b.z.compareTo(a.z));
}();

/// Juncos en la orilla del lago.
final _reeds = () {
  final random = math.Random(17);
  return [
    for (var i = 0; i < 140; i++)
      (
        x: (random.nextDouble() - 0.5) * 30000,
        z: _shoreZ - 120 + random.nextDouble() * 260,
        height: 220 + random.nextDouble() * 280,
        lean: (random.nextDouble() - 0.5) * 0.5,
        cattail: random.nextDouble() < 0.4,
      ),
  ]..sort((a, b) => b.z.compareTo(a.z));
}();

/// Destellos sobre el agua.
final _glints = () {
  final random = math.Random(29);
  return [
    for (var i = 0; i < 320; i++)
      (
        x: (random.nextDouble() - 0.5) * 40000,
        z:
            _shoreZ +
            200 +
            math.pow(random.nextDouble(), 1.6) * (_farShoreZ - _shoreZ - 400),
        phase: random.nextDouble() * math.pi * 2,
        speed: 1.5 + random.nextDouble() * 3,
      ),
  ];
}();

/// Cielo, sol, nubes, montañas, colinas, bosque, lago con sus reflejos y el
/// prado. Va un poco desenfocado, como el fondo de una toma de cine.
class _LandscapePainter extends CustomPainter {
  const _LandscapePainter({required this.camera, required this.seconds});

  final _Camera camera;

  /// Tiempo de la toma, para nubes y destellos.
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = camera.horizonY;
    final full = Offset.zero & size;

    // Cielo.
    canvas.drawRect(
      full,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_skyTop, Color(0xFF79B9F2), _skyHorizon],
              stops: [0, 0.62, 1],
            ).createShader(
              Rect.fromLTRB(
                0,
                horizon - size.height * 1.3,
                size.width,
                horizon + 1,
              ),
            ),
    );

    // Sol y su resplandor (aunque esté fuera de cuadro, su luz entra).
    final sun = camera.projectDirection(_toSun);
    if (sun != null) {
      final glow = size.longestSide * 0.95;
      canvas
        ..drawCircle(
          sun,
          glow,
          Paint()
            ..shader = RadialGradient(
              colors: const [
                Color(0xCCFFF8E1),
                Color(0x66FFE9B5),
                Color(0x00FFE9B5),
              ],
              stops: const [0, 0.16, 1],
            ).createShader(Rect.fromCircle(center: sun, radius: glow)),
        )
        ..drawCircle(
          sun,
          math.max(14, size.shortestSide * 0.035),
          Paint()
            ..color = const Color(0xFFFFFDF4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
    }

    _paintClouds(canvas);

    // Tierra lejana bajo las montañas.
    camera.drawPlane(
      canvas,
      _horizontal(_groundY),
      const Rect.fromLTRB(-400000, _farShoreZ, 400000, 120000),
      (c) => c.drawRect(
        const Rect.fromLTRB(-400000, _farShoreZ, 400000, 120000),
        Paint()
          ..color = Color.lerp(const Color(0xFF557E54), _skyHorizon, 0.45)!,
      ),
    );

    final mountainColor = Color.lerp(
      const Color(0xFF5D7FA6),
      _skyHorizon,
      0.38,
    )!;
    final hillColor = Color.lerp(const Color(0xFF3F7A55), _skyHorizon, 0.32)!;
    final forestColor = Color.lerp(const Color(0xFF1C4A2A), _skyHorizon, 0.18)!;
    _paintRange(canvas, _mountains, mountainColor, snow: true);
    _paintRange(canvas, _hills, hillColor);
    _paintForest(canvas, forestColor);

    // Prado hasta la orilla, con una franja de arena.
    const meadow = Rect.fromLTRB(-400000, -14000, 400000, _shoreZ + 60);
    camera.drawPlane(canvas, _horizontal(_groundY), meadow, (c) {
      c
        ..drawRect(meadow, _grassPaint())
        // Luz cálida de la tarde y bruma hacia la orilla.
        ..drawRect(
          meadow,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x00FFE7A8),
                const Color(0x00FFE7A8),
                const Color(0xFFFFE7A8).withValues(alpha: 0.16),
              ],
              stops: const [0, 0.7, 1],
            ).createShader(meadow),
        )
        ..drawRect(
          const Rect.fromLTRB(-400000, _shoreZ - 300, 400000, _shoreZ + 60),
          Paint()
            ..shader =
                const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00D9C894),
                    Color(0xFFD9C894),
                    Color(0xFFA8956A),
                  ],
                  stops: [0, 0.35, 1],
                ).createShader(
                  const Rect.fromLTRB(
                    -400000,
                    _shoreZ - 300,
                    400000,
                    _shoreZ + 60,
                  ),
                ),
        );
      _paintCloudShadows(c);
    });

    _paintTableShadow(canvas);
    _paintLake(canvas, mountainColor, hillColor, forestColor);
    _paintReeds(canvas);
    _paintTufts(canvas);
  }

  void _paintClouds(Canvas canvas) {
    final drift = seconds * 260;
    for (final cloud in _clouds) {
      // Al salir por un lado vuelven a entrar por el otro, lejos de cuadro.
      final x = (cloud.x + drift + 130000) % 260000 - 130000;
      // Base gris azulada, cuerpo blanco y el borde que mira al sol, cálido.
      for (final (dx, dy, color, blur) in const [
        (0.0, 300.0, Color(0xFFC9D6E6), 0.3),
        (0.0, 0.0, Color(0xF2FFFFFF), 0.22),
        (-380.0, -260.0, Color(0x99FFF4DC), 0.35),
      ]) {
        for (final puff in cloud.puffs) {
          final p = (
            x: x + puff.dx + dx,
            y: cloud.y + puff.dy + dy,
            z: cloud.z,
          );
          final at = camera.project(p);
          if (at == null) continue;
          final radius =
              camera.scaleAt(p) * puff.radius * (dx == 0 ? 1.0 : 0.7);
          if (radius < 1) continue;
          canvas.drawCircle(
            at,
            radius,
            Paint()
              ..color = color
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * blur),
          );
        }
      }
    }
  }

  List<_V3> _closed(List<_V3> ridge) => [
    ...ridge,
    (x: ridge.last.x, y: _groundY + 5, z: ridge.last.z),
    (x: ridge.first.x, y: _groundY + 5, z: ridge.first.z),
  ];

  _V3 _mirror(_V3 p) => (x: p.x, y: 2 * _groundY - p.y, z: p.z);

  void _fill(Canvas canvas, List<Offset> polygon, Paint paint) {
    if (polygon.length < 3) return;
    canvas.drawPath(Path()..addPolygon(polygon, true), paint);
  }

  void _paintRange(
    Canvas canvas,
    List<_V3> ridge,
    Color color, {
    bool snow = false,
  }) {
    final shape = camera.projectPolygon(_closed(ridge));
    if (shape.length < 3) return;
    final bounds = (Path()..addPolygon(shape, true)).getBounds();
    _fill(
      canvas,
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.black, 0.08)!,
            Color.lerp(color, _skyHorizon, 0.35)!,
          ],
        ).createShader(bounds),
    );
    // Laderas: las que miran al sol (a la izquierda) más claras, las otras
    // en sombra; así se ve el relieve de la roca.
    for (var i = 0; i + 1 < ridge.length; i++) {
      final a = ridge[i], b = ridge[i + 1];
      final rise = (a.y - b.y) / (b.x - a.x);
      if (rise.abs() < 0.05) continue;
      final depth = (_groundY - math.min(a.y, b.y)) * 0.3;
      final face = camera.projectPolygon([
        a,
        b,
        (x: b.x, y: b.y + depth, z: b.z),
        (x: a.x, y: a.y + depth, z: a.z),
      ]);
      if (face.length < 3) continue;
      final tint = rise > 0 ? const Color(0xFFFFF1D6) : const Color(0xFF1E2A3A);
      // Fuerte junto a la cresta y desvaneciéndose ladera abajo.
      _fill(
        canvas,
        face,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tint.withValues(alpha: math.min(0.22, rise.abs() * 0.18)),
              tint.withValues(alpha: 0),
            ],
          ).createShader((Path()..addPolygon(face, true)).getBounds())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    if (!snow) return;
    // Nieve en las cumbres más altas.
    const line = _groundY - 11500;
    final run = <_V3>[];
    void flush() {
      if (run.length >= 2) {
        final cap = [
          ...run,
          for (final p in run.reversed)
            (x: p.x, y: p.y + math.min(1600, line - p.y) * 0.7, z: p.z),
        ];
        _fill(
          canvas,
          camera.projectPolygon(cap),
          Paint()..color = const Color(0xFFF2F7FF).withValues(alpha: 0.9),
        );
      }
      run.clear();
    }

    for (final p in ridge) {
      if (p.y < line) {
        run.add(p);
      } else {
        flush();
      }
    }
    flush();
  }

  void _paintForest(Canvas canvas, Color color) {
    _fill(
      canvas,
      camera.projectPolygon(_forestSkyline),
      Paint()..color = color,
    );
    final width = camera.screen.dx * 2;
    for (final pine in _pines) {
      final base = (x: pine.x, y: _groundY, z: pine.z);
      final at = camera.project(base);
      if (at == null || at.dx < -200 || at.dx > width + 200) continue;
      final height = camera.scaleAt(base) * pine.height;
      if (height < 1) continue;
      final dark = Color.lerp(color, Colors.black, 0.05 + pine.shade * 0.07)!;
      final lit = Color.lerp(dark, const Color(0xFFA9C97A), 0.3)!;
      _paintPine(canvas, at, height, pine.x, dark, lit);
    }
  }

  /// Un pino de verdad: tronco, capas de ramas que cuelgan con puntas
  /// irregulares, el lado del sol más claro y un leve vaivén con el viento.
  void _paintPine(
    Canvas canvas,
    Offset base,
    double height,
    double seed,
    Color dark,
    Color lit,
  ) {
    final random = math.Random(seed.round());
    final halfWidth = height * (0.2 + random.nextDouble() * 0.06);
    // El viento mueve más la copa que la base.
    final sway = math.sin(seconds * 0.7 + seed * 0.013) * height * 0.012;
    Offset at(double side, double up) =>
        base + Offset(side * halfWidth + sway * up * up, -height * up);

    canvas.drawLine(
      at(0, 0),
      at(0, 0.18),
      Paint()
        ..color = const Color(0xFF3B2A1E)
        ..strokeWidth = math.max(1, halfWidth * 0.14),
    );

    // Silueta: de la punta hacia abajo por la izquierda y de vuelta por la
    // derecha. Cada capa sale hacia fuera, cuelga y se mete hacia el tronco.
    const tiers = 7;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < tiers; i++) {
      final up = 1 - (i + 1) / tiers * 0.9;
      final spread = math.pow((i + 1) / tiers, 0.85).toDouble();
      final droop = 0.025 + random.nextDouble() * 0.02;
      final notch = up + 0.05;
      for (final (points, side) in [(left, -1.0), (right, 1.0)]) {
        final jitter = 0.85 + random.nextDouble() * 0.3;
        points
          ..add(at(side * spread * 0.45, notch))
          ..add(at(side * spread * jitter, up - droop));
      }
    }
    final crown = Path()..moveTo(at(0, 1).dx, at(0, 1).dy);
    for (final p in left) {
      crown.lineTo(p.dx, p.dy);
    }
    final trunkTop = at(0, 0.12);
    crown.lineTo(trunkTop.dx, trunkTop.dy);
    for (final p in right.reversed) {
      crown.lineTo(p.dx, p.dy);
    }
    crown.close();

    final bounds = crown.getBounds();
    canvas
      ..drawPath(
        crown,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(dark, lit, 0.35)!, dark],
          ).createShader(bounds),
      )
      // La mitad que mira al sol (a la izquierda), más clara.
      ..save()
      ..clipRect(Rect.fromLTRB(bounds.left, bounds.top, base.dx, bounds.bottom))
      ..drawPath(
        crown,
        Paint()
          ..shader = LinearGradient(
            colors: [lit.withValues(alpha: 0.75), lit.withValues(alpha: 0)],
          ).createShader(bounds),
      )
      ..restore();
  }

  /// Sombra de la mesa sobre el pasto.
  void _paintTableShadow(Canvas canvas) {
    final corners = [
      for (final (x, z) in [
        (-_tableHalfWidth, _tableNear),
        (_tableHalfWidth, _tableNear),
        (_tableHalfWidth, _tableFar),
        (-_tableHalfWidth, _tableFar),
      ])
        _sunShadow((x: x, y: 0, z: z), _groundY),
    ];
    _fill(
      canvas,
      camera.projectPolygon(corners),
      Paint()
        ..color = const Color(0x5A0E2A08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _paintLake(
    Canvas canvas,
    Color mountainColor,
    Color hillColor,
    Color forestColor,
  ) {
    const lake = Rect.fromLTRB(-400000, _shoreZ, 400000, _farShoreZ + 260);
    final outline = camera.projectPolygon([
      (x: lake.left, y: _groundY, z: lake.top),
      (x: lake.right, y: _groundY, z: lake.top),
      (x: lake.right, y: _groundY, z: lake.bottom),
      (x: lake.left, y: _groundY, z: lake.bottom),
    ]);
    if (outline.length < 3) return;

    camera.drawPlane(canvas, _horizontal(_groundY), lake, (c) {
      c.drawRect(
        lake,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C6283),
              Color(0xFF2E7FA6),
              Color(0xFF6DB0D8),
              Color(0xFFB6DDF3),
            ],
            stops: [0, 0.12, 0.45, 1],
          ).createShader(lake),
      );
    });

    // Reflejos: el paisaje volteado bajo la línea del agua.
    const water = Color(0xFF3F8DB8);
    canvas
      ..save()
      ..clipPath(Path()..addPolygon(outline, true));
    for (final (ridge, color, alpha) in [
      (_mountains, mountainColor, 0.45),
      (_hills, hillColor, 0.6),
    ]) {
      _fill(
        canvas,
        camera.projectPolygon([for (final p in _closed(ridge)) _mirror(p)]),
        Paint()
          ..color = Color.lerp(color, water, 0.4)!.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    _fill(
      canvas,
      camera.projectPolygon([for (final p in _forestSkyline) _mirror(p)]),
      Paint()
        ..color = Color.lerp(forestColor, water, 0.3)!.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Ondas: líneas claras que se acercan despacio.
    const spacing = 260.0;
    final shift = (seconds * 40) % spacing;
    for (
      var z = _shoreZ + shift;
      z < _farShoreZ;
      z += spacing * (1 + (z - _shoreZ) / 2500)
    ) {
      final band = 4 + (z - _shoreZ) * 0.004;
      _fill(
        canvas,
        camera.projectPolygon([
          (x: -400000, y: _groundY, z: z),
          (x: 400000, y: _groundY, z: z),
          (x: 400000, y: _groundY, z: z + band),
          (x: -400000, y: _groundY, z: z + band),
        ]),
        Paint()..color = const Color(0x1FFFFFFF),
      );
    }

    // Ráfagas de viento sobre el agua: manchas más oscuras y rizadas que
    // cruzan el lago despacio.
    camera.drawPlane(canvas, _horizontal(_groundY), lake, (c) {
      for (var k = 0; k < 5; k++) {
        final x = (seconds * 320 + k * 13000) % 65000 - 32500;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, _shoreZ + 1500 + k * 1900.0),
            width: 9000 + k * 1500,
            height: 900 + k * 260,
          ),
          Paint()
            ..color = const Color(0x22052640)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 300),
        );
      }
    });

    // Destellos del sol, más intensos en el camino de luz hacia el sol.
    final eye = camera.position;
    final sunAzimuth = math.atan2(_toSun.x, _toSun.z);
    for (final glint in _glints) {
      final p = (x: glint.x, y: _groundY, z: glint.z);
      final at = camera.project(p);
      if (at == null) continue;
      final azimuth = math.atan2(p.x - eye.x, p.z - eye.z);
      final path = math.exp(-math.pow((azimuth - sunAzimuth) / 0.16, 2));
      final twinkle = math.max(
        0.0,
        math.sin(seconds * glint.speed + glint.phase),
      );
      final alpha = (0.12 + 0.88 * path) * twinkle;
      if (alpha < 0.03) continue;
      final length = math.max(1.5, camera.scaleAt(p) * 120);
      canvas.drawLine(
        at - Offset(length / 2, 0),
        at + Offset(length / 2, 0),
        Paint()
          ..color = const Color(0xFFFFFBEA).withValues(alpha: alpha)
          ..strokeWidth = math.max(1, length * 0.08)
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();

    // Espuma suave en la orilla.
    _fill(
      canvas,
      camera.projectPolygon([
        (x: -400000, y: _groundY, z: _shoreZ),
        (x: 400000, y: _groundY, z: _shoreZ),
        (x: 400000, y: _groundY, z: _shoreZ + 40),
        (x: -400000, y: _groundY, z: _shoreZ + 40),
      ]),
      Paint()..color = const Color(0x66FFFFFF),
    );
  }

  /// Fuerza del viento en [x]: ráfagas que recorren el prado de izquierda a
  /// derecha (0.6 en calma, hasta 1.6 en lo más fuerte).
  double _gust(double x) =>
      0.6 + math.max(0, math.sin(seconds * 0.9 - x * 0.0006)) * 1.0;

  /// Sombras de las nubes que pasan sobre el prado.
  void _paintCloudShadows(Canvas c) {
    for (var k = 0; k < 3; k++) {
      final x = (seconds * 260 + k * 21000) % 63000 - 31500;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, 3000.0 - k * 5000),
          width: 14000,
          height: 7000,
        ),
        Paint()
          ..color = const Color(0x2A0B2A10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1800),
      );
    }
  }

  void _paintReeds(Canvas canvas) {
    for (final reed in _reeds) {
      final base = (x: reed.x, y: _groundY, z: reed.z);
      final scale = camera.scaleAt(base);
      if (scale * reed.height < 2) continue;
      final sway = math.sin(seconds * 1.3 + reed.x) * 0.06 * _gust(reed.x);
      final top = (
        x: reed.x + reed.height * (reed.lean + sway),
        y: _groundY - reed.height,
        z: reed.z,
      );
      final a = camera.project(base), b = camera.project(top);
      if (a == null || b == null) continue;
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFF4E7A2C)
          ..strokeWidth = math.max(1, scale * 9)
          ..strokeCap = StrokeCap.round,
      );
      if (reed.cattail) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.lerp(a, b, 0.86)!,
            width: math.max(1.5, scale * 16),
            height: math.max(3, scale * 60),
          ),
          Paint()..color = const Color(0xFF6B4423),
        );
      }
    }
  }

  void _paintTufts(Canvas canvas) {
    for (final tuft in _tufts) {
      final base = (x: tuft.x, y: _groundY, z: tuft.z);
      final scale = camera.scaleAt(base);
      if (scale * tuft.height < 2.5) continue;
      final a = camera.project(base);
      if (a == null) continue;
      final blade = Paint()
        ..strokeWidth = math.max(1, scale * 5)
        ..strokeCap = StrokeCap.round;
      Offset? tip;
      for (var k = 0; k < tuft.blades; k++) {
        final spread = (k / (tuft.blades - 1) - 0.5) * 0.9;
        final sway =
            math.sin(seconds * 2 + tuft.seed + k) * 0.08 * _gust(tuft.x) +
            // La ráfaga además las inclina hacia un lado.
            0.12 * (_gust(tuft.x) - 0.6);
        final end = camera.project((
          x: tuft.x + tuft.height * (spread + sway),
          y: _groundY - tuft.height * (0.75 + 0.25 * math.cos(spread)),
          z: tuft.z,
        ));
        if (end == null) continue;
        blade.color = Color.lerp(
          const Color(0xFF3F7A24),
          const Color(0xFF9CD15A),
          (k / tuft.blades + tuft.seed) % 1,
        )!;
        canvas.drawLine(a, end, blade);
        tip ??= end;
      }
      final flower = tuft.flower;
      if (flower != null && tip != null) {
        canvas.drawCircle(
          tip,
          math.max(1.2, scale * 9),
          Paint()..color = flower,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) => true;
}

// -------------------------------------------------------------- Mesa

/// Mesa de madera con sus patas, el reflejo del sol en el barniz y la sombra
/// de la Pokédex.
class _TableTopPainter extends CustomPainter {
  const _TableTopPainter({
    required this.camera,
    required this.shadow,
    required this.glow,
    required this.glowAt,
  });

  final _Camera camera;
  final _Shadow shadow;

  /// Brillo de la pantalla encendida sobre la mesa, y dónde cae.
  final double glow;
  final Offset glowAt;

  @override
  void paint(Canvas canvas, Size size) {
    _paintLegs(canvas);

    camera.drawPlane(canvas, _horizontal(0), _woodRect, (c) {
      _drawWood(c);

      // Luz de la tarde: cálida, más tenue hacia los bordes.
      c.drawRect(
        _woodRect,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  const Color(0xFFFFE2A8).withValues(alpha: 0.14),
                  const Color(0x00000000),
                  const Color(0x33000000),
                ],
                stops: const [0, 0.5, 1],
              ).createShader(
                Rect.fromCircle(center: const Offset(0, 300), radius: 2000),
              ),
      );

      _paintReflection(c);
      _paintShadow(c);

      if (glow > 0) {
        c.drawCircle(
          glowAt,
          520,
          Paint()
            ..shader = RadialGradient(
              colors: [
                const Color(0xFF8FE3FF).withValues(alpha: 0.16 * glow),
                const Color(0x008FE3FF),
              ],
            ).createShader(Rect.fromCircle(center: glowAt, radius: 520)),
        );
      }

      // Canto redondeado del borde cercano, que atrapa la luz.
      const bevel = Rect.fromLTRB(
        -_tableHalfWidth,
        _tableNear,
        _tableHalfWidth,
        _tableNear + 14,
      );
      c.drawRect(
        bevel,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00FFE2B0), Color(0x55FFE2B0)],
          ).createShader(bevel),
      );
    });

    // Canto del tablero, de cara a la cámara (a contraluz, algo oscuro).
    const edge = Rect.fromLTRB(
      -_tableHalfWidth,
      0,
      _tableHalfWidth,
      _tableThickness,
    );
    camera.drawPlane(
      canvas,
      Matrix4.translationValues(0, 0, _tableNear),
      edge,
      (c) {
        c
          ..drawRect(
            edge,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6A4020),
                  Color(0xFF4A2A14),
                  Color(0xFF2E190A),
                ],
              ).createShader(edge),
          )
          ..drawLine(
            const Offset(-_tableHalfWidth, 1.5),
            const Offset(_tableHalfWidth, 1.5),
            Paint()
              ..color = const Color(0x88FFE2B0)
              ..strokeWidth = 3,
          );
        // Las testas de los tablones.
        const plank = _tableHalfWidth * 2 / 19;
        final seam = Paint()
          ..color = const Color(0x88000000)
          ..strokeWidth = 2.5;
        for (var x = -_tableHalfWidth; x <= _tableHalfWidth; x += plank) {
          c.drawLine(Offset(x, 4), Offset(x, _tableThickness), seam);
        }
      },
    );
  }

  /// Cuatro patas de madera hasta el pasto.
  void _paintLegs(Canvas canvas) {
    const half = 50.0;
    const leg = Rect.fromLTRB(-half, _tableThickness, half, _groundY);
    for (final z in [_tableFar - 140, _tableNear + 140]) {
      for (final x in [-_tableHalfWidth + 160, _tableHalfWidth - 160]) {
        camera.drawPlane(canvas, Matrix4.translationValues(x, 0, z), leg, (c) {
          c.drawRect(
            leg,
            Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF7A4A24),
                  Color(0xFF5A3418),
                  Color(0xFF3A200C),
                ],
              ).createShader(leg),
          );
        });
      }
    }
  }

  /// Reflejo alargado del sol en el barniz, donde lo vería la cámara.
  void _paintReflection(Canvas canvas) {
    final eye = camera.position;
    final down = -_toSun.y;
    final t = -eye.y / down;
    if (t <= 0) return;
    final spot = Offset(eye.x + _toSun.x * t, eye.z + _toSun.z * t);
    final oval = Rect.fromCenter(center: spot, width: 420, height: 1300);
    canvas.drawOval(
      oval,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x2EFFF6DC), Color(0x00FFF6DC)],
        ).createShader(oval),
    );
  }

  /// Sombra que se difumina y aclara al alejarse de la mesa, y una sombra
  /// de contacto cuando está apoyada.
  void _paintShadow(Canvas canvas) {
    final path = shadow.outline;
    final lift = (shadow.height / 700).clamp(0.0, 1.0);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1A0C02)
            .withValues(alpha: 0.5 * (1 - lift * 0.7))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 40 * lift),
    );
    // Oclusión de contacto: un halo oscuro y ceñido que asienta la Pokédex
    // sobre la madera.
    final contact = (1 - shadow.height / 70).clamp(0.0, 1.0);
    if (contact > 0) {
      canvas
        ..drawPath(
          path,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.4 * contact)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        )
        ..drawPath(
          path,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.55 * contact)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
    }
  }

  @override
  bool shouldRepaint(_TableTopPainter oldDelegate) => true;
}

// -------------------------------------------------------------- Atmósfera

/// Rayos de sol, destellos de lente, polen flotando, mariposas y pájaros.
class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter({required this.camera, required this.seconds});

  final _Camera camera;

  /// Tiempo de la toma.
  final double seconds;

  static final _pollen = () {
    final random = math.Random(5);
    return [
      for (var i = 0; i < 60; i++)
        (
          x: (random.nextDouble() - 0.5) * 3600,
          y: -80 - random.nextDouble() * 1300,
          z: -800 + random.nextDouble() * 2600,
          speed: 0.4 + random.nextDouble() * 0.8,
          size: 0.6 + random.nextDouble() * 1.0,
          phase: random.nextDouble() * math.pi * 2,
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final sun = camera.projectDirection(_toSun);
    if (sun != null) _paintSunRays(canvas, size, sun);
    _paintBirds(canvas);
    _paintButterflies(canvas);
    _paintPollen(canvas);
    if (sun != null) _paintFlare(canvas, size, sun);

    // Viñeta suave.
    final full = Offset.zero & size;
    canvas.drawRect(
      full,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.9,
          colors: [Color(0x00000000), Color(0x40000000)],
          stops: [0.55, 1],
        ).createShader(full),
    );
  }

  /// Haces de luz que salen del sol hacia la escena.
  void _paintSunRays(Canvas canvas, Size size, Offset sun) {
    final reach = size.longestSide * 1.6;
    final toCenter = size.center(Offset.zero) - sun;
    final main = math.atan2(toCenter.dy, toCenter.dx);
    for (var i = 0; i < 7; i++) {
      final angle = main + (i - 3) * 0.16 + math.sin(seconds * 0.3 + i) * 0.03;
      final spread = 0.035 + (i % 3) * 0.02;
      final a =
          sun +
          Offset(math.cos(angle - spread), math.sin(angle - spread)) * reach;
      final b =
          sun +
          Offset(math.cos(angle + spread), math.sin(angle + spread)) * reach;
      // Muy difuminados: la luz no tiene bordes.
      canvas.drawPath(
        Path()..addPolygon([sun, a, b], true),
        Paint()
          ..blendMode = BlendMode.screen
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            size.shortestSide * 0.05,
          )
          ..shader = ui.Gradient.radial(sun, reach * 0.8, [
            const Color(0x1CFFF1C8),
            const Color(0x00FFF1C8),
          ]),
      );
    }
  }

  /// Destellos de lente en la línea del sol al centro de la imagen.
  void _paintFlare(Canvas canvas, Size size, Offset sun) {
    final rect = (Offset.zero & size).inflate(size.shortestSide * 0.3);
    if (!rect.contains(sun)) return;
    final center = size.center(Offset.zero);
    for (final (k, radius, color) in [
      (0.35, 0.05, const Color(0x22FFE0A0)),
      (0.7, 0.025, const Color(0x2290FFB0)),
      (1.15, 0.08, const Color(0x1890C8FF)),
      (1.5, 0.035, const Color(0x22D0A0FF)),
      (1.9, 0.12, const Color(0x12FFFFFF)),
    ]) {
      final at = Offset.lerp(sun, center, k)!;
      final r = size.shortestSide * radius;
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..blendMode = BlendMode.screen
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
      );
    }
  }

  void _paintBirds(Canvas canvas) {
    for (var k = 0; k < 4; k++) {
      final p = (
        // Cruzan el cielo y, un rato después, vuelven a pasar.
        x: -26000 + seconds * 1100 % 70000 + k * 1500,
        y: -5200 - k * 520 + math.sin(seconds * 0.8 + k) * 200,
        z: 24000.0 + k * 900,
      );
      final at = camera.project(p);
      if (at == null) continue;
      final span = math.max(3, camera.scaleAt(p) * 520);
      final flap = math.sin(seconds * 7 + k * 1.7) * span * 0.35;
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - span, at.dy - flap)
          ..quadraticBezierTo(
            at.dx - span * 0.4,
            at.dy - flap * 0.2,
            at.dx,
            at.dy,
          )
          ..quadraticBezierTo(
            at.dx + span * 0.4,
            at.dy - flap * 0.2,
            at.dx + span,
            at.dy - flap,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, span * 0.12)
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xCC2A3340),
      );
    }
  }

  void _paintButterflies(Canvas canvas) {
    for (final (k, color) in [
      (0, const Color(0xFFFFA62B)),
      (1, const Color(0xFFFFF27A)),
    ]) {
      final t = seconds + k * 3.1;
      final p = (
        // Revolotean más allá de la mesa, nunca pegadas a la cámara.
        x: -1400 + k * 2600 + math.sin(t * 0.55) * 500,
        y: -380 - math.sin(t * 1.4) * 150 - k * 140,
        z: 1900 + math.cos(t * 0.45) * 500,
      );
      final at = camera.project(p);
      if (at == null) continue;
      final size = math.max(2, camera.scaleAt(p) * 28);
      final open = 0.25 + 0.75 * math.sin(t * 16).abs();
      final wing = Paint()..color = color;
      final edge = Paint()
        ..color = const Color(0xFF2B1A10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, size * 0.08);
      for (final side in [-1.0, 1.0]) {
        final upper = Rect.fromCenter(
          center: at + Offset(side * size * 0.55 * open, -size * 0.25),
          width: size * open,
          height: size * 0.9,
        );
        final lower = Rect.fromCenter(
          center: at + Offset(side * size * 0.4 * open, size * 0.3),
          width: size * 0.7 * open,
          height: size * 0.6,
        );
        canvas
          ..drawOval(upper, wing)
          ..drawOval(upper, edge)
          ..drawOval(lower, wing)
          ..drawOval(lower, edge);
      }
      canvas.drawLine(
        at - Offset(0, size * 0.5),
        at + Offset(0, size * 0.5),
        Paint()
          ..color = const Color(0xFF2B1A10)
          ..strokeWidth = math.max(0.8, size * 0.12),
      );
    }
  }

  void _paintPollen(Canvas canvas) {
    for (final mote in _pollen) {
      final p = (
        x: mote.x + math.sin(seconds * 0.5 * mote.speed + mote.phase) * 60,
        y: mote.y + math.sin(seconds * 0.35 + mote.phase) * 40,
        z: -800 + (mote.z + 800 + seconds * 20 * mote.speed) % 2600,
      );
      final at = camera.project(p);
      if (at == null) continue;
      final twinkle =
          0.5 + 0.5 * math.sin(seconds * 2.1 * mote.speed + mote.phase);
      final radius = math.max(0.6, mote.size * camera.scaleAt(p) * 2.4);
      canvas.drawCircle(
        at,
        radius,
        Paint()
          ..color = const Color(0xFFFFF4D2)
              .withValues(alpha: 0.15 + 0.45 * twinkle)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_AtmospherePainter oldDelegate) => true;
}
