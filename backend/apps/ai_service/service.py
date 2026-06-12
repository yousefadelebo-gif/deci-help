"""
AI Service for Decision Analysis
Uses OpenRouter for intelligent decision recommendations
"""

import json
import logging
from typing import Dict, List, Optional
from django.conf import settings

logger = logging.getLogger(__name__)

# Try to import OpenAI (used for OpenRouter compatibility)
try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    logger.warning("OpenAI package not installed. AI features will be disabled.")

# OpenRouter API configuration
OPENROUTER_API_KEY = getattr(settings, 'OPENROUTER_API_KEY', '').strip()
OPENROUTER_BASE_URL = getattr(
    settings,
    'OPENROUTER_BASE_URL',
    'https://openrouter.ai/api/v1',
)
OPENROUTER_MODEL = (
    getattr(settings, 'OPENROUTER_MODEL', '')
    or getattr(settings, 'OPENAI_MODEL', '')
    or 'openai/gpt-4o-mini'
)


class AIDecisionService:
    """Service for AI-powered decision analysis via OpenRouter"""
    
    def __init__(self):
        self.client = None
        self.model = OPENROUTER_MODEL
        
        if OPENAI_AVAILABLE and OPENROUTER_API_KEY:
            self.client = OpenAI(
                api_key=OPENROUTER_API_KEY,
                base_url=OPENROUTER_BASE_URL,
            )
    
    def is_available(self) -> bool:
        """Check if AI service is available"""
        return self.client is not None
    
    def analyze_decision(self, decision_data: Dict) -> Dict:
        """
        Analyze a decision and provide AI recommendation
        
        Args:
            decision_data: Dictionary containing:
                - title: Decision title
                - description: Decision description
                - category: Decision category
                - options: List of options with pros/cons
                - factors: List of factors with weights
                - ratings: Factor ratings for each option
        
        Returns:
            Dictionary with AI analysis results
        """
        if not self.is_available():
            return {
                'success': False,
                'error': 'AI service is not available',
                'recommendation': None
            }
        
        try:
            prompt = self._build_analysis_prompt(decision_data)
            
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": """You are an expert decision-making analyst with expertise in behavioral economics, psychology, and strategic planning. Your role is to help users make better decisions by:

1. Analyzing each option objectively using evidence-based reasoning
2. Evaluating options against the specific factors the user has identified as important
3. Considering both explicit pros/cons and implicit trade-offs
4. Weighing short-term vs long-term implications
5. Identifying potential blind spots or unconsidered factors
6. Providing actionable, practical recommendations

SCORING GUIDELINES:
- Scores must be between 0.0 and 1.0 (decimals)
- 0.9-1.0: Exceptional choice with minimal drawbacks
- 0.7-0.89: Strong choice with manageable concerns
- 0.5-0.69: Moderate choice with notable trade-offs
- 0.3-0.49: Weak choice with significant concerns
- 0.0-0.29: Poor choice with major issues

- Confidence reflects how certain you are in the recommendation based on available information
- Higher confidence (0.8+) when there's clear differentiation between options
- Lower confidence (0.5-0.7) when options are close or information is limited

Be supportive but honest. Never give false optimism - if all options have issues, acknowledge it.

You MUST respond ONLY with valid JSON (no markdown, no code blocks, no explanation outside JSON):
{
    "recommended_option_index": 0,
    "confidence": 0.75,
    "explanation": "2-4 sentence explanation of why this option is recommended, referencing specific factors and trade-offs",
    "option_scores": [
        {"index": 0, "score": 0.72, "reasoning": "1-2 sentence reasoning for this score"},
        {"index": 1, "score": 0.85, "reasoning": "1-2 sentence reasoning for this score"}
    ],
    "insights": [
        "Key insight about the decision that may not be obvious",
        "Another important observation based on the factors"
    ],
    "considerations": [
        "Something important to think about before deciding",
        "A factor that could affect the outcome"
    ],
    "potential_risks": [
        "Risk if choosing the recommended option",
        "General risk to be aware of"
    ]
}"""
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.7,
                max_tokens=2000,
            )
            
            # Parse JSON from response (handle potential markdown code blocks)
            content = response.choices[0].message.content
            if '```json' in content:
                content = content.split('```json')[1].split('```')[0]
            elif '```' in content:
                content = content.split('```')[1].split('```')[0]
            result = json.loads(content.strip())
            
            summary = result.get('summary') or result.get('explanation', '')
            drivers = result.get('drivers') or result.get('insights', [])
            risks = result.get('risks') or result.get('potential_risks', [])
            questions = result.get('questions') or result.get('considerations', [])

            return {
                'success': True,
                'recommendation': result.get('recommended_option_index', 0),
                'confidence': result.get('confidence', 0.5),
                'summary': summary,
                'explanation': summary,
                'option_scores': result.get('option_scores', []),
                'drivers': drivers,
                'risks': risks,
                'questions': questions,
                'insights': drivers,
                'considerations': questions,
                'potential_risks': risks,
            }
            
        except Exception as e:
            logger.error(f"AI analysis error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'recommendation': None
            }
    
    def _build_analysis_prompt(self, data: Dict) -> str:
        """Build the analysis prompt from decision data"""
        title = data.get('title', 'Untitled Decision')
        description = data.get('description', '')
        category = data.get('category', 'General')
        
        prompt = f"""Analyze this decision and provide a data-driven recommendation:

DECISION: {title}
{f'CONTEXT: {description}' if description else ''}
CATEGORY: {category if category else 'General Life Decision'}

OPTIONS TO EVALUATE:
"""
        options = data.get('options', [])
        for i, option in enumerate(options):
            prompt += f"\n[Option {i}] {option.get('name', f'Option {i+1}')}"
            if option.get('description'):
                prompt += f"\n  Details: {option['description']}"
            if option.get('pros'):
                pros = option['pros'] if isinstance(option['pros'], list) else [option['pros']]
                prompt += f"\n  Stated Pros: {', '.join(pros)}"
            if option.get('cons'):
                cons = option['cons'] if isinstance(option['cons'], list) else [option['cons']]
                prompt += f"\n  Stated Cons: {', '.join(cons)}"
        
        factors = data.get('factors', [])
        if factors:
            prompt += "\n\nUSER'S PRIORITY FACTORS (higher weight = more important):\n"
            for factor in factors:
                weight = factor.get('weight', 0.5)
                weight_percent = int(weight * 100)
                importance = "Critical" if weight >= 0.8 else "High" if weight >= 0.6 else "Medium" if weight >= 0.4 else "Low"
                prompt += f"• {factor.get('name', 'Factor')}: {importance} priority ({weight_percent}% weight)\n"
        
        ratings = data.get('ratings', [])
        if ratings:
            prompt += "\nUSER'S RATINGS (how each option performs on each factor, scale 1-10):\n"
            # Group ratings by option
            option_ratings = {}
            for rating in ratings:
                opt_idx = rating.get('option_index', 0)
                if opt_idx not in option_ratings:
                    option_ratings[opt_idx] = []
                option_ratings[opt_idx].append(rating)
            
            for opt_idx, opt_ratings in option_ratings.items():
                opt_name = options[opt_idx].get('name', f'Option {opt_idx+1}') if opt_idx < len(options) else f'Option {opt_idx+1}'
                prompt += f"\n{opt_name}:\n"
                for r in opt_ratings:
                    score = r.get('score', 5)
                    quality = "Excellent" if score >= 9 else "Good" if score >= 7 else "Average" if score >= 5 else "Poor" if score >= 3 else "Very Poor"
                    prompt += f"  • {r.get('factor_name', 'Factor')}: {score}/10 ({quality})\n"
        
        prompt += """

ANALYSIS REQUIREMENTS:
1. Score each option from 0.0 to 1.0 based on the factors and their weights
2. Provide clear reasoning for scores referencing the specific factors
3. Recommend the option with the highest weighted score
4. Set confidence based on how clearly one option outperforms others
5. Provide practical insights the user may not have considered
6. Identify real risks and important considerations

Respond with JSON only."""
        
        return prompt

    def generate_factor_ratings(self, decision_data: Dict) -> Dict:
        """Generate a complete option x factor rating matrix."""
        if not self.is_available():
            return {
                'success': False,
                'error': 'AI service is not available',
                'ratings': []
            }

        try:
            options = decision_data.get('options', [])
            factors = decision_data.get('factors', [])
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": """You are a decision scoring assistant. Rate how each option performs against each factor on a 1-10 scale.

Rules:
- Return one rating for every option_index and factor_index combination.
- Use the full 1-10 range when justified.
- For pro factors, higher score means the option is better.
- For con factors, higher score means the option handles or minimizes the downside better.
- Do not return equal scores unless the options are genuinely equal.

You MUST respond ONLY with valid JSON:
{
  "ratings": [
    {"option_index": 0, "factor_index": 0, "score": 8, "reasoning": "short reason"}
  ]
}"""
                    },
                    {
                        "role": "user",
                        "content": f"""Decision: {decision_data.get('title', '')}
Description: {decision_data.get('description', '')}

Options:
{json.dumps(options)}

Factors:
{json.dumps(factors)}

Generate exactly {len(options) * len(factors)} ratings."""
                    }
                ],
                temperature=0.4,
                max_tokens=1500,
            )
            content = response.choices[0].message.content
            if '```json' in content:
                content = content.split('```json')[1].split('```')[0]
            elif '```' in content:
                content = content.split('```')[1].split('```')[0]
            result = json.loads(content.strip())

            normalized = []
            seen = set()
            for item in result.get('ratings', []):
                try:
                    option_index = int(item.get('option_index'))
                    factor_index = int(item.get('factor_index'))
                    score = float(item.get('score'))
                except (TypeError, ValueError):
                    continue
                if not (0 <= option_index < len(options)) or not (0 <= factor_index < len(factors)):
                    continue
                score = max(1.0, min(10.0, score))
                seen.add((option_index, factor_index))
                normalized.append({
                    'option_index': option_index,
                    'factor_index': factor_index,
                    'score': score,
                    'reasoning': item.get('reasoning', ''),
                })

            expected = len(options) * len(factors)
            if len(seen) != expected:
                return {
                    'success': False,
                    'error': f'AI generated incomplete ratings ({len(seen)}/{expected}).',
                    'ratings': normalized,
                }

            return {'success': True, 'ratings': normalized}
        except Exception as e:
            logger.error(f"AI generate ratings error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'ratings': []
            }

    def _parse_json_content(self, content: str) -> Dict:
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0]
        elif '```' in content:
            content = content.split('```')[1].split('```')[0]
        return json.loads(content.strip())

    def generate_ratings_and_analysis(self, decision_data: Dict) -> Dict:
        """Generate factor ratings and narrative analysis in a single AI call."""
        if not self.is_available():
            return {
                'success': False,
                'error': 'AI service is not available',
                'ratings': [],
            }

        try:
            options = decision_data.get('options', [])
            factors = decision_data.get('factors', [])
            expected = len(options) * len(factors)

            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": """You are a decision analyst. Rate each option against each factor (1-10) and recommend the best option.

Rules:
- Return one rating for every option_index x factor_index pair.
- For pro factors, higher score means better performance.
- For con factors, higher score means the option handles the downside better.
- Base recommendation on weighted factor performance.

Respond ONLY with valid JSON:
{
  "ratings": [{"option_index": 0, "factor_index": 0, "score": 8}],
  "recommended_option_index": 0,
  "confidence": 0.75,
  "explanation": "2-3 sentence recommendation",
  "insights": ["insight"],
  "considerations": ["consideration"],
  "potential_risks": ["risk"]
}"""
                    },
                    {
                        "role": "user",
                        "content": f"""Decision: {decision_data.get('title', '')}
Description: {decision_data.get('description', '')}

Options:
{json.dumps(options)}

Factors:
{json.dumps(factors)}

Generate exactly {expected} ratings plus recommendation."""
                    }
                ],
                temperature=0.4,
                max_tokens=1800,
            )

            result = self._parse_json_content(response.choices[0].message.content)
            normalized = []
            seen = set()
            for item in result.get('ratings', []):
                try:
                    option_index = int(item.get('option_index'))
                    factor_index = int(item.get('factor_index'))
                    score = float(item.get('score'))
                except (TypeError, ValueError):
                    continue
                if not (0 <= option_index < len(options)) or not (0 <= factor_index < len(factors)):
                    continue
                score = max(1.0, min(10.0, score))
                seen.add((option_index, factor_index))
                normalized.append({
                    'option_index': option_index,
                    'factor_index': factor_index,
                    'score': score,
                    'reasoning': item.get('reasoning', ''),
                })

            if len(seen) != expected:
                return {
                    'success': False,
                    'error': f'AI generated incomplete ratings ({len(seen)}/{expected}).',
                    'ratings': normalized,
                }

            summary = result.get('summary') or result.get('explanation', '')
            return {
                'success': True,
                'ratings': normalized,
                'recommendation': result.get('recommended_option_index', 0),
                'confidence': result.get('confidence', 0.5),
                'summary': summary,
                'explanation': summary,
                'drivers': result.get('drivers') or result.get('insights', []),
                'risks': result.get('risks') or result.get('potential_risks', []),
                'questions': result.get('questions') or result.get('considerations', []),
                'insights': result.get('insights', []),
                'considerations': result.get('considerations', []),
                'potential_risks': result.get('potential_risks', []),
            }
        except Exception as e:
            logger.error(f"AI combined ratings/analysis error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'ratings': [],
            }

    def generate_analysis_narrative(
        self,
        decision_data: Dict,
        winner_index: int,
        score_rows: List[Dict],
    ) -> Dict:
        """Generate recommendation narrative when scores are already computed locally."""
        if not self.is_available():
            return {
                'success': False,
                'error': 'AI service is not available',
                'recommendation': None,
            }

        try:
            options = decision_data.get('options', [])
            winner_name = options[winner_index].get('name', f'Option {winner_index + 1}') if winner_index < len(options) else 'Top option'
            score_summary = ', '.join(
                f"{row['option_name']}: {row['percentage']}%"
                for row in score_rows
            )

            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": """You explain a data-driven decision recommendation. Scores are already computed — do NOT recalculate them.

Respond ONLY with valid JSON:
{
  "explanation": "2-3 sentences referencing factors and trade-offs",
  "insights": ["insight"],
  "considerations": ["consideration"],
  "potential_risks": ["risk"]
}"""
                    },
                    {
                        "role": "user",
                        "content": f"""Decision: {decision_data.get('title', '')}
Recommended: {winner_name} (index {winner_index})
Computed scores: {score_summary}

Factors:
{json.dumps(decision_data.get('factors', []))}

Ratings:
{json.dumps(decision_data.get('ratings', []))}

Write a concise narrative for the user."""
                    }
                ],
                temperature=0.5,
                max_tokens=800,
            )

            result = self._parse_json_content(response.choices[0].message.content)
            summary = result.get('summary') or result.get('explanation', '')
            option_scores = [
                {
                    'index': idx,
                    'score': round(float(row['score']), 4),
                    'reasoning': '',
                }
                for idx, row in enumerate(score_rows)
            ]

            return {
                'success': True,
                'recommendation': winner_index,
                'confidence': min(0.95, 0.55 + (score_rows[0]['score'] - (score_rows[1]['score'] if len(score_rows) > 1 else 0)) * 2),
                'summary': summary,
                'explanation': summary,
                'drivers': result.get('drivers') or result.get('insights', []),
                'risks': result.get('risks') or result.get('potential_risks', []),
                'questions': result.get('questions') or result.get('considerations', []),
                'insights': result.get('insights', []),
                'considerations': result.get('considerations', []),
                'potential_risks': result.get('potential_risks', []),
                'option_scores': option_scores,
            }
        except Exception as e:
            logger.error(f"AI narrative error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'recommendation': None,
            }
    
    def suggest_factors(self, decision_data: Dict) -> Dict:
        """Suggest relevant factors for a decision"""
        if not self.is_available():
            return {
                'success': False,
                'error': 'AI service is not available',
                'factors': []
            }
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": """You are an expert decision analyst. Your job is to identify the most important factors for evaluating a decision.

For each factor you suggest:
- Make it specific and measurable when possible
- Explain why it matters for this specific decision
- Assign an appropriate weight (0.0-1.0) based on typical importance
- Mark type as "pro" for benefits/positive criteria or "con" for downsides/risks/costs

Weight guidelines:
- 0.8-1.0: Critical factors that could be deal-breakers
- 0.6-0.79: Very important factors
- 0.4-0.59: Moderately important factors  
- 0.2-0.39: Nice-to-have factors
- 0.0-0.19: Minor considerations

You MUST respond ONLY with valid JSON (no markdown):
{
    "factors": [
        {"name": "Factor Name", "description": "Why this matters for this decision", "type": "pro", "default_weight": 0.8}
    ]
}"""
                    },
                    {
                        "role": "user",
                        "content": f"""Suggest the most important factors to consider for this decision:

DECISION: {decision_data.get('title', '')}
CONTEXT: {decision_data.get('description', 'No additional context provided')}
CATEGORY: {decision_data.get('category', 'General')}
OPTIONS BEING CONSIDERED: {', '.join([o.get('name', '') for o in decision_data.get('options', [])]) or 'Not specified yet'}

Please suggest 5-7 highly relevant factors that will help differentiate between the options and lead to a well-informed decision."""
                    }
                ],
                temperature=0.7,
            )
            
            # Parse JSON from response
            content = response.choices[0].message.content
            if '```json' in content:
                content = content.split('```json')[1].split('```')[0]
            elif '```' in content:
                content = content.split('```')[1].split('```')[0]
            result = json.loads(content.strip())
            
            normalized_factors = []
            for factor in result.get('factors', []):
                factor_type = str(factor.get('type', 'pro')).lower()
                if factor_type not in ('pro', 'con'):
                    factor_type = 'pro'
                try:
                    default_weight = float(factor.get('default_weight', factor.get('suggested_weight', 0.5)))
                except (TypeError, ValueError):
                    default_weight = 0.5
                default_weight = max(0.0, min(1.0, default_weight))
                normalized_factors.append({
                    'name': factor.get('name', ''),
                    'description': factor.get('description', ''),
                    'type': factor_type,
                    'default_weight': default_weight,
                    'suggested_weight': default_weight,
                })

            return {
                'success': True,
                'factors': normalized_factors
            }
            
        except Exception as e:
            logger.error(f"AI suggest factors error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'factors': []
            }
    
    def generate_pros_cons(self, option_name: str, decision_context: str) -> Dict:
        """Generate pros and cons for an option"""
        if not self.is_available():
            return {
                'success': False,
                'error': 'AI service is not available',
                'pros': [],
                'cons': []
            }
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": """You are an expert at evaluating options objectively. Generate balanced, realistic pros and cons.

Guidelines:
- Be specific and practical, not generic
- Consider short-term and long-term implications
- Include financial, emotional, and practical aspects
- Be honest about downsides - don't sugarcoat
- Focus on what's most relevant to the decision context

You MUST respond ONLY with valid JSON:
{
    "pros": ["Specific advantage 1", "Specific advantage 2", "Specific advantage 3"],
    "cons": ["Specific drawback 1", "Specific drawback 2", "Specific drawback 3"]
}"""
                    },
                    {
                        "role": "user",
                        "content": f"""Generate realistic pros and cons for this option:

OPTION: {option_name}
DECISION CONTEXT: {decision_context}

Provide 3-5 specific, actionable pros and 3-5 honest cons."""
                    }
                ],
                temperature=0.7,
            )
            
            # Parse JSON from response
            content = response.choices[0].message.content
            if '```json' in content:
                content = content.split('```json')[1].split('```')[0]
            elif '```' in content:
                content = content.split('```')[1].split('```')[0]
            result = json.loads(content.strip())
            
            return {
                'success': True,
                'pros': result.get('pros', []),
                'cons': result.get('cons', [])
            }
            
        except Exception as e:
            logger.error(f"AI generate pros/cons error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'pros': [],
                'cons': []
            }
    
    def get_decision_insights(self, decision_data: Dict) -> Dict:
        """Get additional insights about a decision"""
        if not self.is_available():
            return {
                'success': False,
                'error': 'AI service is not available',
                'insights': []
            }
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": """You are a decision coach helping users think more deeply about their choices.

Your role is to:
- Identify blind spots and unconsidered factors
- Surface emotional influences on the decision
- Point out missing information that would help
- Ask questions that promote deeper reflection
- Be constructive but honest about potential issues

You MUST respond ONLY with valid JSON:
{
    "insights": [
        "Key observation about the decision that may not be obvious",
        "Another important pattern or consideration"
    ],
    "questions_to_consider": [
        "What would you choose if money wasn't a factor?",
        "How will you feel about this decision in 5 years?"
    ],
    "missing_information": [
        "Specific data or research that would help",
        "Information about alternatives"
    ],
    "emotional_factors": [
        "Emotional influence that may be affecting the decision",
        "Fear or desire that should be acknowledged"
    ]
}"""
                    },
                    {
                        "role": "user",
                        "content": f"""Provide deep insights for this decision:

DECISION: {decision_data.get('title', '')}
CONTEXT: {decision_data.get('description', 'Not provided')}
OPTIONS: {json.dumps([o.get('name', '') for o in decision_data.get('options', [])])}

Help me think about this more deeply and consider what I might be missing."""
                    }
                ],
                temperature=0.8,
            )
            
            # Parse JSON from response
            content = response.choices[0].message.content
            if '```json' in content:
                content = content.split('```json')[1].split('```')[0]
            elif '```' in content:
                content = content.split('```')[1].split('```')[0]
            result = json.loads(content.strip())
            
            return {
                'success': True,
                **result
            }
            
        except Exception as e:
            logger.error(f"AI insights error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'insights': []
            }
    
    def suggest_options(self, title: str, description: str = '') -> Dict:
        """Suggest relevant options for a decision based on the title"""
        if not self.is_available():
            return {
                'success': False,
                'error': 'AI service is not available',
                'options': []
            }
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": """You are an expert decision analyst. Your job is to suggest the most relevant and practical options for a decision.

When suggesting options:
- Make them specific and actionable
- Cover the realistic range of choices (don't just suggest extremes)
- Include both obvious and creative alternatives
- Consider the user's context from the decision title

You MUST respond ONLY with valid JSON (no markdown, no code blocks):
{
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "reasoning": "Brief explanation of why these options cover the decision space well"
}"""
                    },
                    {
                        "role": "user",
                        "content": f"""Suggest 4 relevant options for this decision:

DECISION: {title}
{f'CONTEXT: {description}' if description else ''}

Provide practical, real-world options that someone would actually consider for this decision."""
                    }
                ],
                temperature=0.7,
                max_tokens=500,
            )
            
            # Parse JSON from response
            content = response.choices[0].message.content
            if '```json' in content:
                content = content.split('```json')[1].split('```')[0]
            elif '```' in content:
                content = content.split('```')[1].split('```')[0]
            result = json.loads(content.strip())
            
            return {
                'success': True,
                'suggested_options': result.get('options', []),
                'reasoning': result.get('reasoning', '')
            }
            
        except Exception as e:
            logger.error(f"AI suggest options error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'options': []
            }


# Singleton instance
ai_service = AIDecisionService()
