from pydantic_settings import BaseSettings
from typing import Literal


class Settings(BaseSettings):
    # Aliyun
    aliyun_region: str = "oss-cn-hangzhou"
    aliyun_access_key_id: str
    aliyun_secret_access_key: str
    aliyun_oss_bucket: str
    aliyun_mns_account_id: str = ""
    aliyun_mns_reinfer_queue_name: str
    aliyun_mns_advice_queue_name: str
    
    # Database
    database_url: str
    
    # Model paths
    rtmpose_model_path: str = "/models/rtmpose-m-384x288.onnx"
    
    # Worker configuration
    worker_type: Literal["reinfer", "advice"] = "reinfer"
    log_level: str = "INFO"
    
    # Visibility timeouts (in seconds)
    reinfer_visibility_timeout: int = 45 * 60  # 45 minutes
    advice_visibility_timeout: int = 10 * 60   # 10 minutes
    
    # Processing timeouts (in seconds)
    reinfer_timeout: int = 30 * 60  # 30 minutes
    advice_timeout: int = 5 * 60    # 5 minutes
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()

