import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/game/world/lern_fuchs_world_game.dart';

void main() {
  test('world game exposes the playable World 1 quest nodes', () {
    expect(LernFuchsWorldGame.questNodes, hasLength(5));
    expect(
      LernFuchsWorldGame.questNodes.map((node) => node.id),
      containsAll([
        'waldeingang',
        'lichtung',
        'alter_baum',
        'bruecke',
        'waldsee',
      ]),
    );
    expect(
      LernFuchsWorldGame.questNodes.map((node) => node.questId),
      containsAll([
        'prolog_ovas_ruf',
        'main_zahlenpfad',
        'main_buchstabenhain',
        'side_silbenquelle',
        'side_musterlichtung',
      ]),
    );
  });

  test('world game remains a FlameGame boundary object', () {
    final game = LernFuchsWorldGame(onQuestNodeTapped: (_) {});

    expect(game, isA<FlameGame>());
  });
}
