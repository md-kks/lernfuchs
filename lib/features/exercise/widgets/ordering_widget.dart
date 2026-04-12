import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Drag&Drop-Widget zum Sortieren von Wörtern oder Sätzen.
///
/// Nutzt [ReorderableListView] — Elemente werden durch Langen Druck
/// und Ziehen umsortiert. Genutzt für:
/// - ABC-Sortierung ([AlphabetSortTemplate])
/// - Sätze bilden ([SentenceFormationTemplate])
///
/// Liest die Elemente aus [TaskModel.metadata]`['words']` und
/// meldet die aktuelle Reihenfolge als `List<String>` via [onChanged].
class OrderingWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<List<String>> onChanged;

  const OrderingWidget({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  State<OrderingWidget> createState() => _OrderingWidgetState();
}

class _OrderingWidgetState extends State<OrderingWidget> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    final words = widget.task.metadata['words'] as List?;
    _items = words?.map((w) => w.toString()).toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Ziehe die Wörter in die richtige Reihenfolge:',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
            });
            widget.onChanged(List<String>.from(_items));
          },
          children: _items.asMap().entries.map((entry) {
            return Card(
              key: ValueKey(entry.value),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: Text('${entry.key + 1}'),
                ),
                title: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: const Icon(Icons.drag_handle_rounded),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
