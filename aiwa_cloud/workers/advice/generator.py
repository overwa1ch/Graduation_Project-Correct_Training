"""
Advice Generator
Generates structured advice from result.json using rule engine
"""
import json
import logging
from typing import Dict, List
from .rules.squat_rules import get_applicable_rules

logger = logging.getLogger(__name__)


def generate_advice(result: Dict, template: str = 'squat') -> Dict:
    """
    Generate structured advice from result.json
    
    Args:
        result: Result dictionary (result.json or result_cloud.json)
        template: Exercise template ('squat', 'pushup', etc.)
        
    Returns:
        Advice dictionary with structured advice items
    """
    logger.info(f"Generating advice for template '{template}'")
    
    # Get applicable rules based on template
    if template == 'squat':
        applicable_rules = get_applicable_rules(result)
    else:
        logger.warning(f"No rules defined for template '{template}', returning empty advice")
        applicable_rules = []
    
    logger.info(f"Found {len(applicable_rules)} applicable rules")
    
    # Generate advice items
    advice_list = []
    for rule in applicable_rules:
        # Format detail string with scores
        detail = rule.detail.format(
            form=result['scores'].get('form', 0),
            stability=result['scores'].get('stability', 0),
            tempo=result['scores'].get('tempo', 0),
            overall=result['scores'].get('overall', 0),
            repCount=result.get('repCount', 0)
        )
        
        advice_item = {
            "id": rule.id,
            "title": rule.title,
            "detail": detail,
            "severity": rule.severity,
            "priority": rule.priority,
            "evidence": {}  # P1: Can be enhanced with specific frame/angle data
        }
        
        advice_list.append(advice_item)
    
    # Build final advice structure
    advice = {
        "advice": advice_list,
        "meta": {
            "template": template,
            "version": "v1.0",
            "total_items": len(advice_list),
            "generated_from": result.get('meta', {}).get('engine', 'unknown')
        }
    }
    
    logger.info(f"Generated {len(advice_list)} advice items")
    
    return advice


def generate_advice_from_file(result_path: str, template: str = 'squat') -> Dict:
    """
    Generate advice from result file
    
    Args:
        result_path: Path to result.json or result_cloud.json
        template: Exercise template
        
    Returns:
        Advice dictionary
    """
    logger.info(f"Loading result from {result_path}")
    
    with open(result_path, 'r') as f:
        result = json.load(f)
    
    return generate_advice(result, template)

