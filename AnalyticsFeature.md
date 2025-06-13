# Analytics Feature Documentation

## Overview
The Analytics feature provides comprehensive data visualization and insights for your time tracking data. It includes multiple chart types, statistical summaries, and supports multiple time periods.

## Features

### 📊 Chart Types
1. **Pie Chart**: Time distribution across categories
2. **Bar Chart**: Category-wise time comparison
3. **Line Chart**: Time trends over the selected period
4. **Hourly Activity Chart**: Shows activity patterns throughout the day

### 📅 Time Periods
- **Daily**: View data for a specific day
- **Weekly**: Week-based analysis
- **Monthly**: Monthly insights
- **Yearly**: Annual overview

### 📈 Summary Statistics
- Total time tracked
- Number of tasks completed
- Average session duration
- Completion rate percentage

### 🎨 Visual Features
- Beautiful, animated charts using SwiftUI Charts
- Dark mode support with appropriate color schemes
- Japanese localization throughout
- Smooth scrolling and responsive design
- Color-coded categories with consistent theming

## Technical Implementation

### Files Created
- `/Views/Analytics/AnalyticsView.swift`: Main analytics view with all charts and statistics
- `/Views/Analytics/AnalyticsViewExample.swift`: Integration examples
- Updated `/Utils/Localization.swift`: Added Japanese strings for analytics
- Updated `/Models/SharedTypes.swift`: Added yearly period support
- Updated `/ViewModels/SwiftDataTimeTrackingViewModel.swift`: Added yearly period handling

### Data Models
```swift
enum AnalyticsPeriod: String, CaseIterable {
    case daily, weekly, monthly, yearly
}

struct AnalyticsData {
    let period: AnalyticsPeriod
    let categoryStats: [CategoryAnalytics]
    let totalTime: TimeInterval
    let taskCount: Int
    let mostProductiveHour: Int?
    let averageSessionDuration: TimeInterval
    let completionRate: Double
    let trends: [TrendPoint]
}

struct CategoryAnalytics: Identifiable {
    let category: SDCategory
    var totalTime: TimeInterval
    var taskCount: Int
    let percentage: Double
    let averageDuration: TimeInterval
    let mostActiveHour: Int?
}
```

### Key Components

#### 1. Period Selector
- Segmented control for switching between Daily/Weekly/Monthly/Yearly views
- Navigation buttons for moving between periods
- Localized date range display

#### 2. Summary Cards
Four key metrics displayed in a grid:
- Total time with clock icon
- Task count with list icon
- Average session duration with stopwatch icon
- Completion rate with checkmark icon

#### 3. Time Distribution Pie Chart
- Shows percentage breakdown of time across categories
- Limited to top 8 categories for clarity
- Interactive legend with category colors
- Gradient styling for visual appeal

#### 4. Category Bar Chart
- Horizontal bar chart showing time per category
- Supports up to 10 categories
- Hour-based axis labeling
- Category-specific colors

#### 5. Trend Line Chart
- Line and area chart showing time trends
- Catmull-Rom interpolation for smooth curves
- Date-appropriate axis labeling
- Blue gradient styling

#### 6. Hourly Activity Chart
- 24-hour bar chart showing activity patterns
- Helps identify most productive hours
- Mint gradient styling
- Compact horizontal layout

#### 7. Detailed Statistics
- Top 5 categories with detailed breakdowns
- Shows task count and percentage for each category
- Clean list design with dividers

## Integration Guide

### Method 1: Tab-Based Integration
```swift
TabView {
    // Existing tabs...
    
    AnalyticsView(viewModel: viewModel)
        .tabItem {
            Image(systemName: "chart.bar.xaxis")
            Text("分析")
        }
}
```

### Method 2: Sheet Presentation
```swift
.sheet(isPresented: $showingAnalytics) {
    AnalyticsView(viewModel: viewModel)
}
```

### Method 3: Navigation Link
```swift
NavigationLink(destination: AnalyticsView(viewModel: viewModel)) {
    Text("Analytics")
}
```

## Usage Requirements

### Dependencies
- SwiftUI Charts framework (iOS 16+)
- SwiftData for data persistence
- Existing SwiftDataTimeTrackingViewModel

### Data Requirements
The analytics view works with your existing:
- `SDTimeBlock` entities
- `SDCategory` entities
- `SwiftDataTimeTrackingViewModel`

### Localization
All strings are localized in Japanese through the `L10n` struct:
- `L10n.analytics` - "分析"
- `L10n.totalTime` - "総時間"
- `L10n.taskCount` - "タスク数"
- And many more...

## Performance Considerations

### Optimizations
- Efficient data fetching with SwiftData predicates
- Lazy loading of chart data
- Proper use of @StateObject and @Published for reactive updates
- Memory-efficient chart rendering

### Caching
The view includes intelligent data loading:
- Async data calculation
- Loading states with progress indicators
- Efficient date range calculations

## Customization Options

### Easy Modifications
1. **Chart Colors**: Modify gradient and color schemes in chart definitions
2. **Time Periods**: Add custom periods by extending `AnalyticsPeriod`
3. **Summary Cards**: Add or modify metrics in the summary section
4. **Chart Limits**: Adjust the number of categories shown (currently 8 for pie, 10 for bar)

### Advanced Customizations
1. **Additional Chart Types**: Add scatter plots, area charts, etc.
2. **Export Features**: Add data export functionality
3. **Filtering Options**: Add category or tag-based filtering
4. **Comparison Views**: Add period-over-period comparisons

## Error Handling

The view includes robust error handling:
- Empty state when no data is available
- Graceful fallbacks for missing categories
- Safe date calculations with calendar operations
- Protection against division by zero in calculations

## Accessibility

Features for accessibility:
- Proper VoiceOver support through semantic labels
- High contrast support through dynamic colors
- Scalable text that respects user font size preferences
- Clear visual hierarchy and spacing

## Future Enhancements

Potential future additions:
1. **Goal Tracking**: Compare actual vs. planned time
2. **Productivity Scoring**: Calculate productivity metrics
3. **Pattern Recognition**: AI-powered insights about patterns
4. **Team Analytics**: Multi-user analytics for teams
5. **Export Options**: PDF/CSV export functionality
6. **Custom Date Ranges**: Allow arbitrary date range selection
7. **Drill-down Views**: Detailed views for specific categories or time periods

## Troubleshooting

### Common Issues
1. **Charts not displaying**: Ensure iOS 16+ and Charts framework is available
2. **Data not loading**: Check SwiftData model context is properly passed
3. **Localization issues**: Verify L10n strings are properly imported
4. **Performance issues**: Consider reducing chart data points for large datasets

### Debug Tips
- Use the loading state to verify data fetching
- Check console output for SwiftData fetch errors
- Verify date range calculations with print statements
- Test with various data sizes and time periods