# StethoAI

An AI-powered heart health companion for iOS. Check your heart rate daily with your
phone camera (PPG), record and analyze heart sounds with the microphone, and track
your heart health over time.

> **Wellness & education only — not a medical device.** StethoAI does not diagnose,
> treat, or prevent any condition. Always consult a healthcare provider.

## Requirements

- Xcode 16+ (built with Xcode 26)
- iOS 17+ target (SwiftData)
- [XcodeGen](https://github.com/yonicd/XcodeGen) to generate the project

## Getting started

```bash
brew install xcodegen      # if not installed
xcodegen generate          # regenerate StethoAI.xcodeproj from project.yml
open StethoAI.xcodeproj
```

The `.xcodeproj` is generated from `project.yml` and is git-ignored — edit
`project.yml` for build settings, not the project file directly.

## Architecture

- **Core/** — `Tokens.swift` design system, `AppSettings` (UserDefaults)
- **Models/** — SwiftData models (User, HeartRateReading, HeartSoundRecording,
  BreathingSession, DailyLog, Insight)
- **Services/** — PPG camera manager + signal processing, audio recorder, mocked
  heart-sound analyzer, rule-based insight generator, streak + notification managers
- **Views/** — Onboarding, Home, Scan (heart rate + heart sound), Trends, Breathing,
  Insights, More, and reusable Components

## v1 notes

- Heart sound classification is a **mocked placeholder** — a real Core ML model
  (trained on the CirCor dataset) will be swapped into `HeartSoundAnalyzer` in v2.
- On the simulator (no camera/mic), the PPG and audio flows fall back to synthetic
  signals so the full UX can be exercised.
