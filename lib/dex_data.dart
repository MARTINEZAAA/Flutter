part of 'main.dart';

// Generaciones y tabla de tipos.

class Generation {
  const Generation(this.number, this.roman, this.region, this.first, this.last);

  final int number;
  final String roman;
  final String region;

  /// Primer y último número de la Pokédex Nacional de la generación.
  final int first;
  final int last;

  int get count => last - first + 1;

  String get label => '$roman · $region';

  bool contains(int id) => id >= first && id <= last;
}

const generations = [
  Generation(1, 'I', 'Kanto', 1, 151),
  Generation(2, 'II', 'Johto', 152, 251),
  Generation(3, 'III', 'Hoenn', 252, 386),
  Generation(4, 'IV', 'Sinnoh', 387, 493),
  Generation(5, 'V', 'Teselia', 494, 649),
  Generation(6, 'VI', 'Kalos', 650, 721),
  Generation(7, 'VII', 'Alola', 722, 809),
  Generation(8, 'VIII', 'Galar', 810, 905),
  Generation(9, 'IX', 'Paldea', 906, 1025),
];

/// Posición en [generations] de la especie con ese número, o null.
int? generationIndexOf(int speciesId) {
  final index = generations.indexWhere((gen) => gen.contains(speciesId));
  return index < 0 ? null : index;
}

/// Eficacia de cada tipo atacante contra los tipos defensores (solo los
/// valores distintos de x1).
const _typeChart = <String, Map<String, double>>{
  'normal': {'rock': 0.5, 'ghost': 0, 'steel': 0.5},
  'fire': {
    'fire': 0.5,
    'water': 0.5,
    'grass': 2,
    'ice': 2,
    'bug': 2,
    'rock': 0.5,
    'dragon': 0.5,
    'steel': 2,
  },
  'water': {
    'fire': 2,
    'water': 0.5,
    'grass': 0.5,
    'ground': 2,
    'rock': 2,
    'dragon': 0.5,
  },
  'electric': {
    'water': 2,
    'electric': 0.5,
    'grass': 0.5,
    'ground': 0,
    'flying': 2,
    'dragon': 0.5,
  },
  'grass': {
    'fire': 0.5,
    'water': 2,
    'grass': 0.5,
    'poison': 0.5,
    'ground': 2,
    'flying': 0.5,
    'bug': 0.5,
    'rock': 2,
    'dragon': 0.5,
    'steel': 0.5,
  },
  'ice': {
    'fire': 0.5,
    'water': 0.5,
    'grass': 2,
    'ice': 0.5,
    'ground': 2,
    'flying': 2,
    'dragon': 2,
    'steel': 0.5,
  },
  'fighting': {
    'normal': 2,
    'ice': 2,
    'poison': 0.5,
    'flying': 0.5,
    'psychic': 0.5,
    'bug': 0.5,
    'rock': 2,
    'ghost': 0,
    'dark': 2,
    'steel': 2,
    'fairy': 0.5,
  },
  'poison': {
    'grass': 2,
    'poison': 0.5,
    'ground': 0.5,
    'rock': 0.5,
    'ghost': 0.5,
    'steel': 0,
    'fairy': 2,
  },
  'ground': {
    'fire': 2,
    'electric': 2,
    'grass': 0.5,
    'poison': 2,
    'flying': 0,
    'bug': 0.5,
    'rock': 2,
    'steel': 2,
  },
  'flying': {
    'electric': 0.5,
    'grass': 2,
    'fighting': 2,
    'bug': 2,
    'rock': 0.5,
    'steel': 0.5,
  },
  'psychic': {
    'fighting': 2,
    'poison': 2,
    'psychic': 0.5,
    'dark': 0,
    'steel': 0.5,
  },
  'bug': {
    'fire': 0.5,
    'grass': 2,
    'fighting': 0.5,
    'poison': 0.5,
    'flying': 0.5,
    'psychic': 2,
    'ghost': 0.5,
    'dark': 2,
    'steel': 0.5,
    'fairy': 0.5,
  },
  'rock': {
    'fire': 2,
    'ice': 2,
    'fighting': 0.5,
    'ground': 0.5,
    'flying': 2,
    'bug': 2,
    'steel': 0.5,
  },
  'ghost': {'normal': 0, 'psychic': 2, 'ghost': 2, 'dark': 0.5},
  'dragon': {'dragon': 2, 'steel': 0.5, 'fairy': 0},
  'dark': {
    'fighting': 0.5,
    'psychic': 2,
    'ghost': 2,
    'dark': 0.5,
    'fairy': 0.5,
  },
  'steel': {
    'fire': 0.5,
    'water': 0.5,
    'electric': 0.5,
    'ice': 2,
    'rock': 2,
    'steel': 0.5,
    'fairy': 2,
  },
  'fairy': {
    'fire': 0.5,
    'fighting': 2,
    'poison': 0.5,
    'dragon': 2,
    'dark': 2,
    'steel': 0.5,
  },
};

/// Cuánto daño recibe un Pokémon con estos tipos de cada tipo atacante.
Map<String, double> typeDefenses(List<String> types) => {
  for (final MapEntry(key: attack, value: chart) in _typeChart.entries)
    attack: types.fold(1.0, (total, type) => total * (chart[type] ?? 1)),
};

extension PokemonMatchups on Pokemon {
  Generation? get generation => switch (generationIndexOf(speciesId ?? id)) {
    final index? => generations[index],
    null => null,
  };

  /// Tipos que le hacen daño doble o cuádruple, de más a menos peligroso.
  List<String> get weaknesses {
    final defenses = typeDefenses(types).entries.where((e) => e.value > 1);
    return (defenses.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .map((entry) => entry.key)
        .toList();
  }
}

/// "a", "a y b", "a, b y c".
String _joinSpanish(Iterable<String> items) {
  final list = items.toList();
  if (list.length <= 1) return list.join();
  return '${list.sublist(0, list.length - 1).join(', ')} y ${list.last}';
}

String _multiplierLabel(double value) => switch (value) {
  0 => 'x0',
  0.25 => 'x1/4',
  0.5 => 'x1/2',
  4 => 'x4',
  _ => 'x2',
};

/// Debilidades, resistencias e inmunidades según los tipos del Pokémon.
class _TypeMatchups extends StatelessWidget {
  const _TypeMatchups({required this.types});

  final List<String> types;

  @override
  Widget build(BuildContext context) {
    final defenses = typeDefenses(types).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final weak = defenses.where((e) => e.value > 1).toList();
    final resist = defenses.where((e) => e.value > 0 && e.value < 1).toList();
    final immune = defenses.where((e) => e.value == 0).toList();

    Widget group(String title, List<MapEntry<String, double>> entries) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _pixel(8, color: _lcdDim)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in entries)
                _MatchupChip(type: entry.key, multiplier: entry.value),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DEBILIDADES', style: _pixel(9, color: Colors.white)),
        const SizedBox(height: 8),
        if (weak.isEmpty)
          Text('NINGUNA', style: _pixel(8))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in weak)
                _MatchupChip(type: entry.key, multiplier: entry.value),
            ],
          ),
        if (resist.isNotEmpty) ...[
          const SizedBox(height: 12),
          group('RESISTE', resist),
        ],
        if (immune.isNotEmpty) ...[
          const SizedBox(height: 12),
          group('INMUNE A', immune),
        ],
      ],
    );
  }
}

class _MatchupChip extends StatelessWidget {
  const _MatchupChip({required this.type, required this.multiplier});

  final String type;
  final double multiplier;

  @override
  Widget build(BuildContext context) {
    final strong = multiplier >= 4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _typeColor(type),
        border: Border.all(
          color: strong ? _lightYellow : Colors.white,
          width: strong ? 2.5 : 1.5,
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: _dexText(_typeName(type))),
            TextSpan(
              text: ' ${_multiplierLabel(multiplier)}',
              style: TextStyle(color: strong ? _lightYellow : Colors.white70),
            ),
          ],
        ),
        style: _pixel(7, color: Colors.white, height: 1),
      ),
    );
  }
}
