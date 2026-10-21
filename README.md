# OpenPulse

A free heart check that needs nothing but a phone. OpenPulse measures your heart
rate with the phone's camera, keeps a heart record you can show a doctor, learns
what's usual for you with an on-device machine-learning model, and points you to
care when a reading looks unusual.

> **Wellness and education only. Not a medical device.** OpenPulse does not
> diagnose, treat, or prevent any condition. Always consult a healthcare provider.

## How it measures heart rate

OpenPulse uses **photoplethysmography (PPG)**: measuring blood volume changes with light.

1. The flash lights up a fingertip held over the back camera.
2. Each heartbeat pushes a little more blood into the fingertip, and blood absorbs
   light, so the image gets very slightly darker on every beat.
3. 30 times a second, the camera frame is averaged into one red brightness value.
   Red light travels deepest through tissue, so it carries the cleanest pulse.
4. Auto-exposure is locked once the finger is in place, so the camera doesn't
   "correct away" the tiny brightness changes.
5. A zero-phase band-pass filter keeps only heart-speed rhythms (42–210 bpm).
6. The rate is measured two independent ways: the strongest frequency in the
   spectrum, and the median time between detected beats.
7. A reading is shown only when both agree within 4 bpm. Otherwise the app keeps
   measuring (up to 60 s) and, if it still can't get a clean signal, asks to retry
   rather than show a wrong number.

See `OpenPulse/Services/HeartRateSignalProcessor.swift`.

### Testing and validation

Early on-device readings came out far too low. Raw camera signals from 15 readings
were recorded on an iPhone 15 and analyzed offline, which uncovered two problems:
retries were stacking duplicate camera feeds (each frame arriving 2–3 times), and
the original autocorrelation method was fragile. After the rewrite, the same 15
recordings went from 6 readings (all wrong, 40–69 bpm) to 10 readings, all within
68–80 bpm of a manually counted ~72 bpm. Follow-up live tests were within 2–7 bpm
of a manual pulse count. This has been tested on one person so far; it is not
clinically validated.

## The personal heart model (machine learning)

`OpenPulse/Services/PersonalHeartModel.swift` is a small ridge-regression model
trained on the phone from the user's own readings and daily check-ins (sleep,
caffeine, exercise, stress, mood, time of day). It starts from an estimate based on
the onboarding answers (age, sex, exercise level) and leans on personal data as
readings come in. It shows what's usual for you right now, its typical accuracy,
and what moves your heart rate in bpm. It never leaves the device.

Heart-rate detection itself is signal processing, not machine learning.

## Privacy

No account, no server. The camera image becomes brightness numbers on the phone;
no photos, video, or audio are uploaded. Everything is stored locally with SwiftData.

## Building

Requirements: Xcode 16+ (built with Xcode 26), iOS 17+, and
[XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open OpenPulse.xcodeproj
```

The `.xcodeproj` is generated from `project.yml` and is git-ignored, so edit
`project.yml` for build settings. On the simulator (no camera or microphone), the
heart-rate flow uses a synthetic signal so the full experience can be tried.

## Project layout

- **Core/** — design tokens, app settings, app name
- **Models/** — SwiftData models (user profile, readings, check-ins, heart-sound recordings, breathing sessions)
- **Services/** — camera capture, signal processing, personal heart model, insight patterns, care resources, localization (English, Hindi, Tamil)
- **Views/** — onboarding quiz, Check, History, Help, guided check, breathing, insights, and shared components
