// Genera assets/audio/kanto_route_theme.wav: una melodía chiptune original
// al estilo de las rutas de Kanto en Pokémon Rojo Fuego (GBA): pulso cuadrado
// para la melodía, arpegios rápidos, bajo de onda triangular, batería de ruido
// y un pequeño eco.
//
// Uso: dart run tool/generate_kanto_theme.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const sampleRate = 22050;
const bpm = 116;
const eighth = 60 / bpm / 2;
const barEighths = 8;

int note(String name) {
  const steps = {
    'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, //
    'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11,
  };
  final octave = int.parse(name.substring(name.length - 1));
  return 12 * (octave + 1) + steps[name.substring(0, name.length - 1)]!;
}

double freq(int midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

/// Melodía: pares (nota o 'R' para silencio, duración en corcheas).
const sectionA = [
  ['F#5', 2], ['A5', 2], ['D6', 3], ['C#6', 1], //
  ['B5', 2], ['A5', 2], ['G5', 2], ['F#5', 2],
  ['E5', 2], ['F#5', 1], ['G5', 1], ['A5', 3], ['E5', 1],
  ['F#5', 6], ['R', 2],
  ['D5', 2], ['F#5', 2], ['B5', 3], ['A5', 1],
  ['G5', 2], ['F#5', 2], ['E5', 2], ['D5', 2],
  ['E5', 2], ['G5', 2], ['B5', 2], ['A5', 1], ['G5', 1],
  ['A5', 6], ['R', 2],
];
const sectionB = [
  ['B5', 3], ['A5', 1], ['G5', 2], ['B5', 2], //
  ['C#6', 3], ['B5', 1], ['A5', 2], ['E5', 2],
  ['F#5', 2], ['A5', 2], ['C#6', 2], ['A5', 2],
  ['B5', 4], ['D6', 2], ['B5', 2],
  ['G5', 2], ['B5', 2], ['E6', 3], ['D6', 1],
  ['C#6', 2], ['A5', 2], ['E5', 2], ['C#6', 2],
  ['D6', 3], ['A5', 1], ['F#5', 2], ['A5', 2],
  ['D6', 6], ['R', 2],
];
final sectionA2 = [
  ...sectionA.sublist(0, sectionA.length - 7),
  ['E5', 2], ['G5', 2], ['B5', 2], ['C#6', 2], //
  ['D6', 6], ['R', 2],
];

/// Acordes por compás: [raíz del bajo, notas del arpegio].
const chordsA = ['D', 'G', 'A', 'D', 'Bm', 'G', 'Em', 'A'];
const chordsB = ['G', 'A', 'F#m', 'Bm', 'Em', 'A', 'D', 'D'];
const chordsA2 = ['D', 'G', 'A', 'D', 'Bm', 'G', 'Em', 'D'];

List<int> chordTones(String chord) {
  final minor = chord.endsWith('m');
  final rootName = minor ? chord.substring(0, chord.length - 1) : chord;
  final root = note('${rootName}4');
  return [root, root + (minor ? 3 : 4), root + 7, root + 12];
}

void main() {
  final melody = [...sectionA, ...sectionB, ...sectionA2];
  final chords = [...chordsA, ...chordsB, ...chordsA2];
  final totalEighths = chords.length * barEighths;
  final length = (totalEighths * eighth * sampleRate).round();
  final lead = Float64List(length);
  final mix = Float64List(length);

  void pulse(
    Float64List out,
    int midi,
    double start,
    double duration,
    double volume,
    double duty, {
    bool vibrato = false,
  }) {
    final first = (start * sampleRate).round();
    final count = (duration * sampleRate).round();
    final f = freq(midi);
    var phase = 0.0;
    for (var i = 0; i < count && first + i < out.length; i++) {
      final t = i / sampleRate;
      var current = f;
      if (vibrato && t > 0.14) {
        current *= 1 + 0.007 * math.sin(2 * math.pi * 5.5 * (t - 0.14));
      }
      phase = (phase + current / sampleRate) % 1;
      final attack = math.min(1.0, t / 0.006);
      final decay = 0.72 + 0.28 * math.exp(-t * 9);
      final release = math.min(1.0, (duration - t) / 0.03);
      final wave = phase < duty ? 1.0 : -1.0;
      out[first + i] += wave * volume * attack * decay * release;
    }
  }

  void triangle(int midi, double start, double duration, double volume) {
    final first = (start * sampleRate).round();
    final count = (duration * sampleRate).round();
    final f = freq(midi);
    for (var i = 0; i < count && first + i < length; i++) {
      final t = i / sampleRate;
      final phase = (t * f) % 1;
      // Onda triangular cuantizada a 16 niveles, como el canal de onda de GB.
      final raw = phase < 0.5 ? 4 * phase - 1 : 3 - 4 * phase;
      final stepped = (raw * 8).round() / 8;
      final release = math.min(1.0, (duration - t) / 0.02);
      mix[first + i] += stepped * volume * release;
    }
  }

  var lfsr = 0x7FFF;
  void noise(double start, double duration, double volume, double rate) {
    final first = (start * sampleRate).round();
    final count = (duration * sampleRate).round();
    var hold = 0.0;
    var value = 0.0;
    for (var i = 0; i < count && first + i < length; i++) {
      hold += rate / sampleRate;
      while (hold >= 1) {
        hold -= 1;
        final bit = (lfsr ^ (lfsr >> 1)) & 1;
        lfsr = (lfsr >> 1) | (bit << 14);
        value = (lfsr & 1) == 1 ? 1.0 : -1.0;
      }
      final env = math.exp(-i / sampleRate / (duration / 4));
      mix[first + i] += value * volume * env;
    }
  }

  void kick(double start) {
    final first = (start * sampleRate).round();
    final count = (0.12 * sampleRate).round();
    var phase = 0.0;
    for (var i = 0; i < count && first + i < length; i++) {
      final t = i / sampleRate;
      phase += (150 * math.exp(-t * 28) + 45) / sampleRate;
      mix[first + i] +=
          (phase % 1 < 0.5 ? 1.0 : -1.0) * 0.16 * math.exp(-t * 22);
    }
  }

  // Melodía principal.
  var position = 0.0;
  for (final entry in melody) {
    final name = entry[0] as String;
    final duration = (entry[1] as int) * eighth;
    if (name != 'R') {
      pulse(
        lead,
        note(name),
        position,
        duration * 0.95,
        0.19,
        0.25,
        vibrato: true,
      );
    }
    position += duration;
  }

  for (var bar = 0; bar < chords.length; bar++) {
    final barStart = bar * barEighths * eighth;
    final tones = chordTones(chords[bar]);

    // Arpegio en semicorcheas con pulso fino (12,5 %).
    for (var step = 0; step < 16; step++) {
      final order = [0, 1, 2, 3, 2, 1][step % 6];
      pulse(
        mix,
        tones[order],
        barStart + step * eighth / 2,
        eighth / 2 * 0.8,
        0.055,
        0.125,
      );
    }

    // Bajo saltarín: raíz, raíz, quinta, octava...
    final root = tones[0] - 24;
    const pattern = [0, 0, 7, 12, 0, 0, 7, 12];
    for (var step = 0; step < barEighths; step++) {
      triangle(
        root + pattern[step],
        barStart + step * eighth,
        eighth * 0.85,
        0.24,
      );
    }

    // Batería.
    for (var step = 0; step < barEighths; step++) {
      final t = barStart + step * eighth;
      noise(t, 0.035, 0.035, 14000);
      if (step == 0 || step == 4) kick(t);
      if (step == 2 || step == 6) noise(t, 0.14, 0.09, 6000);
    }
  }

  // Eco ligero en la melodía, al estilo de la reverb del GBA.
  final delay = (0.19 * sampleRate).round();
  for (var i = delay; i < length; i++) {
    lead[i] += lead[i - delay] * 0.32;
  }
  for (var i = 0; i < length; i++) {
    mix[i] += lead[i];
  }

  var peak = 0.0;
  for (final sample in mix) {
    peak = math.max(peak, sample.abs());
  }
  final gain = 0.9 / peak;

  final bytes = Uint8List(44 + length * 2);
  final data = ByteData.sublistView(bytes);
  void text(int offset, String value) =>
      bytes.setRange(offset, offset + value.length, value.codeUnits);
  text(0, 'RIFF');
  data.setUint32(4, 36 + length * 2, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  text(36, 'data');
  data.setUint32(40, length * 2, Endian.little);
  for (var i = 0; i < length; i++) {
    final sample = (mix[i] * gain * 32767).round().clamp(-32768, 32767);
    data.setInt16(44 + i * 2, sample, Endian.little);
  }

  final file = File('assets/audio/kanto_route_theme.wav');
  file.writeAsBytesSync(bytes);
  stdout.writeln(
    'Generado ${file.path} (${(length / sampleRate).toStringAsFixed(1)} s)',
  );
}
