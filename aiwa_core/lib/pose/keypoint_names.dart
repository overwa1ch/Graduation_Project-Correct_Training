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
