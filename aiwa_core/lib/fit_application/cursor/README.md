# Cursor Pagination Contract

This document describes the active cursor namespaces used by `aiwa_core`.

## Payload shape

All cursors are Base64URL-encoded JSON payloads:

```json
{
  "v": 1,
  "h": "<namespace>",
  "k": { "...": "sort keys" }
}
```

- `v`: protocol version
- `h`: cursor namespace
- `k`: sort-key payload

## Active namespaces

| Namespace | Entity | Sort order |
| --- | --- | --- |
| `workoutLog:dateRange:v1` | `WorkoutLog` | `date DESC`, `createdAtUtc DESC`, `id ASC` |
| `milestone:createdAtRange:v1` | `MilestoneEvent` | `createdAtUtc DESC`, `id ASC` |
| `exerciseCatalog:v1` | `Exercise` | `deprecated ASC`, `lower(name) ASC`, `id ASC` |
| `tagCatalog:v1` | `Tag` | `lower(name) ASC`, `id ASC` |

## Cursor key types

### WorkoutLog

```dart
class WorkoutLogCursorKey {
  final String date;
  final String createdAtUtc;
  final String id;
}
```

### MilestoneEvent

```dart
class MilestoneCursorKey {
  final String createdAtUtc;
  final String id;
}
```

### Exercise

```dart
class ExerciseCatalogCursorKey {
  final int deprecated;
  final String nameNormalized;
  final String id;
}
```

### Tag

```dart
class TagCatalogCursorKey {
  final String nameNormalized;
  final String id;
}
```

## Versioning rules

1. Keep namespace format as `<entity>:<scope>:v<version>`.
2. `v=1` must remain backward compatible.
3. Any future breaking cursor change must use a new namespace version.

## Source locations

- Codec: `aiwa_core/lib/fit_application/cursor/cursor_codec.dart`
- Models: `aiwa_core/lib/fit_application/cursor/cursor_models.dart`
- Repository implementations: `aiwa_core/lib/fit_storage/src/repositories/*_repo.dart`
