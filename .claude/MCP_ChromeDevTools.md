# Chrome DevTools MCP Server

**Purpose**: Real-time browser debugging, performance analysis, and network inspection using Chrome DevTools Protocol

## Triggers
- Performance issues and Core Web Vitals optimization (LCP, CLS, INP)
- Console errors and JavaScript debugging needs
- Network debugging (CORS issues, failed requests, headers)
- Layout and CSS debugging with live DOM inspection
- Browser rendering and behavior analysis
- CPU and network throttling for testing
- Real-time performance tracing and insights

## Choose When
- **For debugging**: When you need live browser inspection and real-time analysis
- **Over Playwright**: For performance profiling, console debugging, network inspection
- **With Playwright**: Use both - Playwright for E2E testing, DevTools for debugging
- **For performance**: Core Web Vitals analysis, trace recording, bottleneck identification
- **For network analysis**: Request inspection, CORS debugging, header validation
- **Not for**: Cross-browser testing (Chrome only), complex test automation (use Playwright)

## Works Best With
- **Sequential**: Sequential identifies issue → DevTools debugs with live browser data
- **Playwright**: Playwright automates workflow → DevTools analyzes performance/network
- **Magic**: Magic creates UI → DevTools validates rendering and performance
- **Tavily**: Tavily researches solutions → DevTools validates fixes in real-time

## Key Capabilities

### Browser Control
- **Page Management**: Navigate, create, close, select pages
- **Navigation**: Forward/backward history, URL navigation
- **Page Resizing**: Test responsive layouts
- **Tab Management**: Multi-page workflows and testing

### DOM Interaction & Inspection
- **Live Snapshots**: Accessibility tree snapshots for DOM inspection
- **Element Interaction**: Click, hover, drag, fill forms
- **Form Automation**: Fill multiple form fields efficiently
- **Dialog Handling**: Accept/dismiss alerts, prompts, confirms
- **File Uploads**: Automated file selection and upload
- **Screenshots**: Full page or element-specific captures

### Performance Analysis
- **Performance Tracing**: Record and analyze Chrome performance traces
- **DevTools Insights**: LCP breakdown, document latency, render blocking
- **Core Web Vitals**: Automatic CWV scoring and analysis
- **CPU Throttling**: Simulate slower devices (1-20x slowdown)
- **Network Throttling**: Test on Slow 3G, Fast 3G, 4G, offline modes
- **Performance Insights**: Detailed analysis of specific performance issues

### Network Inspection
- **Request Monitoring**: Track all network requests since page load
- **Request Details**: Headers, payload, response, timing, resource type
- **CORS Debugging**: Identify cross-origin issues
- **Request Filtering**: Filter by resource type (XHR, fetch, scripts, etc.)
- **Network Timeline**: Understand request waterfalls and dependencies

### Console & Debugging
- **Console Messages**: Access all console logs, warnings, errors
- **Error Filtering**: Focus on errors only
- **Script Evaluation**: Execute JavaScript in page context
- **Live Debugging**: Real-time inspection of page state

### Visual Testing
- **Screenshots**: PNG/JPEG, full page or element-specific
- **Visual Regression**: Compare screenshots across changes
- **Layout Debugging**: Visual inspection of rendering issues

## Examples
```
"why is this page slow?" → DevTools (performance trace + insights)
"what's causing this CORS error?" → DevTools (network inspection)
"debug console errors on homepage" → DevTools (console monitoring)
"analyze Core Web Vitals" → DevTools (performance trace + CWV scoring)
"test site on slow 3G" → DevTools (network throttling + performance)
"inspect the login button layout" → DevTools (DOM snapshot + screenshot)
"run E2E test suite" → Playwright (automated testing)
"validate accessibility compliance" → Playwright (WCAG testing)
```

## Performance Analysis Workflow

### Basic Performance Trace
```
1. navigate_page → Load target URL
2. performance_start_trace → Begin recording
3. [Interact with page if needed]
4. performance_stop_trace → Get insights and CWV scores
5. performance_analyze_insight → Deep dive into specific issues
```

### Performance Insights Available
- **LCPBreakdown**: Largest Contentful Paint analysis
- **DocumentLatency**: Time to interactive metrics
- **RenderBlocking**: Resources blocking first paint
- **SlowCSSSelector**: Inefficient CSS selectors
- **LayoutShift**: Cumulative Layout Shift causes
- **InteractionToNextPaint**: INP performance issues

### Network Throttling Test
```
1. emulate_network(throttlingOption: "Slow 3G")
2. navigate_page(url)
3. performance_start_trace()
4. Wait for page load
5. performance_stop_trace() → Analyze slow network impact
6. emulate_network(throttlingOption: "No emulation") → Reset
```

### CPU Throttling Test
```
1. emulate_cpu(throttlingRate: 4) → 4x CPU slowdown
2. navigate_page(url)
3. performance_start_trace()
4. performance_stop_trace() → Analyze on low-end devices
5. emulate_cpu(throttlingRate: 1) → Reset to normal
```

## Network Debugging Workflow

### CORS Investigation
```
1. navigate_page → Load application
2. list_network_requests → Review all requests
3. get_network_request(url) → Inspect specific failing request
4. Analyze headers, response codes, CORS headers
```

### Request Filtering
```
list_network_requests(
  resourceTypes: ["xhr", "fetch"],
  pageSize: 20
) → Focus on API calls only
```

## Console Debugging Workflow

### Error Investigation
```
1. navigate_page → Load page
2. list_console_messages(onlyErrors: true) → Get error logs
3. evaluate_script → Inspect page state
4. Fix issues based on error messages
5. Reload and verify fixes
```

## DOM Inspection Workflow

### Layout Debugging
```
1. navigate_page → Load page
2. take_snapshot → Get accessibility tree with element UIDs
3. take_screenshot(element: "button", uid: "123") → Visual inspection
4. evaluate_script → Check computed styles
5. Identify layout issues from live data
```

### Interactive Debugging
```
1. take_snapshot → Identify elements
2. click(uid: "submit-btn") → Interact
3. wait_for(text: "Success") → Verify behavior
4. list_console_messages → Check for errors
```

## Integration Flows

### Performance Debugging Flow
```
1. Sequential: Analyze user report of slow page
2. DevTools: Navigate to page + start performance trace
3. DevTools: Stop trace → Get CWV scores and insights
4. DevTools: Analyze specific insights (LCP, render blocking)
5. Sequential: Synthesize findings into action plan
6. Magic: Implement optimizations
7. DevTools: Re-test to validate improvements
```

### Bug Investigation Flow
```
1. User reports: "Feature X doesn't work"
2. DevTools: Navigate to page
3. DevTools: Take snapshot + inspect console
4. DevTools: List network requests (check API failures)
5. DevTools: Evaluate script (inspect page state)
6. Sequential: Root cause analysis
7. Fix code
8. DevTools: Verify fix in live browser
```

### UI Debugging Flow
```
1. Magic: Generate UI component
2. DevTools: Take snapshot of rendered component
3. DevTools: Take screenshot for visual validation
4. DevTools: Inspect layout with evaluate_script
5. DevTools: Identify rendering issues
6. Magic: Refine component based on findings
7. DevTools: Validate improvements
```

### Research + Debug Flow
```
1. Tavily: Research performance best practices
2. DevTools: Run performance trace on current site
3. Sequential: Compare findings vs best practices
4. DevTools: Test optimizations with throttling
5. DevTools: Validate improvements with new trace
```

## Chrome DevTools vs Playwright

### Use Chrome DevTools For:
- ⚡ Performance profiling and Core Web Vitals analysis
- 🐛 Console error debugging and JavaScript inspection
- 🌐 Network request debugging (CORS, headers, timing)
- 🎨 Layout and rendering issue investigation
- 📊 Real-time performance insights and bottlenecks
- 🔍 Live DOM and CSS inspection
- 🚀 CPU and network throttling for testing

### Use Playwright For:
- ✅ E2E test automation and test suites
- 🌍 Cross-browser testing (Chrome, Firefox, Safari)
- ♿ Accessibility compliance testing (WCAG)
- 🔄 Complex user journey automation
- 📸 Visual regression testing at scale
- 🎭 Browser context isolation and parallel testing

### Use Both Together:
- Playwright automates user workflows → DevTools profiles performance
- Playwright runs tests → DevTools debugs failures
- Playwright validates functionality → DevTools optimizes performance
- Playwright creates scenarios → DevTools analyzes network behavior

## Advanced Features

### Performance Insights Deep Dive
```javascript
// After performance_stop_trace, analyze specific insights:
performance_analyze_insight(insightName: "LCPBreakdown")
→ Detailed breakdown of LCP contributors
→ Resource loading timeline
→ Recommendations for improvement

performance_analyze_insight(insightName: "RenderBlocking")
→ Scripts/styles blocking first paint
→ Critical resource analysis
→ Optimization opportunities
```

### Multi-Page Testing
```javascript
// Test multiple pages in one session:
1. list_pages → See all open tabs
2. new_page(url: "page1.com") → Open first test page
3. new_page(url: "page2.com") → Open second test page
4. select_page(pageIdx: 0) → Switch to page 1
5. [Run tests on page 1]
6. select_page(pageIdx: 1) → Switch to page 2
7. [Run tests on page 2]
8. close_page(pageIdx: 0) → Clean up
```

### Form Automation
```javascript
// Fill multiple fields efficiently:
fill_form({
  fields: [
    {name: "email", type: "textbox", ref: "uid-123", value: "test@example.com"},
    {name: "remember", type: "checkbox", ref: "uid-456", value: "true"},
    {name: "country", type: "combobox", ref: "uid-789", value: "USA"}
  ]
})
```

### Script Evaluation for State Inspection
```javascript
// Check page state:
evaluate_script(function: "() => window.appState")
→ Returns serialized app state

// Inspect element properties:
evaluate_script(
  function: "(el) => ({width: el.offsetWidth, visible: el.offsetHeight > 0})",
  args: [{uid: "element-123"}]
)
→ Returns element dimensions and visibility
```

## Best Practices

### Performance Analysis
1. Always run traces in consistent network conditions
2. Use CPU throttling to simulate low-end devices
3. Analyze insights systematically (LCP → CLS → INP)
4. Compare before/after traces when optimizing
5. Test on realistic network conditions (3G, 4G)

### Network Debugging
1. Filter requests by resource type to focus investigation
2. Check request timing to identify bottlenecks
3. Inspect headers for CORS and authentication issues
4. Monitor request sizes for optimization opportunities
5. Use network throttling to test edge cases

### Console Debugging
1. Filter errors only when debugging specific issues
2. Evaluate scripts to inspect live page state
3. Clear console between tests for clean results
4. Correlate console errors with network failures

### DOM Inspection
1. Always take snapshot before interacting with elements
2. Use UIDs from snapshots for reliable element targeting
3. Prefer snapshots over screenshots for accessibility data
4. Take screenshots for visual validation and documentation

### Browser Management
1. Clean up pages when done to avoid resource waste
2. Use page selection to manage multi-page workflows
3. Resize pages when testing responsive layouts
4. Handle dialogs promptly to avoid blocking workflows

## Error Handling

### Common Issues
- **Browser not started**: DevTools server doesn't auto-start browser on connect
- **Element not found**: Take fresh snapshot before interaction
- **Navigation timeout**: Increase timeout for slow pages
- **Dialog blocking**: Use handle_dialog to dismiss alerts
- **Performance trace running**: Stop trace before starting new one

### Fallback Strategies
- **Snapshot fails**: Use screenshot for visual inspection
- **Network list empty**: Ensure requests made after page selection
- **Console empty**: Check if page actually logged messages
- **Performance insights unavailable**: Some insights require specific conditions

## Configuration

### Requirements
- Chrome browser installed
- Chrome DevTools MCP server configured
- No auto-start (manually launch or use tools to start)

### Troubleshooting
- **VM port forwarding issues**: See Chrome DevTools MCP troubleshooting guide
- **Browser connection fails**: Verify Chrome installation and MCP server config
- **Tools not working**: Ensure browser is running and page is loaded
- **Performance traces empty**: Verify trace was started before page interaction

## Quality Standards

### Performance Testing
- Run multiple traces for consistent results
- Test on various network/CPU conditions
- Document baseline metrics before optimization
- Validate improvements with new traces

### Debugging Workflow
- Systematically check console → network → performance
- Document findings with screenshots and logs
- Verify fixes in live browser before closing
- Use real user scenarios for testing

### Integration Quality
- Combine with Sequential for systematic analysis
- Use with Playwright for comprehensive testing
- Integrate with Magic for UI validation workflow
- Document debugging patterns for reuse
