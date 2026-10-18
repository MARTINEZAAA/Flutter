import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_activity/main.dart';

const _bulbasaur = Pokemon(
  id: 1,
  name: 'bulbasaur',
  height: 7,
  weight: 69,
  imageUrl: null,
  types: ['grass', 'poison'],
  stats: [PokemonStat(name: 'hp', value: 45)],
  genus: 'Pokémon Semilla',
  abilities: ['Espesura'],
  description: 'Una rara semilla le fue plantada en el lomo al nacer.',
  speciesId: 1,
  evolutions: [
    [EvolutionEntry(id: 1, name: 'bulbasaur')],
    [EvolutionEntry(id: 2, name: 'ivysaur', condition: 'Nv. 16')],
    [EvolutionEntry(id: 3, name: 'venusaur', condition: 'Nv. 32')],
  ],
  megaForms: [
    EvolutionEntry(id: 10033, name: 'venusaur-mega', condition: 'Megapiedra'),
  ],
);

const _megaVenusaur = Pokemon(
  id: 10033,
  name: 'venusaur-mega',
  height: 24,
  weight: 1555,
  imageUrl: null,
  types: ['grass', 'poison'],
  stats: [PokemonStat(name: 'hp', value: 80)],
  speciesId: 3,
);

const _ivysaur = Pokemon(
  id: 2,
  name: 'ivysaur',
  height: 10,
  weight: 130,
  imageUrl: null,
  types: ['grass', 'poison'],
  stats: [PokemonStat(name: 'hp', value: 60)],
  description: 'Cuando le crece bastante el bulbo del lomo, no puede ponerse a dos patas.',
);

Future<void> _pumpDex(
  WidgetTester tester, {
  required List<int> cries,
  required List<String> spoken,
  Size size = const Size(1280, 1000),
  String? trainerName,
  LizIntro lizIntro = LizIntro.none,
  List<int>? generationsLoaded,
  ValueChanged<String>? onTrainerNamed,
  List<String>? blips,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: _withoutAnimations,
      home: PokemonPage(
        trainerName: trainerName,
        lizIntro: lizIntro,
        onTrainerNamed: onTrainerNamed,
        loadPokemon: (id) async => switch (id) {
          2 => _ivysaur,
          10033 => _megaVenusaur,
          _ => _bulbasaur,
        },
        playPokemonCry: (pokemon) async => cries.add(pokemon.id),
        speak: (text) async => spoken.add(text),
        lizBlip: (word) => blips?.add(word),
        autoplayMusic: false,
        loadGeneration: (generation) async {
          generationsLoaded?.add(generation.number);
          return switch (generation.number) {
            1 => const [
              PokemonSummary(id: 1, name: 'bulbasaur', imageUrl: null),
              PokemonSummary(id: 2, name: 'ivysaur', imageUrl: null),
            ],
            _ => const [
              PokemonSummary(id: 152, name: 'chikorita', imageUrl: null),
            ],
          };
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _withoutAnimations(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(disableAnimations: true),
  child: child!,
);

Finder _inList(String text) =>
    find.descendant(of: find.byType(ListView), matching: find.text(text));

/// Campo donde Liz pide el nombre (no la barra de búsqueda).
final _nameField = find.byWidgetPredicate(
  (widget) => widget is TextField && widget.maxLength == 12,
);

void main() {
  testWidgets('Muestra el resumen y las estadísticas del Pokémon', (
    tester,
  ) async {
    final cries = <int>[];
    final spoken = <String>[];
    await _pumpDex(tester, cries: cries, spoken: spoken);

    expect(find.text('BULBASAUR'), findsWidgets);
    expect(find.text('POKEMON SEMILLA'), findsOneWidget);
    expect(find.text('PLANTA'), findsOneWidget);
    expect(find.text(_bulbasaur.description!), findsOneWidget);
    expect(find.text('ESTADISTICAS BASE'), findsOneWidget);
    expect(find.text('45'), findsNWidgets(2)); // PS y TOTAL
    // Al abrir la app no suena nada hasta que el usuario elige un Pokémon.
    expect(cries, isEmpty);
    expect(spoken, isEmpty);
  });

  testWidgets('Al elegir un Pokémon suena su grito y se lee su descripción', (
    tester,
  ) async {
    final cries = <int>[];
    final spoken = <String>[];
    await _pumpDex(tester, cries: cries, spoken: spoken);

    await tester.tap(_inList('IVYSAUR'));
    await tester.pumpAndSettle();

    expect(cries, [2]);
    expect(spoken, hasLength(1));
    expect(spoken.single, contains('Ivysaur'));
    expect(spoken.single, contains(_ivysaur.description!));

    await tester.tap(find.byTooltip('Anterior'));
    await tester.pumpAndSettle();
    expect(cries, [2, 1]);
    expect(find.text('POKEMON SEMILLA'), findsOneWidget);
  });

  testWidgets('Las flechas del teclado cambian de Pokémon', (tester) async {
    final cries = <int>[];
    await _pumpDex(tester, cries: cries, spoken: []);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(cries, [2]);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(cries, [2, 1]);

    // Mientras se escribe en el buscador, las flechas mueven el cursor.
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(cries, [2, 1]);
  });

  testWidgets('Los botones silencian el grito y la voz', (tester) async {
    final cries = <int>[];
    final spoken = <String>[];
    await _pumpDex(tester, cries: cries, spoken: spoken);

    expect(find.byTooltip('Reproducir música'), findsOneWidget);
    await tester.tap(find.byTooltip('Silenciar efectos'));
    await tester.tap(find.byTooltip('Silenciar voz'));
    await tester.pump();
    expect(find.byTooltip('Activar efectos'), findsOneWidget);
    expect(find.byTooltip('Activar voz'), findsOneWidget);

    await tester.tap(_inList('IVYSAUR'));
    await tester.pumpAndSettle();
    expect(cries, isEmpty);
    expect(spoken, isEmpty);
  });

  testWidgets('Se adapta a pantallas de móvil sin desbordarse', (tester) async {
    await _pumpDex(tester, cries: [], spoken: [], size: const Size(340, 740));
    expect(tester.takeException(), isNull);
    expect(find.text('BULBASAUR'), findsWidgets);
  });

  testWidgets('Muestra la cadena evolutiva y las megaevoluciones', (
    tester,
  ) async {
    final cries = <int>[];
    await _pumpDex(tester, cries: cries, spoken: []);

    expect(find.text('EVOLUCIONES'), findsOneWidget);
    expect(find.text('VENUSAUR'), findsOneWidget);
    expect(find.text('NV. 16'), findsOneWidget);
    expect(find.text('NV. 32'), findsOneWidget);
    expect(find.text('MEGAEVOLUCIONES'), findsOneWidget);

    await tester.ensureVisible(find.text('MEGA VENUSAUR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MEGA VENUSAUR'));
    await tester.pumpAndSettle();
    expect(cries, [10033]);
    expect(find.text('MEGA VENUSAUR'), findsWidgets);

    // Desde la mega, la cruceta vuelve a la numeración normal.
    await tester.tap(find.byTooltip('Siguiente'));
    await tester.pumpAndSettle();
    expect(cries, [10033, 1]);
  });

  testWidgets('La presentación abre la Pokédex sobre la mesa', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(home: DexIntroPage(onDone: () => opened = true)),
    );
    // Solo el logo de Pokémon empieza la presentación.
    expect(
      find.image(const AssetImage('assets/images/pokemon_logo.png')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(find.byTooltip('Empezar'), findsOneWidget);

    await tester.tap(find.byTooltip('Empezar'));
    await tester.pump();
    expect(find.byTooltip('Empezar'), findsNothing);

    // Recorre la animación: mesa, Pokédex que se levanta, se abre y se
    // enciende.
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }
    expect(opened, isFalse);
    // Encendida, su pantalla muestra el logo de Pokémon.
    expect(
      find.image(const AssetImage('assets/images/pokemon_logo.png')),
      findsWidgets,
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(opened, isTrue);
  });

  testWidgets('SALTAR termina la presentación', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(home: DexIntroPage(onDone: () => opened = true)),
    );
    await tester.tap(find.byTooltip('Empezar'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('SALTAR'));
    expect(opened, isTrue);
  });

  testWidgets('Liz explica la Pokédex y al final registra el nombre', (
    tester,
  ) async {
    final spoken = <String>[];
    final named = <String>[];
    await _pumpDex(
      tester,
      cries: [],
      spoken: spoken,
      lizIntro: LizIntro.tour,
      onTrainerNamed: named.add,
    );
    // Liz no habla con voz: solo escribe (y suenan sus bips).
    expect(spoken, isEmpty);
    expect(find.textContaining('Soy Liz'), findsOneWidget);

    // Explica todos los controles antes de preguntar el nombre.
    var sawDpad = false;
    while (_nameField.evaluate().isEmpty) {
      await tester.tap(find.text('LIZ').last);
      await tester.pumpAndSettle();
      sawDpad |= find.textContaining('cruceta').evaluate().isNotEmpty;
    }
    expect(sawDpad, isTrue);
    expect(find.textContaining('registremos tu nombre'), findsOneWidget);
    expect(find.text('CANCELAR'), findsNothing);

    await tester.tap(find.byTooltip('Confirmar nombre'));
    await tester.pump();
    expect(find.text('ESCRIBE TU NOMBRE'), findsOneWidget);
    expect(named, isEmpty);

    await tester.enterText(_nameField, 'Ash');
    await tester.tap(find.byTooltip('Confirmar nombre'));
    await tester.pumpAndSettle();
    expect(named, ['Ash']);
    expect(find.textContaining('¡Listo, Ash!'), findsOneWidget);
    expect(find.textContaining('registrado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Liz suena con un bip por letra y VOZ la silencia', (
    tester,
  ) async {
    final blips = <String>[];
    await _pumpDex(
      tester,
      cries: [],
      spoken: [],
      trainerName: 'Misty',
      lizIntro: LizIntro.tour,
      blips: blips,
    );
    await tester.pump(const Duration(seconds: 3));
    // "¡Bienvenido": una por letra; los signos y espacios no suenan.
    expect(blips.take(5).join(), 'Bienv');

    // Con VOZ apagada, Liz calla.
    await tester.tap(find.text('SALTAR'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('VOZ ON'));
    await tester.tap(find.text('VOZ ON'));
    await tester.pumpAndSettle();
    blips.clear();
    await tester.ensureVisible(find.byTooltip('Hablar con Liz'));
    await tester.tap(find.byTooltip('Hablar con Liz'));
    await tester.pump(const Duration(seconds: 3));
    expect(blips, isEmpty);
  });

  testWidgets('SALTAR lleva directo a la pregunta del nombre', (tester) async {
    final spoken = <String>[];
    await _pumpDex(
      tester,
      cries: [],
      spoken: spoken,
      lizIntro: LizIntro.tour,
      onTrainerNamed: (_) {},
    );
    await tester.tap(find.text('SALTAR'));
    await tester.pumpAndSettle();
    expect(_nameField, findsOneWidget);
    expect(find.textContaining('registremos tu nombre'), findsOneWidget);
  });

  testWidgets('Liz guía por los controles de la Pokédex', (tester) async {
    final spoken = <String>[];
    await _pumpDex(
      tester,
      cries: [],
      spoken: spoken,
      trainerName: 'Misty',
      lizIntro: LizIntro.tour,
    );

    expect(find.text('ENTRENADOR'), findsOneWidget);
    expect(find.text('MISTY'), findsOneWidget);
    expect(find.textContaining('Bienvenido a tu Pokédex, Misty'), findsOne);
    expect(spoken, isEmpty);

    var steps = 1;
    while (find.text('SALTAR').evaluate().isNotEmpty) {
      await tester.tap(find.text('LIZ').last);
      await tester.pumpAndSettle();
      steps++;
    }
    expect(find.textContaining('toca mi botón'), findsOneWidget);
    expect(steps, 14);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('LIZ').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('toca mi botón'), findsNothing);
  });

  testWidgets('El botón de Liz abre su menú de ayuda', (tester) async {
    final spoken = <String>[];
    await _pumpDex(
      tester,
      cries: [],
      spoken: spoken,
      trainerName: 'Brock',
      size: const Size(360, 740),
    );
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byTooltip('Hablar con Liz'));
    await tester.tap(find.byTooltip('Hablar con Liz'));
    await tester.pumpAndSettle();
    expect(find.text('¿En qué te ayudo, Brock?'), findsOneWidget);
    expect(find.text('GUIA'), findsOneWidget);

    expect(find.text('VOZ'), findsNothing);

    await tester.tap(find.text('POKEMON?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('qué son los Pokémon'), findsOneWidget);

    await tester.tap(find.text('SALTAR'));
    await tester.pumpAndSettle();
    expect(find.text('SALTAR'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Muestra las debilidades según los tipos', (tester) async {
    final spoken = <String>[];
    await _pumpDex(tester, cries: [], spoken: spoken);

    expect(find.text('DEBILIDADES'), findsOneWidget);
    // Bulbasaur (planta/veneno): débil a fuego, hielo, volador y psíquico.
    for (final weakness in ['FUEGO x2', 'HIELO x2', 'VOLADOR x2']) {
      expect(find.text(weakness), findsOneWidget);
    }
    expect(find.text('PSIQUICO x2'), findsOneWidget);
    expect(find.text('PLANTA x1/4'), findsOneWidget);
    expect(find.text('AGUA x2'), findsNothing);
    expect(find.text('GEN'), findsNothing); // la etiqueta va con su valor
    expect(find.textContaining('KANTO'), findsWidgets);

    await tester.tap(_inList('IVYSAUR'));
    await tester.pumpAndSettle();
    expect(spoken.single, contains('Es débil contra'));
    expect(spoken.single, contains('fuego'));
  });

  test('La tabla de tipos calcula dobles debilidades e inmunidades', () {
    final charizard = typeDefenses(['fire', 'flying']);
    expect(charizard['rock'], 4);
    expect(charizard['ground'], 0);
    expect(charizard['grass'], 0.25);
    expect(typeDefenses(['ghost'])['normal'], 0);
    expect(generationIndexOf(152), 1);
    expect(generationIndexOf(1025), 8);
  });

  testWidgets('La lista se separa por generaciones', (tester) async {
    final loaded = <int>[];
    await _pumpDex(tester, cries: [], spoken: [], generationsLoaded: loaded);

    expect(find.text('GEN I'), findsOneWidget);
    expect(_inList('BULBASAUR'), findsOneWidget);

    await tester.tap(find.byTooltip('Generación siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('GEN II'), findsOneWidget);
    expect(_inList('CHIKORITA'), findsOneWidget);
    expect(_inList('BULBASAUR'), findsNothing);

    // Volver usa la lista guardada, sin pedirla de nuevo.
    await tester.tap(find.byTooltip('Generación anterior'));
    await tester.pumpAndSettle();
    expect(_inList('BULBASAUR'), findsOneWidget);
    expect(loaded, [1, 2]);
  });

  testWidgets('A quien ya conoce no le pregunta el nombre en la guía', (
    tester,
  ) async {
    final named = <String>[];
    await _pumpDex(
      tester,
      cries: [],
      spoken: [],
      trainerName: 'Ash',
      lizIntro: LizIntro.tour,
      onTrainerNamed: named.add,
    );
    while (find.text('SALTAR').evaluate().isNotEmpty) {
      expect(_nameField, findsNothing);
      await tester.tap(find.text('LIZ').last);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('sal a descubrir Pokémon, Ash'), findsOneWidget);
    expect(_nameField, findsNothing);
    expect(named, isEmpty);
  });

  testWidgets('MI NOMBRE permite cambiar el nombre o cancelar', (tester) async {
    final named = <String>[];
    await _pumpDex(
      tester,
      cries: [],
      spoken: [],
      trainerName: 'Brock',
      onTrainerNamed: named.add,
    );
    await tester.tap(find.byTooltip('Hablar con Liz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MI NOMBRE'));
    await tester.pumpAndSettle();
    expect(find.text('Brock'), findsOneWidget); // el nombre actual, ya escrito

    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    expect(_nameField, findsNothing);
    expect(named, isEmpty);

    await tester.tap(find.byTooltip('Hablar con Liz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MI NOMBRE'));
    await tester.pumpAndSettle();
    await tester.enterText(_nameField, 'Gary');
    await tester.tap(find.byTooltip('Confirmar nombre'));
    await tester.pumpAndSettle();
    expect(named, ['Gary']);
    expect(find.textContaining('te llamaré Gary'), findsOneWidget);
  });
}
