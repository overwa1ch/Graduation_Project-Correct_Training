"""
Temporal Smoothing for Keypoint Trajectories
Implements One-Euro Filter and Savitzky-Golay Filter
"""
import numpy as np
from scipy.signal import savgol_filter
import logging
from typing import List

logger = logging.getLogger(__name__)


class OneEuroFilter:
    """
    One Euro Filter for temporal smoothing
    Paper: https://cristal.univ-lille.fr/~casiez/1euro/
    """
    
    def __init__(self, freq: float, mincutoff: float = 1.0, beta: float = 0.007, dcutoff: float = 1.0):
        """
        Initialize One Euro Filter
        
        Args:
            freq: Sampling frequency (e.g., FPS)
            mincutoff: Minimum cutoff frequency
            beta: Cutoff slope
            dcutoff: Cutoff frequency for derivative
        """
        self.freq = freq
        self.mincutoff = mincutoff
        self.beta = beta
        self.dcutoff = dcutoff
        self.x_prev = None
        self.dx_prev = 0.0
    
    def __call__(self, x: float) -> float:
        """
        Apply filter to single value
        
        Args:
            x: Input value
            
        Returns:
            Filtered value
        """
        if self.x_prev is None:
            self.x_prev = x
            return x
        
        # Compute derivative
        dx = (x - self.x_prev) * self.freq
        dx_filtered = self._smoothing_factor(self.dcutoff) * dx + \
                      (1 - self._smoothing_factor(self.dcutoff)) * self.dx_prev
        
        # Compute adaptive cutoff
        cutoff = self.mincutoff + self.beta * abs(dx_filtered)
        
        # Filter signal
        x_filtered = self._smoothing_factor(cutoff) * x + \
                     (1 - self._smoothing_factor(cutoff)) * self.x_prev
        
        # Update state
        self.x_prev = x_filtered
        self.dx_prev = dx_filtered
        
        return x_filtered
    
    def _smoothing_factor(self, cutoff: float) -> float:
        """Calculate smoothing factor from cutoff frequency"""
        r = 2 * np.pi * cutoff / self.freq
        return r / (r + 1)


def apply_savgol_filter(
    trajectory: np.ndarray,
    window_length: int = 11,
    polyorder: int = 3
) -> np.ndarray:
    """
    Apply Savitzky-Golay filter to trajectory
    
    Args:
        trajectory: Input trajectory of shape (num_frames, num_dims)
        window_length: Length of filter window (must be odd)
        polyorder: Order of polynomial fit
        
    Returns:
        Smoothed trajectory
    """
    if len(trajectory) < window_length:
        logger.warning(f"Trajectory length {len(trajectory)} < window_length {window_length}, returning original")
        return trajectory
    
    # Ensure window_length is odd
    if window_length % 2 == 0:
        window_length += 1
    
    return savgol_filter(trajectory, window_length, polyorder, axis=0)


def smooth_keypoints_series(
    keypoints_series: List[np.ndarray],
    fps: float,
    method: str = 'one_euro'
) -> List[np.ndarray]:
    """
    Apply temporal smoothing to entire keypoints series
    
    Args:
        keypoints_series: List of keypoints arrays, each of shape (num_keypoints, 2 or 3)
        fps: Frames per second
        method: Smoothing method ('one_euro' or 'savgol')
        
    Returns:
        List of smoothed keypoints arrays
    """
    num_frames = len(keypoints_series)
    num_keypoints = keypoints_series[0].shape[0]
    num_dims = keypoints_series[0].shape[1]  # 2 for (x, y) or 3 for (x, y, conf)
    
    logger.info(f"Smoothing {num_frames} frames with {num_keypoints} keypoints using {method}")
    
    if method == 'one_euro':
        # Apply One-Euro filter per keypoint dimension
        smoothed = []
        
        for kp_idx in range(num_keypoints):
            # Create filters for each dimension
            filters = [OneEuroFilter(fps) for _ in range(num_dims)]
            
            kp_trajectory = []
            for frame_idx in range(num_frames):
                kp = keypoints_series[frame_idx][kp_idx]
                kp_smooth = np.array([filters[d](kp[d]) for d in range(num_dims)])
                kp_trajectory.append(kp_smooth)
            
            smoothed.append(np.array(kp_trajectory))
        
        # Reconstruct per-frame format
        result = []
        for frame_idx in range(num_frames):
            frame_kps = np.array([smoothed[kp_idx][frame_idx] for kp_idx in range(num_keypoints)])
            result.append(frame_kps)
        
        return result
    
    elif method == 'savgol':
        # Apply Savitzky-Golay filter
        # Reshape to (num_frames, num_keypoints * num_dims)
        flat_series = np.array([kps.flatten() for kps in keypoints_series])
        
        # Apply filter
        smoothed_flat = apply_savgol_filter(flat_series)
        
        # Reshape back to per-frame format
        result = []
        for frame_idx in range(num_frames):
            frame_kps = smoothed_flat[frame_idx].reshape(num_keypoints, num_dims)
            result.append(frame_kps)
        
        return result
    
    else:
        raise ValueError(f"Unknown smoothing method: {method}")


def smooth_keypoints_hybrid(
    keypoints_series: List[np.ndarray],
    fps: float
) -> List[np.ndarray]:
    """
    Apply hybrid smoothing: One-Euro first, then light Savitzky-Golay
    
    Args:
        keypoints_series: List of keypoints arrays
        fps: Frames per second
        
    Returns:
        List of smoothed keypoints arrays
    """
    logger.info("Applying hybrid smoothing (One-Euro + Savitzky-Golay)")
    
    # First pass: One-Euro filter
    smoothed_1 = smooth_keypoints_series(keypoints_series, fps, method='one_euro')
    
    # Second pass: Light Savitzky-Golay for additional smoothness
    smoothed_2 = smooth_keypoints_series(smoothed_1, fps, method='savgol')
    
    return smoothed_2

