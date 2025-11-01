"""
Rep Segmentation Logic
Uses peak-valley detection on knee angles to segment repetitions
"""
import numpy as np
from scipy.signal import find_peaks
import logging
from typing import List, Dict, Tuple

logger = logging.getLogger(__name__)


def calculate_angle(p1: np.ndarray, p2: np.ndarray, p3: np.ndarray) -> float:
    """
    Calculate angle at p2 formed by p1-p2-p3
    
    Args:
        p1, p2, p3: Points as (x, y) arrays
        
    Returns:
        Angle in degrees
    """
    v1 = p1 - p2
    v2 = p3 - p2
    
    # Calculate angle using dot product
    cos_angle = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2) + 1e-8)
    cos_angle = np.clip(cos_angle, -1.0, 1.0)
    angle = np.arccos(cos_angle)
    
    return np.degrees(angle)


def calculate_knee_angle(keypoints: np.ndarray, side: str = 'left') -> float:
    """
    Calculate knee angle from keypoints
    
    Args:
        keypoints: Keypoints array of shape (num_keypoints, 2 or 3)
        side: 'left' or 'right'
        
    Returns:
        Knee angle in degrees
    """
    # COCO keypoint indices (assuming 17-point COCO format)
    # 11: left_hip, 12: right_hip
    # 13: left_knee, 14: right_knee
    # 15: left_ankle, 16: right_ankle
    
    if side == 'left':
        hip_idx, knee_idx, ankle_idx = 11, 13, 15
    else:
        hip_idx, knee_idx, ankle_idx = 12, 14, 16
    
    # Extract points (x, y)
    hip = keypoints[hip_idx, :2]
    knee = keypoints[knee_idx, :2]
    ankle = keypoints[ankle_idx, :2]
    
    # Calculate angle
    angle = calculate_angle(hip, knee, ankle)
    
    return angle


def calculate_hip_angle(keypoints: np.ndarray, side: str = 'left') -> float:
    """
    Calculate hip angle from keypoints
    
    Args:
        keypoints: Keypoints array
        side: 'left' or 'right'
        
    Returns:
        Hip angle in degrees
    """
    # COCO keypoint indices
    # 5: left_shoulder, 6: right_shoulder
    # 11: left_hip, 12: right_hip
    # 13: left_knee, 14: right_knee
    
    if side == 'left':
        shoulder_idx, hip_idx, knee_idx = 5, 11, 13
    else:
        shoulder_idx, hip_idx, knee_idx = 6, 12, 14
    
    shoulder = keypoints[shoulder_idx, :2]
    hip = keypoints[hip_idx, :2]
    knee = keypoints[knee_idx, :2]
    
    angle = calculate_angle(shoulder, hip, knee)
    
    return angle


def segment_reps_by_knee_angle(
    keypoints_series: List[np.ndarray],
    fps: float,
    template: str = 'squat',
    min_rep_duration: float = 1.5,
    max_rep_duration: float = 10.0
) -> List[Dict]:
    """
    Segment reps using knee valley angle detection
    
    Args:
        keypoints_series: List of keypoints arrays
        fps: Frames per second
        template: Exercise template ('squat', 'pushup', etc.)
        min_rep_duration: Minimum rep duration in seconds
        max_rep_duration: Maximum rep duration in seconds
        
    Returns:
        List of rep dictionaries with start_frame, end_frame, duration_ms, etc.
    """
    num_frames = len(keypoints_series)
    logger.info(f"Segmenting {num_frames} frames for {template} exercise")
    
    # Calculate knee angles over time (average of left and right)
    knee_angles = []
    for frame_kps in keypoints_series:
        left_angle = calculate_knee_angle(frame_kps, 'left')
        right_angle = calculate_knee_angle(frame_kps, 'right')
        avg_angle = (left_angle + right_angle) / 2
        knee_angles.append(avg_angle)
    
    knee_angles = np.array(knee_angles)
    
    # Find valleys (local minima) in knee angle
    # Valleys represent the bottom position of squat
    min_distance = int(fps * min_rep_duration)  # Minimum frames between reps
    
    valleys, properties = find_peaks(
        -knee_angles,  # Invert to find minima
        distance=min_distance,
        prominence=15  # Minimum angle change to be considered a valley
    )
    
    logger.info(f"Found {len(valleys)} potential rep valleys")
    
    # Build rep segments
    reps = []
    for i in range(len(valleys) - 1):
        start_frame = int(valleys[i])
        end_frame = int(valleys[i + 1])
        duration_frames = end_frame - start_frame
        duration_ms = int(duration_frames / fps * 1000)
        
        # Filter by duration
        if duration_ms / 1000 < min_rep_duration or duration_ms / 1000 > max_rep_duration:
            logger.debug(f"Skipping rep {i}: duration {duration_ms}ms out of range")
            continue
        
        # Calculate rep statistics
        min_knee_angle = float(knee_angles[start_frame])
        max_knee_angle = float(np.max(knee_angles[start_frame:end_frame]))
        angle_range = max_knee_angle - min_knee_angle
        
        rep_dict = {
            'rep_index': len(reps),
            'start_frame': start_frame,
            'end_frame': end_frame,
            'duration_ms': duration_ms,
            'min_knee_angle': min_knee_angle,
            'max_knee_angle': max_knee_angle,
            'angle_range': angle_range,
        }
        
        reps.append(rep_dict)
    
    logger.info(f"Segmented {len(reps)} valid reps")
    
    return reps


def segment_reps_advanced(
    keypoints_series: List[np.ndarray],
    fps: float,
    template: str = 'squat'
) -> Tuple[List[Dict], Dict]:
    """
    Advanced rep segmentation with additional metrics
    
    Args:
        keypoints_series: List of keypoints arrays
        fps: Frames per second
        template: Exercise template
        
    Returns:
        Tuple of (reps list, metadata dict)
    """
    reps = segment_reps_by_knee_angle(keypoints_series, fps, template)
    
    # Calculate additional metadata
    metadata = {
        'total_frames': len(keypoints_series),
        'total_reps': len(reps),
        'fps': fps,
        'template': template,
        'duration_seconds': len(keypoints_series) / fps,
    }
    
    if len(reps) > 0:
        durations = [r['duration_ms'] for r in reps]
        metadata['avg_rep_duration_ms'] = int(np.mean(durations))
        metadata['std_rep_duration_ms'] = int(np.std(durations))
        metadata['min_rep_duration_ms'] = int(np.min(durations))
        metadata['max_rep_duration_ms'] = int(np.max(durations))
    
    return reps, metadata

