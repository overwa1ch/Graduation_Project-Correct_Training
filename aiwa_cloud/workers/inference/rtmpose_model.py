"""
RTMPose ONNX Model Inference
"""
import onnxruntime as ort
import numpy as np
import cv2
import logging
from typing import List, Tuple

logger = logging.getLogger(__name__)


class RTMPoseModel:
    """RTMPose model for keypoint detection"""
    
    def __init__(self, model_path: str, use_gpu: bool = True):
        """
        Initialize RTMPose model
        
        Args:
            model_path: Path to ONNX model file
            use_gpu: Whether to use GPU acceleration
        """
        self.input_size = (384, 288)  # width x height for RTMPose-m
        
        # Setup execution providers
        providers = ['CUDAExecutionProvider', 'CPUExecutionProvider'] if use_gpu else ['CPUExecutionProvider']
        
        logger.info(f"Loading RTMPose model from {model_path}")
        logger.info(f"Using providers: {providers}")
        
        self.session = ort.InferenceSession(model_path, providers=providers)
        
        # Get input/output names
        self.input_name = self.session.get_inputs()[0].name
        self.output_name = self.session.get_outputs()[0].name
        
        logger.info(f"Model loaded successfully. Input: {self.input_name}, Output: {self.output_name}")
    
    def preprocess(self, frame: np.ndarray) -> np.ndarray:
        """
        Preprocess frame for RTMPose inference
        
        Args:
            frame: Input frame (BGR format from OpenCV)
            
        Returns:
            Preprocessed tensor ready for inference
        """
        # Resize to model input size
        img = cv2.resize(frame, self.input_size)
        
        # Convert BGR to RGB
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Normalize to [0, 1]
        img = img.astype(np.float32) / 255.0
        
        # HWC to CHW
        img = np.transpose(img, (2, 0, 1))
        
        # Add batch dimension
        img = np.expand_dims(img, axis=0)
        
        return img
    
    def postprocess(self, output: np.ndarray, original_shape: Tuple[int, int]) -> np.ndarray:
        """
        Postprocess model output to get keypoints in original image coordinates
        
        Args:
            output: Raw model output
            original_shape: Original image shape (height, width)
            
        Returns:
            Keypoints array of shape (num_keypoints, 3) with (x, y, confidence)
        """
        # Output shape is typically (1, num_keypoints, 3) where last dim is (x, y, confidence)
        keypoints = output[0]  # Remove batch dimension
        
        # Scale keypoints from model input size to original size
        orig_h, orig_w = original_shape
        scale_x = orig_w / self.input_size[0]
        scale_y = orig_h / self.input_size[1]
        
        keypoints[:, 0] *= scale_x
        keypoints[:, 1] *= scale_y
        
        return keypoints
    
    def infer(self, frame: np.ndarray) -> np.ndarray:
        """
        Run inference on single frame
        
        Args:
            frame: Input frame (BGR format)
            
        Returns:
            Keypoints array of shape (num_keypoints, 3) with (x, y, confidence)
        """
        original_shape = frame.shape[:2]  # (height, width)
        
        # Preprocess
        input_tensor = self.preprocess(frame)
        
        # Run inference
        outputs = self.session.run([self.output_name], {self.input_name: input_tensor})
        
        # Postprocess
        keypoints = self.postprocess(outputs[0], original_shape)
        
        return keypoints
    
    def infer_batch(self, frames: List[np.ndarray]) -> List[np.ndarray]:
        """
        Run inference on batch of frames
        
        Args:
            frames: List of input frames
            
        Returns:
            List of keypoints arrays
        """
        results = []
        for i, frame in enumerate(frames):
            if i % 100 == 0:
                logger.info(f"Processing frame {i}/{len(frames)}")
            keypoints = self.infer(frame)
            results.append(keypoints)
        
        return results

