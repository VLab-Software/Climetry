# Climetry - NASA Space Apps Challenge 2024
## Deployment & Features Guide

### 🌐 Live Deployment
**Web Application**: https://nasa-climetry.web.app

### 🚀 Key Features

#### 1. Historical Weather Comparison
- **Climate Normals Integration**: Compares event forecast with historical averages
- **Data Source**: Meteomatics Climate Normals API (multi-year averages)
- **Metrics Compared**:
  - Temperature (°F)
  - Precipitation (inches)
  - Wind Speed (mph)
  - Humidity (%)
- **Smart Analysis**: Shows if conditions are better/worse than typical for that date

#### 2. NASA EONET Integration
- **Natural Event Tracking**: Real-time data from NASA's Earth Observatory
- **Event Types**: Wildfires, storms, floods, volcanoes, droughts
- **Location-Based**: Filters events within 500km radius of user events
- **No API Key Required**: Uses public NASA endpoints

#### 3. Enhanced AI Insights
- **Powered by**: OpenAI GPT-4o-mini
- **Context-Aware**: References NASA data and climate normals
- **Data Sources Mentioned**:
  - Meteomatics weather forecasts
  - Climate Normals (historical averages)
  - NASA EONET (natural disasters)
- **Smart Recommendations**: Based on risk level and historical context

#### 4. Modern UI/UX
- **Gradient Cards**: Risk-colored gradients on event cards
- **Animations**: Smooth scale animations on tap
- **Priority Badges**: Color-coded (URGENT/HIGH/MEDIUM/LOW)
- **Weather Preview**: Icons with imperial units (°F, mph, inches)
- **NASA Branding**: Subtle "Powered by NASA" badges

### 📊 Technical Architecture

#### APIs Used
1. **Meteomatics API**
   - Weather forecasts (current, weekly, monthly, 6-month)
   - Climate normals endpoint for historical data
   - Imperial units throughout

2. **NASA EONET**
   - Earth Observatory Natural Event Tracker
   - Public API (no authentication)
   - Real-time natural disaster data

3. **OpenAI API**
   - GPT-4o-mini model
   - Event-specific weather analysis
   - Contextual recommendations

4. **Firebase**
   - Firestore: Events, users, friends, notifications
   - Authentication: Email/password
   - Storage: Profile photos, event images
   - Hosting: Web deployment

#### Data Flow
```
Event Created → Fetch Weather Forecast → Fetch Climate Normals → 
Calculate Difference → Check NASA Events → Generate AI Insights → 
Display Comparison + Recommendations
```

### 🔧 Build Instructions

#### Web
```bash
flutter build web --release
firebase deploy --only hosting
```
**Result**: https://nasa-climetry.web.app

#### Android
```bash
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS
```bash
# 1. Open Xcode workspace
open ios/Runner.xcworkspace

# 2. Connect iPhone via USB
# 3. Select device in Xcode
# 4. Product → Run (⌘R)
# 5. Trust certificate on iPhone: Settings → General → Device Management
```

### 📱 Features by Platform

| Feature | Web | Android | iOS |
|---------|-----|---------|-----|
| Historical Comparison | ✅ | ✅ | ✅ |
| NASA EONET Integration | ✅ | ✅ | ✅ |
| AI Insights | ✅ | ✅ | ✅ |
| Push Notifications | ❌ | ✅ | ✅ |
| Location Services | ✅ | ✅ | ✅ |
| Dark Mode | ✅ | ✅ | ✅ |

### 🌡️ Historical Comparison Example

**Event**: Beach Party on July 15, 2025
**Location**: Miami, FL

**Forecast vs Climate Normal**:
- Temperature: 88°F (forecast) vs 84°F (average) = **4°F warmer than usual**
- Precipitation: 0.1" (forecast) vs 0.3" (average) = **67% less rain than usual**
- Wind: 12 mph (forecast) vs 15 mph (average) = **3 mph calmer than usual**

**AI Insight**:
> "Great news! Weather conditions are better than the historical average for mid-July in Miami. Based on our internal calculations using NASA EONET data and Meteomatics climate normals, you can expect warmer and drier conditions than typical for this date. The 88°F temperature is perfect for beach activities, and with 67% less precipitation than usual, your event is well-positioned for success."

### 🎯 NASA Space Apps Challenge Integration

**Challenge**: Using Earth observation data to improve event planning

**Our Solution**:
1. **NASA EONET**: Track natural disasters near event locations
2. **Climate Normals**: Compare current forecasts with historical patterns
3. **Smart Insights**: AI combines NASA data + weather data for recommendations
4. **User Education**: Transparent about data sources in UI and insights

### 📈 Performance Metrics

**Web Build**:
- Build Time: 17.1s
- Tree-Shaking: 98.9% (MaterialIcons), 99.4% (CupertinoIcons)
- Bundle Size: Optimized for web delivery

**Android Build**:
- Target SDK: 34
- Min SDK: 21
- APK Size: ~45MB (release)

**iOS Build**:
- Target: iOS 12.0+
- Team ID: C277ZT2F26
- Bundle ID: com.vlabsoftware.climetry

### 🔐 Environment Variables Required

Create `.env` file in project root:
```env
METEOMATICS_USERNAME=your_username
METEOMATICS_PASSWORD=your_password
OPENAI_API_KEY=your_openai_key
GOOGLE_MAPS_API_KEY=your_maps_key
```

### 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/VLab-Software/Climetry.git
cd Climetry

# Install dependencies
flutter pub get

# iOS pods
cd ios && pod install && cd ..

# Run on device/simulator
flutter run
```

### 📝 Git Commits

Latest commits:
- `4d87afe`: Historical weather comparison with climate normals
- `178557c`: Enhanced event card UI with gradients & animations
- `827124b`: NASA integration (EONET + badges)
- `53e757d`: Complete English localization + imperial units

### 🏆 Key Achievements

✅ Complete weather comparison system with 10+ year historical data
✅ NASA EONET integration for natural disaster tracking
✅ AI insights that explain data sources and methodology
✅ Modern, animated UI with excellent UX
✅ Multi-platform deployment (Web live, Android APK, iOS ready)
✅ Fully localized to English with US imperial units
✅ Firebase integration for real-time collaboration

### 📧 Support

- **GitHub**: https://github.com/VLab-Software/Climetry
- **Web App**: https://nasa-climetry.web.app
- **Firebase Console**: https://console.firebase.google.com/project/nasa-climetry

---

Built with ❤️ for NASA Space Apps Challenge 2024
