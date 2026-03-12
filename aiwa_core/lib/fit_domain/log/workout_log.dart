import 'dart:collection';

import '../common/date_only.dart';
import '../common/domain_exception.dart';
import '../common/typedef_ids.dart';
import 'log_block.dart';
import 'set_record.dart';

class WorkoutLog {
  LogId _id;
  DateOnly _date;
  TaskOccurrenceId? _boundTaskOccurrenceId;
  DateTime _createdAtUtc;
  DateTime _lastEditedAtUtc;
  Map<String, dynamic> _metadata;
  final List<LogBlock> _blocks;

  WorkoutLog({
    required LogId id,
    required DateOnly date,
    TaskOccurrenceId? boundTaskOccurrenceId,
    required DateTime createdAtUtc,
    required DateTime lastEditedAtUtc,
    Map<String, dynamic>? metadata,
    List<LogBlock>? blocks,
  })  : _id = id,
        _date = date,
        _boundTaskOccurrenceId = boundTaskOccurrenceId,
        _createdAtUtc = createdAtUtc,
        _lastEditedAtUtc = lastEditedAtUtc,
        _metadata = Map<String, dynamic>.from(
          metadata ?? const <String, dynamic>{},
        ),
        _blocks = List<LogBlock>.from(blocks ?? <LogBlock>[]) {
    requireNonEmpty(id, 'id');
    if (boundTaskOccurrenceId != null) {
      requireNonEmpty(boundTaskOccurrenceId, 'boundTaskOccurrenceId');
    }
    requireUtc(createdAtUtc, 'createdAtUtc');
    requireUtc(lastEditedAtUtc, 'lastEditedAtUtc');
  }

  LogId get id => _id;
  DateOnly get date => _date;
  TaskOccurrenceId? get boundTaskOccurrenceId => _boundTaskOccurrenceId;
  DateTime get createdAtUtc => _createdAtUtc;
  DateTime get lastEditedAtUtc => _lastEditedAtUtc;
  UnmodifiableMapView<String, dynamic> get metadata =>
      UnmodifiableMapView<String, dynamic>(_metadata);
  UnmodifiableListView<LogBlock> get blocks =>
      UnmodifiableListView<LogBlock>(_blocks);

  Map<String, dynamic> toJson() => {
        'id': _id,
        'date': _date.toJson(),
        'boundTaskOccurrenceId': _boundTaskOccurrenceId,
        'createdAtUtc': _createdAtUtc.toUtc().toIso8601String(),
        'lastEditedAtUtc': _lastEditedAtUtc.toUtc().toIso8601String(),
        'metadata': _metadata,
        'blocks': _blocks.map((b) => b.toJson()).toList(),
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return WorkoutLog(
      id: json['id'] as String,
      date: DateOnly.fromJson(json['date'] as String),
      boundTaskOccurrenceId: json['boundTaskOccurrenceId'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
      lastEditedAtUtc:
          DateTime.parse(json['lastEditedAtUtc'] as String).toUtc(),
      metadata: rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : rawMetadata is Map
              ? Map<String, dynamic>.from(rawMetadata)
              : const <String, dynamic>{},
      blocks: (json['blocks'] as List<dynamic>?)
              ?.map((e) => LogBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <LogBlock>[],
    );
  }

  void insertBlock(int position, LogBlock block, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    if (position < 0 || position > _blocks.length) {
      throw ValidationException(
        'validation.block_position',
        'position out of range',
        {'position': position, 'length': _blocks.length},
      );
    }
    _blocks.insert(position, block);
    _touch(nowUtc);
  }

  void appendBlock(LogBlock block, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    _blocks.add(block);
    _touch(nowUtc);
  }

  void updateBlock(BlockId blockId, LogBlock newBlock, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    requireNonEmpty(blockId, 'blockId');
    final index = _indexOfBlockId(blockId);
    if (index == -1) {
      throw NotFoundException(
        'not_found.block',
        'Block not found',
        {'blockId': blockId},
      );
    }
    if (newBlock.id != blockId) {
      throw ValidationException(
        'validation.block_id_mismatch',
        'newBlock id must match blockId',
        {'blockId': blockId, 'newBlockId': newBlock.id},
      );
    }
    _blocks[index] = newBlock;
    _touch(nowUtc);
  }

  void removeBlock(BlockId blockId, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    requireNonEmpty(blockId, 'blockId');
    final index = _indexOfBlockId(blockId);
    if (index == -1) {
      throw NotFoundException(
        'not_found.block',
        'Block not found',
        {'blockId': blockId},
      );
    }
    _blocks.removeAt(index);
    _touch(nowUtc);
  }

  void reorderBlocks(int fromIndex, int toIndex, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    if (fromIndex < 0 || fromIndex >= _blocks.length) {
      throw ValidationException(
        'validation.block_from_index',
        'fromIndex out of range',
        {'fromIndex': fromIndex, 'length': _blocks.length},
      );
    }
    if (toIndex < 0 || toIndex > _blocks.length) {
      throw ValidationException(
        'validation.block_to_index',
        'toIndex out of range',
        {'toIndex': toIndex, 'length': _blocks.length},
      );
    }
    if (fromIndex == toIndex) {
      return;
    }
    final block = _blocks.removeAt(fromIndex);
    _blocks.insert(toIndex, block);
    _touch(nowUtc);
  }

  void toggleChecklistItem(BlockId blockId, int index, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    final blockIndex = _requireBlockIndex(blockId);
    final block = _blocks[blockIndex];
    final updated = block.maybeMap(
      checklistBlock: (b) {
        requireIndexInRange(index, b.items.length, 'index');
        final items = List<ChecklistItem>.from(b.items);
        final item = items[index];
        items[index] = item.copyWith(checked: !item.checked);
        return b.copyWith(items: items);
      },
      orElse: () => throw InvariantException(
        'invariant.block_type',
        'Block is not a ChecklistBlock',
        {'blockId': blockId},
      ),
    );
    _blocks[blockIndex] = updated;
    _touch(nowUtc);
  }

  void addChecklistItem(BlockId blockId, String text, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    final blockIndex = _requireBlockIndex(blockId);
    final block = _blocks[blockIndex];
    final updated = block.maybeMap(
      checklistBlock: (b) {
        final items = List<ChecklistItem>.from(b.items)
          ..add(ChecklistItem(text: text, checked: false));
        return b.copyWith(items: items);
      },
      orElse: () => throw InvariantException(
        'invariant.block_type',
        'Block is not a ChecklistBlock',
        {'blockId': blockId},
      ),
    );
    _blocks[blockIndex] = updated;
    _touch(nowUtc);
  }

  void removeChecklistItem(BlockId blockId, int index, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    final blockIndex = _requireBlockIndex(blockId);
    final block = _blocks[blockIndex];
    final updated = block.maybeMap(
      checklistBlock: (b) {
        requireIndexInRange(index, b.items.length, 'index');
        final items = List<ChecklistItem>.from(b.items);
        items.removeAt(index);
        return b.copyWith(items: items);
      },
      orElse: () => throw InvariantException(
        'invariant.block_type',
        'Block is not a ChecklistBlock',
        {'blockId': blockId},
      ),
    );
    _blocks[blockIndex] = updated;
    _touch(nowUtc);
  }

  void addSet(BlockId blockId, SetRecord set, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    final blockIndex = _requireBlockIndex(blockId);
    final block = _blocks[blockIndex];
    final updated = block.maybeMap(
      exerciseBlock: (b) {
        final sets = List<SetRecord>.from(b.sets)..add(set);
        return b.copyWith(sets: sets);
      },
      orElse: () => throw InvariantException(
        'invariant.block_type',
        'Block is not an ExerciseBlock',
        {'blockId': blockId},
      ),
    );
    _blocks[blockIndex] = updated;
    _touch(nowUtc);
  }

  void updateSet(
      BlockId blockId, int setIndex, SetRecord set, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    final blockIndex = _requireBlockIndex(blockId);
    final block = _blocks[blockIndex];
    final updated = block.maybeMap(
      exerciseBlock: (b) {
        requireIndexInRange(setIndex, b.sets.length, 'setIndex');
        final sets = List<SetRecord>.from(b.sets);
        sets[setIndex] = set;
        return b.copyWith(sets: sets);
      },
      orElse: () => throw InvariantException(
        'invariant.block_type',
        'Block is not an ExerciseBlock',
        {'blockId': blockId},
      ),
    );
    _blocks[blockIndex] = updated;
    _touch(nowUtc);
  }

  void removeSet(BlockId blockId, int setIndex, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    final blockIndex = _requireBlockIndex(blockId);
    final block = _blocks[blockIndex];
    final updated = block.maybeMap(
      exerciseBlock: (b) {
        requireIndexInRange(setIndex, b.sets.length, 'setIndex');
        final sets = List<SetRecord>.from(b.sets);
        sets.removeAt(setIndex);
        return b.copyWith(sets: sets);
      },
      orElse: () => throw InvariantException(
        'invariant.block_type',
        'Block is not an ExerciseBlock',
        {'blockId': blockId},
      ),
    );
    _blocks[blockIndex] = updated;
    _touch(nowUtc);
  }

  void bindTaskOccurrence(TaskOccurrenceId taskOccurrenceId, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    requireNonEmpty(taskOccurrenceId, 'taskOccurrenceId');
    if (_boundTaskOccurrenceId != null) {
      throw InvariantException(
        'invariant.task_occurrence_already_bound',
        'WorkoutLog already bound to a TaskOccurrence',
        {'boundTaskOccurrenceId': _boundTaskOccurrenceId},
      );
    }
    _boundTaskOccurrenceId = taskOccurrenceId;
    _touch(nowUtc);
  }

  void unbindTaskOccurrence(DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    if (_boundTaskOccurrenceId == null) {
      return;
    }
    _boundTaskOccurrenceId = null;
    _touch(nowUtc);
  }

  void replaceMetadata(Map<String, dynamic> metadata, DateTime nowUtc) {
    _requireUtcNow(nowUtc);
    _metadata = Map<String, dynamic>.from(metadata);
    _touch(nowUtc);
  }

  int _indexOfBlockId(BlockId blockId) {
    for (var i = 0; i < _blocks.length; i++) {
      if (_blocks[i].id == blockId) return i;
    }
    return -1;
  }

  int _requireBlockIndex(BlockId blockId) {
    requireNonEmpty(blockId, 'blockId');
    final index = _indexOfBlockId(blockId);
    if (index == -1) {
      throw NotFoundException(
        'not_found.block',
        'Block not found',
        {'blockId': blockId},
      );
    }
    return index;
  }

  void _touch(DateTime nowUtc) {
    _lastEditedAtUtc = nowUtc;
  }

  void _requireUtcNow(DateTime nowUtc) {
    requireUtc(nowUtc, 'nowUtc');
  }
}
