# API Discovery Patterns

Complete methodology for researching and selecting APIs during Phase 1.

## Overview

Phase 1 (Discovery) is critical because choosing the wrong API means starting over. This guide provides systematic patterns for API research and selection.

## Discovery Process

```
Step 1: Identify Domain
└─ Extract from user's description

Step 2: Research Available APIs
├─ Use WebSearch to find options
├─ Use WebFetch to load documentation
└─ Collect 3-5 candidate APIs

Step 3: Compare Options
├─ Create comparison matrix
├─ Score each option
└─ Identify best fit

Step 4: DECIDE and Justify
├─ Select one API
├─ Document reasoning
└─ Record in DECISIONS.md

Step 5: Research Technical Details
├─ Base URL and endpoints
├─ Authentication method
├─ Request/response format
├─ Rate limits
└─ Example requests

Step 6: Analyze API Completeness
├─ List all available metrics
├─ Calculate coverage percentage
└─ Ensure ≥50% coverage
```

## Step 1: Identify Domain

Extract domain from user's description:

**Common domains**:
- Agriculture (crops, livestock, production)
- Finance (stocks, bonds, commodities)
- Weather (forecasts, historical, climate)
- Economy (GDP, inflation, employment)
- Healthcare (diseases, treatments, statistics)
- Energy (prices, production, consumption)
- Transportation (traffic, routes, schedules)
- Real Estate (prices, inventory, sales)

**Pattern recognition**:
- User mentions "corn, soybeans" → Agriculture
- User mentions "stocks, bonds" → Finance
- User mentions "temperature, precipitation" → Weather
- User mentions "GDP, inflation" → Economy

## Step 2: Research Available APIs

### WebSearch Strategy

Use multiple search queries to find comprehensive options:

```python
# Primary search
query1 = f"{domain} API free data"

# Specific searches
query2 = f"{domain} official API documentation"
query3 = f"{domain} government API open data"
query4 = f"best {domain} API for developers"

# Examples:
# "agriculture API free data"
# "USDA API official documentation"
# "agriculture government API open data"
# "best agriculture API for developers"
```

### Information to Collect

For each API found, collect:

**Basic info**:
- API name
- Provider (government, private, open source)
- Official documentation URL
- Registration/signup URL (if required)

**Key characteristics**:
- Cost (free, freemium, paid)
- Authentication (API key, OAuth, none)
- Rate limits (requests/minute or day)
- Data coverage (geographic, temporal)
- Data freshness (real-time, daily, monthly)
- Documentation quality (excellent, good, poor)

### WebFetch Strategy

Once you have candidate APIs, use WebFetch to load documentation:

```python
# Fetch main documentation page
url1 = "https://api-provider.com/docs"

# Fetch API reference
url2 = "https://api-provider.com/docs/api-reference"

# Fetch getting started guide
url3 = "https://api-provider.com/docs/getting-started"

# Extract:
# - Base URL
# - Main endpoints
# - Authentication details
# - Example requests/responses
# - Rate limits
```

## Step 3: Compare Options

Create a comparison matrix with these criteria:

### Comparison Criteria

**1. Data Coverage (40% weight)**
- Does it have the metrics user needs?
- Geographic coverage (US? Global? Specific regions?)
- Temporal coverage (how far back? how current?)
- Score: 0-10

**2. Cost (25% weight)**
- Free: 10 points
- Freemium (free tier sufficient): 8 points
- Freemium (needs paid tier): 5 points
- Paid only: 2 points

**3. Ease of Use (20% weight)**
- Simple REST API: 10 points
- REST with complex auth: 7 points
- SOAP or complex protocol: 4 points
- Difficult to use: 2 points

**4. Documentation Quality (10% weight)**
- Excellent (examples, guides, reference): 10 points
- Good (clear reference): 7 points
- Basic (minimal docs): 4 points
- Poor (no docs): 1 point

**5. Reliability (5% weight)**
- Official government/institution: 10 points
- Established private company: 8 points
- Community/open source (active): 6 points
- Unknown/new: 3 points

### Comparison Matrix Template

```markdown
| API Name | Provider | Coverage | Cost | Ease | Docs | Reliability | Score |
|----------|----------|----------|------|------|------|-------------|-------|
| API A    | Gov      | 9/10     | 10   | 9    | 8    | 10          | 9.3   |
| API B    | Private  | 7/10     | 8    | 7    | 7    | 8           | 7.5   |
| API C    | OSS      | 6/10     | 10   | 5    | 4    | 6           | 6.6   |

Weights: Coverage 40%, Cost 25%, Ease 20%, Docs 10%, Reliability 5%

Final Scores:
- API A: 9×0.4 + 10×0.25 + 9×0.2 + 8×0.1 + 10×0.05 = 9.0
- API B: 7×0.4 + 8×0.25 + 7×0.2 + 7×0.1 + 8×0.05 = 7.3
- API C: 6×0.4 + 10×0.25 + 5×0.2 + 4×0.1 + 6×0.05 = 6.5
```

## Step 4: DECIDE and Justify

Select the API with highest score and document decision:

### DECISIONS.md Template

```markdown
# Architecture Decisions

## Date: {current_date}

## Context

User needs: {summarize user's workflow/objective}

Domain identified: {domain}

## APIs Considered

### Option 1: {API_NAME_1}
- Provider: {provider}
- Coverage: {coverage details}
- Cost: {cost structure}
- Pros: {list advantages}
- Cons: {list disadvantages}
- Score: {score}

### Option 2: {API_NAME_2}
- Provider: {provider}
- Coverage: {coverage details}
- Cost: {cost structure}
- Pros: {list advantages}
- Cons: {list disadvantages}
- Score: {score}

### Option 3: {API_NAME_3}
- Provider: {provider}
- Coverage: {coverage details}
- Cost: {cost structure}
- Pros: {list advantages}
- Cons: {list disadvantages}
- Score: {score}

## Decision

**Selected API: {CHOSEN_API}**

### Justification

{Chosen API} was selected because:

1. **Coverage**: {explain how it meets user's needs}
2. **Cost**: {explain cost advantage}
3. **Quality**: {explain data quality}
4. **Reliability**: {explain reliability factors}
5. **Ease of Use**: {explain why it's easy to integrate}

### Trade-offs Accepted

- {Trade-off 1}: {explanation}
- {Trade-off 2}: {explanation}

## Conclusion

{Chosen API} provides the best balance of coverage, cost, and ease of use
for this use case. The {score} score reflects its strong fit with user requirements.
```

## Step 5: Research Technical Details

Once API is selected, extract detailed technical information:

### Information to Extract

**Base URL and Endpoints**:
```
Base URL: https://api.example.com/v1

Main endpoints:
- GET /data/{metric} - Fetch metric data
- GET /entities - List available entities
- GET /metadata - Get metadata
```

**Authentication**:
```
Method: API key in header
Header name: X-API-Key
Registration: https://api.example.com/signup
Free tier: 10,000 requests/day
```

**Request Format**:
```
GET /data/production?entity=CORN&year=2024

Required parameters:
- entity: string (entity identifier)
- year: integer (4-digit year)

Optional parameters:
- state: string (state code)
- aggregation: string (national|state|county)
```

**Response Format**:
```json
{
  "metadata": {
    "entity": "CORN",
    "year": 2024,
    "unit": "BUSHELS"
  },
  "data": [
    {
      "state": "IOWA",
      "value": "2,500,000,000",
      "percentage": "17.5"
    }
  ]
}
```

**Rate Limits**:
```
Free tier: 10,000 requests/day
Paid tier: 100,000 requests/day
Rate limit headers:
- X-RateLimit-Limit: 10000
- X-RateLimit-Remaining: 9875
- X-RateLimit-Reset: 1640995200
```

**Error Codes**:
```
200: Success
400: Bad request (invalid parameters)
401: Unauthorized (invalid API key)
404: Not found (entity doesn't exist)
429: Rate limit exceeded
500: Internal server error
```

## Step 6: Analyze API Completeness

Calculate what percentage of user needs the API can satisfy.

### Completeness Analysis

**1. List user's required metrics**:
From user's description, extract what they want to analyze:
- Production
- Area
- Yield
- Prices
- Exports
- (etc.)

**2. List API's available metrics**:
From API documentation, list all available metrics:
- Production ✅
- Area ✅
- Yield ✅
- Prices ❌ (not available)
- Exports ❌ (not available)

**3. Calculate coverage**:
```
Coverage = (Available metrics / Required metrics) × 100
Coverage = (3 / 5) × 100 = 60%
```

**4. Verify coverage threshold**:
- ✅ Coverage ≥ 50%: Acceptable (can create useful agent)
- ❌ Coverage < 50%: Need to find different API or adjust scope

**5. Document in DECISIONS.md**:
```markdown
## API Completeness Analysis

### User Requirements
1. Production data ✅ (available)
2. Area data ✅ (available)
3. Yield data ✅ (available)
4. Price data ❌ (not available in this API)
5. Export data ❌ (not available in this API)

### Coverage
- Available: 3/5 metrics (60%)
- Status: ✅ Acceptable (≥50%)

### Implications
- Agent can fulfill 60% of user's needs
- For prices and exports, will document as "not available"
- Consider future v2.0 with additional API for missing metrics
```

## Domain-Specific Patterns

### Agriculture APIs

**Common sources**:
- USDA NASS (US): Crops, livestock, production
- FAO (Global): Agriculture statistics
- World Bank Ag: Agricultural indicators
- ERS USDA: Economic research data

**Key metrics**:
- Production (quantity produced)
- Area (acres planted/harvested)
- Yield (production per acre)
- Prices (farm gate, wholesale)
- Trade (exports, imports)

### Finance APIs

**Common sources**:
- Alpha Vantage: Stock prices, indicators
- Yahoo Finance: Stock data, news
- IEX Cloud: Real-time stock data
- FRED API: Economic indicators

**Key metrics**:
- Prices (open, high, low, close)
- Volume (shares traded)
- Technical indicators (RSI, MACD)
- Fundamentals (P/E, market cap)
- Earnings (EPS, revenue)

### Weather APIs

**Common sources**:
- NOAA API: US weather data
- OpenWeather: Global weather
- Weather.gov: US forecasts
- Weatherstack: Weather API

**Key metrics**:
- Temperature (current, forecast)
- Precipitation (rain, snow)
- Wind (speed, direction)
- Humidity
- Pressure

### Economy APIs

**Common sources**:
- FRED API: US economic data
- World Bank API: Global indicators
- IMF API: International data
- BLS API: Labor statistics

**Key metrics**:
- GDP (growth, per capita)
- Inflation (CPI, PPI)
- Employment (unemployment rate)
- Trade (balance, exports, imports)
- Interest rates

## Common Pitfalls

### Pitfall 1: Choosing Based Only on Documentation Quality

❌ **Wrong**: "This API has excellent docs, let's use it"
✅ **Right**: "This API covers 80% of user needs AND has good docs"

**Why**: Documentation quality is only 10% of decision. Coverage is 40%.

### Pitfall 2: Not Verifying Data Availability

❌ **Wrong**: "API docs say they have data for 1866-present"
✅ **Right**: "Tested API with current year, confirmed data is available"

**Why**: Docs can be outdated. Always verify with test requests.

### Pitfall 3: Ignoring Rate Limits

❌ **Wrong**: "Free tier is 100 requests/day, should be enough"
✅ **Right**: "User needs 50 states × 5 metrics = 250 requests. Need paid tier."

**Why**: Underestimating requests leads to non-functional agent.

### Pitfall 4: Not Analyzing Completeness

❌ **Wrong**: "API has some relevant data, good enough"
✅ **Right**: "API covers 3/5 required metrics (60%), acceptable for v1.0"

**Why**: Without completeness analysis, user expectations won't be met.

### Pitfall 5: Choosing Most Popular Instead of Best Fit

❌ **Wrong**: "Everyone uses Alpha Vantage, so we should too"
✅ **Right**: "For this use case, FRED has better coverage (80% vs 40%)"

**Why**: Popular ≠ best fit. Analyze each use case independently.

## Summary

Effective API discovery requires:

1. **Systematic research** - Use WebSearch + WebFetch methodically
2. **Objective comparison** - Score APIs on multiple criteria
3. **Clear justification** - Document why you chose this API
4. **Technical depth** - Extract all necessary details from docs
5. **Completeness analysis** - Verify ≥50% coverage
6. **Documentation** - Record decision in DECISIONS.md

**Time investment**: ~10-15 minutes
**Impact**: Prevents weeks of rework from wrong API choice

**Remember**: The API you choose now will be the foundation of the entire agent.
Choose carefully!
