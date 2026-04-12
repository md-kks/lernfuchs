import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/core/engine/templates/math_grade1_templates.dart';
import 'package:lernfuchs/core/engine/templates/math_grade2_templates.dart';
import 'package:lernfuchs/core/engine/templates/math_grade3_templates.dart';
import 'package:lernfuchs/core/engine/templates/math_grade4_templates.dart';

void main() {
  // ── Kl.1 ──────────────────────────────────────────────────────
  group('CountDotsTemplate', () {
    const t = CountDotsTemplate();

    test('dotCount stimmt mit correctAnswer überein', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(1, rng);
        expect(task.correctAnswer, equals(task.metadata['dotCount']));
      }
    });

    test('evaluate: richtige Antwort', () {
      final task = t.generate(1, Random(1));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('dotCount >= 1', () {
      final rng = Random(7);
      for (int i = 0; i < 50; i++) {
        final task = t.generate(1, rng);
        expect(task.metadata['dotCount'] as int, greaterThanOrEqualTo(1));
      }
    });
  });

  group('ShapeRecognitionTemplate', () {
    const t = ShapeRecognitionTemplate();

    test('choices enthält immer 4 Optionen', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = t.generate(1, rng);
        final choices = task.metadata['choices'] as List;
        expect(choices.length, equals(4));
      }
    });

    test('correctAnswer ist in choices enthalten', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = t.generate(1, rng);
        final choices = task.metadata['choices'] as List;
        expect(choices.contains(task.correctAnswer), isTrue);
      }
    });
  });

  group('PatternContinuationTemplate', () {
    const t = PatternContinuationTemplate();

    test('correctAnswer ist in choices', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = t.generate(1, rng);
        final choices = task.metadata['choices'] as List;
        expect(choices.contains(task.correctAnswer), isTrue);
      }
    });

    test('visible hat mindestens 4 Elemente', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = t.generate(2, rng);
        final visible = task.metadata['visible'] as List;
        expect(visible.length, greaterThanOrEqualTo(4));
      }
    });
  });

  group('NumberWritingTemplate', () {
    const t = NumberWritingTemplate();

    test('Zahl-zu-Wort und Wort-zu-Zahl', () {
      final rng = Random(42);
      int numToWord = 0, wordToNum = 0;
      for (int i = 0; i < 40; i++) {
        final task = t.generate(1, rng);
        if (task.metadata['showWord'] == true) {
          numToWord++;
          expect(task.correctAnswer is int, isTrue);
        } else {
          wordToNum++;
          expect(task.correctAnswer is String, isTrue);
        }
      }
      // Beide Richtungen sollten vorkommen
      expect(numToWord, greaterThan(0));
      expect(wordToNum, greaterThan(0));
    });
  });

  // ── Kl.2 ──────────────────────────────────────────────────────
  group('ClockTemplate', () {
    const t = ClockTemplate();

    test('Schwierigkeit 1: nur volle Stunden', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = t.generate(1, rng);
        expect(task.metadata['minute'], equals(0));
      }
    });

    test('Schwierigkeit 2: halbe Stunden', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(2, rng);
        expect([0, 30].contains(task.metadata['minute']), isTrue);
      }
    });

    test('evaluate: korrekte Zeit akzeptiert', () {
      final task = ClockTemplate().generate(1, Random(1));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('evaluate: verschiedene Formate akzeptiert', () {
      final rng = Random(5);
      final task = t.generate(1, rng);
      final parts = (task.correctAnswer as String).split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      // Ohne führende Null
      expect(t.evaluate(task, '$h:${m.toString().padLeft(2, '0')}'), isTrue);
    });
  });

  group('MoneyTemplate', () {
    const t = MoneyTemplate();

    test('Gesamtbetrag stimmt mit Münzsumme überein', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = t.generate(2, rng);
        final coins = (task.metadata['coins'] as List).cast<int>();
        final totalFromCoins = coins.reduce((a, b) => a + b);
        expect(task.correctAnswer, equals(totalFromCoins));
      }
    });

    test('evaluate: richtiger Betrag akzeptiert', () {
      final task = t.generate(1, Random(1));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });

    test('Schwierigkeit 1: nur bis 50 Cent', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(1, rng);
        expect(task.correctAnswer as int, lessThanOrEqualTo(50));
      }
    });
  });

  group('NumberWallTemplate', () {
    const t = NumberWallTemplate();

    test('Zahlenmauer-Invariante: mid = a+b, b+c; top = mid1+mid2', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(2, rng);
        final md = task.metadata;
        final a = md['a'] as int;
        final b = md['b'] as int;
        final c = md['c'] as int;
        final mid1 = md['mid1'] as int;
        final mid2 = md['mid2'] as int;
        final top = md['top'] as int;
        expect(mid1, equals(a + b));
        expect(mid2, equals(b + c));
        expect(top, equals(mid1 + mid2));
      }
    });

    test('correctAnswer ist der versteckte Wert', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final task = t.generate(2, rng);
        final hidden = task.metadata['hidden'] as String;
        final expected = task.metadata[hidden] as int;
        expect(task.correctAnswer, equals(expected));
      }
    });
  });

  group('CalculationChainTemplate', () {
    const t = CalculationChainTemplate();

    test('Rechenkette ist korrekt berechnet', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(2, rng);
        final start = task.metadata['start'] as int;
        final chain = (task.metadata['chain'] as List)
            .cast<Map<String, dynamic>>();
        int current = start;
        for (final step in chain) {
          final op = step['op'] as String;
          final operand = step['operand'] as int;
          if (op == '+') {
            current += operand;
          } else {
            current -= operand;
          }
          expect(step['result'], equals(current));
        }
      }
    });

    test('Zwischenwert nie negativ', () {
      final rng = Random(42);
      for (int i = 0; i < 50; i++) {
        final task = t.generate(2, rng);
        final chain = (task.metadata['chain'] as List)
            .cast<Map<String, dynamic>>();
        for (final step in chain) {
          expect(step['result'] as int, greaterThanOrEqualTo(0));
        }
      }
    });
  });

  group('WordProblemGrade2Template', () {
    const t = WordProblemGrade2Template();

    test('Ergebnis ist nicht negativ', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(1, rng);
        expect(task.correctAnswer as int, greaterThanOrEqualTo(0));
      }
    });

    test('evaluate: richtiges Ergebnis', () {
      final task = t.generate(1, Random(1));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  // ── Kl.3 ──────────────────────────────────────────────────────
  group('WrittenAdditionTemplate', () {
    const t = WrittenAdditionTemplate();

    test('a + b = correctAnswer', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(3, rng);
        final a = task.metadata['a'] as int;
        final b = task.metadata['b'] as int;
        expect(task.correctAnswer, equals(a + b));
      }
    });
  });

  group('WrittenSubtractionTemplate', () {
    const t = WrittenSubtractionTemplate();

    test('a - b = correctAnswer, nie negativ', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(3, rng);
        final a = task.metadata['a'] as int;
        final b = task.metadata['b'] as int;
        expect(task.correctAnswer, equals(a - b));
        expect(task.correctAnswer as int, greaterThanOrEqualTo(0));
      }
    });
  });

  group('UnitConversionTemplate', () {
    const t = UnitConversionTemplate();

    test('Umrechnung stimmt mit factor überein', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(1, rng);
        final factor = task.metadata['factor'] as int;
        final inputValue = task.metadata['inputValue'] as int;
        // Bei forward: result = input * factor
        expect(task.correctAnswer, equals(inputValue * factor));
      }
    });
  });

  group('GeometryTemplate', () {
    const t = GeometryTemplate();

    test('Quadrat-Umfang = 4 * Seite', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(1, rng);
        if (task.metadata['shape'] == 'square' &&
            task.metadata['askPerimeter'] == true) {
          final side = task.metadata['side'] as int;
          expect(task.correctAnswer, equals(4 * side));
        }
      }
    });

    test('Quadrat-Fläche = Seite²', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(1, rng);
        if (task.metadata['shape'] == 'square' &&
            task.metadata['askPerimeter'] == false) {
          final side = task.metadata['side'] as int;
          expect(task.correctAnswer, equals(side * side));
        }
      }
    });

    test('Rechteck-Umfang = 2*(w+h)', () {
      final rng = Random(99);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(2, rng);
        if (task.metadata['shape'] == 'rectangle' &&
            task.metadata['askPerimeter'] == true) {
          final w = task.metadata['width'] as int;
          final h = task.metadata['height'] as int;
          expect(task.correctAnswer, equals(2 * (w + h)));
        }
      }
    });
  });

  // ── Kl.4 ──────────────────────────────────────────────────────
  group('WrittenMultiplicationTemplate', () {
    const t = WrittenMultiplicationTemplate();

    test('a × b = correctAnswer', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(3, rng);
        final a = task.metadata['a'] as int;
        final b = task.metadata['b'] as int;
        expect(task.correctAnswer, equals(a * b));
      }
    });
  });

  group('WrittenDivisionTemplate', () {
    const t = WrittenDivisionTemplate();

    test('dividend ÷ divisor = correctAnswer (kein Rest)', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(3, rng);
        final dividend = task.metadata['dividend'] as int;
        final divisor = task.metadata['divisor'] as int;
        final quotient = task.metadata['quotient'] as int;
        expect(dividend, equals(divisor * quotient));
        expect(task.correctAnswer, equals(quotient));
      }
    });
  });

  group('LargeNumbersTemplate', () {
    const t = LargeNumbersTemplate();

    test('Runden auf Zehnerstelle: Ergebnis ist Vielfaches von 10', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(1, rng);
        if (task.metadata.containsKey('roundTo') &&
            task.metadata['roundTo'] == 10) {
          expect((task.correctAnswer as int) % 10, equals(0));
        }
      }
    });
  });

  group('DiagramReadingTemplate', () {
    const t = DiagramReadingTemplate();

    test('Summen-Fragen: correctAnswer = Summe aller Werte', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(1, rng);
        if (task.metadata['qType'] == 'sum') {
          final values = (task.metadata['values'] as List).cast<int>();
          final sum = values.reduce((a, b) => a + b);
          expect(task.correctAnswer, equals(sum));
        }
      }
    });

    test('Differenz-Fragen: correctAnswer = max - min', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(2, rng);
        if (task.metadata['qType'] == 'diff') {
          final values = (task.metadata['values'] as List).cast<int>();
          final diff = values.reduce((a, b) => a > b ? a : b) -
              values.reduce((a, b) => a < b ? a : b);
          expect(task.correctAnswer, equals(diff));
        }
      }
    });
  });

  group('FractionTemplate', () {
    const t = FractionTemplate();

    test('Zähler ist kleiner als Nenner (wenn vorhanden)', () {
      final rng = Random(42);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(1, rng);
        final num = task.metadata['numerator'] as int?;
        final den = task.metadata['denominator'] as int?;
        if (num != null && den != null) {
          expect(num, lessThan(den));
        }
      }
    });

    test('evaluate: korrekte Antwort akzeptiert', () {
      final task = t.generate(1, Random(1));
      expect(t.evaluate(task, task.correctAnswer), isTrue);
    });
  });

  group('DecimalNumberTemplate', () {
    const t = DecimalNumberTemplate();

    test('evaluate: korrekte Dezimalzahl mit Komma oder Punkt', () {
      // Additionsaufgabe
      final rng = Random(99);
      for (int i = 0; i < 30; i++) {
        final task = t.generate(3, rng);
        if (task.metadata.containsKey('a') && task.correctAnswer is String) {
          expect(t.evaluate(task, task.correctAnswer), isTrue);
          // Mit Komma statt Punkt
          final withComma = task.correctAnswer.toString().replaceAll('.', ',');
          expect(t.evaluate(task, withComma), isTrue);
        }
      }
    });
  });
}
