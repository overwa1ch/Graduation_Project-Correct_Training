"""
REINFER Pipeline
Combines RTMPose inference, temporal smoothing, and segmentation
"""
import json
import logging
from typing import Dict, Optional
import numpy as np

from .rtmpose_model import RTMPoseModel
from .temporal_smoothing import smooth_keypoints_series
from .segmentation import segment_reps_advanced

logger = logging.getLogger(__name__)


class ReinferPipeline:
    """Pipeline for re-inferring keypoints and generating cloud results"""
    
    def __init__(self, model_path: str, use_gpu: bool = True):
        """
        Initialize pipeline
        
        Args:
            model_path: Path to RTMPose ONNX model
            use_gpu: Whether to use GPU acceleration
        """
        logger.info(f"Initializing REINFER pipeline with model: {model_path}")
        self.model = RTMPoseModel(model_path, use_gpu=use_gpu)
    
    def process(
        self,
        keypoints_json_path: str,
        video_path: Optional[str] = None,
        result_local_path: Optional[str] = None
    ) -> Dict:
        """
        Main processing pipeline
        
        Steps:
        1. Load neutral keypoints from app
        2. (Optional) Re-infer from video if provided
        3. Apply temporal smoothing
        4. Segment reps
        5. Generate result_cloud.json
        
        Args:
            keypoints_json_path: Path to keypoints.json from app
            video_path: Optional path to video for re-inference
            result_local_path: Optional path to result_local.json
            
        Returns:
            result_cloud dictionary
        """
        logger.info("Starting REINFER pipeline")
        
        # 1. Load keypoints
        with open(keypoints_json_path, 'r') as f:
            neutral_data = json.load(f)
        
        fps = neutral_data['sampling']['effectiveFps']
        frames = neutral_data['frames']
        template = neutral_data.get('template', 'squat')
        
        logger.info(f"Loaded {len(frames)} frames at {fps} FPS for template '{template}'")
        
        # Extract keypoints series
        keypoints_series = []
        for frame in frames:
            # Convert keypoints to numpy array (x, y, confidence)
            kps = np.array([[kp['x'], kp['y'], kp.get('confidence', 1.0)] 
                           for kp in frame['keypoints']])
            keypoints_series.append(kps)
        
        # 2. (P0: Skip video re-inference, use app keypoints)
        # TODO P1: If video_path provided, re-infer with RTMPose
        if video_path:
            logger.info("Video re-inference not yet implemented (P1 feature)")
        
        # 3. Apply temporal smoothing
        logger.info("Applying temporal smoothing")
        smoothed_series = smooth_keypoints_series(keypoints_series, fps, method='one_euro')
        
        # 4. Segment reps
        logger.info("Segmenting reps")
        reps, metadata = segment_reps_advanced(smoothed_series, fps, template)
        
        # 5. Generate result_cloud.json (P0: same format as result.json)
        logger.info(f"Generating result_cloud with {len(reps)} reps")
        
        # Calculate scores (P0: placeholder logic)
        form_score = self._calculate_form_score(reps)
        stability_score = self._calculate_stability_score(smoothed_series)
        tempo_score = self._calculate_tempo_score(reps, metadata)
        overall_score = int((form_score + stability_score + tempo_score) / 3)
        
        result = {
            "scores": {
                "form": form_score,
                "stability": stability_score,
                "tempo": tempo_score,
                "overall": overall_score
            },
            "repCount": len(reps),
            "quality": {
                "lowConfidence": False,
                "coverage": 0.95
            },
            "meta": {
                "template": template,
                "strictness": "strict",
                "engine": "RTMPose-m",
                "fps": int(fps),
                "smoothing": "one_euro",
                "cloud_version": "1.0.0"
            },
            "evidence": []  # P1: Add specific evidence items
        }
        
        logger.info(f"Pipeline complete. Overall score: {overall_score}")
        
        return result
    
    def _calculate_form_score(self, reps: list) -> int:
        """
        Calculate form score based on rep characteristics
        
        P0: Placeholder logic based on knee angle range
        P1: Implement proper form analysis
        """
        if len(reps) == 0:
            return 50
        
        # Check knee angle range (good squat should have 60-90 degree range)
        angle_ranges = [r['angle_range'] for r in reps]
        avg_range = np.mean(angle_ranges)
        
        if avg_range >= 60:
            return 85
        elif avg_range >= 45:
            return 75
        elif avg_range >= 30:
            return 65
        else:
            return 55
    
    def _calculate_stability_score(self, keypoints_series: list) -> int:
        """
        Calculate stability score based on keypoint variance
        
        P0: Placeholder logic
        P1: Implement proper stability analysis
        """
        # Calculate variance in hip positions
        hip_positions = [kps[11, :2] for kps in keypoints_series]  # Left hip
        hip_variance = np.var(hip_positions, axis=0).mean()
        
        # Lower variance = higher stability
        if hip_variance < 10:
            return 85
        elif hip_variance < 20:
            return 75
        elif hip_variance < 30:
            return 65
        else:
            return 55
    
    def _calculate_tempo_score(self, reps: list, metadata: dict) -> int:
        """
        Calculate tempo score based on rep consistency
        
        P0: Placeholder logic
        P1: Implement proper tempo analysis
        """
        if len(reps) == 0:
            return 50
        
        # Check consistency of rep durations
        std_duration = metadata.get('std_rep_duration_ms', 0)
        
        if std_duration < 300:  # < 300ms std
            return 85
        elif std_duration < 500:
            return 75
        elif std_duration < 800:
            return 65
        else:
            return 55

