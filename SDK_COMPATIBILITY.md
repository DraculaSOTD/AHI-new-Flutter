# SDK Compatibility Documentation

## Executive Summary

**Status**: Body scan ✅ works | Face scan ❌ does not work

This document explains the incompatibility between the Vastmindz face scanning SDK and the AHI body scanning SDK, and outlines potential solutions.

## The Problem: OpenCV Version Conflict

### Root Cause

Both SDKs use OpenCV for image processing but require **different, incompatible versions**:

| SDK | OpenCV Version | Native Libraries | Purpose |
|-----|----------------|------------------|---------|
| **AHI BodyScan** | 4.5.5 | `libcontourGenerator.so` | Body contour generation |
| **Vastmindz rPPG** | 4.1.2 | `librppg_core.so`, `librppg_bridge.so` | Vital sign extraction from facial video |

### Technical Details

When both SDKs are included in the same Android application:

1. **Symbol Collision**: Both OpenCV versions export identical C++ symbols (e.g., `_ZN2cv3MatC1Ev` for `cv::Mat` constructor)
2. **Single Namespace**: Android's native library loader uses a single global symbol table per process
3. **Undefined Behavior**: When `libcontourGenerator.so` (AHI) tries to call OpenCV 4.5.5 functions but finds OpenCV 4.1.2 symbols from Vastmindz libraries, it crashes:
   ```
   UnsatisfiedLinkError: dlopen failed: cannot locate symbol "_ZN2cv3MatC1Ev"
   referenced by "/data/app/.../libcontourGenerator.so"
   ```

## Current State

### What Works ✅

- **Body Scan**: Fully functional with accurate measurements
- **App Stability**: No crashes during normal operation
- **Face Detection**: ML Kit successfully detects faces and facial landmarks

### What Doesn't Work ❌

- **Face Scan Vital Signs**: Cannot extract heart rate, respiratory rate, or other rPPG-based metrics
- **Reason**: Native rPPG processing requires `librppg_core.so` and `librppg_bridge.so`, which are excluded to prevent OpenCV conflicts

### Technical Flow (Current)

```
Camera Image
    ↓
ML Kit Face Detection (Java only) ✅ Works
    ↓
Face Landmarks Extracted ✅ Works
    ↓
FaceData object created ✅ Works
    ↓
sendFaceData() called ✅ Works
    ↓
coreManager.track() → ❌ SKIPPED (native libs not available)
    ↓
socketManager.update() → ❌ NEVER CALLED (no BGR signal data)
    ↓
WebSocket Server → ⏱️ TIMEOUT (receives no data, returns zeros)
```

## Solutions Evaluated

### ✅ Solution 1: Current Implementation (Safe Degradation)
**Status**: Implemented
**Complexity**: Low
**Timeline**: Complete

**What it does:**
- Detects when native libraries are unavailable
- Prevents crashes by skipping `coreManager.track()` calls
- Logs clear warnings about OpenCV conflicts
- Body scan works perfectly

**Limitations:**
- Face scan does not provide vital signs
- Cannot be fixed without external changes (see solutions below)

**Files Modified:**
- `vastmindz_sdk/android/src/main/kotlin/com/example/rppg_common/Analysis.kt:480-497`
- `ahi_bodyscan_flutter/android/app/build.gradle.kts:163-169` (documentation)

---

### ⚠️ Solution 2: Contact Vastmindz for OpenCV 4.5.5 Compatible SDK
**Status**: Recommended next step
**Complexity**: External dependency
**Timeline**: Unknown (vendor dependent)

**What to request:**
1. Rebuilt `librppg_core.so` and `librppg_bridge.so` against OpenCV 4.5.5
2. Or: Server-side-only SDK version that doesn't require native libraries
3. Or: Guidance on OpenCV version migration

**Contact Information:**
- SDK Provider: Vastmindz (rppg-core-0.2.0.aar)
- Check SDK documentation for support channels
- Reference ticket: OpenCV 4.1.2 vs 4.5.5 incompatibility with AHI SDK

---

### ⚠️ Solution 3: Multi-Process Architecture
**Status**: Not recommended
**Complexity**: Very High
**Timeline**: 2-3 weeks

**Approach:**
- Run face scan in separate Android process (`:face_scan_process`)
- Isolated native library namespace prevents conflicts
- IPC (Inter-Process Communication) for data exchange

**Why Not Recommended:**
- Camera session cannot be shared across processes
- Requires complex SurfaceView/TextureView sharing
- High memory overhead (2+ processes)
- Flutter architecture not designed for multi-process
- Extremely difficult debugging

**Implementation Complexity:**
- 4-5 new files (Service, IPC handlers, AIDL)
- 300-500 lines of code
- Significant Flutter plugin architecture changes

---

### ❌ Solution 4: Recompile Vastmindz SDK
**Status**: Not feasible
**Complexity**: Very High
**Timeline**: N/A

**Why Not Feasible:**
- Proprietary SDK - source code unavailable
- Legal/licensing concerns
- Would require C++ build environment matching vendor's setup
- No warranty/support after modifications
- OpenCV API changes between 4.1.2 and 4.5.5 may break functionality

---

### ❌ Solution 5: Downgrade AHI SDK to OpenCV 4.1.2
**Status**: Not feasible
**Complexity**: Impossible
**Timeline**: N/A

**Why Impossible:**
- AHI SDK distributed as compiled AAR from Maven Central
- No source code access
- OpenCV 4.5.5 likely required for specific features
- Would require vendor cooperation

---

### ⚠️ Solution 6: Alternative Face Scan SDK
**Status**: Fallback option
**Complexity**: Very High
**Timeline**: 1-3 months

**Potential Alternatives:**

1. **Binah.ai** (Cloud-based rPPG)
   - Pros: Cloud processing, no native libs, production-ready
   - Cons: Subscription cost, internet dependency, privacy concerns

2. **Anura.ai** (rPPG SaaS)
   - Pros: High accuracy, no OpenCV conflicts
   - Cons: Commercial license, API limits

3. **Custom TensorFlow Lite Implementation**
   - Pros: Full control, uses TFLite (not OpenCV)
   - Cons: Months of development, accuracy validation needed

4. **Google ML Kit + Custom rPPG**
   - Pros: Face detection already implemented
   - Cons: Still requires OpenCV or custom signal processing

**Implementation Effort:**
- Complete rewrite of face scan feature
- New API integration and authentication
- Accuracy validation and calibration
- Different pricing/licensing model

---

### ⚠️ Solution 7: Symbol Renaming (Advanced)
**Status**: Not recommended
**Complexity**: Very High
**Timeline**: 1-2 weeks
**Risk**: High

**Approach:**
Use `objcopy` to rename OpenCV symbols in one SDK:
```bash
objcopy --redefine-sym _ZN2cv3MatC1Ev=_ZN2cv3MatC1Ev_v412 \
        librppg_core.so librppg_core_renamed.so
```

**Challenges:**
- Must rename ALL conflicting symbols (hundreds+)
- Must rename in both `librppg_core.so` and `librppg_bridge.so`
- Breaks digital signatures
- Fragile - breaks with any SDK update
- May violate SDK licensing terms
- No vendor support after modification

**Why Not Recommended:**
- High risk of symbol table corruption
- Extremely difficult to maintain
- Unknown legal implications
- Would need automation for every SDK update

---

## Recommendation

### Immediate Action
✅ **Current implementation (Solution 1)** is deployed and working:
- Body scan fully functional
- No crashes
- Clear logging of face scan limitations

### Next Steps (Prioritized)

1. **Contact Vastmindz Support** (Solution 2)
   - Request OpenCV 4.5.5 compatible version
   - Or request server-side-only SDK
   - Timeline: 1-2 weeks for response, unknown for implementation

2. **If Vastmindz Cannot Help**:
   - Evaluate alternative face scan SDKs (Solution 6)
   - Consider Binah.ai or Anura.ai for production
   - Budget: ~$2000-5000/year for commercial rPPG service

3. **Long-term Architecture Decision**:
   - If both features required: Use different SDKs with compatible dependencies
   - If face scan optional: Ship with body scan only, add face scan later
   - If face scan critical: Replace Vastmindz with alternative solution

## Technical Reference

### File Locations

**Build Configuration:**
- `ahi_bodyscan_flutter/android/app/build.gradle.kts` - Native library exclusions (lines 97-108)
- `vastmindz_sdk/android/build.gradle` - Native library exclusions (lines 118-127)

**Source Code:**
- `vastmindz_sdk/android/src/main/kotlin/com/example/rppg_common/Analysis.kt` - Face data handling with graceful degradation (lines 480-497)

**Documentation:**
- `SDK_COMPATIBILITY.md` (this file)
- Inline comments in `build.gradle.kts` explaining OpenCV conflicts

### Log Messages to Monitor

**Success (Native libs available):**
```
D/Analysis: Native RppgCore initialized successfully
```

**Expected (No native libs - current state):**
```
W/Analysis: Native libraries not available - using server-side processing only
W/Analysis: Cannot send face data: native rPPG libraries not available (OpenCV conflict with AHI SDK)
```

**Failure (OpenCV conflict):**
```
E/AndroidRuntime: FATAL EXCEPTION: main
E/AndroidRuntime: java.lang.UnsatisfiedLinkError: dlopen failed: cannot locate symbol "_ZN2cv3MatC1Ev"
```

## Conclusion

The OpenCV version conflict between Vastmindz and AHI SDKs is a **fundamental architectural incompatibility**. The current implementation prioritizes **stability and body scan functionality** while providing **safe degradation** for face scan.

**Achieving both features requires external changes**:
- Vastmindz SDK update (preferred)
- Alternative face scan solution (fallback)
- Or architectural changes (not recommended)

**Current Status**: Production-ready for body scanning, face scanning disabled.

---

*Last Updated: 2026-03-06*
*Document Version: 1.0*
