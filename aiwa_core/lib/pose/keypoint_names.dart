const List<String> kNeutralKeypointNames = [
  'nose',
  'leftEyeInner',
  'leftEye',
  'leftEyeOuter',
  'rightEyeInner',
  'rightEye',
  'rightEyeOuter',
  'leftEar',
  'rightEar',
  'leftMouth',
  'rightMouth',
  'leftShoulder',
  'rightShoulder',
  'leftElbow',
  'rightElbow',
  'leftWrist',
  'rightWrist',
  'leftPinky',
  'rightPinky',
  'leftIndex',
  'rightIndex',
  'leftThumb',
  'rightThumb',
  'leftHip',
  'rightHip',
  'leftKnee',
  'rightKnee',
  'leftAnkle',
  'rightAnkle',
  'leftHeel',
  'rightHeel',
  'leftFootIndex',
  'rightFootIndex',
];

const Set<String> kNeutralKeypointNameSet = {
  ...kNeutralKeypointNames,
};

const List<String> kMoveNet17Names = [
  'nose',
  'leftEye',
  'rightEye',
  'leftEar',
  'rightEar',
  'leftShoulder',
  'rightShoulder',
  'leftElbow',
  'rightElbow',
  'leftWrist',
  'rightWrist',
  'leftHip',
  'rightHip',
  'leftKnee',
  'rightKnee',
  'leftAnkle',
  'rightAnkle',
];

const String kLeftHip = 'leftHip';
const String kRightHip = 'rightHip';
const String kLeftKnee = 'leftKnee';
const String kRightKnee = 'rightKnee';
const String kLeftAnkle = 'leftAnkle';
const String kRightAnkle = 'rightAnkle';
const String kLeftShoulder = 'leftShoulder';
const String kRightShoulder = 'rightShoulder';

const List<String> kPrimaryLowerBodyJoints = [
  kLeftHip,
  kRightHip,
  kLeftKnee,
  kRightKnee,
  kLeftAnkle,
  kRightAnkle,
];

const List<String> kPrimaryTrunkJoints = [
  kLeftShoulder,
  kRightShoulder,
  kLeftHip,
  kRightHip,
];

String _toSnakeCase(String input) {
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    final isUpper = ch.toUpperCase() == ch && ch.toLowerCase() != ch;
    if (isUpper && i != 0) {
      buffer.write('_');
    }
    buffer.write(ch.toLowerCase());
  }
  return buffer.toString();
}

final Map<String, String> _neutralSnakeToCamel = {
  for (final name in kNeutralKeypointNames) _toSnakeCase(name): name,
  for (final name in kMoveNet17Names) _toSnakeCase(name): name,
  'mouth_left': 'leftMouth',
  'mouth_right': 'rightMouth',
};

/// Normalize a neutral keypoint name to the canonical camelCase form used by
/// aiwa_core. Accepts legacy snake_case variants and returns the original name
/// when no canonical mapping is known.
String normalizeNeutralKeypointName(String name) {
  if (kNeutralKeypointNameSet.contains(name)) {
    return name;
  }

  final lower = name.toLowerCase();
  final alias = _neutralSnakeToCamel[lower];
  if (alias != null) {
    return alias;
  }

  final sanitized = lower.replaceAll('-', '_');
  final sanitizedAlias = _neutralSnakeToCamel[sanitized];
  if (sanitizedAlias != null) {
    return sanitizedAlias;
  }

  final fromSnake = _neutralSnakeToCamel[_toSnakeCase(name)];
  return fromSnake ?? name;
}
