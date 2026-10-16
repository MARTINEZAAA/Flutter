import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_activity/main.dart';

void main() {
  testWidgets('Muestra los datos del Pokémon', (WidgetTester tester) async {
    int? playedPokemonId;
    const pokemon = Pokemon(
      id: 1,
      name: 'bulbasaur',
      height: 7,
      weight: 69,
      imageUrl: null,
      types: ['grass', 'poison'],
      stats: [PokemonStat(name: 'hp', value: 45)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PokemonPage(
          loadPokemon: (_) async => pokemon,
          playPokemonSound: (id) async => playedPokemonId = id,
          loadPokemonPage: (_) async => const PokemonPageResult(
            pokemon: [
              PokemonSummary(id: 1, name: 'bulbasaur', imageUrl: null),
              PokemonSummary(id: 2, name: 'ivysaur', imageUrl: null),
            ],
            hasNext: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bulbasaur'), findsNWidgets(2));
    expect(find.text('Planta'), findsOneWidget);
    expect(find.text('0.7 m'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.byTooltip('Reproducir música'), findsOneWidget);
    expect(find.byTooltip('Silenciar efectos'), findsOneWidget);

    await tester.tap(find.text('Ivysaur'));
    await tester.pumpAndSettle();
    expect(playedPokemonId, 2);

    await tester.tap(find.byTooltip('Silenciar efectos'));
    await tester.pump();
    expect(find.byTooltip('Activar efectos'), findsOneWidget);
  });
}
