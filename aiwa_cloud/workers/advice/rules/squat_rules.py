"""
Squat-specific rules for advice generation
"""
from typing import List, Dict, Callable


class Rule:
    """Rule definition for advice generation"""
    
    def __init__(
        self,
        id: str,
        condition: Callable[[Dict], bool],
        title: str,
        detail: str,
        severity: str,
        priority: int = 0
    ):
        self.id = id
        self.condition = condition
        self.title = title
        self.detail = detail
        self.severity = severity  # 'error', 'warning', 'info'
        self.priority = priority  # Higher = more important


# Define 15 squat rules
SQUAT_RULES: List[Rule] = [
    # Critical form issues
    Rule(
        id="depth_insufficient",
        condition=lambda r: r['scores']['form'] < 60,
        title="Squat deeper for better form",
        detail="Your form score is {form}/100. Try to squat until your thighs are at least parallel to the ground.",
        severity="error",
        priority=10
    ),
    
    Rule(
        id="depth_good",
        condition=lambda r: r['scores']['form'] >= 80,
        title="Great squat depth!",
        detail="Your form score is {form}/100. You're achieving excellent depth.",
        severity="info",
        priority=1
    ),
    
    # Stability issues
    Rule(
        id="stability_poor",
        condition=lambda r: r['scores']['stability'] < 60,
        title="Improve stability",
        detail="Your stability score is {stability}/100. Focus on keeping your core tight and weight centered over mid-foot.",
        severity="warning",
        priority=9
    ),
    
    Rule(
        id="stability_good",
        condition=lambda r: r['scores']['stability'] >= 80,
        title="Excellent stability",
        detail="Your stability score is {stability}/100. You're maintaining good balance throughout the movement.",
        severity="info",
        priority=1
    ),
    
    # Tempo issues
    Rule(
        id="tempo_inconsistent",
        condition=lambda r: r['scores']['tempo'] < 60,
        title="Maintain consistent tempo",
        detail="Your tempo score is {tempo}/100. Try counting 2-1-2 (down-pause-up) for each rep to build consistency.",
        severity="warning",
        priority=7
    ),
    
    Rule(
        id="tempo_good",
        condition=lambda r: r['scores']['tempo'] >= 80,
        title="Great tempo control",
        detail="Your tempo score is {tempo}/100. You're maintaining excellent rhythm.",
        severity="info",
        priority=1
    ),
    
    # Rep count feedback
    Rule(
        id="low_rep_count",
        condition=lambda r: r['repCount'] < 5,
        title="Complete more reps",
        detail="You completed {repCount} reps. Aim for at least 8-12 reps per set for strength building.",
        severity="info",
        priority=5
    ),
    
    Rule(
        id="good_rep_count",
        condition=lambda r: 8 <= r['repCount'] <= 15,
        title="Good rep count",
        detail="You completed {repCount} reps. This is a good range for building strength and endurance.",
        severity="info",
        priority=1
    ),
    
    Rule(
        id="high_rep_count",
        condition=lambda r: r['repCount'] > 20,
        title="High rep count",
        detail="You completed {repCount} reps. Consider adding weight if form remains good at this volume.",
        severity="info",
        priority=2
    ),
    
    # Overall performance
    Rule(
        id="overall_excellent",
        condition=lambda r: r['scores']['overall'] >= 85,
        title="Excellent performance!",
        detail="Your overall score is {overall}/100. Keep up the great work!",
        severity="info",
        priority=1
    ),
    
    Rule(
        id="overall_good",
        condition=lambda r: 70 <= r['scores']['overall'] < 85,
        title="Good performance",
        detail="Your overall score is {overall}/100. Focus on the areas marked for improvement.",
        severity="info",
        priority=1
    ),
    
    Rule(
        id="overall_needs_work",
        condition=lambda r: r['scores']['overall'] < 70,
        title="Focus on fundamentals",
        detail="Your overall score is {overall}/100. Review the specific feedback below to improve your form.",
        severity="warning",
        priority=8
    ),
    
    # Quality warnings
    Rule(
        id="low_confidence",
        condition=lambda r: r.get('quality', {}).get('lowConfidence', False),
        title="Detection quality issue",
        detail="Some keypoints had low confidence. Ensure good lighting and camera angle for better analysis.",
        severity="warning",
        priority=6
    ),
    
    Rule(
        id="poor_coverage",
        condition=lambda r: r.get('quality', {}).get('coverage', 1.0) < 0.8,
        title="Incomplete body visibility",
        detail="Parts of your body were not visible in some frames. Make sure your full body is in frame.",
        severity="warning",
        priority=6
    ),
    
    # Encouragement
    Rule(
        id="keep_practicing",
        condition=lambda r: r['scores']['overall'] < 80 and r['repCount'] >= 5,
        title="Keep practicing",
        detail="You're making progress! Consistency is key to improving your squat form.",
        severity="info",
        priority=1
    ),
]


def get_applicable_rules(result: Dict) -> List[Rule]:
    """
    Get all rules that apply to the given result
    
    Args:
        result: Result dictionary (result.json or result_cloud.json)
        
    Returns:
        List of applicable rules, sorted by priority (descending)
    """
    applicable = []
    
    for rule in SQUAT_RULES:
        try:
            if rule.condition(result):
                applicable.append(rule)
        except (KeyError, TypeError):
            # Skip rules that fail due to missing data
            continue
    
    # Sort by priority (higher first)
    applicable.sort(key=lambda r: r.priority, reverse=True)
    
    return applicable

