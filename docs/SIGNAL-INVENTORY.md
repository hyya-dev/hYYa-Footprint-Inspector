# Signal inventory

Phase 1 research, written 2026-10-17. Target: iOS 26+ (our builds use the iOS 27 SDK).

This file lists every signal we plan to show and how an engineer re-implements it. The *list* of
signals was checked against an existing open-source inspector so we don't miss any. Every
description, explanation and fix here is our own. Don't copy wording or code from any reference
app into the product.

Where a fact isn't confirmed on a device, it says **unverified**. Treat those as test items for
Phase 2.

---

## Legend

| Column | Meaning |
|---|---|
| **Group** | **P** = Passive (no prompt). **N** = Needs permission. **A** = Advanced (a public API used in a way it wasn't meant for). |
| **Perm** | The Info.plist usage key, or `—` for none. |
| **RRA** | Apple "Required Reason API" category: `BOOT` system boot time · `DISK` disk space · `KBD` active keyboards · `FTS` file timestamp · `UD` user defaults · `—` none. If we use one, we must declare it with an approved reason in `PrivacyInfo.xcprivacy`. |
| **Persist** | `R` until restart · `I` until reinstall · `E` until erase · `HW` fixed for the hardware/model · `S` until you change the setting · `C` changes often · `A` follows the Apple Account |
| **Sev** | How much it helps identify or profile you: **L** low · **M** medium · **H** high |
| **Fix** | **Yes** / **Partly** / **Only Apple**, plus our fix level: L1 one tap in our app · L2 one tap to Settings · L3 guided steps · L4 only Apple |
| **iOS 27** | `Changed` / `Still open` where a source confirms it; otherwise `unverified` |

**Why iOS allows passive signals.** Apps need them to work properly: lay out the screen, pick
fonts and languages, adapt to accessibility settings, save battery, choose a network strategy.
The problem is that each one is harmless alone, but together they form a near-unique
"fingerprint" that is the same in every app, so trackers can link your activity without asking.

---

## 1. Passive signals (no prompt)

### 1.1 Device identity

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `idfv` | Vendor ID | `UIDevice.current.identifierForVendor` | — · — | A UUID shared by every app from the same developer on this phone. Lets one company's apps share state and spot abuse. | Until **all** apps from that developer are deleted | H: a ready-made cross-app ID within one company | Partly: delete every app from that developer (L3) | unverified |
| `device-name` | Device name | `UIDevice.current.name` | — · — | Since iOS 16 it returns only the model ("iPhone"). Apps holding the `user-assigned-device-name` entitlement still get your custom name (often "Firstname's iPhone"). | S | L (H for entitled apps) | Yes: Settings › General › About › Name; use a name without your own (L2/L3) | unverified |
| `kern-hostname` | Kernel host name | `sysctlbyname("kern.hostname")` | — · — | DNS host name. On some setups it reflects the device name. **unverified** what it returns on iOS 26. | S | L–M | Partly: same rename as above (L3) | unverified |
| `os-version` | iOS version | `UIDevice.current.systemVersion` | — · — | The exact iOS version. Apps use it to gate features. | Until you update | L: shared by millions | Yes: stay up to date, which joins the bigger crowd (L3) | unverified |
| `model-id` | Hardware model | `sysctlbyname("hw.machine")` (e.g. `iPhone17,1`), `sysctlbyname("hw.model")` (board ID) | — · — | The exact model and board. Used for performance tuning. | HW | L–M: narrows to one model | Only Apple (L4) | unverified |
| `cpu-type` | CPU type | `sysctlbyname("hw.cputype")`, `hw.cpusubtype` | — · — | CPU architecture codes. | HW | L | Only Apple (L4) | unverified |

### 1.2 System

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `cpu-count` | Processor count | `ProcessInfo.processInfo.processorCount` | — · — | Number of cores. Used for sizing thread pools. | HW | L | Only Apple (L4) | unverified |
| `ram` | Physical memory | `ProcessInfo.processInfo.physicalMemory` | — · — | Total RAM, which tells models apart. | HW | L | Only Apple (L4) | unverified |
| `os-build-string` | OS version and build | `ProcessInfo.processInfo.operatingSystemVersionString` | — · — | Version **plus build number**, which separates betas and Rapid Security Responses from release builds. | Until you update | L–M: beta users stand out | Partly: leave the beta programme (L3) | unverified |
| `kernel-version` | Kernel version | `sysctlbyname("kern.version")` | — · — | The Darwin/XNU build string, including its compile timestamp. | Until you update | L–M | Partly: as above (L3) | unverified |
| `boot-time` | Last restart time | `sysctlbyname("kern.boottime")` (also `ProcessInfo.systemUptime`) | — · **BOOT** | The exact second the phone last started. Used for measuring elapsed time. Combined with other values it is close to unique until the next restart. | **R** | H: stable and unique between restarts | Yes: restart the phone regularly (L3) | unverified |
| `lockdown-mode` | Lockdown Mode on/off | `UserDefaults.standard.bool(forKey: "LDMGlobalEnabled")`, an **undocumented global key** | — · **UD** | Whether Lockdown Mode is on. Very few people use it, so it marks you out. | S | M: rare flag | Don't fix; it's protective. Explain the trade-off (L3) | unverified. **App Review risk:** undocumented key, and no approved UD reason fits reading a key we didn't write |

### 1.3 Battery and power

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `battery` | Battery level and state | `UIDevice.isBatteryMonitoringEnabled = true` → `batteryLevel`, `batteryState` | — · — | Charge level and whether it's charging. Used to defer heavy work. It drifts slowly, so two apps can match sessions minutes apart. | C | L–M: short-term linking | Only Apple (L4) | unverified |
| `low-power` | Low Power Mode | `ProcessInfo.processInfo.isLowPowerModeEnabled` | — · — | Whether Low Power Mode is on. Apps use it to cut work. | S/C | L | Not worth fixing (L4) | unverified |
| `thermal` | Thermal state | `ProcessInfo.processInfo.thermalState` | — · — | nominal / fair / serious / critical. | C | L | Only Apple (L4) | unverified |

### 1.4 Storage

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `disk-total` | Total storage | `URL.resourceValues(forKeys: [.volumeTotalCapacityKey])` on `NSHomeDirectory()` | — · **DISK** | Storage tier (128 GB / 256 GB / …). | HW | L–M | Only Apple (L4) | unverified |
| `disk-free` | Free space | `.volumeAvailableCapacityKey` | — · **DISK** | Byte-exact free space. Used to check before downloads. It drifts slowly, so the same value in two apps links them. | C (slowly) | M–H: a classic cross-app fingerprint | Only Apple (L4) | unverified |
| `disk-reclaimable` | Free space incl. purgeable | `.volumeAvailableCapacityForImportantUsageKey`, `…ForOpportunisticUsageKey` | — · **DISK** | Free space if caches were purged. Adds precision to the value above. | C | M | Only Apple (L4) | unverified |
| `volume-created` | Setup / erase date | `.volumeCreationDateKey` | — · **unverified** whether it falls under DISK or FTS | **The second the phone was set up or last erased.** Practically unique per device and stable for years. | **E** | **H**: the strongest passive identifier | Only Apple (erasing resets it but isn't a real fix) (L4) | **Still open** (Privacy Guides, July 2026) |
| `volume-uuid` | Volume UUID | `.volumeUUIDStringKey` | — · — | Appears to be the same on every iPhone, so not identifying. **unverified** on 26/27. | HW | L | n/a | unverified |
| `volume-name` | Volume name | `.volumeNameKey`, `.volumeLocalizedNameKey` | — · — | Appears to be identical across devices. | HW | L | n/a | unverified |

### 1.5 Display

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `screen-pixels` | Native resolution | `UIScreen.nativeBounds` (via the window scene's `screen`) | — · — | Physical pixels, which point to the model family. Changes with Display Zoom. | HW/S | L | Only Apple (L4) | unverified |
| `screen-scale` | Scale | `UIScreen.scale` | — · — | @2x / @3x. | HW | L | Only Apple (L4) | unverified |
| `screen-native-scale` | Native scale | `UIScreen.nativeScale` | — · — | Real scale factor. Reveals whether **Display Zoom** is on. | HW/S | L | Only Apple (L4) | unverified |
| `max-fps` | Refresh rate | `UIScreen.maximumFramesPerSecond` | — · — | 60 vs 120 Hz (ProMotion → Pro model). | HW | L | Only Apple (L4) | unverified |
| `brightness` | Brightness | `UIScreen.brightness` | — · — | Current brightness, 0–1. Hints at surroundings (dark room, outdoors). | C | L | Only Apple (L4) | unverified |
| `gamut` | Colour gamut | `traitCollection.displayGamut` | — · — | sRGB vs P3. | HW | L | Only Apple (L4) | unverified |
| `size-class` | Size classes | `traitCollection.horizontalSizeClass` / `verticalSizeClass` | — · — | Compact/regular; varies by device and orientation. | C | L | Only Apple (L4) | unverified |
| `text-size` | Text size | `traitCollection.preferredContentSizeCategory` | — · — | Your Dynamic Type choice. A large setting can hint at eyesight needs. | S | M: a user choice with many values | Partly: it's an accessibility need; explain, don't push a change (L3) | unverified |
| `safe-area` | Safe-area insets | `UIWindow.safeAreaInsets` | — · — | Notch vs Dynamic Island chassis. | HW | L | Only Apple (L4) | unverified |

### 1.6 Audio

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `audio-outputs` | Connected outputs | `AVAudioSession.sharedInstance().currentRoute.outputs` → `portType`, `portName` | — · — | Connected headphones, car, AirPlay. **The AirPods default name contains the owner's first name** ("Sam's AirPods Pro"). Used for routing audio. | S/C | **H**: can hand over your first name | Yes: rename the accessory. Settings › Bluetooth › ⓘ next to the device › Name, or tap the AirPods name at the top of Settings (L3) | **Still open** (Privacy Guides, July 2026) |
| `audio-inputs` | Connected inputs | `currentRoute.inputs` | — · — | Built-in mic vs headset vs accessory. | C | L–M | Partly: rename (L3) | unverified |
| `sample-rate` | Sample rate | `AVAudioSession.sampleRate` | — · — | Current hardware rate. Differs by route. | C | L | Only Apple (L4) | unverified |
| `audio-latency` | Latency | `outputLatency`, `inputLatency` | — · — | Route-specific latency (for example, Bluetooth vs wired). | C | L | Only Apple (L4) | unverified |
| `other-audio` | Other audio playing | `AVAudioSession.isOtherAudioPlaying` | — · — | Whether you're listening to something in another app right now. | C | L | Only Apple (L4) | unverified |
| `volume` | System volume | `AVAudioSession.outputVolume` | — · — | The current volume, 0–1. Fairly precise and changes slowly, so it helps link sessions. | C | L–M | Only Apple (L4) | unverified |

Note: the reference also reads output/input channel counts and a list of every audio device, but
**only on macOS** (CoreAudio). They are not iOS signals; keep them for the macOS port.

### 1.7 Language, region, time

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `locale-id` | Locale | `Locale.current.identifier` | — · — | Language, region and calendar in one string. Used for formatting. | S | M | Partly: Settings › General › Language & Region (L3) | unverified |
| `first-weekday` | First day of week | `Locale.current.firstDayOfWeek` | — · — | Your setting, which may differ from the region default. | S | L–M: customisations add entropy | Partly: reset to default (L3) | unverified |
| `hour-cycle` | 12/24-hour clock | `Locale.current.hourCycle` | — · — | Clock preference. | S | L–M | Partly: as above (L3) | unverified |
| `languages` | Preferred languages | `Locale.preferredLanguages` | — · — | Ordered language list. Can hint at origin or heritage. | S | M–H: an unusual combination is rare | Partly: remove languages you don't use (L3) | unverified |
| `timezone` | Time zone | `TimeZone.current.identifier` | — · — | Your city-level zone. **A VPN doesn't hide it**, and a mismatch with your region suggests travel. | C (travel) | M | Partly: Settings › General › Date & Time (set manually) (L3) | unverified |
| `calendar-system` | Calendar system | `Calendar.current.identifier` | — · — | Gregorian, Islamic, Hebrew, Buddhist… Can hint at religion or culture. | S | M (sensitive inference) | Partly (L3) | unverified |
| `keyboards` | Enabled keyboards | `UITextInputMode.activeInputModes` → `primaryLanguage` | — · **KBD** | Every keyboard language you've added, in order. Strongly reflects which languages you write. | S | M–H | Partly: Settings › General › Keyboard › Keyboards; remove unused ones (L3) | unverified |

### 1.8 Accessibility and appearance

All `UIAccessibility.*` properties, readable by any app.

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `voiceover` | VoiceOver | `UIAccessibility.isVoiceOverRunning` | — · — | Screen-reader use. Apps need it to adapt their UI. **Can imply a disability**, which is sensitive data. | S | M (sensitive) | Don't advise turning it off. Explain only (L4) | unverified |
| `switch-control` | Switch Control | `isSwitchControlRunning` | — · — | Same: implies a motor disability. | S | M (sensitive) | Explain only (L4) | unverified |
| `guided-access` | Guided Access | `isGuidedAccessEnabled` | — · — | Kiosk or child use. | C | L | Explain only | unverified |
| `grayscale` | Greyscale filter | `isGrayscaleEnabled` | — · — | Colour filter on. | S | L | Explain only | unverified |
| `invert` | Classic Invert | `isInvertColorsEnabled` | — · — | Invert on. | S | L | Explain only | unverified |
| `reduce-motion` | Reduce Motion | `isReduceMotionEnabled` | — · — | Reduce Motion on. | S | L | Explain only | unverified |
| `a11y-other` | Other accessibility flags | `isAssistiveTouchRunning`, `isShakeToUndoEnabled`, `isBoldTextEnabled`, `isDarkerSystemColorsEnabled`, `isReduceTransparencyEnabled`, `isMonoAudioEnabled`, `isSpeakScreenEnabled`, `isSpeakSelectionEnabled`, `isClosedCaptioningEnabled`, `isVideoAutoplayEnabled`, `shouldDifferentiateWithoutColor`, `buttonShapesEnabled`, `isOnOffSwitchLabelsEnabled` | — · — | Thirteen on/off flags. Each one that differs from the default adds identifying detail, and some hint at hearing or vision needs. | S | M combined | Partly: only change ones you don't need (L3) | unverified |
| `dark-mode` | Light/dark mode | `traitCollection.userInterfaceStyle` | — · — | Appearance preference (it flips at sunset if set to Automatic). | S/C | L | Not worth fixing | unverified |
| `contrast` | Increase Contrast | `traitCollection.accessibilityContrast` | — · — | Contrast setting. | S | L | Explain only | unverified |

### 1.9 Clipboard (without reading its contents)

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `clip-count` | Clipboard change counter | `UIPasteboard.general.changeCount` | — · — | A counter that every app sees and that goes up on each copy. Used to know when to refresh a Paste button. Two apps reading the same value can link you. | **R on iOS 27 beta 3+** (it now resets on reboot). Before that it survived restarts (reported, **unverified**) | M (H before iOS 27) | Partly: restarting resets it on iOS 27 (L3) | **Changed**: resets on reboot (beta 3+) |
| `clip-has-text` | Clipboard has text | `UIPasteboard.general.hasStrings` | — · — | Whether text was copied. **No "pasted from" banner** appears. | C | L | Only Apple (L4) | unverified |
| `clip-has-url` | Clipboard has link | `hasURLs` | — · — | Whether a link was copied. | C | L | Only Apple | unverified |
| `clip-has-image` | Clipboard has image | `hasImages` | — · — | Whether an image was copied. | C | L | Only Apple | unverified |
| `clip-has-color` | Clipboard has colour | `hasColors` | — · — | Whether a colour value was copied. | C | L | Only Apple | unverified |
| `clip-items` | Clipboard item count | `numberOfItems` | — · — | Number of items. | C | L | Only Apple | unverified |

Reading the clipboard *contents* is separate: it triggers the paste banner or prompt, and you can
control it per app under Settings › Apps › [app] › Paste from Other Apps (Ask / Deny / Allow).

### 1.10 Motion sensors (no permission needed)

All come from `CMMotionManager`, sampled for a moment. **No usage key and no prompt.**

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `accel` | Accelerometer | `startAccelerometerUpdates()` → `accelerometerData.acceleration` | — · — | Raw 3-axis acceleration. Used for games and orientation. At high rates it can reveal gait, taps and in-vehicle motion. Tiny factory calibration errors have been used as a hardware fingerprint in research. | C | M | Only Apple (L4) | **Still open** (Privacy Guides) |
| `gyro` | Gyroscope (raw) | `startGyroUpdates()` → `gyroData.rotationRate` | — · — | Raw rotation. Same concerns. | C | M | Only Apple | **Still open** |
| `magnetometer` | Magnetometer (raw) | `startMagnetometerUpdates()` | — · — | Raw magnetic field, affected by nearby metal and your surroundings. | C | M | Only Apple | **Still open** |
| `attitude` | Orientation | `startDeviceMotionUpdates(using:)` → `deviceMotion.attitude` | — · — | Roll, pitch and yaw: how you hold the phone. | C | L–M | Only Apple | **Still open** |
| `gravity` | Gravity vector | `deviceMotion.gravity` | — · — | Which way is down. | C | L | Only Apple | **Still open** |
| `user-accel` | User acceleration | `deviceMotion.userAcceleration` | — · — | Your movement with gravity removed. | C | M | Only Apple | **Still open** |
| `rotation-fused` | Rotation (corrected) | `deviceMotion.rotationRate` | — · — | Bias-corrected rotation. | C | L–M | Only Apple | **Still open** |
| `mag-calibrated` | Magnetic field (calibrated) | `deviceMotion.magneticField` (with a magnetic-north reference frame) | — · — | Calibrated field and its accuracy. | C | L–M | Only Apple | **Still open** |
| `heading` | Compass heading | `deviceMotion.heading` (iOS 11+, north-aligned frame) | — · — | **Which way you're facing, with no location permission.** | C | M | Only Apple | **Still open** |

### 1.11 Network

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `hostname` | Local host name | `gethostname()` | — · — | Host name; **unverified** what iOS 26 returns. | S | L | Partly: rename the device (L3) | unverified |
| `net-expensive` | Expensive connection | `NWPathMonitor` → `path.isExpensive` | — · — | On cellular or a personal hotspot. Used to save data. | C | L | n/a | unverified |
| `low-data` | Low Data Mode | `path.isConstrained` | — · — | Low Data Mode is on. | S | L | n/a | unverified |
| `interfaces` | Available interfaces | `path.availableInterfaces` → `.type` | — · — | Wi-Fi, cellular, wired, other. | C | L | n/a | unverified |
| `vpn` | VPN in use | `CFNetworkCopySystemProxySettings()` → `__SCOPED__` keys containing `tun`/`tap`/`ppp`/`ipsec` (heuristic) | — · — | Whether a VPN tunnel is up. **Apps can see you use a VPN** even though it hides your IP from them. May give false positives (system `utun` interfaces); **unverified**. | C | M | No fix: a VPN can't hide itself. Explain (L4) | unverified |
| `vpn-ifaces` | VPN interface names | same | — · — | The names of the tunnel interfaces. | C | L | — | unverified |
| `local-ip` | Device IP addresses | `getifaddrs()` → `AF_INET` / `AF_INET6` per `ifa_name` (`en0`, `pdp_ip0`, `utun*`…) | — · — | Local Wi-Fi IP, cellular IP and IPv6 addresses. A global IPv6 prefix can point to your home network. | C | M | Partly: iOS rotates temporary IPv6 addresses; iCloud Private Relay/VPN hide the *public* IP but not these (L3) | unverified |

### 1.12 Fonts and voices

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `font-count` | Font family count | `CTFontManagerCopyAvailableFontFamilyNames()` (or `UIFont.familyNames`) | — · — | Number of families. Stock phones match; extra fonts stand out. **unverified** whether fonts installed by other apps are visible here. | S | L–M | Partly: remove font apps/profiles (Settings › General › Fonts) (L3) | unverified |
| `font-list` | Font family list | same | — · — | The full list. | S | L–M | Partly (L3) | unverified |
| `voice-count` | Installed voice count | `AVSpeechSynthesisVoice.speechVoices()` | — · — | Number of text-to-speech voices. | S | M | Partly: delete unused voices. Settings › Accessibility › Spoken Content › Voices (L3) | unverified |
| `voice-langs` | Voice languages | same → `.language` | — · — | Languages you've downloaded voices for. | S | M | Partly (L3) | unverified |
| `voice-premium` | Downloaded enhanced voices | same → `.quality` (`.enhanced` / `.premium`) | — · — | Voices you chose to download, which suggests languages you use or accessibility needs. | S | M–H: personal choices | Partly (L3) | unverified |
| `voice-list` | Full voice list | same → `name`, `language`, `gender`, `quality` | — · — | The whole set. | S | M | Partly (L3) | unverified |

### 1.13 App, account, graphics, cellular

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `app-build` | Our own build info | `Bundle.main.infoDictionary` (`CFBundleShortVersionString`, `CFBundleVersion`, `DTSDKName`) | — · — | The app's own version. Not about you; it's context. | I | L | n/a | n/a |
| `install-date` | App install date | `FileManager.url(for: .documentDirectory…)` → `.creationDateKey` | — · **FTS** | When *this* app was installed. | **I** | M | Yes: reinstall resets it (L3) | unverified |
| `icloud-token` | iCloud identity token (hashed) | `FileManager.default.ubiquityIdentityToken` (hash it; never show it raw) | — · — | An opaque token that stays the same while the same Apple Account is signed in with iCloud Drive on. It changes if you sign out. **unverified** whether it's per-developer and whether it needs the iCloud capability. | **A** | M–H | Partly: turn off iCloud Drive or sign out (heavy) (L3) | unverified |
| `storefront` | App Store country | StoreKit 2 `Storefront.current?.countryCode` | — · — | Your App Store country. **A VPN doesn't change it.** | A | L–M | Only Apple (change of country is a big step) (L4) | unverified |
| `gpu-name` | GPU name | `MTLCreateSystemDefaultDevice()?.name` | — · — | e.g. "Apple A18 Pro GPU" → chip. | HW | L | Only Apple | unverified |
| `gpu-mem` | GPU working set | `MTLDevice.recommendedMaxWorkingSetSize` | — · — | Tracks the RAM tier. | HW | L | Only Apple | unverified |
| `gpu-rt` | Ray tracing | `MTLDevice.supportsRaytracing` | — · — | Chip generation. | HW | L | Only Apple | unverified |
| `gpu-families` | GPU families | `MTLDevice.supportsFamily(.apple1…apple9, .common1-3, .metal3)` | — · — | Chip generation. | HW | L | Only Apple | unverified |
| `sim-count` | Active cellular plans | `CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology?.count` | — · — | Number of active SIM/eSIM services (dual SIM stands out). Carrier name and country codes have returned placeholders since iOS 16 (`CTCarrier` is deprecated). | S | L–M | Partly: remove unused eSIMs (L3) | unverified |
| `radio-tech` | Radio technology per plan | same → values (`…LTE`, `…NR`, `…NRNSA`) | — · — | 4G/5G per service. | C | L | n/a | unverified |

---

## 2. Advanced (clever use of public APIs)

| id | Signal | API | Perm · RRA | What it reveals · legitimate use | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|---|
| `apps-detected` | Installed apps (probe) | `UIApplication.shared.canOpenURL(URL("scheme://"))` for each scheme listed in `LSApplicationQueriesSchemes` | — · — | Whether specific apps are installed: messaging, dating, banking, VPN, password managers. Meant for "open in app X" buttons. | S (until you delete the app) | **H**: drives sensitive inferences (§3) | Only Apple (L4). Partly: delete apps you no longer use (L3) | **Changed**: the declared list is capped at **25** for apps linked on the iOS 27 SDK (50 before). **unverified:** whether apps hidden with iOS 18 "Hide and Require Face ID" still answer `true` |
| `apps-missing` | Apps not installed | same (negative results) | — · — | The complement. Absence also informs. | S | M | Only Apple | as above |
| `web-ua` | Web user agent | `WKWebView.evaluateJavaScript("navigator.userAgent")` | — · — | iOS version as the web sees it. | Until you update | L | Only Apple | unverified |
| `web-platform` | Web platform | `navigator.platform` | — · — | "iPhone". | HW | L | Only Apple | unverified |
| `web-langs` | Web languages | `navigator.languages` | — · — | Language list exposed to JavaScript. | S | M | Partly: as `languages` | unverified |
| `web-cores` | Web core count | `navigator.hardwareConcurrency` | — · — | Core count as JavaScript sees it (WebKit may cap it; **unverified**). | HW | L | Only Apple | unverified |
| `web-memory` | Web device memory | `navigator.deviceMemory` | — · — | Usually undefined in WebKit. Shown for completeness. | — | L | n/a | unverified |
| `web-tz` | Web time-zone offset | `new Date().getTimezoneOffset()` | — · — | UTC offset. | C | L–M | Partly | unverified |
| `web-screen` | Web screen | `screen.width/height`, `devicePixelRatio`, `screen.colorDepth` | — · — | Screen geometry. | HW | L | Only Apple | unverified |
| `web-canvas` | Canvas fingerprint | Draw text and shapes on a `<canvas>`, hash `toDataURL()` | — · — | Rendering differences between GPU and OS builds. On iPhones it mostly separates model/OS combinations. Safari's fingerprinting protection adds noise; **unverified** whether that applies inside third-party `WKWebView`s on iOS 26. | Until you update | L–M | Only Apple | unverified |
| `web-webgl` | WebGL renderer | `WEBGL_debug_renderer_info` → `UNMASKED_VENDOR_WEBGL` / `UNMASKED_RENDERER_WEBGL` | — · — | GPU vendor/renderer string (WebKit usually returns a generic "Apple GPU"). | HW | L | Only Apple | unverified |
| `reinstall-count` | Reinstall counter | Keychain: `SecItemAdd`/`SecItemCopyMatching` with `kSecClassGenericPassword`, plus a `UserDefaults` "already recorded" flag | — · **UD** (the flag) | **Keychain items survive deleting the app.** An app can count how often you've reinstalled it and recognise you after a reinstall. | **E** (`…ThisDeviceOnly` items aren't restored to a new phone; synchronisable items can follow your Apple Account) | **H**: defeats "delete and reinstall" | Only Apple (only Erase All Content and Settings clears it) (L4) | unverified |
| `first-install` | First install date | same log | — · UD | When you first installed it, even after deletions. | E | H | Only Apple | unverified |
| `current-install` | Current install date | same log | — · UD | Start of the current install. | I | M | — | unverified |
| `install-history` | Install history | same log | — · UD | Every install timestamp. | E | H | Only Apple | unverified |

---

## 3. Needs permission

General fix: Settings › Privacy & Security › [category] › [app], or Settings › Apps › [app]. Our
app can only open its own Settings page officially (`UIApplication.openSettingsURLString`), so
fixes for other apps are guided steps (L3).

### 3.1 Motion & Fitness: `NSMotionUsageDescription`

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `activity` | Current activity | `CMMotionActivityManager.queryActivityStarting(from:to:to:)` / `startActivityUpdates` | Stationary / walking / running / driving / cycling, with confidence. **The API can return up to 7 days of history.** | C | H: daily routine and commute | Yes: Settings › Privacy & Security › Motion & Fitness (per app, or turn off Fitness Tracking) (L3) | unverified |
| `pressure` | Air pressure | `CMAltimeter.startRelativeAltitudeUpdates` → `pressure` | Barometric pressure, which hints at weather and altitude. | C | M | Yes: as above | unverified |
| `rel-altitude` | Relative altitude | same → `relativeAltitude` | Height change, such as floors climbed. | C | M | Yes | unverified |
| `abs-altitude` | Absolute altitude | `CMAltimeter.startAbsoluteAltitudeUpdates` → `altitude`, `accuracy`, `precision` | Height above sea level (3 values). | C | M–H | Yes | unverified |
| `steps` | Steps today | `CMPedometer.queryPedometerData(from:to:)` → `numberOfSteps` (up to 7 days back) | Activity level. | C | M | Yes | unverified |
| `distance` | Distance today | → `distance` | Distance travelled. | C | M | Yes | unverified |
| `floors-up` / `floors-down` | Floors | → `floorsAscended` / `floorsDescended` | Building and stairs habits (2 signals). | C | M | Yes | unverified |
| `pace` / `cadence` / `avg-pace` | Pace and cadence | → `currentPace`, `currentCadence`, `averageActivePace` | Fitness and gait (3 signals). | C | M | Yes | unverified |

### 3.2 Location: `NSLocationWhenInUseUsageDescription`

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `loc-auth` | Location permission state | `CLLocationManager.authorizationStatus` (readable **before** you're asked) | Whether you allowed, denied or haven't decided. | S | L | — | unverified |
| `loc-precise` | Precise vs approximate | `accuracyAuthorization` | Whether Precise Location is on. | S | L | Yes: turn off Precise Location for apps that don't need it (L3) | unverified |
| `coordinate` | Coordinates | `requestLocation()` / `startUpdatingLocation()` → `coordinate` | Where you are, to a few metres. | C | **H** | Yes: Settings › Privacy & Security › Location Services › [app] › Never/While Using; Precise off (L3) | unverified |
| `altitude` | Altitude | → `altitude` | Height, sometimes down to the floor. | C | M–H | Yes | unverified |
| `h-acc` / `v-acc` | Accuracy | → `horizontalAccuracy`, `verticalAccuracy` | Precision of the fix (2 signals). | C | L | — | unverified |
| `floor` | Floor | → `floor?.level` | Building floor, where mapped. | C | M | Yes | unverified |
| `speed` | Speed | → `speed` | Driving, walking. | C | M | Yes | unverified |
| `course` | Direction of travel | → `course` | Heading while moving. | C | L–M | Yes | unverified |

### 3.3 Camera: `NSCameraUsageDescription`

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `cam-count` | Camera count | `AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInTripleCamera, .builtInTrueDepthCamera, .builtInLiDARDepthCamera, .external, .continuityCamera], mediaType: .video, position: .unspecified).devices` | Lens line-up (Pro vs non-Pro). **unverified:** listing devices may work *without* camera permission; only capture needs it. Test. | HW | L | Only Apple | unverified |
| `cam-type` | Each camera's type and field of view | `device.localizedName`, `.position`, `formats.first?.videoFieldOfView` | Model detail. | HW | L | Only Apple | unverified |
| `cam-uid` | Each camera's unique ID | `device.uniqueID` | On iOS this looks like a fixed string per camera type, not per phone. **unverified**. | HW | L | — | unverified |

### 3.4 Bluetooth: `NSBluetoothAlwaysUsageDescription`

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `ble-scan` | Nearby Bluetooth devices | `CBCentralManager.scanForPeripherals(withServices: nil)` → `peripheral.name` / `CBAdvertisementDataLocalNameKey`, `RSSI` | Headphones, watches, TVs, cars and trackers nearby, often **with owners' names**. Reveals your household and also places. | C | **H** | Yes: Settings › Privacy & Security › Bluetooth (L3). Also rename your own devices | unverified |

### 3.5 Local Network: `NSLocalNetworkUsageDescription` + every type listed in `NSBonjourServices`

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `bonjour` | Devices on your Wi-Fi | `NWBrowser(for: .bonjour(type:domain:nil), using: params)` with `includePeerToPeer = true`, ~1 s per type, over ~44 service types (AirPlay, RAOP, companion-link, HomeKit/HAP, Matter, Google Cast, Spotify Connect, Sonos, Roku, printers/IPP/scanners, SMB/AFP/NFS/FTP/SFTP/SSH/WebDAV, VNC/RDP, Hue, MQTT, CoAP, Wemo, SIP, H.323, device-info, sleep-proxy…) | Named speakers, TVs, printers, Macs ("Jane's MacBook Pro") and smart-home hubs. An inventory that's often unique to one home. | C (per network) | **H** | Yes: Settings › Privacy & Security › Local Network (L3). Rename devices to avoid your name | unverified |

### 3.6 Contacts: `NSContactsUsageDescription`

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `contact-containers` | Contact accounts | `CNContactStore.containers(matching: nil)` | Number of contact sources (iCloud, Exchange, Google). | S | M | Yes: Settings › Privacy & Security › Contacts; choose **Limited Access** (iOS 18+) (L3) | unverified |
| `contact-count` | Contact count | `enumerateContacts(with: CNContactFetchRequest)` | Size of your social circle. | C | M | Yes | unverified |
| `contact-phones` | Phone number count | keys `CNContactPhoneNumbersKey` | — | C | M | Yes | unverified |
| `contact-emails` | Email count | `CNContactEmailAddressesKey` | — | C | M | Yes | unverified |
| `contact-postal` | Postal address count | `CNContactPostalAddressesKey` | — | C | M | Yes | unverified |
| `contact-labels` | Phone label mix | `CNLabeledValue.label` → `localizedString(forLabel:)` | Custom labels such as "Mum" or "Work" hint at relationships. | C | M–H | Yes | unverified |

Note: with full access, the same API returns **all names, numbers, addresses and photos**. We only
show counts, but our explanation should say what's possible.

### 3.7 Photos: `NSPhotoLibraryUsageDescription`

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `geo-count` | Geotagged items | `PHAsset.fetchAssets(with: PHFetchOptions)` → `asset.location` | How many photos carry GPS coordinates. | C | M | Yes: Settings › Privacy & Security › Location Services › Camera › Never (stops new geotags); turn off "Location" in the share sheet's Options (L3) | unverified |
| `geo-recent` | Recent places | cluster `asset.location` on a ~1 km grid, newest first | Where you've been lately. | C | **H** | Yes: choose **Limited Access** or None for apps (L3) | unverified |
| `geo-frequent` | Frequent places | same, by count | **Likely home and work.** | C | **H** | Yes | unverified |
| `photo-count` / `video-count` / `audio-count` | Library counts | `PHAsset.fetchAssets(with: .image/.video/.audio, options: nil).count` | Library size (3 signals). | C | L–M | Yes | unverified |
| `albums-user` / `albums-smart` / `albums-shared` | Album counts | `PHAssetCollection.fetchAssetCollections(with: .album/.smartAlbum, subtype: .albumRegular/.any/.albumCloudShared)` | Organisation habits; shared albums imply family or friends (3 signals). | C | L–M | Yes | unverified |

**Design warning:** the reference app turns coordinates into place names with `CLGeocoder`, which
**sends coordinates to Apple's servers** (and `CLGeocoder` may be deprecated in iOS 26 in favour
of MapKit; **unverified**). That breaks our "nothing leaves the phone" rule. Use an offline
approach instead: on-device clustering plus a bundled coarse city list, or show distances only.

### 3.8 Calendars: `NSCalendarsFullAccessUsageDescription` (iOS 17+)

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `cal-count` | Calendar count | `EKEventStore().calendars(for: .event).count` | — | S | L–M | Yes: Settings › Privacy & Security › Calendars; prefer **Add Events Only** (L3) | unverified |
| `cal-source-count` | Account count | `Set(calendars.map(\.source.title))` | — | S | M | Yes | unverified |
| `cal-sources` | Account names | `source.title` | Providers you use. Titles are often **email addresses or employer domains**. | S | **H** | Yes | unverified |
| `cal-types` | Calendar types | `calendar.type` (local / calDAV / exchange / subscription / birthday) | Exchange hints at work; subscriptions hint at interests (sports, holidays). | S | M | Yes | unverified |
| `cal-events` | Events in ±30 days | `events(matching: predicateForEvents(withStart:end:calendars:))` | How busy you are. With full access the titles, places and attendees are readable too. | C | M–H | Yes | unverified |

### 3.9 Reminders: `NSRemindersFullAccessUsageDescription`

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `rem-lists` | List count | `calendars(for: .reminder).count` | — | S | L | Yes: Settings › Privacy & Security › Reminders (L3) | unverified |
| `rem-titles` | List names | `calendar.title` | Names like "Pharmacy", "Baby" or "Visa application" can be revealing. | S | M–H | Yes | unverified |
| `rem-open` | Open reminders | `fetchReminders(matching: predicateForIncompleteReminders(…))` | Count. | C | L | Yes | unverified |

### 3.10 Media & Apple Music: `NSAppleMusicUsageDescription`

| id | Signal | API | What it reveals | Persist | Sev | Fix | iOS 27 |
|---|---|---|---|---|---|---|---|
| `songs` / `albums` / `playlists` / `artists` | Library counts | `MPMediaQuery.songs().items`, `.albums()/.playlists()/.artists().collections` | Library size (4 signals). | C | L–M | Yes: Settings › Privacy & Security › Media & Apple Music (L3) | unverified |
| `top-genres` | Top genres | count `MPMediaItem.genre` | Taste, which can hint at age, culture or religion. | C | M | Yes | unverified |
| `top-artists` | Top artists | count `MPMediaItem.artist` | Taste profile. | C | M | Yes | unverified |
| `recent-adds` | Added in last 30 days | `MPMediaItem.dateAdded` | Recent activity. | C | L | Yes | unverified |
| `music-sub` | Apple Music status | `SKCloudServiceController().requestCapabilities` → `.musicCatalogPlayback`, `.musicCatalogSubscriptionEligible`, `.addToCloudMusicLibrary` | Whether you subscribe, which signals spending power. | S | L–M | Yes | unverified |

### Signal count

| Group | Rows (counting each row in the tables; paired ids count separately) |
|---|---|
| Passive | 6 + 6 + 3 + 6 + 9 + 6 + 7 + 9 + 6 + 9 + 7 + 6 + 10 = **90** |
| Advanced | 2 app probe + 9 WebView + 4 reinstall log = **15** |
| Needs permission | 13 motion + 9 location + 3 camera + 1 Bluetooth + 1 Bonjour + 6 contacts + 9 photos + 5 calendar + 3 reminders + 8 music = **58** |
| **Total** | **163** distinct signals on iOS (plus 2 macOS-only audio signals that are excluded) |

---

## 4. Gaps: what the reference does **not** cover

Everything below is readable by an iOS 26 app, either passively or after a prompt. "Show?" is our
recommendation. **Demo** means we request the permission on demand to show the user. **Explain**
means we describe it without requesting it.

### 4.1 Passive gaps (no prompt), worth adding

| Area | API | Perm | What it reveals | Show? | App Review risk |
|---|---|---|---|---|---|
| Passcode / Face ID set up | `LAContext().canEvaluatePolicy(.deviceOwnerAuthentication…)`, `.biometryType` | — (`NSFaceIDUsageDescription` only needed to *use* Face ID) | Whether a **passcode is set**, and Face ID vs Touch ID vs none | **Yes**: also a security tip | Low |
| Apple Pay set up | `PKPaymentAuthorizationController.canMakePayments()` / `canMakePayments(usingNetworks:)` | — | Whether Wallet has cards, and which networks | Yes | Low |
| Mail / Messages set up | `MFMailComposeViewController.canSendMail()`, `MFMessageComposeViewController.canSendText()` | — | Whether the Mail app has an account | Yes | Low |
| Phone call in progress | `CXCallObserver().calls` | — | Whether you're on a call right now | Yes | Low |
| Notifications choice | `UNUserNotificationCenter.current().notificationSettings()` | — | Our own notification state only | No (own app only) | — |
| Tracking permission state | `ATTrackingManager.trackingAuthorizationStatus` | — to read; `NSUserTrackingUsageDescription` to ask | Whether "Allow Apps to Request to Track" is off (status = denied/restricted) | **Yes**, with a fix: Settings › Privacy & Security › Tracking | Low (don't request unless we explain why; we don't track) |
| IDFA | `ASIdentifierManager.shared().advertisingIdentifier` | `NSUserTrackingUsageDescription` | All zeros unless tracking is allowed | **Explain** (show it's zeroed). Requesting ATT in a no-tracking app is a **High** review risk | High if requested |
| Region formats | `Locale.current.region`, `.measurementSystem`, `.currency`, temperature unit (`MeasurementFormatter`) | — | Region and custom formats; mismatches with language add entropy | Yes | Low |
| System uptime | `ProcessInfo.processInfo.systemUptime` | RRA **BOOT** | Same as boot time | Fold into `boot-time` | Low with a declared reason |
| OS build | `sysctlbyname("kern.osversion")` | — | Exact build number | Fold into `os-build-string` | Low |
| Screen recording / mirroring | `UIScreen.isCaptured` / `sceneCaptureState` | — | Screen being recorded or mirrored | Optional | Low |
| Device lock state | `UIApplication.isProtectedDataAvailable` | — | Locked / unlocked (in the background) | Explain | Low |
| Game controllers / keyboards | `GCController.controllers()`, `GCKeyboard.coalesced`, `GCMouse` | — | Connected controllers by **product name** | Optional | Low |
| Clipboard patterns | `UIPasteboard.detectPatterns(for: [.probableWebURL, .number, …])` | — | Whether the clipboard holds a URL/number/search term, **without the paste banner** | **Yes**: belongs with §1.9 | Low |
| App Store transaction | StoreKit 2 `AppTransaction.shared` → `originalPurchaseDate`, `originalAppVersion` | — | When **this Apple Account first got the app**. Survives reinstall and new phones | **Yes** (account-level persistence) | Low |
| iCloud account status | `CKContainer.default().accountStatus` | iCloud capability | Signed in to iCloud or not | Optional (needs entitlement) | Low |
| iCloud key-value store | `NSUbiquitousKeyValueStore` | iCloud capability | Lets an app keep an ID that **survives erase and follows you to new devices** | **Explain** (persistence technique) | Low |
| App Group container | `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` | App Groups entitlement | A developer's apps share files and an ID | Explain | — |
| DeviceCheck bits | `DCDevice.current.generateToken` + server | — | 2 bits per device per developer, kept by Apple. Survive reinstall (and, reportedly, erase: **unverified**) | **Explain** (persistence) | — (we have no server) |
| Managed device | `UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")` | RRA **UD** (AC6B.1) | Whether an MDM profile configures apps, i.e. a work phone | Yes | Low |
| Location Services master switch | `CLLocationManager.locationServicesEnabled()` | — | Location fully off | Yes | Low |
| Compass heading via CoreLocation | `CLLocationManager.startUpdatingHeading()` | — (**unverified**) | Heading | Covered by `heading` | Low |
| Personal Voice | `AVSpeechSynthesizer.requestPersonalVoiceAuthorization` | prompt | Whether you made a Personal Voice (accessibility) | Explain | Medium |
| Push registration | `UIApplication.shared.isRegisteredForRemoteNotifications` | — | Own app only | No | — |

### 4.2 Permission-gated gaps

| Area | API | Permission key / entitlement | What it reveals | Show? | App Review risk |
|---|---|---|---|---|---|
| Health | `HKHealthStore.requestAuthorization`, sample queries | `NSHealthShareUsageDescription` (+`NSHealthUpdateUsageDescription`), HealthKit entitlement | Steps, heart, sleep, cycles, medications, clinical records: **the most sensitive data on the phone**. Apps can't tell whether you denied *read* access | **Explain**, plus optional read-only demo of 1–2 non-clinical types | **High**: Guideline 5.1.3 expects a health purpose; no clinical records |
| HomeKit | `HMHomeManager` → homes, rooms, accessories | `NSHomeKitUsageDescription`, HomeKit entitlement | Home names (often the address), rooms ("Baby's room"), devices, cameras | Explain, optional demo | Medium–High (needs a home-related purpose) |
| Microphone | `AVAudioApplication.requestRecordPermission`, `AVAudioRecorder` | `NSMicrophoneUsageDescription` | Live audio. (The audio *route* is passive, see §1.6.) | Explain + permission state only; never record | Medium if we ask with no real use |
| Speech recognition | `SFSpeechRecognizer.requestAuthorization` | `NSSpeechRecognitionUsageDescription` (+mic) | Transcripts; on-device or sent to Apple | Explain | Medium |
| Camera capture | `AVCaptureSession` | `NSCameraUsageDescription` | Live images (faces, rooms, documents) | Explain; keep §3.3 enumeration | Low (already requested) |
| Bluetooth advertising | `CBPeripheralManager` | `NSBluetoothAlwaysUsageDescription` | Lets an app act as a beacon for nearby tracking | Explain | Low |
| Beacons / Visits / Always location | `CLBeaconIdentityConstraint` ranging, `startMonitoringVisits()`, `requestAlwaysAuthorization` | `NSLocationAlwaysAndWhenInUseUsageDescription` | Background places, visits with arrival/departure times | Explain | **High** if we request Always with no need |
| Wi-Fi network name | `NEHotspotNetwork.fetchCurrent` | Access Wi-Fi Information entitlement **and** precise location (or a VPN/hotspot config) | Wi-Fi SSID/BSSID, which reveals place and household | **Demo** (we already need location) | Medium (entitlement must be justified) |
| Wi-Fi Aware (iOS 26) | `WiFiAware` framework | entitlement + pairing | Peer devices | Explain | Medium |
| Focus status | `INFocusStatusCenter.default.requestAuthorization` → `focusStatus.isFocused` | Communication Notifications capability, plus a prompt | Whether a Focus is on (not which) | Explain | Medium (capability must fit) |
| Siri | `INPreferences.requestSiriAuthorization` | `NSSiriUsageDescription`, Siri entitlement | Siri requests routed to the app | Explain | Medium |
| NFC | `NFCNDEFReaderSession` | `NFCReaderUsageDescription`, NFC entitlement | Tags only when you scan; not a passive leak | Explain only | Low |
| Nearby Interaction | `NISession` | `NSNearbyInteractionUsageDescription` | Distance/direction to a U1/UWB peer | Explain | Low |
| Screen Time | `FamilyControls` `AuthorizationCenter`, `DeviceActivity`, `ManagedSettings` | Family Controls entitlement (needs Apple's approval for distribution) | Usage reports render in a sandboxed extension, so apps can't extract raw data | Explain (it's privacy-preserving) | **High** (entitlement approval) |
| SharePlay | `GroupActivities` | — | Participants only when you start a session | Explain only | Low |
| Wallet passes | `PKPassLibrary().passes()` | Wallet entitlement; passes from **own team only** | Own passes only | Explain | Low |
| Files | `UIDocumentPickerViewController` | — | Only the files you pick | Explain (good model of consent) | Low |
| Photos picker | `PHPickerViewController` | — | Picked items only, but **embedded location stays** unless you turn it off in Options | **Yes**: a teachable moment | Low |
| Limited Contacts picker (iOS 18) | `ContactAccessPicker` | — | Only shared contacts | Explain | Low |
| Calendar write-only | `requestWriteOnlyAccessToEvents` | `NSCalendarsWriteOnlyAccessUsageDescription` | Nothing readable | Explain as the good option | Low |
| MusicKit history | `MusicAuthorization.request()`, `MusicRecentlyPlayedRequest` | `NSAppleMusicUsageDescription` | **Recently played** and recommendations (more revealing than library counts) | Demo (same key as §3.10) | Low |
| Declared Age Range (iOS 26) | `DeclaredAgeRange` framework | prompt each time | Your age band, if you or your parent shares it | Explain | Low |
| Accessory Setup Kit / Bluetooth accessories | `ASAccessorySession` | `NSAccessorySetupKit…` keys | Paired accessories you approve | Explain | Low |
| Push token | `registerForRemoteNotifications` | prompt for alerts | A per-app device token on the developer's server | Explain | — |

### 4.3 Things that are *not* possible on iOS 26 (say so plainly)
- Listing installed apps; reading another app's data; reading Safari history.
- Seeing **which other apps** hold a permission (see §6).
- Serial number, UDID, IMEI, MAC address (`02:00:00:00:00:00` since iOS 7), phone number, carrier
  name (placeholders since iOS 16).

---

## 5. Inference

### 5.1 What the reference draws (categories only)
From installed-app probes, with a threshold per category (some fire on a single app):
- **privacy-minded** (encrypted messaging, private email/VPN, password managers)
- **dating** (dating apps; note the group includes an LGBTQ+ app, which implies sexual orientation)
- **gaming**
- **developer / tech worker**
- **finance / investing / crypto**
- **self-improvement / learning**
- **owns a specific car brand**
- **heavy social-media user**
- a catch-all card for the other apps it found

Its summary screen also draws inferences from passive signals:
- **region**
- **languages** (from keyboards)
- **travel** (time zone doesn't match region)
- **setup/erase date** of the phone
- **likely first name** (from the audio accessory name, using name patterns in several languages)
- **customised regional formats** (calendar, clock, week start, units, currency, date/number style
  vs region defaults)
- **reading/vision hints**
- **Lockdown Mode**
- **clipboard activity**
- **uptime**

### 5.2 What we should do
Do all of the above, plus permission-based inferences, but with calm, conditional wording. Every
card shows its basis (which signals) and its fix.

| Inference | Basis | Suggested wording (ours) | Flag level |
|---|---|---|---|
| App-category profile | `apps-detected` (user picks categories, §SENSITIVE-APP-CATALOGUE) | "Any app could guess you might be into **gaming**, because it can see Steam and Twitch are installed." | Normal |
| Sensitive app categories (health, sexuality, religion, politics, money trouble, addiction recovery) | `apps-detected` | "Apps in this group can hint at something personal. A tracker could note that **[app]** is installed." Never state the trait as fact. | **Concerning** |
| Your first name | `audio-outputs`, `ble-scan`, `bonjour` names | "Your headphones are named 'Sam's AirPods', so apps can learn the name **Sam**." | **Concerning**, easy fix |
| Phone setup date | `volume-created` | "This iPhone was set up or erased on 3 March 2025 at 14:02:11. Few phones share that exact second." | **Concerning**, Only Apple |
| Recognised after reinstall | `reinstall-count`, `AppTransaction` | "Deleting an app doesn't make you a stranger to it." | Concerning |
| Travel / where you live | `timezone` vs region/storefront | "Your time zone suggests you're in Japan, but your region is UK." | Normal |
| Home and work | `geo-frequent`, `coordinate` | "Your photos point to two places you visit most. These are often home and work." | **Concerning** |
| Employer | `cal-sources`, `cal-types` (Exchange), managed device | "Your calendar accounts include a work domain." | Concerning |
| Household | `bonjour`, `ble-scan`, shared albums | "Your Wi-Fi shows 2 TVs, a baby monitor and 'Alex's iPad'." | Concerning |
| Languages / background | `languages`, `keyboards`, `voice-langs`, `calendar-system` | "You type in Arabic and English." Avoid any ethnicity or religion claim. | Normal (handle with care) |
| Accessibility needs | §1.8, `text-size` | "Apps can tell some accessibility features are on. They are there for you; we're only pointing it out." **No fix pushed.** | Normal, never alarming |
| Routine | `activity`, `steps`, `cal-events` | "Apps with Motion access can see you usually drive around 8am." | Concerning |
| Spending power | `music-sub`, Apple Pay, Pro model (`max-fps`, camera count), storage tier | "Your phone model and storage tier hint at a higher budget." | Normal |
| VPN / security posture | `vpn`, `lockdown-mode`, passcode check | "Apps can see you use a VPN. That's fine; it still hides your address." | Positive |

Rules: say "could guess" or "might" rather than "you are"; show the evidence; one clear next step;
don't stack scary cards. Keep inference on-device only.

---

## 6. Our app's own data needs and limits

- **iOS can't tell an app which *other* apps hold a permission.** For "which apps can see my
  Health / Location / Photos / Contacts / Bluetooth / Local Network…", we can only **guide the
  user through Settings**:
  - Settings › Privacy & Security › [category] lists the apps for most categories (Health:
    Settings › Health › Data Access & Devices; Bluetooth and Local Network have their own lists).
  - **Safety Check** (Settings › Privacy & Security › Safety Check › Manage Sharing & Access)
    reviews app permissions in one flow. It's the best target for a guided check-up.
  - **App Privacy Report** (Settings › Privacy & Security › App Privacy Report) shows which apps
    used location, camera, mic, contacts, photos and more, plus network domains, over 7 days. We
    should walk users through turning it on and reading it.
  - Location: Settings › Privacy & Security › Location Services › System Services and each app's
    "Precise Location".
- **We can only open our own Settings page officially** (`openSettingsURLString`). Other panes are
  guided steps, see `SETTINGS-LINKS.md`.
- **Our own permission requests:** ask only when the user taps "Show me" for that category, never
  at launch. Keys we'll need: `NSMotionUsageDescription`, `NSLocationWhenInUseUsageDescription`,
  `NSCameraUsageDescription` (if enumeration really needs it), `NSBluetoothAlwaysUsageDescription`,
  `NSLocalNetworkUsageDescription` + `NSBonjourServices` (every type listed),
  `NSContactsUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `NSCalendarsFullAccessUsageDescription`, `NSRemindersFullAccessUsageDescription`,
  `NSAppleMusicUsageDescription`. Optional, depending on what we demo: HealthKit, HomeKit, Wi-Fi
  Info entitlement. Don't add `NSMicrophoneUsageDescription` unless we use the mic (the reference
  declares it without a matching signal).
- **`LSApplicationQueriesSchemes`:** at most **25** (iOS 27 SDK). See `SENSITIVE-APP-CATALOGUE.md`.
- **Privacy manifest (`PrivacyInfo.xcprivacy`):** declare BOOT, DISK, KBD, FTS and UD with
  approved reasons. Reasons to check against Apple's current list (from memory, **unverified**):
  - DISK `85F4.1` (shown to the user) fits
  - FTS `C617.1` (inside the container) / `DDA9.1` (shown to the user) fit
  - UD `CA92.1` (own data) fits our own flags
  - KBD and BOOT have no obvious "show the user" reason. This is an **App Review risk**: prepare a
    review note or drop/redesign those two.
  - Reading `LDMGlobalEnabled` is undocumented. Treat it as optional and remove it if it's
    rejected.
- **Nothing leaves the phone:** no reverse geocoding, no IP lookup, no analytics. The App Privacy
  label is "Data Not Collected".
