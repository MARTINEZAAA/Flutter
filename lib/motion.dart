part of 'main.dart';

// Animación de cada Pokémon en la pantalla principal.
//
// Cada uno tiene un "perfil" propio que sale de sus datos:
// - Movimiento base según su tipo (los de fuego titilan, los de agua nadan,
//   los fantasmas se desvanecen...) o uno propio si es un Pokémon famoso.
// - Efectos de sus dos tipos (brasas, burbujas, rayos, hojas, nieve...).
// - Una acción especial cada pocos segundos según su mejor estadística:
//   rugido, giro, salto, embestida, carga de energía o escudo.
// - Ritmo según su velocidad, fuerza según su peso, estela si es muy rápido,
//   aura brillante con su silueta y rayos de luz si es legendario.
// Además aparece con un destello al abrirlo y proyecta sombra en el suelo.

enum _Motion {
  bounce,
  hop,
  flicker,
  swim,
  sway,
  spark,
  soar,
  levitate,
  haunt,
  stomp,
  glint,
  punch,
  wobble,
  prowl,
  majestic,
  float,
  flop,
  breathe,
  teleport,
  lazy,
  serpent,
}

/// Acción especial que hace de vez en cuando.
enum _Action { none, roar, spin, jump, dash, charge, brace, twirl, nod }

enum _Fx {
  embers,
  flames,
  bubbles,
  ripples,
  rain,
  splash,
  bolts,
  leaves,
  petals,
  pollen,
  snow,
  frost,
  rings,
  wisps,
  gas,
  sparkles,
  hearts,
  notes,
  zzz,
  question,
  toxic,
  rocks,
  wind,
  feathers,
  smoke,
  glints,
  rays,
}

/// Efectos que van detrás del Pokémon; el resto va delante.
const _backFx = {
  _Fx.flames,
  _Fx.ripples,
  _Fx.rings,
  _Fx.gas,
  _Fx.smoke,
  _Fx.rays,
};

/// Gesto propio de un Pokémon famoso.
class _Signature {
  const _Signature(this.motion, this.action, [this.fx = const []]);

  final _Motion motion;
  final _Action action;
  final List<_Fx> fx;
}

const _signatures = <int, _Signature>{
  1: _Signature(_Motion.sway, _Action.nod, [_Fx.leaves]), // Bulbasaur
  2: _Signature(_Motion.sway, _Action.nod, [_Fx.leaves, _Fx.petals]),
  3: _Signature(_Motion.stomp, _Action.roar, [_Fx.petals, _Fx.leaves]),
  4: _Signature(_Motion.flicker, _Action.jump, [_Fx.embers]), // Charmander
  5: _Signature(_Motion.flicker, _Action.dash, [_Fx.embers, _Fx.flames]),
  6: _Signature(_Motion.soar, _Action.roar, [_Fx.flames, _Fx.wind]),
  7: _Signature(_Motion.swim, _Action.spin, [_Fx.bubbles]), // Squirtle
  8: _Signature(_Motion.swim, _Action.spin, [_Fx.bubbles, _Fx.ripples]),
  9: _Signature(_Motion.stomp, _Action.charge, [_Fx.splash, _Fx.bubbles]),
  25: _Signature(_Motion.hop, _Action.jump, [_Fx.bolts]), // Pikachu
  26: _Signature(_Motion.hop, _Action.charge, [_Fx.bolts]),
  35: _Signature(_Motion.float, _Action.twirl, [_Fx.sparkles, _Fx.notes]),
  36: _Signature(_Motion.float, _Action.twirl, [_Fx.sparkles]),
  39: _Signature(_Motion.float, _Action.twirl, [_Fx.notes]), // Jigglypuff
  40: _Signature(_Motion.float, _Action.twirl, [_Fx.notes, _Fx.hearts]),
  54: _Signature(_Motion.wobble, _Action.nod, [_Fx.question]), // Psyduck
  63: _Signature(_Motion.teleport, _Action.charge, [_Fx.rings]), // Abra
  64: _Signature(_Motion.teleport, _Action.charge, [_Fx.rings]),
  65: _Signature(_Motion.teleport, _Action.charge, [_Fx.rings]),
  66: _Signature(_Motion.punch, _Action.dash), // Machop
  67: _Signature(_Motion.punch, _Action.dash),
  68: _Signature(_Motion.punch, _Action.roar),
  79: _Signature(_Motion.lazy, _Action.nod, [_Fx.question]), // Slowpoke
  80: _Signature(_Motion.lazy, _Action.nod, [_Fx.bubbles]),
  92: _Signature(_Motion.haunt, _Action.none, [_Fx.gas]), // Gastly
  93: _Signature(_Motion.haunt, _Action.twirl, [_Fx.wisps, _Fx.gas]),
  94: _Signature(_Motion.haunt, _Action.dash, [_Fx.wisps, _Fx.smoke]),
  95: _Signature(_Motion.serpent, _Action.roar, [_Fx.rocks]), // Onix
  129: _Signature(_Motion.flop, _Action.jump, [_Fx.splash]), // Magikarp
  130: _Signature(_Motion.serpent, _Action.roar, [_Fx.rain, _Fx.ripples]),
  131: _Signature(_Motion.swim, _Action.nod, [_Fx.notes, _Fx.ripples]),
  132: _Signature(_Motion.wobble, _Action.none), // Ditto
  133: _Signature(_Motion.hop, _Action.jump, [_Fx.hearts]), // Eevee
  143: _Signature(_Motion.breathe, _Action.none, [_Fx.zzz]), // Snorlax
  144: _Signature(_Motion.soar, _Action.twirl, [_Fx.snow, _Fx.frost]),
  145: _Signature(_Motion.soar, _Action.charge, [_Fx.bolts, _Fx.rain]),
  146: _Signature(_Motion.soar, _Action.roar, [_Fx.flames, _Fx.embers]),
  149: _Signature(_Motion.soar, _Action.jump, [_Fx.hearts, _Fx.wind]),
  150: _Signature(_Motion.levitate, _Action.charge, [_Fx.rings]), // Mewtwo
  151: _Signature(_Motion.float, _Action.twirl, [_Fx.bubbles, _Fx.sparkles]),
  174: _Signature(_Motion.float, _Action.twirl, [_Fx.notes]),
  196: _Signature(_Motion.levitate, _Action.twirl, [_Fx.rings, _Fx.sparkles]),
  197: _Signature(_Motion.prowl, _Action.brace, [_Fx.smoke, _Fx.glints]),
  199: _Signature(_Motion.lazy, _Action.nod, [_Fx.rings]),
  249: _Signature(_Motion.soar, _Action.roar, [_Fx.wind, _Fx.rain]), // Lugia
  250: _Signature(_Motion.soar, _Action.roar, [_Fx.flames, _Fx.sparkles]),
  251: _Signature(_Motion.float, _Action.twirl, [_Fx.leaves, _Fx.sparkles]),
  282: _Signature(_Motion.levitate, _Action.twirl, [_Fx.sparkles]),
  382: _Signature(_Motion.swim, _Action.roar, [_Fx.rain, _Fx.ripples]),
  383: _Signature(_Motion.stomp, _Action.roar, [_Fx.embers, _Fx.flames]),
  384: _Signature(_Motion.serpent, _Action.roar, [_Fx.wind]), // Rayquaza
  445: _Signature(_Motion.prowl, _Action.dash, [_Fx.wind]), // Garchomp
  446: _Signature(_Motion.breathe, _Action.none, [_Fx.zzz]), // Munchlax
  448: _Signature(_Motion.punch, _Action.charge, [_Fx.rings]), // Lucario
  493: _Signature(_Motion.majestic, _Action.charge, [_Fx.sparkles]),
  658: _Signature(_Motion.prowl, _Action.dash, [_Fx.bubbles]), // Greninja
  700: _Signature(_Motion.float, _Action.twirl, [_Fx.hearts, _Fx.sparkles]),
  778: _Signature(_Motion.wobble, _Action.none, [_Fx.smoke]), // Mimikyu
};

bool _isLegendary(int id) => const [
  (144, 146),
  (150, 151),
  (243, 251),
  (377, 386),
  (480, 494),
  (638, 649),
  (716, 721),
  (772, 773),
  (785, 809),
  (888, 905),
  (1001, 1025),
].any((range) => id >= range.$1 && id <= range.$2);

_Motion _typeMotion(List<String> types) {
  // Lo que más se nota manda: un fantasma flota aunque sea de otro tipo, y
  // quien vuela, vuela.
  if (types.contains('ghost')) return _Motion.haunt;
  if (types.contains('flying')) return _Motion.soar;
  return switch (types.firstOrNull) {
    'fire' => _Motion.flicker,
    'water' => _Motion.swim,
    'grass' => _Motion.sway,
    'electric' => _Motion.spark,
    'psychic' => _Motion.levitate,
    'ground' || 'rock' => _Motion.stomp,
    'steel' => _Motion.glint,
    'fighting' => _Motion.punch,
    'poison' => _Motion.wobble,
    'dark' => _Motion.prowl,
    'dragon' => _Motion.majestic,
    'fairy' || 'ice' => _Motion.float,
    'bug' => _Motion.hop,
    _ => _Motion.bounce,
  };
}

List<_Fx> _typeFx(String type) => switch (type) {
  'fire' => const [_Fx.embers, _Fx.flames],
  'water' => const [_Fx.bubbles, _Fx.ripples],
  'electric' => const [_Fx.bolts],
  'grass' => const [_Fx.leaves, _Fx.pollen],
  'ice' => const [_Fx.snow, _Fx.frost],
  'psychic' => const [_Fx.rings, _Fx.sparkles],
  'ghost' => const [_Fx.wisps],
  'fairy' => const [_Fx.sparkles, _Fx.hearts],
  'poison' => const [_Fx.toxic],
  'rock' => const [_Fx.rocks],
  'steel' => const [_Fx.glints],
  'dark' => const [_Fx.smoke],
  'dragon' => const [_Fx.flames, _Fx.sparkles],
  'flying' => const [_Fx.wind, _Fx.feathers],
  'bug' => const [_Fx.pollen],
  _ => const [],
};

/// Un efecto con su color y su densidad (1 = completo).
typedef _FxLayer = ({_Fx fx, Color color, double density});

/// Todo lo que define cómo se anima un Pokémon.
class _Profile {
  _Profile(Pokemon pokemon) : seed = pokemon.speciesId ?? pokemon.id {
    final types = pokemon.types.isEmpty ? const ['normal'] : pokemon.types;
    final signature = _signatures[seed];
    final stats = {for (final stat in pokemon.stats) stat.name: stat.value};
    final kilos = pokemon.weight / 10;
    legendary = _isLegendary(seed);
    motion = signature?.motion ?? _typeMotion(types);
    color = _typeColor(types.first);

    // Efectos: los de su gesto propio, los de su primer tipo y, más
    // suaves, los del segundo.
    final layers = <_Fx, _FxLayer>{};
    void add(_Fx fx, String type, double density) => layers.putIfAbsent(
      fx,
      () => (fx: fx, color: _typeColor(type), density: density),
    );
    for (final fx in signature?.fx ?? const <_Fx>[]) {
      add(fx, types.first, 1);
    }
    for (final fx in _typeFx(types.first)) {
      add(fx, types.first, 1);
    }
    if (types.length > 1) {
      for (final fx in _typeFx(types[1])) {
        add(fx, types[1], 0.5);
      }
    }
    if (legendary) add(_Fx.rays, types.first, 1);
    fx = layers.values.toList();

    // Ritmo: de 20 a 160 de velocidad, de un ciclo lento a uno ágil.
    final speed = stats['speed'] ?? 70;
    final agility = ((speed - 20) / 140).clamp(0.0, 1.0);
    period =
        (2.6 - 1.3 * agility) *
        switch (motion) {
          _Motion.breathe || _Motion.lazy => 2.0,
          _Motion.majestic || _Motion.haunt || _Motion.serpent => 1.4,
          _Motion.levitate || _Motion.float => 1.2,
          _Motion.teleport => 1.8,
          _ => 1.0,
        };
    trails = speed >= 100;

    // Fuerza: los ligeros se mueven más que los pesados.
    strength = (1.25 - math.log(kilos + 1) / math.log(400) * 0.6).clamp(
      0.6,
      1.25,
    );

    final special = stats['special-attack'] ?? 60;
    glow = legendary ? 1.0 : (0.3 + 0.45 * (special / 150)).clamp(0.3, 0.8);

    action = signature?.action ?? _actionFromStats(stats, kilos, types);
    actionLength = switch (action) {
      _Action.roar => 1.4,
      _Action.charge => 1.6,
      _Action.brace => 1.2,
      _Action.nod => 0.8,
      _ => 1.0,
    };
    actionEvery = 4.5 + 2.5 * _hash(seed, 1);
    actionOffset = actionEvery * _hash(seed, 2);
    phase = _hash(seed, 3);
    move = _moveFor(seed, types);
    attackEvery = 8 + 3 * _hash(seed, 4);
  }

  final int seed;
  late final bool legendary;
  late final _Motion motion;
  late final _Action action;
  late final List<_FxLayer> fx;
  late final Color color;
  late final double period;
  late final double strength;
  late final double glow;
  late final bool trails;
  late final double actionLength;
  late final double actionEvery;
  late final double actionOffset;
  late final double phase;

  /// Su ataque característico y cada cuántos segundos lo lanza.
  late final _Move move;
  late final double attackEvery;

  bool get airborne => const {
    _Motion.soar,
    _Motion.levitate,
    _Motion.haunt,
    _Motion.float,
    _Motion.teleport,
  }.contains(motion);

  static _Action _actionFromStats(
    Map<String, int> stats,
    double kilos,
    List<String> types,
  ) {
    if (stats.isEmpty) return _Action.jump;
    final best = stats.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    final heavy = kilos > 120;
    return switch (best) {
      'attack' => heavy ? _Action.roar : _Action.dash,
      'special-attack' => _Action.charge,
      'defense' => heavy ? _Action.roar : _Action.brace,
      'special-defense' =>
        types.contains('fairy') || types.contains('psychic')
            ? _Action.twirl
            : _Action.brace,
      'speed' =>
        types.contains('flying') || types.contains('fairy')
            ? _Action.twirl
            : _Action.spin,
      _ => heavy ? _Action.roar : _Action.jump,
    };
  }
}

/// Número pseudoaleatorio estable entre 0 y 1.
double _hash(int seed, int salt) {
  final v = math.sin((seed * 31 + salt * 97) * 12.9898) * 43758.5453;
  return v - v.floorToDouble();
}

/// Postura del sprite en un instante. Los desplazamientos van en fracciones
/// del lado de la pantalla.
class _Pose {
  double dx = 0;
  double dy = 0;
  double rotation = 0;
  double sx = 1;
  double sy = 1;
  double opacity = 1;

  /// Brillo extra del aura (al cargar energía o rugir).
  double glow = 0;

  /// Temblor de toda la escena.
  double shake = 0;

  /// Golpe contra el suelo (levanta polvo), de 0 a 1.
  double impact = 0;

  /// Golpe hacia delante (estrella de impacto), de 0 a 1.
  double hit = 0;

  /// Acción especial en curso y por dónde va (0..1), o null.
  _Action? action;
  double actionPhase = 0;

  /// Ataque en curso y por dónde va (0..1), o null.
  _Move? move;
  double movePhase = 0;

  /// Movimientos hacia el rival (positivo) o hacia atrás (negativo), que
  /// luego se orientan según hacia dónde mire el Pokémon: desplazamiento e
  /// inclinación de todo el cuerpo desde los pies.
  double forward = 0;
  double lean = 0;
}

_Pose _poseAt(_Profile profile, double time) {
  final pose = _Pose();
  final t = (time / profile.period + profile.phase) % 1;
  final p = 2 * math.pi * t;
  final k = profile.strength;
  switch (profile.motion) {
    case _Motion.bounce:
      final up = math.sin(p).abs();
      pose.dy = -0.07 * k * Curves.easeOut.transform(up);
      final squash = math.pow(1 - up, 8).toDouble();
      pose.sx = 1 + 0.07 * squash;
      pose.sy = 1 - 0.08 * squash + 0.03 * up;
      pose.impact = squash > 0.7 ? (squash - 0.7) / 0.3 * 0.6 : 0;
    case _Motion.hop:
      final up = math.sin(2 * p).abs();
      pose.dy = -0.05 * k * up;
      final squash = math.pow(1 - up, 10).toDouble();
      pose.sy = 1 + 0.04 * up - 0.06 * squash;
      pose.sx = 1 + 0.05 * squash;
      pose.rotation = 0.04 * math.sin(p);
    case _Motion.flicker:
      final f = math.sin(3 * p) * 0.6 + math.sin(7 * p) * 0.4;
      pose.sy = 1 + 0.03 * f;
      pose.sx = 1 - 0.012 * f;
      pose.dy = -0.012 * math.sin(p);
      pose.glow = 0.2 + 0.2 * f;
    case _Motion.swim:
      pose.dy = 0.04 * k * math.sin(p);
      pose.rotation = 0.07 * k * math.cos(p);
      pose.dx = 0.02 * math.sin(p);
      pose.sx = 1 + 0.02 * math.sin(2 * p);
    case _Motion.sway:
      pose.rotation = 0.07 * k * math.sin(p);
      pose.sy = 1 + 0.02 * math.sin(2 * p);
      pose.sx = 1 - 0.01 * math.sin(2 * p);
    case _Motion.spark:
      final shock = t > 0.55 && t < 0.75;
      if (shock) {
        pose.dx = 0.014 * math.sin(time * 160);
        pose.dy = -0.04 * k * math.sin((t - 0.55) / 0.2 * math.pi);
        pose.glow = 0.8;
      }
      pose.sy = 1 + 0.012 * math.sin(2 * p);
    case _Motion.soar:
      pose.dy = -0.04 + 0.07 * k * math.sin(p);
      pose.rotation = 0.05 * math.sin(p + math.pi / 2);
      pose.sy = 1 + 0.045 * math.sin(4 * p);
      pose.sx = 1 - 0.015 * math.sin(4 * p);
    case _Motion.levitate:
      pose.dy = -0.04 + 0.045 * k * math.sin(p);
      pose.sx = pose.sy = 1 + 0.02 * math.sin(p);
      pose.glow = 0.25 + 0.25 * math.sin(p);
    case _Motion.haunt:
      pose.dy = -0.04 + 0.045 * math.sin(p);
      pose.dx = 0.035 * math.sin(2 * p);
      pose.rotation = 0.04 * math.sin(2 * p);
      pose.opacity = 0.45 + 0.55 * (0.5 + 0.5 * math.cos(p));
    case _Motion.stomp:
      final lift = t < 0.7
          ? Curves.easeOut.transform(t / 0.7)
          : 1 - math.pow((t - 0.7) / 0.08, 2).clamp(0.0, 1.0).toDouble();
      pose.dy = -0.05 * k * lift;
      final impact = t < 0.78 || t > 0.95 ? 0.0 : 1 - (t - 0.78) / 0.17;
      pose.impact = impact;
      pose.shake = 0.012 * impact;
      pose.sx = 1 + 0.07 * impact;
      pose.sy = 1 - 0.07 * impact + 0.02 * lift;
    case _Motion.glint:
      pose.dy = -0.01 * math.sin(p);
      pose.sy = 1 + 0.01 * math.sin(p);
    case _Motion.punch:
      final jab = math.pow(math.max(0, math.sin(2 * p)), 6).toDouble();
      pose.sx = pose.sy = 1 + 0.1 * k * jab;
      pose.dy = 0.01 * jab + 0.006 * math.sin(4 * p);
      pose.rotation = 0.05 * jab * (math.sin(p) > 0 ? 1 : -1);
      pose.hit = jab > 0.85 ? (jab - 0.85) / 0.15 : 0;
    case _Motion.wobble:
      pose.sx = 1 + 0.07 * k * math.sin(2 * p);
      pose.sy = 1 - 0.07 * k * math.sin(2 * p);
      pose.rotation = 0.03 * math.sin(p);
    case _Motion.prowl:
      pose.dx = 0.035 * k * math.sin(p);
      pose.rotation = 0.04 * math.sin(p);
      pose.sy = 1 - 0.02 * math.cos(2 * p);
      pose.dy = 0.006 * math.cos(2 * p);
    case _Motion.majestic:
      pose.dy = -0.015 + 0.03 * math.sin(p);
      pose.sx = pose.sy = 1 + 0.03 * (0.5 - 0.5 * math.cos(p));
      pose.rotation = 0.02 * math.sin(p);
      pose.glow = 0.3 * (0.5 - 0.5 * math.cos(p));
    case _Motion.float:
      pose.dy = -0.03 - 0.035 * k * math.sin(p).abs();
      pose.rotation = 0.04 * math.sin(p);
      pose.sx = 1 + 0.02 * math.cos(2 * p);
      pose.sy = 1 - 0.02 * math.cos(2 * p);
    case _Motion.flop:
      final up = math.sin(2 * p).abs();
      pose.dy = -0.1 * up;
      pose.rotation = 0.35 * math.sin(2 * p);
      pose.impact = up < 0.15 ? (0.15 - up) / 0.15 * 0.5 : 0;
    case _Motion.breathe:
      final breath = 0.5 - 0.5 * math.cos(p);
      pose.sx = 1 + 0.03 * breath;
      pose.sy = 1 + 0.045 * breath;
    case _Motion.teleport:
      pose.dy = -0.03 + 0.03 * math.sin(p);
      pose.dx = 0.07 * (t < 0.5 ? -1 : 1);
      final edge = math.min((t - 0.5).abs(), math.min(t, 1 - t));
      pose.opacity = (edge / 0.05).clamp(0.0, 1.0);
      pose.sx = 0.6 + 0.4 * pose.opacity;
      pose.sy = 1.3 - 0.3 * pose.opacity;
      pose.glow = 1 - pose.opacity;
    case _Motion.lazy:
      pose.rotation = 0.05 * math.sin(p);
      pose.dy = 0.006 * math.sin(2 * p);
    case _Motion.serpent:
      pose.rotation = 0.09 * k * math.sin(p);
      pose.dx = 0.03 * math.sin(p - 0.6);
      pose.sx = 1 + 0.035 * math.sin(2 * p);
      pose.sy = 1 - 0.02 * math.sin(2 * p) + 0.02 * math.sin(p);
  }
  // Su ataque característico; mientras ataca no hace otra acción.
  final attack = _attackPhase(profile, time);
  if (attack != null) {
    _applyAttack(pose, profile.move, attack, time);
    return pose;
  }
  // Acción especial (no durante la aparición).
  if (profile.action != _Action.none && time > 1.4) {
    final local = (time + profile.actionOffset) % profile.actionEvery;
    if (local < profile.actionLength) {
      _applyAction(pose, profile.action, local / profile.actionLength, time);
    }
  }
  return pose;
}

void _applyAction(_Pose pose, _Action action, double a, double time) {
  pose
    ..action = action
    ..actionPhase = a;
  double bump(double from, double to) =>
      a < from || a > to ? 0 : math.sin((a - from) / (to - from) * math.pi);
  switch (action) {
    case _Action.none:
      break;
    case _Action.roar:
      final crouch = bump(0, 0.25);
      final roar = bump(0.2, 0.85);
      pose.sy *= 1 - 0.07 * crouch;
      pose.sx *= 1 + 0.04 * crouch;
      pose.sx *= 1 + 0.12 * roar;
      pose.sy *= 1 + 0.12 * roar;
      pose.dx += 0.012 * roar * math.sin(time * 95);
      pose.shake = math.max(pose.shake, 0.012 * roar);
      pose.glow += 0.8 * roar;
    case _Action.spin:
      final turn = Curves.easeInOut.transform(a);
      pose.sx *= math.cos(2 * math.pi * turn);
      pose.dy -= 0.07 * math.sin(math.pi * a);
    case _Action.jump:
      final crouch = bump(0, 0.2);
      final air = bump(0.18, 0.85);
      final land = bump(0.84, 1);
      pose.sy *= (1 - 0.13 * crouch) * (1 + 0.07 * air) * (1 - 0.12 * land);
      pose.sx *= (1 + 0.08 * crouch) * (1 - 0.04 * air) * (1 + 0.1 * land);
      pose.dy -= 0.24 * air;
      pose.rotation += 0.08 * air * math.sin(a * 2 * math.pi);
      pose.impact = math.max(pose.impact, land);
    case _Action.dash:
      final back = bump(0, 0.35);
      final lunge = bump(0.3, 0.6);
      pose.sx *= (1 - 0.06 * back) * (1 + 0.3 * lunge);
      pose.sy *= (1 - 0.06 * back) * (1 + 0.3 * lunge);
      pose.dy += 0.015 * back - 0.03 * lunge;
      pose.hit = math.max(pose.hit, bump(0.4, 0.62));
    case _Action.charge:
      if (a < 0.75) {
        final power = a / 0.75;
        pose.sy *= 1 - 0.06 * power;
        pose.sx *= 1 + 0.03 * power;
        pose.dx += 0.008 * power * math.sin(time * 120);
        pose.glow += 1.4 * power;
      } else {
        final burst = bump(0.75, 1);
        pose.sx *= 1 + 0.12 * burst;
        pose.sy *= 1 + 0.12 * burst;
        pose.glow += 1.6 * burst;
        pose.shake = math.max(pose.shake, 0.008 * burst);
      }
    case _Action.brace:
      final hold = bump(0, 1);
      pose.sx *= 1 - 0.04 * hold;
      pose.sy *= 1 - 0.05 * hold;
      pose.glow += 0.5 * hold;
    case _Action.twirl:
      final turn = Curves.easeInOut.transform(a);
      pose.sx *= math.cos(4 * math.pi * turn);
      pose.dy -= 0.09 * math.sin(math.pi * a);
      pose.glow += 0.5 * math.sin(math.pi * a);
    case _Action.nod:
      pose.dy += 0.02 * math.sin(a * 4 * math.pi).abs();
      pose.rotation += 0.04 * math.sin(a * 2 * math.pi);
  }
}

/// Lo que se sabe de la figura del Pokémon dentro de su sprite, en
/// fracciones de la imagen (0..1): dónde está su cuerpo, su cabeza, su boca
/// (la punta de la cabeza hacia donde mira), hasta dónde llega la cabeza y
/// hacia qué lado mira.
@immutable
class _SpriteInfo {
  const _SpriteInfo({
    required this.body,
    required this.head,
    required this.mouth,
    required this.neck,
    required this.facesLeft,
    this.aspect = 1,
  });

  /// Mientras carga (o sin internet): una figura típica que mira a la
  /// izquierda, como la mayoría de los sprites de Rojo Fuego.
  static const fallback = _SpriteInfo(
    body: Rect.fromLTRB(0.22, 0.22, 0.78, 0.86),
    head: Offset(0.45, 0.36),
    mouth: Offset(0.3, 0.42),
    neck: 0.5,
    facesLeft: true,
  );

  final Rect body;
  final Offset head;
  final Offset mouth;

  /// Altura donde termina la cabeza.
  final double neck;
  final bool facesLeft;

  /// Ancho entre alto de la imagen.
  final double aspect;
}

/// Sprites ya analizados, por dirección.
final _spriteInfos = <String, _SpriteInfo>{};

/// Mira los píxeles del sprite para encontrar su figura. Los sprites de
/// frente de los juegos miran hacia la izquierda (hacia el Pokémon del
/// jugador), así que la boca es lo que más sobresale a la izquierda en la
/// parte de arriba.
Future<_SpriteInfo?> _analyzeSprite(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return null;
  final w = image.width;
  final h = image.height;
  bool solid(int x, int y) => data.getUint8((y * w + x) * 4 + 3) > 40;

  var minX = w, maxX = -1, minY = h, maxY = -1, count = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!solid(x, y)) continue;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
      count++;
    }
  }
  if (count < 20) return null;
  final height = maxY - minY + 1;

  // Cabeza: la parte de arriba de la figura.
  final headBottom = minY + (height * 0.45).round();
  var headX = 0.0, headY = 0.0, headCount = 0;
  for (var y = minY; y <= headBottom; y++) {
    for (var x = minX; x <= maxX; x++) {
      if (!solid(x, y)) continue;
      headX += x;
      headY += y;
      headCount++;
    }
  }
  headX /= math.max(1, headCount);
  headY /= math.max(1, headCount);

  // Boca: lo que más sobresale a la izquierda en la cabeza.
  var mouthX = w;
  var mouthY = (minY + height * 0.35).round();
  for (
    var y = minY + (height * 0.12).round();
    y <= minY + (height * 0.55).round();
    y++
  ) {
    for (var x = minX; x <= maxX; x++) {
      if (!solid(x, y)) continue;
      if (x < mouthX) {
        mouthX = x;
        mouthY = y;
      }
      break;
    }
  }
  // Un poco hacia dentro, para que salga de la boca y no del borde.
  final inward = (maxX - minX) * 0.04;

  return _SpriteInfo(
    body: Rect.fromLTRB(minX / w, minY / h, (maxX + 1) / w, (maxY + 1) / h),
    head: Offset(headX / w, headY / h),
    mouth: Offset((mouthX + inward) / w, mouthY / h),
    neck: (headBottom + 1) / h,
    facesLeft: true,
    aspect: w / h,
  );
}

/// Pasa las medidas del sprite a la pantalla y aplica la postura: escala y
/// giro desde los pies, desplazamiento, y el movimiento propio de la cabeza.
class _Rig {
  _Rig(this.box, this.info, this.pose, this.appear) {
    final side = box.shortestSide;
    // Igual que BoxFit.contain.
    final height = math.min(box.height, box.width / info.aspect);
    fit = Rect.fromCenter(
      center: box.center(Offset.zero),
      width: height * info.aspect,
      height: height,
    );
    // Unidad de movimiento y de efectos: el tamaño de la figura, para que
    // un Pokémon pequeño haga ataques pequeños y uno grande, grandes.
    final body =
        map(info.body.topLeft) &
        Size(info.body.width * fit.width, info.body.height * fit.height);
    unit = (body.longestSide * 1.5).clamp(side * 0.4, side);
    feet = Offset(body.center.dx, body.bottom);
    dir = info.facesLeft ? -1 : 1;
  }

  final Size box;
  final _SpriteInfo info;
  final _Pose pose;
  final double appear;
  late final Rect fit;
  late final double unit;
  late final Offset feet;

  /// -1 si mira a la izquierda, 1 si a la derecha.
  late final double dir;

  Offset map(Offset normalized) =>
      fit.topLeft +
      Offset(normalized.dx * fit.width, normalized.dy * fit.height);

  Alignment _alignment(Offset p) =>
      Alignment(p.dx / box.width * 2 - 1, p.dy / box.height * 2 - 1);

  Alignment get feetAlignment => _alignment(feet);

  double get rotation => pose.rotation + pose.lean * dir;
  Offset get offset =>
      Offset((pose.dx + pose.forward * dir) * unit, pose.dy * unit);

  /// Dónde queda en pantalla un punto del sprite con la postura actual.
  Offset posed(Offset normalized) {
    var p = map(normalized);
    // Escala desde los pies.
    p =
        feet +
        Offset(
          (p.dx - feet.dx) * pose.sx * appear,
          (p.dy - feet.dy) * pose.sy * appear,
        );
    // Giro desde los pies.
    final angle = rotation;
    final d = p - feet;
    p =
        feet +
        Offset(
          d.dx * math.cos(angle) - d.dy * math.sin(angle),
          d.dx * math.sin(angle) + d.dy * math.cos(angle),
        );
    return p + offset;
  }
}

/// Mueve el sprite de [pokemon] con su animación característica. Se queda
/// quieto si el sistema pide reducir animaciones.
class _PokemonMotion extends StatefulWidget {
  const _PokemonMotion({
    required this.pokemon,
    required this.child,
    this.spriteUrl,
    this.shiny = false,
  });

  final Pokemon pokemon;
  final Widget child;

  /// Dirección del sprite, para analizar su figura.
  final String? spriteUrl;

  /// Es la versión variocolor: brilla con destellos al aparecer.
  final bool shiny;

  @override
  State<_PokemonMotion> createState() => _PokemonMotionState();
}

class _PokemonMotionState extends State<_PokemonMotion>
    with SingleTickerProviderStateMixin {
  late _Profile _profile = _Profile(widget.pokemon);
  _SpriteInfo _info = _SpriteInfo.fallback;
  late final _ticker = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  );

  /// Segundos desde que apareció.
  final _time = ValueNotifier<double>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
      _loadInfo();
    }
  }

  @override
  void didUpdateWidget(_PokemonMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pokemon.id != widget.pokemon.id) {
      _profile = _Profile(widget.pokemon);
      // Vuelve a aparecer con su destello.
      if (_ticker.isActive) {
        _ticker
          ..stop()
          ..start();
      }
    }
    if (oldWidget.spriteUrl != widget.spriteUrl && _ticker.isActive) {
      _loadInfo();
    }
  }

  /// Analiza la figura del sprite (una sola vez por sprite).
  void _loadInfo() {
    final url = widget.spriteUrl;
    _info = _spriteInfos[url] ?? _SpriteInfo.fallback;
    if (url == null || _spriteInfos.containsKey(url)) return;
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener((image, _) async {
      stream.removeListener(listener);
      final info = await _analyzeSprite(image.image);
      image.dispose();
      if (info == null) return;
      _spriteInfos[url] = info;
      if (mounted && widget.spriteUrl == url) setState(() => _info = info);
    }, onError: (error, stackTrace) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) => ValueListenableBuilder<double>(
        valueListenable: _time,
        child: widget.child,
        builder: (context, time, child) =>
            _frame(constraints.biggest, time, child!),
      ),
    );
  }

  Widget _frame(Size size, double time, Widget sprite) {
    final profile = _profile;
    final pose = _poseAt(profile, time);

    // Aparición: sale como silueta blanca que crece y toma color.
    final appear = Curves.easeOutBack.transform((time / 0.6).clamp(0.0, 1.0));
    final white = 1 - ((time - 0.25) / 0.5).clamp(0.0, 1.0);
    final fadeIn = (time / 0.15).clamp(0.0, 1.0);
    final rig = _Rig(size, _info, pose, appear);

    Widget place(_Rig rig, Widget child, {double extraScale = 1}) => Opacity(
      opacity: (rig.pose.opacity * fadeIn).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: rig.offset,
        child: Transform.rotate(
          angle: rig.rotation,
          alignment: rig.feetAlignment,
          child: Transform.scale(
            scaleX: rig.pose.sx * appear * extraScale,
            scaleY: rig.pose.sy * appear * extraScale,
            alignment: rig.feetAlignment,
            child: child,
          ),
        ),
      ),
    );

    final pulse = 0.75 + 0.25 * math.sin(2 * math.pi * time / 1.8);
    final glow = (profile.glow * pulse + pose.glow * 0.5).clamp(0.0, 1.6);
    final glowColor = profile.legendary
        ? Color.lerp(profile.color, const Color(0xFFFFE27A), 0.5)!
        : profile.color;
    final trails =
        profile.trails || pose.hit > 0 || pose.action == _Action.dash;
    final shake = pose.shake * rig.unit;

    return Transform.translate(
      offset: Offset(
        shake * math.sin(time * 110),
        shake * 0.6 * math.cos(time * 95),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(
              painter: _FxPainter(profile, time, rig, back: true),
            ),
          ),
          // Aura con la forma del Pokémon.
          place(
            rig,
            Opacity(
              opacity: (glow / 1.6).clamp(0.0, 1.0),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: rig.unit / 45,
                  sigmaY: rig.unit / 45,
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(glowColor, BlendMode.srcIn),
                  child: sprite,
                ),
              ),
            ),
            extraScale: 1.06,
          ),
          // Estela de los rápidos.
          if (trails)
            for (final lag in const [0.12, 0.06])
              place(
                _Rig(
                  size,
                  _info,
                  _poseAt(profile, math.max(0, time - lag)),
                  appear,
                ),
                Opacity(
                  opacity: lag == 0.12 ? 0.15 : 0.28,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      profile.color.withValues(alpha: 0.6),
                      BlendMode.srcATop,
                    ),
                    child: sprite,
                  ),
                ),
              ),
          place(
            rig,
            white > 0
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: white),
                      BlendMode.srcATop,
                    ),
                    child: sprite,
                  )
                : profile.motion == _Motion.glint
                ? ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) => _glintShader(bounds, time),
                    child: sprite,
                  )
                : sprite,
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: _FxPainter(
                profile,
                time,
                rig,
                back: false,
                shiny: widget.shiny,
              ),
            ),
          ),
          if (pose.move case final move?)
            _moveBanner(move, pose.movePhase, size.shortestSide),
        ],
      ),
    );
  }
}

/// Letrero con el nombre del ataque, como en los juegos.
Widget _moveBanner(_Move move, double a, double side) {
  final show = a < 0.08
      ? a / 0.08
      : a > 0.9
      ? (1 - a) / 0.1
      : 1.0;
  final text = move.style == _MoveStyle.splash && a > 0.55
      ? '¡NO PASÓ NADA!'
      : '¡${move.name}!';
  return IgnorePointer(
    child: Align(
      alignment: const Alignment(0, 0.92),
      child: Opacity(
        opacity: show.clamp(0.0, 1.0),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: side * 0.03,
            vertical: side * 0.015,
          ),
          decoration: BoxDecoration(
            color: const Color(0xE6161616),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: move.colors[0], width: 2),
          ),
          child: Text(
            _dexText(text),
            style: _pixel(
              (side / 24).clamp(7.0, 12.0),
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Franja de luz que cruza a los de acero.
Shader _glintShader(Rect bounds, double time) {
  final x = ((time / 2.2) % 1) * 3 - 1.5;
  return LinearGradient(
    begin: Alignment(x - 0.4, -1),
    end: Alignment(x + 0.4, 1),
    colors: const [Color(0x00FFFFFF), Color(0xAAFFFFFF), Color(0x00FFFFFF)],
    stops: const [0.4, 0.5, 0.6],
  ).createShader(bounds);
}

/// Dibujos de pixel art pequeños (X = píxel pintado).
const _heartBits = [
  ' XX XX ',
  'XXXXXXX',
  'XXXXXXX',
  ' XXXXX ',
  '  XXX  ',
  '   X   ',
];
const _noteBits = [
  '  XXXX ',
  '  X  X ',
  '  X  X ',
  '  X  X ',
  'XXX XXX',
  'XXX XXX',
];
const _zBits = ['XXXXX', '   X ', '  X  ', ' X   ', 'XXXXX'];
const _questionBits = [' XXX ', 'X   X', '   X ', '  X  ', '     ', '  X  '];

/// Partículas y luces en pixel art. Todo sale del tiempo y de la semilla
/// del Pokémon, así que no guardan estado.
class _FxPainter extends CustomPainter {
  _FxPainter(
    this.profile,
    this.time,
    this.rig, {
    required this.back,
    this.shiny = false,
  }) : pose = rig.pose;

  final _Profile profile;
  final double time;
  final _Rig rig;
  final _Pose pose;
  final bool back;

  /// Destellos de Pokémon variocolor.
  final bool shiny;

  late Canvas _canvas;
  late Size _size;
  late double _px;

  /// Tamaño de referencia de los efectos (sale de la figura del Pokémon).
  late double _side;
  late Offset _center;
  late Offset _ground;

  /// Boca y cabeza con la postura actual, y hacia dónde mira (-1 o 1).
  late Offset _mouthPoint;
  late Offset _headPoint;
  late double _dir;

  double _rand(int i, int salt) => _hash(profile.seed * 7 + i, salt);

  void _square(Offset c, Color color, [double scale = 1]) {
    _canvas.drawRect(
      Rect.fromCenter(center: c, width: _px * scale, height: _px * scale),
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
  }

  void _bits(List<String> rows, Offset center, Color color, [double unit = 1]) {
    final u = _px * 0.6 * unit;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final w = rows.first.length;
    for (final (y, row) in rows.indexed) {
      for (var x = 0; x < row.length; x++) {
        if (row[x] != 'X') continue;
        _canvas.drawRect(
          Rect.fromLTWH(
            center.dx + (x - w / 2) * u,
            center.dy + (y - rows.length / 2) * u,
            u + 0.3,
            u + 0.3,
          ),
          paint,
        );
      }
    }
  }

  /// Estrella de 4 puntas que titila.
  void _star(Offset c, Color color, double shine) {
    if (shine <= 0) return;
    final tint = color.withValues(alpha: color.a * shine.clamp(0.0, 1.0));
    _square(c, tint);
    for (final d in const [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ]) {
      _square(c + d * _px * (0.6 + shine), tint, 0.7);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _canvas = canvas;
    _size = size;
    _side = rig.unit;
    _px = math.max(2.5, _side / 48);
    final info = rig.info;
    _center = rig.posed(info.body.center);
    // La sombra se queda en el suelo aunque salte.
    _ground = Offset(_center.dx, rig.feet.dy);
    _mouthPoint = rig.posed(info.mouth);
    _headPoint = rig.posed(info.head);
    _dir = rig.dir;

    if (back) {
      _shadow();
      for (final layer in profile.fx) {
        if (_backFx.contains(layer.fx)) _draw(layer);
      }
      _actionBack();
    } else {
      for (final layer in profile.fx) {
        if (!_backFx.contains(layer.fx)) _draw(layer);
      }
      _dust();
      _impact();
      _actionFront();
      _attack();
      _entrance();
      if (shiny) _shinySparkle();
    }
  }

  void _shadow() {
    final lift = (-pose.dy).clamp(0.0, 0.3) / 0.3;
    final base = profile.airborne ? 0.7 : 1.0;
    final width = _side * 0.42 * base * (1 - 0.45 * lift) * pose.sx.abs();
    _canvas.drawOval(
      Rect.fromCenter(center: _ground, width: width, height: width * 0.22),
      Paint()
        ..color = Colors.black.withValues(
          alpha: 0.18 * (1 - 0.6 * lift) * pose.opacity,
        ),
    );
  }

  void _draw(_FxLayer layer) {
    final d = layer.density;
    int count(int n) => math.max(1, (n * d).round());
    final s = time;
    final cx = _center.dx;
    switch (layer.fx) {
      case _Fx.embers:
        for (var i = 0; i < count(9); i++) {
          final life = (s * 0.7 + _rand(i, 1)) % 1;
          final x =
              cx +
              _side * (_rand(i, 2) - 0.5) * 0.7 +
              math.sin(life * 6 + i) * _px * 2;
          final y = _ground.dy - _side * 0.8 * life;
          final color = Color.lerp(
            const Color(0xFFFFF27A),
            const Color(0xFFFF3B1C),
            life,
          )!.withValues(alpha: 1 - life);
          _square(Offset(x, y), color, 1.4 - life * 0.8);
        }
      case _Fx.flames:
        // Lenguas de fuego detrás, que suben y se mecen; las de dragón, con
        // sus colores. Una capa exterior y otra interior más brillante.
        final dragon = layer.color == _typeColor('dragon');
        final outer = dragon
            ? const [Color(0xFF3A2BD9), Color(0xFF7B4DFF), Color(0x007B4DFF)]
            : const [Color(0xFFFF8A00), Color(0xFFE8320C), Color(0x00E8320C)];
        final inner = dragon
            ? const [Color(0xFFE6DDFF), Color(0xFFB9A2FF), Color(0x00B9A2FF)]
            : const [Color(0xFFFFFBD1), Color(0xFFFFD23A), Color(0x00FFD23A)];
        final n = count(7);
        for (final (colors, scale, alpha) in [
          (outer, 1.0, 0.55),
          (inner, 0.6, 0.75),
        ]) {
          for (var i = 0; i < n; i++) {
            final f = (i + 0.5) / n - 0.5;
            final x = cx + _side * f * 0.62;
            final width = _side * 0.2 * scale;
            final height =
                _side *
                scale *
                (0.32 +
                    0.1 * math.sin(s * 6 + i * 1.9) +
                    0.06 * math.sin(s * 11 + i)) *
                (1 - f.abs() * 0.9);
            final base = _ground.dy + _px;
            final sway = math.sin(s * 5 + i * 2.3) * width * 0.35;
            final rect = Rect.fromLTRB(
              x - width / 2,
              base - height,
              x + width / 2,
              base,
            );
            _canvas.drawPath(
              Path()
                ..moveTo(x - width / 2, base)
                ..quadraticBezierTo(
                  x - width * 0.6,
                  base - height * 0.55,
                  x + sway,
                  base - height,
                )
                ..quadraticBezierTo(
                  x + width * 0.6,
                  base - height * 0.55,
                  x + width / 2,
                  base,
                )
                ..close(),
              Paint()
                ..shader = LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    for (final c in colors) c.withValues(alpha: c.a * alpha),
                  ],
                ).createShader(rect),
            );
          }
        }
      case _Fx.bubbles:
        for (var i = 0; i < count(7); i++) {
          final life = (s * 0.5 + _rand(i, 1)) % 1;
          final x =
              cx +
              _side * (_rand(i, 2) - 0.5) * 0.8 +
              math.sin(life * 9 + i) * _px * 2;
          final y = _ground.dy - _side * 0.85 * life;
          final r = _px * (1 + 1.5 * _rand(i, 3));
          final alpha = (1 - life) * 0.9;
          _canvas.drawCircle(
            Offset(x, y),
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = _px * 0.5
              ..color = const Color(0xFF6EC3FF).withValues(alpha: alpha),
          );
          _square(
            Offset(x - r * 0.4, y - r * 0.4),
            Colors.white.withValues(alpha: alpha),
            0.5,
          );
        }
      case _Fx.ripples:
        for (var i = 0; i < 3; i++) {
          final life = (s * 0.6 + i / 3) % 1;
          final w = _side * (0.3 + 0.6 * life);
          _canvas.drawOval(
            Rect.fromCenter(center: _ground, width: w, height: w * 0.2),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = _px * 0.5
              ..color = const Color(0xFF6EC3FF)
                  .withValues(alpha: 0.6 * (1 - life)),
          );
        }
      case _Fx.rain:
        final paint = Paint()
          ..strokeWidth = _px * 0.45
          ..color = const Color(0xFF9BD0FF).withValues(alpha: 0.65);
        for (var i = 0; i < count(16); i++) {
          final life = (s * 1.8 + _rand(i, 1)) % 1;
          final x = _size.width * (_rand(i, 2) * 1.2 - 0.1) - life * _px * 6;
          final y = _size.height * life;
          _canvas.drawLine(
            Offset(x, y),
            Offset(x - _px * 1.2, y + _px * 3.5),
            paint,
          );
        }
      case _Fx.splash:
        for (var i = 0; i < count(8); i++) {
          final life = (s * 1.2 + _rand(i, 1)) % 1;
          final x = cx + (_rand(i, 2) - 0.5) * _side * 0.9 * life;
          final y = _ground.dy - _side * 0.4 * 4 * life * (1 - life);
          _square(
            Offset(x, y),
            const Color(0xFF6EC3FF).withValues(alpha: 1 - life * 0.6),
            0.9,
          );
        }
      case _Fx.bolts:
        _bolts(d);
      case _Fx.leaves:
        for (var i = 0; i < count(6); i++) {
          // Remolino de hojas que sube alrededor.
          final life = (s * 0.25 + _rand(i, 1)) % 1;
          final angle = s * 1.5 + i * 2 * math.pi / 6;
          final radius = _side * (0.32 + 0.08 * math.sin(s + i));
          final c = Offset(
            cx + math.cos(angle) * radius,
            _ground.dy - _side * 0.7 * life + math.sin(angle) * _side * 0.08,
          );
          final front = math.sin(angle) > -0.3;
          final alpha = math.sin(life * math.pi) * (front ? 1 : 0.4);
          _square(c, const Color(0xFF5BD14E).withValues(alpha: alpha), 1.3);
          _square(
            c + Offset(_px * 0.8, -_px * 0.8),
            const Color(0xFF2E8B2E).withValues(alpha: alpha),
            0.8,
          );
        }
      case _Fx.petals:
        for (var i = 0; i < count(7); i++) {
          final life = (s * 0.35 + _rand(i, 1)) % 1;
          final x =
              _size.width * _rand(i, 2) +
              math.sin(life * 6 + i) * _px * 4 +
              life * _px * 8;
          final y = _size.height * life;
          final flip = math.sin(s * 5 + i).abs();
          _canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x, y),
              width: _px * 1.6,
              height: _px * (0.4 + flip),
            ),
            Paint()
              ..color = const Color(0xFFFF9EC7)
                  .withValues(alpha: math.sin(life * math.pi)),
          );
        }
      case _Fx.pollen:
        for (var i = 0; i < count(8); i++) {
          final a = s * 0.7 * (1 + _rand(i, 1));
          final c = Offset(
            cx + _side * 0.45 * math.sin(a + i * 1.3),
            _center.dy + _side * 0.32 * math.cos(a * 1.3 + i * 2.1),
          );
          final twinkle = 0.5 + 0.5 * math.sin(s * 6 + i);
          _square(
            c,
            const Color(0xFFFFE97A).withValues(alpha: 0.4 + 0.6 * twinkle),
            0.7,
          );
        }
      case _Fx.snow:
        for (var i = 0; i < count(12); i++) {
          final life = (s * 0.35 + _rand(i, 1)) % 1;
          final x =
              _size.width * _rand(i, 2) + math.sin(life * 5 + i) * _px * 3;
          final y = _size.height * life;
          final twinkle = 0.5 + 0.5 * math.sin(s * 4 + i * 1.7);
          final color = Color.lerp(
            const Color(0xFFBFF4FF),
            Colors.white,
            twinkle,
          )!;
          if (i.isEven) {
            _star(Offset(x, y), color, 0.4 + 0.4 * twinkle);
          } else {
            _square(Offset(x, y), color, 0.8);
          }
        }
      case _Fx.frost:
        for (var i = 0; i < count(5); i++) {
          final cycle = (s * 0.6 + _rand(i, 1)).floor();
          final life = (s * 0.6 + _rand(i, 1)) % 1;
          final c = Offset(
            cx + _side * (_rand(i, 10 + cycle) - 0.5) * 0.6,
            _center.dy + _side * (_rand(i, 20 + cycle) - 0.5) * 0.6,
          );
          _star(c, const Color(0xFFDFF9FF), math.sin(life * math.pi));
        }
      case _Fx.rings:
        final charge = pose.action == _Action.charge ? 1.6 : 1.0;
        for (var i = 0; i < 3; i++) {
          final life = (s * 0.8 * charge + i / 3) % 1;
          final color = Color.lerp(
            const Color(0xFFFF6FD8),
            const Color(0xFF9B6BFF),
            i / 2,
          )!;
          _canvas.drawOval(
            Rect.fromCenter(
              center: _center,
              width: _side * (0.3 + 0.7 * life),
              height: _side * (0.12 + 0.3 * life),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = _px * (1 - life * 0.6)
              ..color = color.withValues(alpha: 0.75 * (1 - life)),
          );
        }
      case _Fx.wisps:
        for (var i = 0; i < count(3); i++) {
          // Fuegos fatuos que orbitan con su estela.
          for (var trail = 4; trail >= 0; trail--) {
            final angle = (s - trail * 0.05) * 1.4 + i * 2 * math.pi / 3;
            final c = Offset(
              cx + math.cos(angle) * _side * 0.42,
              _center.dy + math.sin(angle) * _side * 0.16 - _side * 0.05,
            );
            final f = 1 - trail / 5;
            _canvas.drawCircle(
              c,
              _px * (0.8 + 1.4 * f),
              Paint()
                ..color = const Color(0xFFB57BFF).withValues(alpha: 0.25 * f),
            );
            if (trail == 0) {
              _canvas.drawCircle(
                c,
                _px * 0.9,
                Paint()..color = const Color(0xFFEAD9FF),
              );
            }
          }
        }
      case _Fx.gas:
        for (var i = 0; i < count(6); i++) {
          final angle = s * 0.6 + i * math.pi / 3;
          final c = Offset(
            cx + math.cos(angle) * _side * 0.22,
            _center.dy + math.sin(angle * 1.3) * _side * 0.18,
          );
          _canvas.drawCircle(
            c,
            _side * (0.12 + 0.04 * math.sin(s * 2 + i)),
            Paint()..color = const Color(0xFF7A3FB8).withValues(alpha: 0.16),
          );
        }
      case _Fx.sparkles:
        for (var i = 0; i < count(6); i++) {
          final cycle = (s * 0.9 + _rand(i, 1)).floor();
          final life = (s * 0.9 + _rand(i, 1)) % 1;
          final c = Offset(
            cx + _side * (_rand(i, 10 + cycle) - 0.5) * 0.85,
            _center.dy + _side * (_rand(i, 20 + cycle) - 0.5) * 0.75,
          );
          final color = i.isEven ? const Color(0xFFFFC6EC) : Colors.white;
          _star(c, color, math.sin(life * math.pi));
        }
      case _Fx.hearts:
        for (var i = 0; i < count(3); i++) {
          final life = (s * 0.35 + i / 3) % 1;
          final c = Offset(
            cx + _side * (0.25 * (i - 1)) + math.sin(life * 8 + i) * _px * 2,
            _center.dy - _side * (0.05 + 0.4 * life),
          );
          _bits(
            _heartBits,
            c,
            const Color(0xFFFF5C9A).withValues(alpha: math.sin(life * math.pi)),
            0.9,
          );
        }
      case _Fx.notes:
        const noteColors = [
          Color(0xFF58A6FF),
          Color(0xFFFF6FB5),
          Color(0xFF6EE07A),
        ];
        for (var i = 0; i < count(3); i++) {
          final life = (s * 0.4 + i / 3) % 1;
          final side = i.isEven ? 1 : -1;
          final c = Offset(
            cx + side * _side * (0.22 + 0.15 * life),
            _center.dy -
                _side * (0.1 + 0.35 * life) +
                math.sin(life * 10) * _px,
          );
          _bits(
            _noteBits,
            c,
            noteColors[i % 3].withValues(alpha: math.sin(life * math.pi)),
            0.8,
          );
        }
      case _Fx.zzz:
        for (var i = 0; i < 3; i++) {
          final life = (s * 0.3 + i / 3) % 1;
          final c = Offset(
            cx + _side * (0.15 + 0.2 * life),
            _center.dy - _side * (0.2 + 0.3 * life),
          );
          _bits(
            _zBits,
            c,
            const Color(0xFF3B6FD9).withValues(alpha: math.sin(life * math.pi)),
            0.6 + 0.8 * life,
          );
        }
      case _Fx.question:
        final life = (s * 0.3) % 1;
        if (life < 0.6) {
          final show = math.sin(life / 0.6 * math.pi);
          _bits(
            _questionBits,
            Offset(
              cx + _side * 0.22,
              _center.dy - _side * 0.38 - show * _px * 2,
            ),
            const Color(0xFF28AAFD).withValues(alpha: show),
            1.2,
          );
        }
      case _Fx.toxic:
        for (var i = 0; i < count(7); i++) {
          final life = (s * 0.55 + _rand(i, 1)) % 1;
          final x = cx + _side * (_rand(i, 2) - 0.5) * 0.7;
          final y = _ground.dy - _side * 0.65 * life;
          final r = _px * (0.8 + _rand(i, 3)) * (0.5 + life);
          if (life > 0.9) {
            // Revienta.
            _canvas.drawCircle(
              Offset(x, y),
              r * 1.8,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = _px * 0.4
                ..color = const Color(0xFFC77DFF),
            );
          } else {
            _canvas.drawCircle(
              Offset(x, y),
              r,
              Paint()..color = const Color(0xFFA040C0).withValues(alpha: 0.75),
            );
          }
        }
      case _Fx.rocks:
        for (var i = 0; i < count(5); i++) {
          // Rocas que levitan alrededor.
          final angle = s * 0.8 + i * 2 * math.pi / 5;
          final c = Offset(
            cx + math.cos(angle) * _side * 0.4,
            _center.dy +
                math.sin(angle) * _side * 0.12 +
                math.sin(s * 2 + i) * _px,
          );
          final shade = math.sin(angle) > 0 ? 1.0 : 0.6;
          _square(
            c,
            Color.lerp(Colors.black, const Color(0xFF9C8455), shade)!,
            2,
          );
          _square(
            c - Offset(_px * 0.4, _px * 0.4),
            Color.lerp(Colors.black, const Color(0xFFC8B07A), shade)!,
            0.9,
          );
        }
      case _Fx.wind:
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _px * 0.5
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < count(4); i++) {
          final life = (s * 0.9 + _rand(i, 1)) % 1;
          final y = _size.height * (0.2 + 0.6 * _rand(i, 2));
          final x = _size.width * (life * 1.4 - 0.2);
          paint.color = Colors.white.withValues(
            alpha: 0.7 * math.sin(life * math.pi),
          );
          _canvas.drawArc(
            Rect.fromCenter(
              center: Offset(x, y),
              width: _side * 0.3,
              height: _side * 0.1,
            ),
            math.pi * 0.1,
            math.pi * 0.8,
            false,
            paint,
          );
        }
      case _Fx.feathers:
        for (var i = 0; i < count(3); i++) {
          final life = (s * 0.25 + _rand(i, 1)) % 1;
          final x = _size.width * _rand(i, 2) + math.sin(life * 6) * _px * 4;
          final y = _size.height * life;
          _canvas
            ..save()
            ..translate(x, y)
            ..rotate(math.sin(life * 6) * 0.8)
            ..drawOval(
              Rect.fromCenter(
                center: Offset.zero,
                width: _px * 1.2,
                height: _px * 3,
              ),
              Paint()
                ..color = Colors.white.withValues(
                  alpha: math.sin(life * math.pi),
                ),
            )
            ..restore();
        }
      case _Fx.smoke:
        for (var i = 0; i < count(6); i++) {
          final life = (s * 0.4 + _rand(i, 1)) % 1;
          final c = Offset(
            cx + _side * (_rand(i, 2) - 0.5) * 0.6,
            _ground.dy - _side * 0.6 * life,
          );
          // Sombra morada que sube y se disipa.
          _canvas.drawCircle(
            c,
            _side * (0.04 + 0.06 * life),
            Paint()
              ..color = const Color(0xFF4B2A73)
                  .withValues(alpha: 0.28 * math.sin(life * math.pi))
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, _px),
          );
        }
      case _Fx.glints:
        for (var i = 0; i < count(3); i++) {
          final cycle = (s * 0.5 + _rand(i, 1)).floor();
          final life = (s * 0.5 + _rand(i, 1)) % 1;
          final c = Offset(
            cx + _side * (_rand(i, 10 + cycle) - 0.5) * 0.5,
            _center.dy + _side * (_rand(i, 20 + cycle) - 0.5) * 0.5,
          );
          _star(
            c,
            Colors.white,
            life < 0.3 ? math.sin(life / 0.3 * math.pi) : 0,
          );
        }
      case _Fx.rays:
        // Rayos de luz que giran detrás de los legendarios.
        final radius = _side * 0.75;
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(
                layer.color,
                const Color(0xFFFFE27A),
                0.6,
              )!.withValues(alpha: 0.35),
              const Color(0x00FFFFFF),
            ],
          ).createShader(Rect.fromCircle(center: _center, radius: radius));
        const rays = 12;
        for (var i = 0; i < rays; i++) {
          final a = s * 0.25 + i * 2 * math.pi / rays;
          const half = math.pi / rays / 2;
          _canvas.drawPath(
            Path()
              ..moveTo(_center.dx, _center.dy)
              ..lineTo(
                _center.dx + math.cos(a - half) * radius,
                _center.dy + math.sin(a - half) * radius,
              )
              ..lineTo(
                _center.dx + math.cos(a + half) * radius,
                _center.dy + math.sin(a + half) * radius,
              )
              ..close(),
            paint,
          );
        }
    }
  }

  /// Rayos eléctricos con resplandor, a ráfagas.
  void _bolts(double density) {
    final s = time;
    final charging = pose.action == _Action.charge;
    final burst = pose.glow > 0.6 || charging;
    final window = (s * 0.8 + profile.phase) % 1;
    if (!burst && window > 0.22) return;
    // Parpadeo dentro de la ráfaga.
    if ((s * 30).floor().isOdd) return;
    final step = (s * 15).floor();
    final count = math.max(2, ((charging ? 6 : 4) * density).round());
    // Destello en toda la pantalla.
    _canvas.drawRect(
      Offset.zero & _size,
      Paint()..color = const Color(0xFFFFF27A).withValues(alpha: 0.08),
    );
    for (var i = 0; i < count; i++) {
      final angle = 2 * math.pi * _rand(i, step);
      final dir = Offset(math.cos(angle), math.sin(angle));
      final normal = Offset(-dir.dy, dir.dx);
      var point = _center + dir * _side * (0.18 + 0.12 * _rand(i, step + 1));
      final path = Path()..moveTo(point.dx, point.dy);
      for (var j = 0; j < 4; j++) {
        point += dir * _px * 3 + normal * _px * 2.2 * (j.isEven ? 1 : -1);
        path.lineTo(point.dx, point.dy);
      }
      _canvas
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _px * 2.4
            ..color = const Color(0xFFFFE600).withValues(alpha: 0.35),
        )
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _px * 0.9
            ..color = const Color(0xFFFFFDE0),
        );
    }
  }

  /// Polvo al golpear el suelo.
  void _dust() {
    final impact = pose.impact;
    if (impact <= 0.05) return;
    final spread = 1 - impact;
    for (var i = 0; i < 8; i++) {
      final side = i.isEven ? -1 : 1;
      final c = Offset(
        _ground.dx + side * _side * (0.15 + 0.3 * spread * (0.5 + _rand(i, 1))),
        _ground.dy - _px * (1 + 3 * spread * _rand(i, 2)),
      );
      _canvas.drawCircle(
        c,
        _px * (1 + 1.2 * spread),
        Paint()
          ..color = const Color(0xFFC9B28A).withValues(alpha: 0.75 * impact),
      );
    }
  }

  /// Estrella de impacto al golpear hacia delante.
  void _impact() {
    final hit = pose.hit;
    if (hit <= 0.05) return;
    final c = _center + Offset(0, _side * 0.05);
    final paint = Paint()
      ..strokeWidth = _px * 0.9
      ..strokeCap = StrokeCap.square;
    for (var i = 0; i < 10; i++) {
      final a = i * 2 * math.pi / 10 + profile.phase;
      final dir = Offset(math.cos(a), math.sin(a));
      final inner = _side * (0.25 + 0.1 * hit);
      final outer = inner + _side * (i.isEven ? 0.18 : 0.1) * hit;
      paint.color = (i.isEven ? const Color(0xFFFFE04A) : Colors.white)
          .withValues(alpha: hit);
      _canvas.drawLine(c + dir * inner, c + dir * outer, paint);
    }
  }

  /// Detrás: onda del rugido.
  void _actionBack() {
    if (pose.action != _Action.roar) return;
    final a = pose.actionPhase;
    if (a < 0.25) return;
    for (var i = 0; i < 2; i++) {
      final life = ((a - 0.25) / 0.75 * 1.4 - i * 0.35).clamp(0.0, 1.0);
      if (life <= 0 || life >= 1) continue;
      _canvas.drawCircle(
        _center,
        _side * (0.2 + 0.6 * life),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _px * (1.5 - life)
          ..color = Colors.white.withValues(alpha: 0.6 * (1 - life)),
      );
    }
  }

  /// Delante: energía que se concentra y estalla, escudo, destellos.
  void _actionFront() {
    final a = pose.actionPhase;
    switch (pose.action) {
      case _Action.charge:
        if (a < 0.75) {
          // Partículas que se juntan en el centro.
          for (var i = 0; i < 10; i++) {
            final life = (a / 0.75 * 2 + _rand(i, 1)) % 1;
            final angle = 2 * math.pi * _rand(i, 2);
            final c =
                _center +
                Offset(math.cos(angle), math.sin(angle)) *
                    _side *
                    0.5 *
                    (1 - life);
            _square(c, profile.color.withValues(alpha: life), 1.1);
          }
        } else {
          final burst = (a - 0.75) / 0.25;
          _canvas.drawCircle(
            _center,
            _side * (0.15 + 0.45 * burst),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = _px * 1.5 * (1 - burst)
              ..color = Colors.white.withValues(alpha: 1 - burst),
          );
          for (var i = 0; i < 12; i++) {
            final angle = i * math.pi / 6;
            _square(
              _center +
                  Offset(math.cos(angle), math.sin(angle)) *
                      _side *
                      (0.2 + 0.4 * burst),
              profile.color.withValues(alpha: 1 - burst),
              1.3,
            );
          }
        }
      case _Action.brace:
        // Escudo hexagonal.
        final show = math.sin(a * math.pi);
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = i * math.pi / 3 + math.pi / 6;
          final p =
              _center + Offset(math.cos(angle), math.sin(angle)) * _side * 0.45;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        _canvas
          ..drawPath(
            path,
            Paint()
              ..color = const Color(0xFF8FE3FF).withValues(alpha: 0.18 * show),
          )
          ..drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = _px * 0.8
              ..color = const Color(0xFFBFF4FF).withValues(alpha: 0.9 * show),
          );
      case _Action.twirl || _Action.spin:
        for (var i = 0; i < 6; i++) {
          final angle = a * 4 * math.pi + i * math.pi / 3;
          _star(
            _center +
                Offset(
                  math.cos(angle) * _side * 0.38,
                  math.sin(angle) * _side * 0.14,
                ),
            Colors.white,
            math.sin(a * math.pi),
          );
        }
      default:
        break;
    }
  }

  /// Brillo de los variocolor, como en los juegos: al aparecer, estrellas
  /// que giran a su alrededor y se abren; después, algún destello suelto
  /// sobre su cuerpo cada pocos segundos.
  void _shinySparkle() {
    const gold = Color(0xFFFFE04A);
    if (time > 0.25 && time < 1.7) {
      final life = (time - 0.25) / 1.45;
      for (var i = 0; i < 10; i++) {
        final delay = (i % 2) * 0.18;
        final t = ((life - delay) / (1 - delay)).clamp(0.0, 1.0);
        if (t <= 0 || t >= 1) continue;
        final angle = i * math.pi / 5 + t * math.pi * 1.4;
        final radius = _side * (0.12 + 0.4 * Curves.easeOut.transform(t));
        _star(
          _center + Offset(math.cos(angle), math.sin(angle) * 0.8) * radius,
          i.isEven ? gold : Colors.white,
          math.sin(t * math.pi) * 1.3,
        );
      }
    }
    final cycle = (time / 3.5).floor();
    final local = time % 3.5;
    if (time > 2 && local < 0.6) {
      for (var i = 0; i < 3; i++) {
        final t = ((local - i * 0.12) / 0.35).clamp(0.0, 1.0);
        if (t <= 0 || t >= 1) continue;
        final p =
            _center +
            Offset(
              (_rand(i, 50 + cycle) - 0.5) * _side * 0.45,
              (_rand(i, 60 + cycle) - 0.5) * _side * 0.45,
            );
        _star(p, i.isEven ? Colors.white : gold, math.sin(t * math.pi));
      }
    }
  }

  /// Destello al aparecer: anillo del color de su tipo.
  void _entrance() {
    if (time > 0.9) return;
    final life = time / 0.9;
    _canvas.drawCircle(
      _center,
      _side * (0.1 + 0.55 * Curves.easeOut.transform(life)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _px * 1.5 * (1 - life)
        ..color = profile.color.withValues(alpha: 1 - life),
    );
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + 0.3;
      _star(
        _center +
            Offset(math.cos(angle), math.sin(angle)) * _side * 0.45 * life,
        Colors.white,
        1 - life,
      );
    }
  }

  @override
  bool shouldRepaint(_FxPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.profile != profile;
}

// ---------------------------------------------------------------- Ataques

/// Cómo se ve un ataque.
enum _MoveStyle {
  /// Rayo continuo (Hiperrayo, Rayo Hielo, Hidrobomba, Rayo Solar...).
  beam,

  /// Chorro de fuego (Lanzallamas, Llamarada, Fuego Sagrado...).
  flame,

  /// Descargas que salen del cuerpo (Impactrueno, Rayo).
  bolt,

  /// Rayo que cae del cielo (Trueno).
  thunder,

  /// Proyectiles (Bola Sombra, Esfera Aural, Hoja Afilada, Rapidez...).
  projectile,

  /// Ondas que avanzan (Psíquico, Pulso Umbrío, Zumbido, Canto).
  wave,

  /// El suelo tiembla y se agrieta (Terremoto, Golpe Cuerpo).
  quake,

  /// Rocas que caen (Avalancha).
  rockfall,

  /// Tormenta de nieve (Ventisca).
  blizzard,

  /// Ráfaga de golpes (A Bocajarro, Puño Dinámico).
  flurry,

  /// Destello que llena la pantalla (Brillo Mágico).
  gleam,

  /// Salpicadura: no pasa nada.
  splash,
}

/// Forma de los proyectiles.
enum _Shot { orb, blob, star, leaf, shuriken, crescent }

class _Move {
  const _Move(
    this.name,
    this.style,
    this.colors, {
    this.shot = _Shot.orb,
    this.count = 1,
    this.size = 1,
  });

  final String name;
  final _MoveStyle style;

  /// Color principal y color del centro (el más brillante).
  final List<Color> colors;
  final _Shot shot;

  /// Proyectiles por ataque.
  final int count;

  /// Tamaño relativo del ataque.
  final double size;

  /// Duración en segundos.
  double get length => switch (style) {
    _MoveStyle.quake || _MoveStyle.blizzard => 2.2,
    _MoveStyle.splash => 2.0,
    _ => 2.4,
  };
}

const _hyperBeam = _Move('Hiperrayo', _MoveStyle.beam, [
  Color(0xFFFF9F1C),
  Color(0xFFFFF3B0),
], size: 1.2);
const _flamethrower = _Move('Lanzallamas', _MoveStyle.flame, [
  Color(0xFFE8320C),
  Color(0xFFFFE04A),
]);
const _hydroPump = _Move('Hidrobomba', _MoveStyle.beam, [
  Color(0xFF2F7DFF),
  Color(0xFFD6F0FF),
], size: 1.1);
const _thunderbolt = _Move('Rayo', _MoveStyle.bolt, [
  Color(0xFFFFD500),
  Color(0xFFFFFDE0),
]);
const _razorLeaf = _Move(
  'Hoja Afilada',
  _MoveStyle.projectile,
  [Color(0xFF3FBF3F), Color(0xFFB7F5A0)],
  shot: _Shot.leaf,
  count: 6,
);
const _iceBeam = _Move('Rayo Hielo', _MoveStyle.beam, [
  Color(0xFF6FD3FF),
  Color(0xFFFFFFFF),
], size: 0.8);
const _closeCombat = _Move('A Bocajarro', _MoveStyle.flurry, [
  Color(0xFFFFE04A),
  Color(0xFFFFFFFF),
]);
const _sludgeBomb = _Move(
  'Bomba Lodo',
  _MoveStyle.projectile,
  [Color(0xFF8E3FBF), Color(0xFFD9A3FF)],
  shot: _Shot.blob,
  count: 3,
);
const _earthquake = _Move('Terremoto', _MoveStyle.quake, [
  Color(0xFF8B6B3E),
  Color(0xFFC9B28A),
]);
const _airSlash = _Move(
  'Tajo Aéreo',
  _MoveStyle.projectile,
  [Color(0xFFDDF4FF), Color(0xFFFFFFFF)],
  shot: _Shot.crescent,
  count: 3,
);
const _psychic = _Move('Psíquico', _MoveStyle.wave, [
  Color(0xFFFF4FBF),
  Color(0xFFFFC6EC),
]);
const _bugBuzz = _Move('Zumbido', _MoveStyle.wave, [
  Color(0xFF8BC34A),
  Color(0xFFE6FFB0),
]);
const _rockSlide = _Move('Avalancha', _MoveStyle.rockfall, [
  Color(0xFF8C7853),
  Color(0xFFC8B07A),
]);
const _shadowBall = _Move('Bola Sombra', _MoveStyle.projectile, [
  Color(0xFF4B2A73),
  Color(0xFFB57BFF),
], size: 1.4);
const _dragonPulse = _Move('Pulso Dragón', _MoveStyle.beam, [
  Color(0xFF5B3BFF),
  Color(0xFFB9E4FF),
], size: 1.1);
const _darkPulse = _Move('Pulso Umbrío', _MoveStyle.wave, [
  Color(0xFF3A1F4F),
  Color(0xFF9B59B6),
]);
const _flashCannon = _Move('Foco Resplandor', _MoveStyle.beam, [
  Color(0xFFB8C4D6),
  Color(0xFFFFFFFF),
]);
const _moonblast = _Move('Fuerza Lunar', _MoveStyle.projectile, [
  Color(0xFFFF8AD8),
  Color(0xFFFFF0FA),
], size: 1.5);
const _waterGun = _Move('Pistola Agua', _MoveStyle.beam, [
  Color(0xFF2F7DFF),
  Color(0xFFD6F0FF),
], size: 0.6);
const _thunder = _Move('Trueno', _MoveStyle.thunder, [
  Color(0xFFFFD500),
  Color(0xFFFFFDE0),
]);
const _sing = _Move('Canto', _MoveStyle.wave, [
  Color(0xFFFF8AD8),
  Color(0xFFFFF0FA),
]);
const _dazzlingGleam = _Move('Brillo Mágico', _MoveStyle.gleam, [
  Color(0xFFFF8AD8),
  Color(0xFFFFFFFF),
]);

/// Ataque típico de cada tipo.
const _typeMoves = <String, _Move>{
  'normal': _hyperBeam,
  'fire': _flamethrower,
  'water': _hydroPump,
  'electric': _thunderbolt,
  'grass': _razorLeaf,
  'ice': _iceBeam,
  'fighting': _closeCombat,
  'poison': _sludgeBomb,
  'ground': _earthquake,
  'flying': _airSlash,
  'psychic': _psychic,
  'bug': _bugBuzz,
  'rock': _rockSlide,
  'ghost': _shadowBall,
  'dragon': _dragonPulse,
  'dark': _darkPulse,
  'steel': _flashCannon,
  'fairy': _moonblast,
};

/// Ataques característicos de Pokémon famosos.
const _signatureMoves = <int, _Move>{
  1: _razorLeaf, // Bulbasaur
  2: _razorLeaf,
  3: _Move('Rayo Solar', _MoveStyle.beam, [
    Color(0xFFFFE04A),
    Color(0xFFFFFFF0),
  ], size: 1.6),
  4: _Move('Ascuas', _MoveStyle.flame, [
    Color(0xFFFF6A1C),
    Color(0xFFFFE04A),
  ], size: 0.6),
  5: _flamethrower,
  6: _Move('Lanzallamas', _MoveStyle.flame, [
    Color(0xFFE8320C),
    Color(0xFFFFE04A),
  ], size: 1.4),
  7: _waterGun, // Squirtle
  8: _waterGun,
  9: _Move('Hidrobomba', _MoveStyle.beam, [
    Color(0xFF2F7DFF),
    Color(0xFFD6F0FF),
  ], size: 1.5),
  25: _Move('Impactrueno', _MoveStyle.bolt, [
    Color(0xFFFFD500),
    Color(0xFFFFFDE0),
  ]),
  26: _thunder,
  35: _moonblast,
  36: _moonblast,
  39: _sing, // Jigglypuff
  40: _sing,
  54: _Move('Confusión', _MoveStyle.wave, [
    Color(0xFFFF4FBF),
    Color(0xFFFFC6EC),
  ]),
  65: _psychic,
  68: _Move('Puño Dinámico', _MoveStyle.flurry, [
    Color(0xFFFF6A1C),
    Color(0xFFFFFFFF),
  ]),
  94: _shadowBall,
  95: _rockSlide,
  129: _Move('Salpicadura', _MoveStyle.splash, [
    Color(0xFF6EC3FF),
    Color(0xFFFFFFFF),
  ]),
  130: _hyperBeam,
  131: _iceBeam,
  133: _Move(
    'Rapidez',
    _MoveStyle.projectile,
    [Color(0xFFFFD500), Color(0xFFFFFDE0)],
    shot: _Shot.star,
    count: 5,
  ),
  143: _Move('Golpe Cuerpo', _MoveStyle.quake, [
    Color(0xFF8B6B3E),
    Color(0xFFC9B28A),
  ]),
  144: _Move('Ventisca', _MoveStyle.blizzard, [
    Color(0xFFBFF4FF),
    Color(0xFFFFFFFF),
  ]),
  145: _thunder,
  146: _Move('Llamarada', _MoveStyle.flame, [
    Color(0xFFE8320C),
    Color(0xFFFFE04A),
  ], size: 1.6),
  149: _hyperBeam,
  150: _Move('Onda Mental', _MoveStyle.wave, [
    Color(0xFF9B6BFF),
    Color(0xFFFFC6EC),
  ], size: 1.4),
  151: _psychic,
  196: _psychic,
  197: _darkPulse,
  249: _Move('Aerochorro', _MoveStyle.beam, [
    Color(0xFF9FD8FF),
    Color(0xFFFFFFFF),
  ], size: 1.4),
  250: _Move('Fuego Sagrado', _MoveStyle.flame, [
    Color(0xFFFF4F9A),
    Color(0xFFFFE04A),
  ], size: 1.5),
  282: _dazzlingGleam,
  382: _Move(
    'Pulso Primigenio',
    _MoveStyle.projectile,
    [Color(0xFF2F7DFF), Color(0xFFD6F0FF)],
    count: 4,
    size: 1.2,
  ),
  383: _Move('Filo del Abismo', _MoveStyle.quake, [
    Color(0xFFE8320C),
    Color(0xFFFFB04A),
  ]),
  384: _Move('Ascenso Draco', _MoveStyle.beam, [
    Color(0xFF3FBF6A),
    Color(0xFFE6FFB0),
  ], size: 1.6),
  448: _Move('Esfera Aural', _MoveStyle.projectile, [
    Color(0xFF2F7DFF),
    Color(0xFFD6F0FF),
  ], size: 1.3),
  658: _Move(
    'Shuriken de Agua',
    _MoveStyle.projectile,
    [Color(0xFF2F7DFF), Color(0xFFD6F0FF)],
    shot: _Shot.shuriken,
    count: 3,
  ),
  700: _dazzlingGleam,
};

_Move _moveFor(int species, List<String> types) =>
    _signatureMoves[species] ??
    _typeMoves[types.first] ??
    _typeMoves['normal']!;

/// Cuándo ataca: el primero a los 2 s de aparecer y luego cada
/// [_Profile.attackEvery] segundos. Devuelve por dónde va (0..1) o null.
double? _attackPhase(_Profile profile, double time) {
  if (time < 2) return null;
  final local = (time - 2) % profile.attackEvery;
  final length = profile.move.length;
  return local < length ? local / length : null;
}

/// Postura al atacar: se prepara, lanza el ataque con retroceso y vuelve.
void _applyAttack(_Pose pose, _Move move, double a, double time) {
  pose
    ..move = move
    ..movePhase = a;
  double bump(double from, double to) =>
      a < from || a > to ? 0 : math.sin((a - from) / (to - from) * math.pi);
  // Preparación (0 → 0.3), ataque sostenido (0.3 → 0.8) y vuelta. Todo el
  // cuerpo se mueve junto: se inclina desde los pies.
  final windup = bump(0, 0.32);
  final hold = a < 0.28
      ? 0.0
      : a < 0.36
      ? Curves.easeOut.transform((a - 0.28) / 0.08)
      : a < 0.8
      ? 1.0
      : 1 - Curves.easeIn.transform((a - 0.8) / 0.2);
  final tremble = math.sin(time * 55) * hold;
  pose.glow += 1.2 * windup + 0.5 * hold;

  switch (move.style) {
    case _MoveStyle.flame || _MoveStyle.beam || _MoveStyle.blizzard:
      // Se echa atrás tomando aire, se lanza hacia delante y se sostiene
      // mientras sale el ataque, temblando y empujado por la fuerza.
      pose.lean += -0.1 * windup + (0.07 + 0.01 * tremble) * hold;
      pose.sy *= 1 + 0.05 * windup - 0.03 * hold;
      pose.sx *= 1 - 0.02 * windup + 0.02 * hold;
      pose.forward += 0.02 * windup - 0.02 * hold * move.size;
      pose.shake = math.max(pose.shake, 0.004 * hold * move.size);
    case _MoveStyle.wave:
      // Concentra la mente: sube un poco y vibra.
      pose.dy -= 0.04 * hold;
      pose.lean += -0.05 * windup + 0.03 * hold + 0.015 * tremble;
      pose.sx *= 1 + 0.03 * hold * math.sin(time * 12);
      pose.sy *= 1 - 0.03 * hold * math.sin(time * 12);
    case _MoveStyle.bolt:
      // Se encoge cargando y suelta la descarga temblando.
      pose.sy *= 1 - 0.1 * windup + 0.04 * hold;
      pose.sx *= 1 + 0.06 * windup;
      pose.dx += 0.012 * math.sin(time * 140) * hold;
      pose.dy -= 0.03 * hold;
      pose.glow += 0.8 * hold;
    case _MoveStyle.thunder:
      // Se estira hacia el cielo y llama al rayo.
      pose.lean += -0.1 * (windup + hold * 0.6);
      pose.dx += 0.01 * math.sin(time * 140) * hold;
      pose.sy *= 1 + 0.06 * hold;
    case _MoveStyle.projectile:
      // Se echa hacia atrás para tomar impulso y lo lanza con todo el
      // cuerpo.
      final snap = bump(0.28, 0.5);
      pose.lean += -0.2 * windup + 0.16 * snap;
      pose.forward += -0.03 * windup + 0.06 * snap;
      pose.sx *= 1 + 0.06 * snap;
      pose.sy *= 1 - 0.05 * windup;
    case _MoveStyle.rockfall:
      // Se encabrita y cae con fuerza para provocar el derrumbe.
      final slam = bump(0.3, 0.55);
      pose.lean += -0.25 * windup + 0.14 * slam;
      pose.dy -= 0.06 * windup;
      pose.shake = math.max(pose.shake, 0.02 * slam);
      pose.impact = math.max(pose.impact, slam);
    case _MoveStyle.flurry:
      // Corre hacia el rival y lanza golpes.
      final rush = bump(0.25, 0.85);
      pose.forward += 0.16 * rush;
      final jab = math.sin(a * 34);
      pose.lean += (0.06 + 0.08 * jab) * rush;
      pose.sx *= 1 + 0.06 * jab.abs() * rush;
      pose.hit = math.max(pose.hit, (jab > 0.9 ? 1.0 : 0.0) * rush);
    case _MoveStyle.quake:
      // Salta y cae con todo su peso.
      pose.dy -= 0.18 * bump(0.05, 0.35);
      pose.lean += -0.08 * bump(0.05, 0.35);
      final slam = a > 0.33 && a < 0.85 ? 1 - (a - 0.33) / 0.52 : 0.0;
      pose.shake = math.max(pose.shake, 0.03 * slam);
      pose.impact = math.max(pose.impact, slam);
      pose.sx *= 1 + 0.1 * slam;
      pose.sy *= 1 - 0.1 * slam;
    case _MoveStyle.gleam:
      // Se eleva y se abre para soltar el destello.
      pose.dy -= 0.06 * hold;
      pose.sx *= 1 + 0.08 * hold;
      pose.sy *= 1 + 0.08 * hold;
    case _MoveStyle.splash:
      final flop = math.sin(a * 6 * math.pi);
      pose.dy -= 0.12 * flop.abs();
      pose.rotation += 0.4 * flop;
  }
}

extension on _FxPainter {
  /// Punto desde el que sale el ataque, según el tipo de ataque: la boca
  /// (fuego, rayos, ondas), las mejillas o la cabeza (descargas), el pecho
  /// (esferas que lanza) o el cuerpo (hojas, estrellas...).
  Offset get _mouth => switch (pose.move?.style) {
    _MoveStyle.bolt => _headPoint,
    _MoveStyle.projectile => switch (pose.move?.shot) {
      _Shot.orb => Offset.lerp(_mouthPoint, _center, 0.4)!,
      _Shot.blob => _mouthPoint,
      _ => Offset.lerp(_mouthPoint, _center, 0.6)!,
    },
    _ => _mouthPoint,
  };

  /// Hacia dónde va el ataque: el rival, del lado al que mira.
  Offset get _foe {
    final distance = math.max(_size.width * 0.38, _side * 0.7);
    return Offset(
      (_mouth.dx + _dir * distance).clamp(_px * 3, _size.width - _px * 3),
      _mouth.dy + _side * 0.05,
    );
  }

  void _attack() {
    final move = pose.move;
    if (move == null) return;
    final a = pose.movePhase;
    // Avance del ataque una vez lanzado, y cómo se apaga al final.
    final fire = ((a - 0.25) / 0.55).clamp(0.0, 1.0);
    final fade = a < 0.8 ? 1.0 : 1 - (a - 0.8) / 0.2;
    final windup = a < 0.3 ? a / 0.3 : 0.0;

    // Energía que se concentra en la boca antes de lanzarlo.
    final charges = switch (move.style) {
      _MoveStyle.quake || _MoveStyle.splash || _MoveStyle.flurry => false,
      _ => true,
    };
    if (windup > 0 && charges) {
      _orb(
        _mouth,
        _px * (0.5 + 2.5 * windup) * move.size,
        move.colors[0],
        move.colors[1],
        windup,
      );
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 + time * 3;
        _square(
          _mouth +
              Offset(math.cos(angle), math.sin(angle)) *
                  _side *
                  0.2 *
                  (1 - windup),
          move.colors[1].withValues(alpha: windup),
          0.8,
        );
      }
    }
    if (a < 0.25) return;

    switch (move.style) {
      case _MoveStyle.beam:
        _beam(move, fire, fade);
      case _MoveStyle.flame:
        _flame(move, fire, fade);
      case _MoveStyle.bolt:
        _boltAttack(move, fade, fromSky: false);
      case _MoveStyle.thunder:
        _boltAttack(move, fade, fromSky: true);
      case _MoveStyle.projectile:
        _projectiles(move, a);
      case _MoveStyle.wave:
        _waves(move, fire, fade);
      case _MoveStyle.quake:
        _quake(move, a);
      case _MoveStyle.rockfall:
        _rockfall(move, a);
      case _MoveStyle.blizzard:
        _blizzard(move, fire, fade);
      case _MoveStyle.flurry:
        _flurry(move, a);
      case _MoveStyle.gleam:
        _gleam(move, fire, fade);
      case _MoveStyle.splash:
        _splashMove(a);
    }
  }

  /// Esfera de energía con resplandor.
  void _orb(Offset c, double r, Color outer, Color inner, double alpha) {
    if (r <= 0 || alpha <= 0) return;
    _canvas
      ..drawCircle(
        c,
        r * 1.8,
        Paint()
          ..color = outer.withValues(alpha: 0.35 * alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      )
      ..drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              inner.withValues(alpha: alpha),
              outer.withValues(alpha: alpha),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
  }

  /// Destello de impacto donde llega el ataque.
  void _burst(Offset c, Color color, double strength, [double scale = 1]) {
    if (strength <= 0) return;
    _orb(c, _px * 3 * scale * strength, color, Colors.white, strength);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + time * 4;
      _square(
        c +
            Offset(math.cos(angle), math.sin(angle)) *
                _px *
                (3 + 4 * strength) *
                scale,
        color.withValues(alpha: strength),
      );
    }
  }

  void _beam(_Move move, double fire, double fade) {
    final reach = (fire / 0.25).clamp(0.0, 1.0);
    final end = Offset.lerp(_mouth, _foe, reach)!;
    final width =
        _side * 0.06 * move.size * fade * (1 + 0.15 * math.sin(time * 45));
    if (width <= 0.5) return;
    _canvas
      ..drawLine(
        _mouth,
        end,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width * 2.2
          ..color = move.colors[0].withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.5),
      )
      ..drawLine(
        _mouth,
        end,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width
          ..color = move.colors[0],
      )
      ..drawLine(
        _mouth,
        end,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width * 0.4
          ..color = move.colors[1],
      );
    // Anillos que recorren el rayo.
    final dir = _foe - _mouth;
    for (var i = 0; i < 4; i++) {
      final t = (time * 2.5 + i / 4) % 1;
      if (t > reach) continue;
      _canvas.drawOval(
        Rect.fromCenter(
          center: _mouth + dir * t,
          width: width * 0.8,
          height: width * 2,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _px * 0.5
          ..color = move.colors[1].withValues(alpha: 0.8 * fade),
      );
    }
    if (reach >= 1) {
      _burst(end, move.colors[0], fade, move.size);
      for (var i = 0; i < 6; i++) {
        final angle =
            math.pi * (0.5 + _rand(i, (time * 8).floor())) +
            (_dir > 0 ? math.pi : 0);
        _star(
          end +
              Offset(math.cos(angle), math.sin(angle)) *
                  _side *
                  0.12 *
                  _rand(i, 5),
          move.colors[1],
          fade,
        );
      }
    }
  }

  void _flame(_Move move, double fire, double fade) {
    const n = 46;
    final dir = _foe - _mouth;
    final normal = Offset(-dir.dy, dir.dx) / dir.distance;
    for (var k = 0; k < n; k++) {
      // Cada llamita sale en su momento y viaja hasta el rival.
      final q = ((fire - k / n * 0.55) / 0.45).clamp(0.0, 1.0);
      if (q <= 0 || q >= 1) continue;
      final spread = (_rand(k, 7) - 0.5) * _side * 0.3 * q * move.size;
      final p = _mouth + dir * q + normal * spread;
      final r = _px * (0.8 + 3 * q) * move.size;
      final color = Color.lerp(move.colors[1], move.colors[0], q)!;
      _canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = color.withValues(alpha: (1 - q * 0.7) * fade)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4),
      );
    }
    if (fire > 0.45) _burst(_foe, move.colors[0], fade, move.size);
  }

  void _boltAttack(_Move move, double fade, {required bool fromSky}) {
    // Las descargas parpadean.
    if ((time * 24).floor().isOdd || fade <= 0) return;
    final step = (time * 12).floor();
    _canvas.drawRect(
      Offset.zero & _size,
      Paint()
        ..color = (fromSky ? Colors.white : move.colors[1]).withValues(
          alpha: (fromSky ? 0.25 : 0.12) * fade,
        ),
    );
    final bolts = fromSky ? 1 : 3;
    for (var i = 0; i < bolts; i++) {
      final start = fromSky
          ? Offset(_foe.dx + _px * 4 * (_rand(i, step) - 0.5), 0)
          : _mouth;
      final end =
          _foe +
          Offset(
            (_rand(i, step + 3) - 0.5) * _side * 0.2,
            (_rand(i, step + 4) - 0.5) * _side * 0.25,
          );
      final dir = end - start;
      final normal = Offset(-dir.dy, dir.dx) / dir.distance;
      final path = Path()..moveTo(start.dx, start.dy);
      const segments = 7;
      for (var j = 1; j <= segments; j++) {
        final wiggle = j == segments ? 0.0 : _rand(i * 9 + j, step) - 0.5;
        final p = start + dir * (j / segments) + normal * wiggle * _side * 0.12;
        path.lineTo(p.dx, p.dy);
      }
      final width = _px * (fromSky ? 1.6 : 1);
      _canvas
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width * 3
            ..color = move.colors[0].withValues(alpha: 0.4 * fade)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, width),
        )
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..color = move.colors[1].withValues(alpha: fade),
        );
    }
    _burst(_foe, move.colors[0], fade, fromSky ? 1.4 : 1);
  }

  void _projectiles(_Move move, double a) {
    final arc = move.shot == _Shot.blob;
    for (var i = 0; i < move.count; i++) {
      final q = (a - 0.25 - i * 0.07) / 0.35;
      final spread = move.count == 1
          ? 0.0
          : (i / (move.count - 1) - 0.5) * _side * 0.3;
      Offset at(double q) {
        final p = Offset.lerp(_mouth, _foe + Offset(0, spread), q)!;
        return arc ? p - Offset(0, _side * 0.35 * 4 * q * (1 - q)) : p;
      }

      if (q > 0 && q < 1) {
        // Estela.
        for (var t = 3; t >= 1; t--) {
          final tq = q - t * 0.05;
          if (tq <= 0) continue;
          _orb(
            at(tq),
            _px * 0.8 * move.size,
            move.colors[0],
            move.colors[1],
            0.3 / t,
          );
        }
        _shot(move, at(q));
      } else if (q >= 1 && q < 1.3) {
        _burst(at(1), move.colors[0], 1 - (q - 1) / 0.3, move.size);
      }
    }
  }

  void _shot(_Move move, Offset c) {
    final r = _px * 2 * move.size;
    final spin = time * 14;
    switch (move.shot) {
      case _Shot.orb:
        _orb(c, r, move.colors[0], move.colors[1], 1);
        // Remolino de energía.
        for (var i = 0; i < 3; i++) {
          final angle = spin + i * 2 * math.pi / 3;
          _square(
            c + Offset(math.cos(angle), math.sin(angle)) * r * 0.8,
            move.colors[1],
            0.6,
          );
        }
      case _Shot.blob:
        _canvas.drawCircle(c, r * 0.8, Paint()..color = move.colors[0]);
        _square(c - Offset(r * 0.3, r * 0.3), move.colors[1], 0.7);
      case _Shot.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final rr = i.isEven ? r : r * 0.45;
          final angle = i * math.pi / 5 - math.pi / 2 + spin * 0.5;
          final p = c + Offset(math.cos(angle), math.sin(angle)) * rr;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        _canvas
          ..drawPath(path, Paint()..color = move.colors[0])
          ..drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = _px * 0.4
              ..color = move.colors[1],
          );
      case _Shot.leaf:
        _canvas
          ..save()
          ..translate(c.dx, c.dy)
          ..rotate(spin)
          ..drawOval(
            Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.8),
            Paint()..color = move.colors[0],
          )
          ..drawLine(
            Offset(-r, 0),
            Offset(r, 0),
            Paint()
              ..strokeWidth = _px * 0.3
              ..color = move.colors[1],
          )
          ..restore();
      case _Shot.shuriken:
        _canvas
          ..save()
          ..translate(c.dx, c.dy)
          ..rotate(spin * 1.5);
        for (var i = 0; i < 4; i++) {
          _canvas
            ..rotate(math.pi / 2)
            ..drawPath(
              Path()
                ..moveTo(0, 0)
                ..lineTo(r * 1.4, -r * 0.3)
                ..lineTo(r * 0.3, r * 0.3)
                ..close(),
              Paint()..color = i.isEven ? move.colors[0] : move.colors[1],
            );
        }
        _canvas.restore();
      case _Shot.crescent:
        _canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 1.4),
          math.pi * 0.6,
          math.pi * 0.8,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _px * 0.9
            ..strokeCap = StrokeCap.round
            ..color = move.colors[0],
        );
    }
  }

  void _waves(_Move move, double fire, double fade) {
    final sing = move.name == 'Canto';
    final around = move.name == 'Pulso Umbrío';
    // La pantalla se tiñe un poco.
    _canvas.drawRect(
      Offset.zero & _size,
      Paint()
        ..color = move.colors[0].withValues(
          alpha: 0.08 * fade * (0.6 + 0.4 * math.sin(time * 12)),
        ),
    );
    for (var i = 0; i < 5; i++) {
      final q = (fire * 1.4 - i * 0.16).clamp(0.0, 1.0);
      if (q <= 0 || q >= 1) continue;
      final radius = _side * (0.12 + 0.75 * q) * move.size;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _px * (1.6 - q)
        ..color = Color.lerp(
          move.colors[1],
          move.colors[0],
          q,
        )!.withValues(alpha: (1 - q) * fade);
      if (around) {
        _canvas.drawCircle(_center, radius, paint);
      } else {
        _canvas.drawArc(
          Rect.fromCircle(center: _mouth, radius: radius),
          _dir < 0 ? math.pi * 0.72 : -math.pi * 0.28,
          math.pi * 0.56,
          false,
          paint,
        );
      }
      if (sing) {
        _bits(
          _noteBits,
          _mouth + Offset(_dir * radius, math.sin(time * 6 + i) * _px * 3),
          move.colors[0].withValues(alpha: (1 - q) * fade),
          0.9,
        );
      }
    }
  }

  void _quake(_Move move, double a) {
    if (a < 0.33) return;
    final q = ((a - 0.33) / 0.6).clamp(0.0, 1.0);
    final fade = 1 - q;
    // Grietas que se abren desde donde cae.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _px * 0.7
      ..color = Colors.black.withValues(alpha: 0.7 * fade);
    for (var i = 0; i < 6; i++) {
      final side = i.isEven ? -1 : 1;
      var p = _ground;
      final path = Path()..moveTo(p.dx, p.dy);
      for (var j = 0; j < 5; j++) {
        p += Offset(
          side * _side * 0.07 * math.min(1, q * 3),
          (_rand(i * 5 + j, 3) - 0.5) * _px * 3,
        );
        path.lineTo(p.dx, p.dy);
      }
      _canvas.drawPath(path, paint);
    }
    // Rocas (o lava) que saltan.
    for (var i = 0; i < 10; i++) {
      final life = (q * 1.5 - _rand(i, 1) * 0.4).clamp(0.0, 1.0);
      if (life <= 0 || life >= 1) continue;
      final x = _ground.dx + (_rand(i, 2) - 0.5) * _size.width * 0.9;
      final y = _ground.dy - _side * 0.35 * 4 * life * (1 - life);
      _square(
        Offset(x, y),
        (i.isEven ? move.colors[0] : move.colors[1]).withValues(alpha: fade),
        1.6,
      );
    }
  }

  void _rockfall(_Move move, double a) {
    for (var i = 0; i < 6; i++) {
      final q = (a - 0.25 - i * 0.07) / 0.25;
      final x = _foe.dx - _dir * (_rand(i, 1) - 0.3) * _side * 0.45;
      final groundY = _foe.dy + _side * 0.12;
      if (q > 0 && q < 1) {
        final y = -_px * 4 + (groundY + _px * 4) * q * q;
        final size = 2.2 + _rand(i, 2) * 1.4;
        _square(Offset(x, y), move.colors[0], size);
        _square(
          Offset(x - _px * 0.5, y - _px * 0.5),
          move.colors[1],
          size * 0.45,
        );
      } else if (q >= 1 && q < 1.6) {
        final puff = (q - 1) / 0.6;
        for (final side in const [-1, 1]) {
          _canvas.drawCircle(
            Offset(x + side * _px * 3 * puff, groundY),
            _px * (1 + 1.5 * puff),
            Paint()
              ..color = const Color(0xFFC9B28A)
                  .withValues(alpha: 0.8 * (1 - puff)),
          );
        }
      }
    }
  }

  void _blizzard(_Move move, double fire, double fade) {
    _canvas.drawRect(
      Offset.zero & _size,
      Paint()..color = Colors.white.withValues(alpha: 0.25 * fade * fire),
    );
    for (var i = 0; i < 40; i++) {
      final life = (time * 1.6 + _rand(i, 1)) % 1;
      final x = _dir < 0
          ? _size.width * (1.1 - 1.3 * life)
          : _size.width * (-0.1 + 1.3 * life);
      final y = _size.height * _rand(i, 2) + math.sin(life * 8 + i) * _px * 2;
      final color = move.colors[i % 2].withValues(alpha: fade);
      if (i % 5 == 0) {
        _star(Offset(x, y), color, 0.7 * fade);
      } else {
        _square(Offset(x, y), color, 0.8);
      }
    }
  }

  void _flurry(_Move move, double a) {
    for (var i = 0; i < 5; i++) {
      final q = (a - 0.3 - i * 0.09) / 0.14;
      if (q <= 0 || q >= 1) continue;
      final c =
          _foe +
          Offset(
            -_dir * (_rand(i, 1) - 0.3) * _side * 0.3,
            (_rand(i, 2) - 0.5) * _side * 0.35,
          );
      final strength = math.sin(q * math.pi);
      final paint = Paint()
        ..strokeWidth = _px * 0.9
        ..strokeCap = StrokeCap.square;
      for (var k = 0; k < 8; k++) {
        final angle = k * math.pi / 4 + i;
        final dir = Offset(math.cos(angle), math.sin(angle));
        paint.color = (k.isEven ? move.colors[0] : move.colors[1]).withValues(
          alpha: strength,
        );
        _canvas.drawLine(
          c + dir * _px * 2,
          c + dir * _px * (3 + (k.isEven ? 5 : 3) * strength),
          paint,
        );
      }
    }
  }

  void _gleam(_Move move, double fire, double fade) {
    _canvas.drawRect(
      Offset.zero & _size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.7 * fade),
            move.colors[0].withValues(alpha: 0.3 * fade),
            move.colors[0].withValues(alpha: 0),
          ],
          stops: const [0, 0.4, 1],
          radius: 0.4 + 0.8 * fire,
        ).createShader(Offset.zero & _size),
    );
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 + _rand(i, 1);
      _star(
        _center +
            Offset(math.cos(angle), math.sin(angle)) *
                _side *
                (0.15 + 0.6 * fire) *
                (0.6 + 0.4 * _rand(i, 2)),
        i.isEven ? Colors.white : move.colors[0],
        fade,
      );
    }
  }

  void _splashMove(double a) {
    // Unas gotitas... y nada más.
    for (var i = 0; i < 8; i++) {
      final life = (a * 3 + _rand(i, 1)) % 1;
      final x = _ground.dx + (_rand(i, 2) - 0.5) * _side * 0.6 * life;
      final y = _ground.dy - _side * 0.25 * 4 * life * (1 - life);
      _square(
        Offset(x, y),
        const Color(0xFF6EC3FF).withValues(alpha: 1 - life),
        0.8,
      );
    }
  }
}
