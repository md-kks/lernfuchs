import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lernfuchs/game/world/lern_fuchs_world_game.dart';
import 'package:lernfuchs/game/world/world_quest_node.dart';

void main() {
  test('world game exposes the playable World 1 quest nodes', () {
    expect(LernFuchsWorldGame.questNodes, hasLength(8));
    expect(
      LernFuchsWorldGame.questNodes.map((node) => node.id),
      containsAll([
        'waldeingang',
        'bruecke',
        'alter_baum',
        'lichtung',
        'chapter2_alter_baum',
        'chapter2_nebelbruecke',
        'chapter2_mauer_der_funken',
        'chapter2_wegweiser_aus_klang',
      ]),
    );
    expect(
      LernFuchsWorldGame.questNodes.map((node) => node.questId),
      containsAll([
        'chapter1_ovas_ruf',
        'chapter1_zahlenpfad',
        'chapter1_singende_blaetter',
        'chapter1_erste_lichtung',
        'chapter2_alter_baum',
        'chapter2_nebelbruecke',
        'chapter2_mauer_der_funken',
        'chapter2_wegweiser_aus_klang',
      ]),
    );
  });

  test('chapter 2 unlocks after the chapter 1 slice in order', () {
    final nodes = LernFuchsWorldGame.questNodes;

    expect(nodes.map((node) => node.order), List.generate(8, (index) => index));
    expect(nodes[3].questId, 'chapter1_erste_lichtung');
    expect(nodes[4].questId, 'chapter2_alter_baum');

    final game = LernFuchsWorldGame(onQuestNodeTapped: (_) {});
    game.updateUnlockedOrder(4);

    expect(game.stateForOrder(0), QuestNodeState.completed);
    expect(game.stateForOrder(3), QuestNodeState.completed);
    expect(game.stateForOrder(4), QuestNodeState.current);
    expect(game.stateForOrder(5), QuestNodeState.lockedNear);
    expect(game.stateForOrder(7), QuestNodeState.lockedFar);
  });

  test('world game remains a FlameGame boundary object', () {
    final game = LernFuchsWorldGame(onQuestNodeTapped: (_) {});

    expect(game, isA<FlameGame>());
  });
}
