# Sample Agent Structure

Complete example of a well-structured agent created using the 5-phase protocol.

## Example: USDA Agriculture Agent

This example shows the complete structure of a production-ready agent for US agriculture data.

## Directory Structure

```
usda-agriculture-agent/
├── .claude-plugin/
│   └── marketplace.json          # MANDATORY - Installation manifest
├── SKILL.md                       # Main skill documentation (6,200 words)
├── scripts/
│   ├── fetch_nass.py             # API client (280 lines)
│   ├── parse_conditions.py       # Parser for crop conditions (180 lines)
│   ├── parse_progress.py         # Parser for planting progress (165 lines)
│   ├── parse_yield.py            # Parser for yield data (170 lines)
│   ├── parse_production.py       # Parser for production data (175 lines)
│   ├── parse_area.py             # Parser for area data (168 lines)
│   ├── analyze_nass.py           # Analysis functions (520 lines)
│   └── utils/
│       ├── __init__.py
│       ├── helpers.py            # Temporal helpers (180 lines)
│       ├── cache_manager.py      # Caching system (120 lines)
│       ├── rate_limiter.py       # Rate limiting (110 lines)
│       └── validators/
│           ├── __init__.py
│           ├── parameter_validator.py    # Input validation (150 lines)
│           ├── data_validator.py         # Data validation (200 lines)
│           ├── temporal_validator.py     # Temporal checks (120 lines)
│           └── completeness_validator.py # Coverage checks (110 lines)
├── tests/
│   ├── __init__.py
│   ├── test_integration.py       # End-to-end tests (250 lines)
│   ├── test_parse.py             # Parser tests (180 lines)
│   ├── test_analyze.py           # Analysis tests (160 lines)
│   ├── test_helpers.py           # Helper tests (90 lines)
│   ├── test_validation.py        # Validator tests (150 lines)
│   └── conftest.py               # Pytest fixtures (40 lines)
├── references/
│   ├── nass-api-guide.md         # API documentation (1,500 words)
│   ├── analysis-methods.md       # Methodology reference (2,000 words)
│   ├── crop-commodities.md       # Domain knowledge (800 words)
│   └── troubleshooting.md        # Common issues (600 words)
├── assets/
│   ├── config.json               # Configuration template
│   └── metadata.json             # Commodity metadata
├── data/
│   ├── raw/                      # Raw API responses (cached)
│   ├── processed/                # Parsed data
│   ├── cache/                    # Cache files
│   └── analysis/                 # Analysis outputs
├── README.md                      # Quick start guide (1,000 words)
├── INSTALLATION.md                # Detailed tutorial (1,500 words)
├── DECISIONS.md                   # Architecture decisions (600 words)
├── VERSION                        # Current version (1.0.0)
└── CHANGELOG.md                   # Release notes (400 words)

Total:
- Python code: 2,868 lines
- Documentation: 8,400 words
- Tests: 870 lines (30% of code)
```

## File Contents

### .claude-plugin/marketplace.json

```json
{
  "name": "usda-agriculture-agent",
  "owner": {
    "name": "Agent Creator",
    "email": "noreply@example.com"
  },
  "metadata": {
    "description": "USDA agriculture data analysis",
    "version": "1.0.0",
    "created": "2025-01-20",
    "updated": "2025-01-20"
  },
  "plugins": [
    {
      "name": "usda-agriculture",
      "description": "Use when analyzing US agriculture data, crop production, planting progress, crop conditions, yield, or area. Triggers: 'USDA', 'NASS', 'crop', 'corn', 'soybeans', 'wheat', 'production', 'yield', 'planted', 'harvested'. Covers 120+ commodities across all US states with data since 1866.",
      "source": "./",
      "strict": false,
      "skills": ["./"]
    }
  ]
}
```

**Key points**:
- Description matches SKILL.md frontmatter EXACTLY
- skills points to `["./"]` (SKILL.md in root)
- source is `"./"`

### SKILL.md (Frontmatter)

```yaml
---
name: usda-agriculture
description: Use when analyzing US agriculture data, crop production, planting progress, crop conditions, yield, or area. Triggers: 'USDA', 'NASS', 'crop', 'corn', 'soybeans', 'wheat', 'production', 'yield', 'planted', 'harvested'. Covers 120+ commodities across all US states with data since 1866.
---
```

**Key points**:
- Description is IDENTICAL to marketplace.json
- Includes triggers for automatic activation
- Specifies coverage (120+ commodities, all states, since 1866)

### scripts/analyze_nass.py (Key Functions)

```python
#!/usr/bin/env python3
"""
Analysis functions for USDA NASS agriculture data.
"""

from typing import Dict, List, Optional, Any
import pandas as pd
from datetime import datetime

from utils.helpers import (
    get_current_nass_year,
    get_nass_year_with_fallback,
    format_year_message
)
from utils.validators.parameter_validator import validate_entity, validate_year
from utils.validators.data_validator import DataValidator
from utils.validators.temporal_validator import validate_temporal_consistency


def production_analysis(
    commodity: str,
    year: Optional[int] = None,
    state: Optional[str] = None
) -> Dict:
    """
    Analyze production data for commodity.

    Args:
        commodity: Commodity name (e.g., "CORN", "SOYBEANS")
        year: Year (None for auto-detection)
        state: State code (None for US total)

    Returns:
        Dict with production analysis and validation info
    """
    # Validate inputs
    commodity = validate_entity(commodity, VALID_COMMODITIES)
    year = validate_year(year) if year else None

    # Auto-detect year if needed
    year_requested = year
    if year is None:
        year, fallback = get_nass_year_with_fallback()

    # Fetch and parse data
    raw_data = fetch_production(commodity, year, state)

    # Validate response
    validator = DataValidator()
    response_validation = validator.validate_response(raw_data)
    if response_validation.has_critical_issues():
        raise DataQualityError(response_validation.get_summary())

    # Parse
    df = parse_production_response(raw_data)

    # Validate parsed data
    df_validation = validator.validate_dataframe(df, 'production')
    temporal_validation = validate_temporal_consistency(df)

    if df_validation.has_critical_issues():
        raise DataQualityError(df_validation.get_summary())

    # Perform analysis
    results = _analyze_production(df, commodity, year, state)

    # Return with metadata
    return {
        'commodity': commodity,
        'year': year,
        'year_requested': year_requested,
        'year_info': format_year_message(year, year_requested),
        'state': state or 'US',
        'data': results,
        'validation': {
            'passed': df_validation.all_passed(),
            'warnings': df_validation.get_warnings(),
            'summary': df_validation.get_summary()
        }
    }


def comprehensive_agriculture_report(
    commodity: str,
    year: Optional[int] = None,
    include_metrics: Optional[List[str]] = None
) -> Dict:
    """
    Generate comprehensive report combining ALL metrics.

    This all-in-one function fetches and combines:
    - Production data
    - Area (planted and harvested)
    - Yield
    - Crop conditions
    - Planting progress

    Args:
        commodity: Commodity to analyze
        year: Year (None for auto-detection)
        include_metrics: Specific metrics (None = all)

    Returns:
        Dict with all metrics consolidated, summary, and alerts
    """
    from datetime import datetime

    # Auto-detect year
    year_requested = year
    if year is None:
        year, _ = get_nass_year_with_fallback()

    # Initialize report
    report = {
        'commodity': commodity,
        'year': year,
        'year_requested': year_requested,
        'year_info': format_year_message(year, year_requested),
        'generated_at': datetime.now().isoformat(),
        'metrics': {},
        'alerts': []
    }

    # Determine metrics to fetch
    all_metrics = ['production', 'area', 'yield', 'conditions', 'progress']
    metrics_to_fetch = include_metrics if include_metrics else all_metrics

    # Fetch each metric with graceful degradation
    if 'production' in metrics_to_fetch:
        try:
            report['metrics']['production'] = production_analysis(commodity, year)
        except Exception as e:
            report['metrics']['production'] = {'error': str(e), 'status': 'unavailable'}
            report['alerts'].append(f"Production data unavailable: {e}")

    if 'area' in metrics_to_fetch:
        try:
            report['metrics']['area'] = area_analysis(commodity, year)
        except Exception as e:
            report['metrics']['area'] = {'error': str(e), 'status': 'unavailable'}

    # ... repeat for all metrics ...

    # Generate summary
    report['summary'] = _generate_summary(report['metrics'], commodity, year)

    # Detect alerts
    report['alerts'].extend(_detect_alerts(report['metrics']))

    return report


def _generate_summary(metrics: Dict, commodity: str, year: int) -> str:
    """Generate human-readable summary."""
    insights = []

    # Extract key insights from each metric
    for metric_name, metric_data in metrics.items():
        if 'error' not in metric_data and 'data' in metric_data:
            # Extract most important insight
            if metric_name == 'production' and 'total' in metric_data['data']:
                insights.append(f"Production: {metric_data['data']['total']:,.0f} bushels")

    # Combine
    if insights:
        summary = f"{commodity} {year}: " + ". ".join(insights[:3])
    else:
        summary = f"{commodity} {year}: No data available"

    return summary


def _detect_alerts(metrics: Dict) -> List[str]:
    """Detect significant findings."""
    alerts = []

    for metric_name, metric_data in metrics.items():
        if 'error' in metric_data:
            continue

        # Check for large changes
        if 'change_percent' in metric_data.get('data', {}):
            change = metric_data['data']['change_percent']
            if abs(change) > 15:
                alerts.append(f"Large {metric_name} change: {change:+.1f}%")

    return alerts
```

**Key features**:
- Complete validation at all layers
- Auto-year detection with fallback
- Comprehensive report function
- Graceful degradation
- Clear return structure with metadata

### tests/test_integration.py (Sample)

```python
#!/usr/bin/env python3
"""
Integration tests for USDA agriculture agent.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / 'scripts'))

from analyze_nass import (
    production_analysis,
    comprehensive_agriculture_report
)


def test_production_auto_year():
    """Test production analysis with auto-year detection."""
    print("\n✓ Testing production_analysis() with auto-year...")

    try:
        result = production_analysis('CORN')

        # Validations
        assert 'year' in result
        assert 'year_info' in result
        assert 'data' in result
        assert 'validation' in result
        assert result['year'] >= 2024

        print(f"  ✓ Auto-year: {result['year']}")
        print(f"  ✓ Year info: {result['year_info']}")
        print(f"  ✓ Validation: {result['validation']['summary']}")

        return True

    except Exception as e:
        print(f"  ✗ FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_comprehensive_report():
    """Test comprehensive report generation."""
    print("\n✓ Testing comprehensive_agriculture_report()...")

    try:
        result = comprehensive_agriculture_report('CORN')

        # Validations
        assert 'metrics' in result
        assert 'summary' in result
        assert 'alerts' in result
        assert isinstance(result['metrics'], dict)

        metrics_count = len(result['metrics'])
        print(f"  ✓ Metrics combined: {metrics_count}")
        print(f"  ✓ Summary: {result['summary'][:80]}...")
        print(f"  ✓ Alerts: {len(result['alerts'])}")

        return True

    except Exception as e:
        print(f"  ✗ FAILED: {e}")
        return False


def main():
    """Run integration tests."""
    print("=" * 70)
    print("INTEGRATION TESTS - USDA Agriculture Agent")
    print("=" * 70)

    tests = [
        ("Auto-year detection", test_production_auto_year),
        ("Comprehensive report", test_comprehensive_report),
    ]

    results = []
    for test_name, test_func in tests:
        passed = test_func()
        results.append((test_name, passed))

    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)

    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}: {test_name}")

    passed_count = sum(1 for _, p in results if p)
    total_count = len(results)

    print(f"\nResults: {passed_count}/{total_count} passed")

    return passed_count == total_count


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
```

### README.md (Structure)

```markdown
# USDA Agriculture Agent

Production-ready agent for analyzing US agriculture data via USDA NASS QuickStats API.

## Features

- 📊 Production data (120+ commodities)
- 🌾 Area (planted/harvested)
- 📈 Yield analysis
- 🌤️ Crop conditions
- ⏱️ Planting progress
- 🇺🇸 All US states
- 📅 Data since 1866

## Quick Start

### 1. Get API Key

Free registration: https://quickstats.nass.usda.gov/api#registration

### 2. Configure

```bash
export NASS_API_KEY="your_key_here"
```

### 3. Install

```bash
/plugin marketplace add ./usda-agriculture-agent
```

### 4. Use

```
"US corn production in 2024"
"Compare soybeans this year vs last year"
"Iowa wheat yield"
```

## Testing

### Run All Tests

```bash
cd usda-agriculture-agent
python3 tests/test_integration.py
```

### Expected Output

```
======================================================================
INTEGRATION TESTS - USDA Agriculture Agent
======================================================================

✓ Testing production_analysis() with auto-year...
  ✓ Auto-year: 2025
  ✓ Year info: Using 2025 data (current year auto-detected)
  ✓ Validation: Validation: 8/8 passed (0 critical issues)

✓ Testing comprehensive_agriculture_report()...
  ✓ Metrics combined: 5
  ✓ Summary: CORN 2025: Production: 15,100,000,000 bushels. Area: 91,500,000 ac...
  ✓ Alerts: 0

======================================================================
SUMMARY
======================================================================
✅ PASS: Auto-year detection
✅ PASS: Comprehensive report

Results: 2/2 passed
```

## Documentation

- `INSTALLATION.md` - Detailed setup guide
- `references/nass-api-guide.md` - API documentation
- `references/analysis-methods.md` - Methodology reference
- `DECISIONS.md` - Architecture decisions

## Support

Issues? See `references/troubleshooting.md`
```

### DECISIONS.md (Sample)

```markdown
# Architecture Decisions

## Date: 2025-01-20

## Context

User needs: Daily analysis of US crop data including production, area, yield,
comparing current year vs previous, state rankings.

Domain: US Agriculture

## APIs Considered

### Option 1: USDA NASS QuickStats API
- Provider: USDA (US Government)
- Coverage: 120+ commodities, all states, 1866-present
- Cost: Free (API key required)
- Pros: Official data, comprehensive, free, excellent coverage
- Cons: Rate limit (10,000/day), learning curve
- Score: 9.0/10

### Option 2: FAO API
- Provider: UN Food and Agriculture Organization
- Coverage: Global, but US data less detailed
- Cost: Free
- Pros: Global coverage, free
- Cons: Less detail for US states, slower updates
- Score: 6.5/10

### Option 3: World Bank Agriculture API
- Provider: World Bank
- Coverage: Country-level only
- Cost: Free
- Pros: Free, reliable
- Cons: No state-level data, limited commodities
- Score: 5.0/10

## Decision

**Selected API: USDA NASS QuickStats API**

### Justification

NASS was selected because:

1. **Coverage**: Complete US state-level data for 120+ commodities
2. **History**: Data since 1866 enables long-term trend analysis
3. **Official**: Direct from USDA, highest data quality
4. **Cost**: Free with generous rate limit (10,000/day)
5. **Updates**: Current year data available during season

### Trade-offs Accepted

- Rate limit: 10,000/day sufficient for most use cases
- US only: Not global, but matches user's requirement
- Complexity: API has learning curve, mitigated by good docs

## Architectural Decisions

### Modular Parsers (5 parsers instead of 1 generic)

**Decision**: Create separate parser for each data type
- parse_production.py
- parse_area.py
- parse_yield.py
- parse_conditions.py
- parse_progress.py

**Rationale**:
- Each data type has unique structure
- Scalable (easy to add new types)
- Testable (isolated tests)
- Maintainable (clear responsibilities)

### Complete Validation System

**Decision**: Implement 4-layer validation
- parameter_validator.py
- data_validator.py
- temporal_validator.py
- completeness_validator.py

**Rationale**:
- Data quality is critical for agriculture decisions
- Clear error messages save debugging time
- User confidence in results
- Production-ready from v1.0

### Comprehensive Report Function

**Decision**: Include comprehensive_agriculture_report()

**Rationale**:
- Users want "everything" in one query
- Combines all 5 metrics
- Graceful degradation (if 1 fails, others work)
- Better UX (don't need to know individual functions)

## Conclusion

NASS QuickStats provides optimal balance of coverage, quality, and cost
for US agriculture analysis. Modular architecture enables scalability
and maintainability.
```

## Metrics

**Code statistics**:
- Total lines: 2,868
- Scripts: 1,998 lines (70%)
- Tests: 870 lines (30%)
- Test coverage: 30% (meets minimum 25%)

**Documentation**:
- Total words: 8,400
- SKILL.md: 6,200 words
- References: 4,900 words
- README + INSTALLATION: 2,500 words

**Completeness**:
- ✅ marketplace.json (validated)
- ✅ SKILL.md with description sync
- ✅ Modular parsers (5 parsers)
- ✅ Validation system (4 validators)
- ✅ Temporal helpers
- ✅ Comprehensive report function
- ✅ Test suite (25+ tests, all passing)
- ✅ VERSION + CHANGELOG
- ✅ Complete documentation

## Installation Verification

```bash
# 1. Create agent (automated via agent-creator)
# 2. Validate marketplace.json
python3 -c "import json; json.load(open('usda-agriculture-agent/.claude-plugin/marketplace.json')); print('✅ Valid JSON')"

# 3. Test installation
/plugin marketplace add ./usda-agriculture-agent

# Expected output:
# ✅ Plugin installed: usda-agriculture
# ✅ Skills activated: 1

# 4. Test activation
# Query: "US corn production 2024"
# Expected: Agent activates automatically
```

## Summary

This sample demonstrates:

1. **Complete structure** - All mandatory files and directories
2. **Quality code** - Modular, validated, tested
3. **Professional docs** - Comprehensive and useful
4. **Production-ready** - Tests pass, installs cleanly
5. **User-friendly** - Clear examples, good UX

**Time to create**: ~60-90 minutes using agent-creator protocol
**Quality level**: Production-ready from v1.0
**Maintenance**: Easy due to modular architecture
