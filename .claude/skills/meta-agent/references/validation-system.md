# Validation System

Complete guide to implementing data validation in agents.

## Overview

A robust validation system ensures data quality and reliability at multiple layers:

1. **Parameter validation** - Validate user inputs before API calls
2. **Response validation** - Validate API responses
3. **Data validation** - Validate parsed DataFrames
4. **Temporal validation** - Validate time-based consistency
5. **Completeness validation** - Validate data coverage

## Why Validation Is Mandatory

**Without validation**:
- ❌ Silent failures (bad data passes through)
- ❌ Cryptic errors (fails deep in execution)
- ❌ User doesn't trust data
- ❌ Debugging is nightmare

**With validation**:
- ✅ Clear error messages
- ✅ Early failure detection
- ✅ Data quality transparency
- ✅ User confidence in results

## Validation Architecture

### Four-Layer Validation

```
Layer 1: PARAMETER VALIDATION (before API call)
├─ Validate entity names
├─ Validate year ranges
├─ Validate geographic parameters
└─ Normalize inputs

Layer 2: RESPONSE VALIDATION (after API call)
├─ Validate response structure
├─ Check for error codes
├─ Validate data presence
└─ Check response types

Layer 3: DATA VALIDATION (after parsing)
├─ Validate DataFrame schema
├─ Check required columns
├─ Validate data types
└─ Check for excessive NaN values

Layer 4: TEMPORAL/COMPLETENESS VALIDATION
├─ Validate temporal consistency
├─ Check for future dates
├─ Validate data freshness
└─ Validate coverage percentage
```

## Implementation Guide

### Step 1: Create Validation Infrastructure

Create `utils/validators/` directory:

```bash
mkdir -p scripts/utils/validators
touch scripts/utils/validators/__init__.py
touch scripts/utils/validators/parameter_validator.py
touch scripts/utils/validators/data_validator.py
touch scripts/utils/validators/temporal_validator.py
touch scripts/utils/validators/completeness_validator.py
```

### Step 2: Implement Core Classes

**ValidationResult class** - Represents single validation check:

```python
@dataclass
class ValidationResult:
    check_name: str           # Name of check (e.g., "not_empty")
    level: ValidationLevel    # CRITICAL, WARNING, or INFO
    passed: bool             # Did check pass?
    message: str             # Human-readable message
    details: Optional[Dict]  # Additional context
```

**ValidationReport class** - Collection of results:

```python
class ValidationReport:
    def __init__(self):
        self.results: List[ValidationResult] = []

    def add(self, result: ValidationResult):
        """Add a validation result"""

    def has_critical_issues(self) -> bool:
        """Check if any critical issues found"""

    def all_passed(self) -> bool:
        """Check if all validations passed"""

    def get_warnings(self) -> List[str]:
        """Get all warning messages"""

    def get_summary(self) -> str:
        """Get summary like 'Validation: 8/10 passed (1 critical issues)'"""
```

### Step 3: Implement Validators

See `references/python-templates.md` for complete implementations of:
- `parameter_validator.py`
- `data_validator.py`
- `temporal_validator.py`
- `completeness_validator.py`

### Step 4: Integrate in Analysis Functions

Every analysis function should follow this pattern:

```python
def {analysis_function}(entity: str, year: Optional[int] = None) -> Dict:
    """
    Analysis function with complete validation.

    Validates at every layer:
    1. Parameters before API call
    2. API response
    3. Parsed DataFrame
    4. Temporal consistency
    """
    from utils.validators.parameter_validator import validate_entity, validate_year
    from utils.validators.data_validator import DataValidator
    from utils.validators.temporal_validator import validate_temporal_consistency

    # LAYER 1: VALIDATE INPUTS
    entity = validate_entity(entity, valid_entities=VALID_ENTITIES)
    year = validate_year(year, min_year=1900, allow_future=False)

    # Fetch data
    raw_data = fetch_{metric}(entity, year)

    # LAYER 2: VALIDATE API RESPONSE
    validator = DataValidator()
    response_validation = validator.validate_response(raw_data)

    if response_validation.has_critical_issues():
        raise DataQualityError(
            f"API response validation failed: {response_validation.get_summary()}"
        )

    # Parse data
    df = parse_{type}(raw_data)

    # LAYER 3: VALIDATE PARSED DATA
    df_validation = validator.validate_dataframe(df, data_type='{type}')

    # LAYER 4: VALIDATE TEMPORAL CONSISTENCY
    temporal_validation = validate_temporal_consistency(df)

    # Check for critical issues
    if df_validation.has_critical_issues():
        raise DataQualityError(
            f"Data validation failed: {df_validation.get_summary()}"
        )

    # Warnings are logged but don't block
    warnings = df_validation.get_warnings() + temporal_validation.get_warnings()
    if warnings:
        logger.warning(f"Data quality warnings: {warnings}")

    # Perform analysis
    results = _analyze(df)

    # Return with validation metadata
    return {
        'data': results,
        'year': year,
        'validation': {
            'passed': df_validation.all_passed() and temporal_validation.all_passed(),
            'warnings': warnings,
            'summary': df_validation.get_summary()
        }
    }
```

## Validation Levels

Use appropriate levels for different checks:

### CRITICAL (must pass)
- Required data is present
- Data types are correct
- Required columns exist
- No future dates (when not allowed)
- Valid parameter ranges

**Action**: Raise exception if fails

### WARNING (should review)
- Excessive NaN values (>30%)
- Data is stale (>2 years old)
- Missing optional entities
- Large gaps in time series

**Action**: Log warning, continue execution

### INFO (informational)
- Coverage percentage
- Data freshness notes
- Optimization suggestions

**Action**: Include in response metadata

## Validation Patterns by Domain

### Time-Series Data

```python
def validate_timeseries(df: pd.DataFrame) -> ValidationReport:
    """Validate time-series specific requirements."""
    report = ValidationReport()

    # Check 1: Chronological order
    years = df['year'].tolist()
    is_sorted = years == sorted(years)
    report.add(ValidationResult(
        check_name="chronological_order",
        level=ValidationLevel.WARNING,
        passed=is_sorted,
        message="Data is chronologically ordered" if is_sorted else "Data not sorted by year"
    ))

    # Check 2: Consistent frequency
    if len(years) > 2:
        year_diffs = [years[i+1] - years[i] for i in range(len(years)-1)]
        is_consistent = len(set(year_diffs)) == 1
        report.add(ValidationResult(
            check_name="consistent_frequency",
            level=ValidationLevel.WARNING,
            passed=is_consistent,
            message=f"Frequency: {year_diffs[0]} years" if is_consistent else f"Inconsistent gaps: {set(year_diffs)}"
        ))

    return report
```

### Geographic Data

```python
def validate_geographic_coverage(
    df: pd.DataFrame,
    expected_regions: List[str]
) -> ValidationReport:
    """Validate geographic coverage."""
    report = ValidationReport()

    actual_regions = set(df['region'].unique())
    expected_set = set(expected_regions)

    # Check completeness
    missing = expected_set - actual_regions
    extra = actual_regions - expected_set

    report.add(ValidationResult(
        check_name="all_regions_present",
        level=ValidationLevel.WARNING,
        passed=len(missing) == 0,
        message=f"Missing regions: {missing}" if missing else "All regions present"
    ))

    if extra:
        report.add(ValidationResult(
            check_name="unexpected_regions",
            level=ValidationLevel.INFO,
            passed=True,
            message=f"Extra regions found: {extra}"
        ))

    return report
```

### Numeric Data

```python
def validate_numeric_ranges(
    df: pd.DataFrame,
    column: str,
    min_value: Optional[float] = None,
    max_value: Optional[float] = None
) -> ValidationReport:
    """Validate numeric values are in expected range."""
    report = ValidationReport()

    values = df[column].dropna()

    if min_value is not None:
        below_min = (values < min_value).sum()
        report.add(ValidationResult(
            check_name=f"{column}_min_value",
            level=ValidationLevel.WARNING,
            passed=below_min == 0,
            message=f"{below_min} values below minimum {min_value}"
        ))

    if max_value is not None:
        above_max = (values > max_value).sum()
        report.add(ValidationResult(
            check_name=f"{column}_max_value",
            level=ValidationLevel.WARNING,
            passed=above_max == 0,
            message=f"{above_max} values above maximum {max_value}"
        ))

    # Check for outliers (simple approach: 3 standard deviations)
    mean = values.mean()
    std = values.std()
    outliers = ((values < mean - 3*std) | (values > mean + 3*std)).sum()

    report.add(ValidationResult(
        check_name=f"{column}_outliers",
        level=ValidationLevel.INFO,
        passed=outliers < len(values) * 0.05,  # <5% outliers is OK
        message=f"Outliers: {outliers} ({outliers/len(values)*100:.1f}%)"
    ))

    return report
```

## Testing Validation System

Create `tests/test_validation.py`:

```python
#!/usr/bin/env python3
"""Tests for validation system."""

import sys
from pathlib import Path
import pandas as pd

sys.path.insert(0, str(Path(__file__).parent.parent / 'scripts'))

from utils.validators.parameter_validator import validate_entity, validate_year, ValidationError
from utils.validators.data_validator import DataValidator, ValidationLevel
from utils.validators.temporal_validator import validate_temporal_consistency


def test_validate_entity_valid():
    """Test entity validation with valid input."""
    result = validate_entity("corn", ["CORN", "SOYBEANS"])
    assert result == "CORN", "Should normalize to uppercase"
    print("✓ Entity validation: valid case")


def test_validate_entity_invalid():
    """Test entity validation with invalid input."""
    try:
        validate_entity("WHEAT", ["CORN", "SOYBEANS"])
        assert False, "Should raise ValidationError"
    except ValidationError as e:
        assert "Invalid entity" in str(e)
        print("✓ Entity validation: invalid case")


def test_validate_year_current():
    """Test year validation with None (current year)."""
    from datetime import datetime
    year = validate_year(None)
    assert year == datetime.now().year
    print("✓ Year validation: current year")


def test_validate_year_future():
    """Test year validation rejects future years."""
    try:
        validate_year(2099, allow_future=False)
        assert False, "Should reject future year"
    except ValidationError as e:
        assert "future" in str(e).lower()
        print("✓ Year validation: future year rejected")


def test_dataframe_validation():
    """Test DataFrame validation."""
    validator = DataValidator()

    # Valid DataFrame
    df = pd.DataFrame({
        'entity': ['CORN', 'SOYBEANS'],
        'year': [2024, 2024],
        'value': [100.0, 200.0]
    })

    report = validator.validate_dataframe(df, 'test')
    assert report.all_passed() or not report.has_critical_issues()
    print(f"✓ DataFrame validation: {report.get_summary()}")


def test_temporal_validation():
    """Test temporal consistency validation."""
    df = pd.DataFrame({
        'entity': ['CORN'] * 3,
        'year': [2022, 2023, 2024],
        'value': [100.0, 110.0, 120.0]
    })

    report = validate_temporal_consistency(df)
    assert not report.has_critical_issues()
    print(f"✓ Temporal validation: {report.get_summary()}")


def main():
    """Run all validation tests."""
    print("=" * 70)
    print("VALIDATION SYSTEM TESTS")
    print("=" * 70)

    tests = [
        test_validate_entity_valid,
        test_validate_entity_invalid,
        test_validate_year_current,
        test_validate_year_future,
        test_dataframe_validation,
        test_temporal_validation,
    ]

    passed = 0
    for test in tests:
        try:
            test()
            passed += 1
        except Exception as e:
            print(f"✗ {test.__name__}: {e}")

    print(f"\n{passed}/{len(tests)} tests passed")
    return passed == len(tests)


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
```

## Best Practices

### 1. Fail Fast
Validate early in the pipeline. Better to fail before expensive API calls.

### 2. Clear Messages
Every validation should have a clear, actionable message:
- ❌ "Validation failed"
- ✅ "Missing required column 'year' in DataFrame"

### 3. Appropriate Levels
- Use CRITICAL for data integrity issues
- Use WARNING for quality concerns
- Use INFO for informational notices

### 4. Include Context
Use `details` dict for additional context:

```python
ValidationResult(
    check_name="missing_entities",
    level=ValidationLevel.WARNING,
    passed=False,
    message="Some entities missing",
    details={
        'expected': ['CORN', 'SOYBEANS', 'WHEAT'],
        'found': ['CORN', 'SOYBEANS'],
        'missing': ['WHEAT']
    }
)
```

### 5. Return Metadata
Always include validation info in response:

```python
return {
    'data': analysis_results,
    'validation': {
        'passed': report.all_passed(),
        'warnings': report.get_warnings(),
        'summary': report.get_summary(),
        'details': [
            {
                'check': r.check_name,
                'level': r.level.value,
                'passed': r.passed,
                'message': r.message
            }
            for r in report.results
        ]
    }
}
```

### 6. Graceful Degradation
For comprehensive reports, continue if one metric fails:

```python
for metric_name in metrics_to_fetch:
    try:
        report['metrics'][metric_name] = fetch_metric(metric_name)
    except Exception as e:
        report['metrics'][metric_name] = {
            'error': str(e),
            'status': 'unavailable'
        }
        report['alerts'].append(f"{metric_name} unavailable: {e}")
```

## Common Validation Patterns

### Pattern 1: Required Field Validation

```python
required_fields = ['entity', 'year', 'value']
for field in required_fields:
    report.add(ValidationResult(
        check_name=f"has_{field}",
        level=ValidationLevel.CRITICAL,
        passed=field in df.columns,
        message=f"Required field '{field}' {'present' if field in df.columns else 'MISSING'}"
    ))
```

### Pattern 2: Data Type Validation

```python
expected_types = {
    'entity': 'object',
    'year': 'int64',
    'value': 'float64'
}

for column, expected_type in expected_types.items():
    if column in df.columns:
        actual_type = str(df[column].dtype)
        report.add(ValidationResult(
            check_name=f"{column}_type",
            level=ValidationLevel.CRITICAL,
            passed=actual_type == expected_type,
            message=f"'{column}' type: {actual_type} (expected: {expected_type})"
        ))
```

### Pattern 3: Completeness Check

```python
null_threshold = 0.3  # 30% threshold

for column in df.columns:
    null_pct = df[column].isna().sum() / len(df)
    report.add(ValidationResult(
        check_name=f"{column}_completeness",
        level=ValidationLevel.WARNING if null_pct > null_threshold else ValidationLevel.INFO,
        passed=null_pct <= null_threshold,
        message=f"'{column}' completeness: {(1-null_pct)*100:.1f}%"
    ))
```

## Summary

A complete validation system:

1. **Validates at 4 layers** - Parameters, responses, parsed data, consistency
2. **Provides clear feedback** - Detailed messages with context
3. **Uses appropriate levels** - CRITICAL, WARNING, INFO
4. **Includes metadata** - Returns validation info with results
5. **Enables debugging** - Clear error messages point to root cause
6. **Builds trust** - Users see data quality reports

**Impact**:
- ✅ Reliable data (validated at multiple layers)
- ✅ Transparency (user sees validation report)
- ✅ Clear error messages (not just "generic error")
- ✅ Problem detection (gaps, nulls, inconsistencies)
- ✅ User confidence in results
