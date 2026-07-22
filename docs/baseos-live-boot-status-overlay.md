# BaseOS Live Boot Status Overlay

| Field | Value |
| --- | --- |
| Status | Draft — human review required |
| Provenance | Manual |
| Target | BaseOS Android 14 product image for BraX3 (MT6835) |
| Product repository | `device/braxos` |
| Priority | High |
| Date | 2026-07-22 |
| Implementation state | Not started |
| Design reference | User-provided terminal-style BaseOS boot mockup; the layout contract is reproduced below so the temporary image is not the only source of truth |

## 1. Summary

BaseOS shall replace the opaque boot animation with an optional terminal-style status overlay that displays a small, curated set of truthful Android boot milestones and a monotonic progress bar.

The overlay begins only after SurfaceFlinger has created a display surface and launched `bootanimation`. Events that happened before that point may appear only as completed historical facts that can be proven by the running system. The product must never imply that it is live-rendering bootloader or kernel output while those components are still executing.

This feature is a status renderer, not a log viewer. Production builds must not give `bootanimation` access to logcat, the kernel log, debugfs, device identifiers, or arbitrary system text.

## 2. Problem

The current animation provides little diagnostic value. When a device boots slowly or appears stuck, an engineer cannot see whether Android reached storage setup, APEX activation, the runtime, core services, or SystemUI. The resulting troubleshooting loop requires a cable, a host computer, and a separate log capture.

The supplied design communicates progress well, but several example messages are not technically honest:

- `loading kernel` cannot be live when Android's userspace boot animation is already rendering;
- `unlocking bootloader` is not part of a normal boot and must never be shown as progress;
- `mounting N modules` and `adb bridge ready` must not be shown unless an authoritative producer reports those exact facts;
- a shell prompt must not suggest that an interactive privileged shell exists.

The feature must preserve the visual concept while correcting those semantics.

## 3. Goals

1. Show the latest completed and pending high-level boot milestones without requiring ADB.
2. Make a stalled phase identifiable from the device screen.
3. Preserve the BaseOS dark terminal visual language shown in the reference.
4. Keep all user-build text curated, bounded, deterministic, and free of device or user data.
5. Add no dependency that can block Android boot or delay dismissal of the animation.
6. Degrade to the existing boot animation when status data or assets are unavailable.
7. Reuse Android's existing `service.bootanim.progress` transport in version 1 instead of introducing a general-purpose logging channel.

## 4. Non-goals

- Rendering live preloader, bootloader, verified-boot, or kernel logs.
- Reading or displaying `logcat`, `dmesg`, pstore, tombstones, SELinux denials, or arbitrary service output.
- Providing an interactive terminal, ADB shell, recovery console, or touch controls.
- Changing bootloader lock state, AVB policy, encryption, factory mode, serial numbers, IMEIs, or other device identity data.
- Diagnosing a failure that occurs before SurfaceFlinger and `bootanimation` can render. Bootloader/recovery graphics remain separate future work.
- Localizing diagnostic strings in version 1. Version 1 uses reviewed printable ASCII strings so rendering is deterministic before Android resources are available.
- Reporting component health that has no authoritative readiness signal. “Started” and “ready” must not be used interchangeably.

## 5. User stories

- As a BaseOS engineer, I can identify the last reached Android boot phase by looking at a stalled device.
- As a device owner, I see a polished and accurate explanation of boot progress rather than fictional console output.
- As a security reviewer, I can prove that the renderer accepts only numeric progress and trusted, build-time text.
- As a release engineer, I can disable the overlay by omitting its configuration asset without maintaining a second `bootanimation` binary.

## 6. Boot-phase boundary

```text
Boot ROM -> preloader -> bootloader/AVB -> kernel -> init
                                                |
                                                v
                                      SurfaceFlinger ready
                                                |
                                                v
                                      bootanimation starts
                                                |
                           live overlay can begin here only
                                                |
                      zygote -> system_server -> SystemUI -> boot complete
```

Required behavior:

- Before the first rendered frame, no live on-screen status is possible through Android `bootanimation`.
- Once rendering starts, the overlay may show `kernel userspace active`, `system image available`, and `display compositor ready` as completed facts because those conditions are prerequisites of the running binary and surface.
- The overlay must not animate a prior phase as if it is currently executing.
- An unlocked or non-green verified-boot state must never be presented as “verified” or “locked.” Version 1 omits bootloader security state rather than granting the renderer broad property access.

## 7. Experience and visual contract

### 7.1 Reference composition

```text
  [BaseOS wordmark]

  [ ok ] kernel userspace active
  [ ok ] system image available
  [ ok ] display compositor ready
  [ ok ] device storage ready
  [ .. ] activating APEX packages
  [wait] activating APEX packages (only after the stall threshold)
          ...

  baseos@boot:~$ _

  ====================================---------  progress
```

The composition shall match the reference's visual hierarchy, spacing, dark background, monospaced status text, and orange accent. It must not copy the reference's placeholder messages when they are not supported by real signals.

### 7.2 Required elements

1. Approved BaseOS wordmark near the top safe area.
2. A status history containing completed milestones and one current milestone.
3. A non-interactive footer styled as `baseos@boot:~$ _`.
4. A progress bar near the bottom safe area.
5. No percentages are required in the primary design; the bar is sufficient.

The footer is decorative. It must not accept input, expose a shell, launch a service, or blink faster than once per second.

### 7.3 Status prefixes

| Prefix | Meaning | Color token |
| --- | --- | --- |
| `[ ok ]` | Authoritatively completed | Success green |
| `[ .. ]` | Next milestone is pending | Active amber |
| `[wait]` | The pending milestone has not advanced for 8 seconds | Active amber |
| `[warn]` | A build-safe, authoritative warning | Warning orange |
| `[boot]` | Boot completion was received before animation exit | BaseOS orange |

Color is supplemental. The text prefix must communicate state without color.

Version 1 does not infer `[fail]`. A future authoritative error channel may add it under a separate reviewed contract.

### 7.4 History and motion

- A milestone is added once and must never be duplicated.
- The renderer retains at most 9 visible lines on a phone display.
- When more lines exist, it scrolls the oldest unpinned line out and keeps the newest pending line visible.
- Progress may move forward only. A lower or malformed input is ignored for the rest of that `bootanimation` process.
- Progress interpolation must be time-based and must not call `sleep` or `usleep` in the rendering path.
- The overlay must not flash, pulse, or change color more than three times per second.

### 7.5 Layout

- Respect display cutouts, rounded corners, overscan, and the animation canvas dimensions.
- Use proportional anchors so the same assets work on supported portrait resolutions.
- Minimum horizontal safe margin: 5 percent of canvas width.
- Wordmark region: top 8–18 percent.
- Status region: top 22–66 percent.
- Footer baseline: 86–90 percent.
- Progress bar: 92–95 percent.
- Text must be clipped within the safe region; it must never wrap into a second line.
- If a configured string does not fit, truncate it with `...`; do not reduce text below the approved minimum size.
- Landscape and unusual aspect ratios may use the ordinary animation fallback if the status layout cannot satisfy the minimum dimensions.

### 7.6 Branding decision

The approved mockup and this requirement use the visible name `BaseOS`. The current product makefile identifies the product and brand as `BraxOS`. Before approval, the product owner must resolve that naming mismatch. The renderer must consume a product-supplied wordmark asset and must not hard-code either wordmark into generic AOSP C++.

## 8. Functional architecture

### 8.1 Architectural decision

Version 1 uses a numeric, monotonic milestone value carried by Android's existing exact-integer property:

```text
service.bootanim.progress = 0..100
```

The same value drives both the progress bar and the milestone table. Human-readable text comes only from a trusted configuration packaged inside the read-only boot animation ZIP. Runtime producers cannot submit text.

This keeps the trust boundary small:

```text
authoritative platform event
          |
          v
bounded numeric progress property
          |
          v
bootanimation maps value through trusted status table
          |
          v
fixed text + progress rendered on SurfaceFlinger surface
```

### 8.2 Existing behavior to preserve

The Android 14 source already:

- defines `service.bootanim.progress` as an exact integer property;
- resets it to `0` in SurfaceFlinger before starting `bootanimation`;
- permits `system_server` and `bootanimation` to set the `bootanim_system_prop` type;
- enables progress only when the first line of `desc.txt` has a nonzero fourth field;
- renders progress only during the last animation part.

The BaseOS implementation must remain compatible with a boot animation ZIP that has no status table.

### 8.3 Asset contract

The BaseOS boot animation ZIP shall contain:

- the existing `desc.txt`, with the fourth top-line field set to `1`;
- normal animation parts and image assets;
- a reviewed monospaced printable-ASCII font asset;
- a BaseOS wordmark asset;
- `status.txt`, using the versioned grammar below.

`status.txt` grammar:

```text
version 1
max_visible 9
5|kernel userspace active
10|system image available
20|display compositor ready
30|device storage ready
40|APEX packages activated
50|Android runtime started
60|system server started
70|core system services ready
80|activity manager ready
90|applications may start
95|system interface ready
100|BaseOS ready
```

Parser requirements:

- Accept only `version 1`.
- Accept 1–16 milestone rows.
- Require strictly increasing integer thresholds from 1 through 100.
- Require a final threshold of 100.
- Accept printable ASCII `0x20` through `0x7e` only.
- Limit each label to 48 bytes after parsing.
- Reject duplicate thresholds, duplicate labels, unknown directives, embedded NULs, and malformed rows.
- Treat the whole status configuration as invalid if any row is invalid.
- On invalid or missing configuration, run the ordinary boot animation with no status overlay.

### 8.4 Milestone semantics and ownership

The property value means “all configured milestones at or below this value have completed.” The first milestone above the value is rendered as pending. Producers must not skip a milestone whose label would then become a false claim.

| Value | Display after completion | Authoritative completion signal | Owner |
| ---: | --- | --- | --- |
| 5 | kernel userspace active | Inferred prerequisite of executing `/system/bin/bootanimation` | Renderer contract |
| 10 | system image available | The system binary and trusted animation ZIP have been loaded | `bootanimation` |
| 20 | display compositor ready | EGL surface is initialized and the first frame can be drawn | `bootanimation` |
| 30 | device storage ready | `post-fs-data` completed and device-encrypted storage required by core services is available | Platform `init` action |
| 40 | APEX packages activated | Existing authoritative APEXd-ready property/event | Platform `init` action |
| 50 | Android runtime started | Zygote service reached the platform-defined running state | Platform `init` action |
| 60 | system server started | `system_server` entered its initialization path | `system_server` |
| 70 | core system services ready | `SystemServiceManager.PHASE_SYSTEM_SERVICES_READY` completed | `system_server` |
| 80 | activity manager ready | `SystemServiceManager.PHASE_ACTIVITY_MANAGER_READY` completed | `system_server` |
| 90 | applications may start | `SystemServiceManager.PHASE_THIRD_PARTY_APPS_CAN_START` completed | `system_server` |
| 95 | system interface ready | SystemUI reports its defined first-ready milestone through an internal system-server API | SystemUI + `system_server` |
| 100 | BaseOS ready | `SystemServiceManager.PHASE_BOOT_COMPLETED` or the existing authoritative boot-completed path | `system_server` |

The exact setter locations may change during implementation review, but the semantic owners above may not be replaced with timers.

### 8.5 Writer rules

- SurfaceFlinger remains the reset owner and sets progress to `0` immediately before each animation start.
- `bootanimation` may advance the value from `0` to `20` only after the trusted ZIP has loaded and it can draw; this truthfully completes the three prerequisite rows at 5, 10, and 20.
- Platform `init` owns values 30–50.
- `system_server` owns values 60–100 and is the only property writer on behalf of SystemUI.
- Each writer must compare against or otherwise preserve monotonic progress; the renderer independently ignores regressions.
- No vendor app, ordinary system app, shell command in a user build, or network-delivered input may write the property.
- A producer failure must not block boot. Later boot phases may advance, but the implementation must not display a skipped milestone as completed unless the later phase logically proves it. Any proposed skip requires an explicit truth-table test.
- Progress values not listed in `status.txt` may move the bar but do not create a line.

### 8.6 Stall behavior

- Start a monotonic timer whenever the highest accepted progress value changes.
- Show the next line as `[ .. ]` for the first 8 seconds.
- Change only its prefix to `[wait]` after 8 seconds without progress.
- Do not display elapsed seconds, timestamps, estimates, or a failure claim.
- Return to ordinary pending/completed rendering immediately when progress advances.
- The timer is visual only and must never trigger a reboot, service restart, property write, or boot delay.

### 8.7 Exit behavior

- Existing `service.bootanim.exit` behavior remains authoritative.
- The overlay must exit immediately when requested, even if progress is below 100.
- If progress reaches 100 before exit, `[boot] BaseOS ready` may appear; no minimum display delay is allowed.
- A missing 100-percent frame is acceptable on a fast boot. Delaying Android to show it is not.

## 9. Build integration

- Generic parsing and rendering belong in the AOSP `bootanimation` implementation so the behavior is optional and asset-driven.
- BaseOS-specific assets and strings belong in the BaseOS product layer.
- The BaseOS product must package its own boot animation ZIP rather than altering unrelated products.
- Presence of a valid `status.txt` enables the overlay. Absence is the build-time kill switch.
- The feature is intended for `user`, `userdebug`, and `eng` after acceptance. Debug builds may expose additional numeric diagnostics through ADB, but raw-log rendering is outside this specification.
- No new always-running daemon is permitted for version 1.

## 10. Security and privacy

1. Runtime input is numeric only and clamped to `0..100`.
2. All visible milestone text is stored on a verified, read-only product/system image.
3. The renderer must not receive permissions for `logd`, `/dev/kmsg`, pstore, debugfs, proc entries beyond its existing needs, device identity storage, radio/NVRAM, or user data.
4. The overlay must never display serial number, IMEI, IMSI, phone number, MAC address, SSID, IP address, account name, file path, package name, crash text, or user-supplied content.
5. SELinux changes must be limited to the smallest property reads/writes needed by authoritative platform producers. Reuse the existing `bootanim_system_prop` type unless review proves a narrower new type is required.
6. Do not add `audit2allow`-generated broad rules.
7. The decorative prompt must have no input path or backing shell process.
8. A malformed ZIP asset must cause a safe fallback, never a crash loop.

## 11. Reliability and performance budgets

- Status parsing occurs once per animation start, not per frame.
- Property polling is limited to 10 Hz or piggybacks on the existing progress check; it must not perform disk I/O per frame.
- Store at most 16 parsed rows and 9 visible rows.
- Added resident memory target: no more than 1 MiB excluding product artwork already required by the animation.
- The overlay must not reduce the configured animation frame rate by more than 5 percent on the target device.
- Across 30 matched cold boots, median time to boot completion must regress by no more than 100 ms and p95 by no more than 200 ms relative to the same build with `status.txt` removed.
- A renderer error or process exit must not prevent `system_server`, SystemUI, or boot completion.
- No sleep, blocking file read, binder call, or network operation is permitted in the frame loop.

## 12. Acceptance criteria

### AC-01 — Feature activation and fallback

- **Given** a valid BaseOS boot animation ZIP containing `status.txt`
- **When** `bootanimation` starts
- **Then** it renders the terminal status overlay.

- **Given** a missing, unsupported, or malformed `status.txt`
- **When** `bootanimation` starts
- **Then** it renders the ordinary animation without crashing or delaying boot.

### AC-02 — Honest start boundary

- **Given** the first drawable frame
- **When** the overlay becomes visible
- **Then** it may show prerequisite facts as completed, but it does not show the bootloader or kernel as currently executing.

### AC-03 — Monotonic milestone rendering

- **Given** progress values `10, 30, 40, 70` in order
- **When** the renderer polls them
- **Then** it displays each proven configured milestone once, keeps the first higher milestone pending, and never duplicates a line.

- **Given** a later lower value
- **When** the renderer polls it
- **Then** both the bar and history remain at the prior high-water mark.

### AC-04 — Stall indication

- **Given** a pending milestone and no progress change
- **When** 8 monotonic seconds elapse
- **Then** its prefix changes from `[ .. ]` to `[wait]` without declaring failure or changing boot behavior.

### AC-05 — Exit remains authoritative

- **Given** progress below 100
- **When** `service.bootanim.exit=1` is observed
- **Then** the process exits through the existing path without waiting for a final status frame.

### AC-06 — Trusted text only

- **Given** arbitrary logcat, kernel, property, package, or user strings present on the device
- **When** the overlay renders
- **Then** none can appear unless the identical reviewed text is present in the trusted `status.txt`.

### AC-07 — No identity leakage

- **Given** a production device with radio and user data provisioned
- **When** the complete animation is captured frame by frame
- **Then** no stable device identifier, network identifier, account data, user content, or filesystem path is visible.

### AC-08 — Build variants

- **Given** BaseOS `user`, `userdebug`, and `eng` builds with the same valid asset
- **When** each boots
- **Then** the production status vocabulary is identical and raw logs are absent from all three.

### AC-09 — Parser bounds

- **Given** too many rows, out-of-range values, non-increasing values, a missing final 100, overlong labels, non-ASCII bytes, embedded NULs, or unknown directives
- **When** the status table is parsed
- **Then** the entire overlay configuration is rejected and the ordinary animation continues.

### AC-10 — Responsive layout

- **Given** every BaseOS-supported phone resolution and cutout profile
- **When** the overlay renders
- **Then** the logo, status text, footer, and progress bar remain within safe bounds with no overlap or two-line wrapping.

### AC-11 — Security policy

- **Given** a production policy build and a full boot
- **When** SELinux denials and the final policy diff are reviewed
- **Then** `bootanimation` has no new log, kernel-log, debugfs, radio/NVRAM, identifier, or user-data read access.

### AC-12 — Performance

- **Given** matched overlay-enabled and fallback builds on the target hardware
- **When** the defined 30-boot performance test is run
- **Then** frame-rate, memory, median boot, and p95 boot budgets in section 11 are satisfied.

### AC-13 — SystemUI readiness

- **Given** SystemUI has not reached its defined first-ready point
- **When** the rest of `system_server` advances
- **Then** `system interface ready` is not reported.

- **Given** SystemUI reports readiness through the internal system-server API
- **When** system_server accepts that report
- **Then** it advances progress to at least 95 without granting SystemUI direct property-write permission.

### AC-14 — Branding and non-interactivity

- **Given** the approved product asset
- **When** the overlay renders
- **Then** it shows the approved wordmark and a decorative prompt that has no input handling or shell process.

## 13. Verification plan

| Test ID | Level | Covers | Method |
| --- | --- | --- | --- |
| BT-001 | Unit | AC-01, AC-09 | Parser table tests for every valid and invalid grammar class |
| BT-002 | Unit | AC-03 | Feed ordered, skipped, repeated, and decreasing progress sequences |
| BT-003 | Unit | AC-04 | Fake monotonic clock at 7.9 s, 8.0 s, and after progress resumes |
| BT-004 | Unit | AC-05 | Assert exit interrupts rendering at every progress threshold |
| BT-005 | Unit | AC-06, AC-07 | Fuzz runtime properties and confirm only table text reaches render commands |
| BT-006 | Screenshot/golden | AC-10, AC-14 | Approved portrait sizes, cutouts, maximum label length, 1 and 9 rows |
| BT-007 | Integration | AC-02, AC-03 | Instrumented cold boot with timestamped producer and rendered-stage traces |
| BT-008 | Integration | AC-08 | Boot `user`, `userdebug`, and `eng`; compare visible vocabulary |
| BT-009 | Integration | AC-13 | Delay SystemUI readiness and verify progress remains below 95 |
| BT-010 | Security | AC-06, AC-07, AC-11 | SELinux policy diff, denial review, frame OCR, and process/FD inspection |
| BT-011 | Fault injection | AC-01, AC-05 | Corrupt/missing asset, kill renderer, freeze producer, and force early exit |
| BT-012 | Performance | AC-12 | 30 matched cold boots per variant plus frame-time and RSS collection |

Every acceptance criterion must have a passing test result attached before the spec is approved for release.

## 14. Implementation work packages

This section is sequencing guidance, not authorization to implement.

1. **Renderer contract**
   - Parse the optional status asset once.
   - Maintain a progress high-water mark and line history.
   - Draw semantic prefixes, labels, footer, and bar without blocking the frame loop.
   - Preserve ordinary-animation fallback.

2. **BaseOS visual assets**
   - Produce the approved wordmark, font, animation frames, and version-1 `status.txt`.
   - Enable progress in `desc.txt`.
   - Verify image dimensions, compression, and read-only packaging.

3. **Early milestone producers**
   - Retain SurfaceFlinger's reset.
   - Publish first-draw, post-fs-data, APEX, and zygote milestones from authoritative platform events.
   - Prove that every jump makes only true statements.

4. **Framework milestone producers**
   - Add a small internal boot-status reporter owned by `system_server`.
   - Map existing SystemServiceManager phases to the specified thresholds.
   - Accept a single authenticated SystemUI-ready notification without giving SystemUI direct property access.

5. **Policy and product wiring**
   - Reuse existing exact-integer property policy where possible.
   - Package assets only for the BaseOS product.
   - Keep the feature dormant for products without `status.txt`.

6. **Verification and rollout**
   - Complete BT-001 through BT-012.
   - Capture review screenshots from physical BraX3 hardware.
   - Run security and boot-performance gates.

## 15. Likely code and configuration touchpoints

These are evidence-backed starting points; implementation review must confirm the final diff.

- `frameworks/base/cmds/bootanimation/BootAnimation.cpp` and `BootAnimation.h`: optional parser, state model, and rendering.
- `frameworks/base/cmds/bootanimation/bootanim.rc`: service context; no new daemon is expected.
- `frameworks/native/services/surfaceflinger/SurfaceFlinger.cpp`: existing exit/progress reset and start sequence.
- `frameworks/base/services/java/com/android/server/SystemServer.java` and/or the narrow SystemServiceManager integration point: later milestone reporting.
- The authoritative SystemUI startup component: authenticated ready notification only.
- Platform `init*.rc`: post-fs-data, APEX, and runtime milestone actions.
- `system/sepolicy/private/property_contexts`, `bootanim.te`, and `system_server.te`: verify existing property access and prevent permission expansion.
- `device/braxos`: BaseOS product packaging, assets, and product-only wiring.

## 16. Source evidence from the current tree

The draft was checked against the local Android 14 iodé/ODM-derived source:

- `BootAnimation.cpp` defines and reads `service.bootanim.progress`.
- The fourth integer on the first `desc.txt` line enables the existing progress feature.
- Existing progress drawing occurs only in the last animation part.
- The existing rendering path increments displayed progress with a 100 ms `usleep`; the new overlay path must replace that behavior with non-blocking time-based interpolation.
- SurfaceFlinger resets `service.bootanim.exit` and `service.bootanim.progress` before `ctl.start bootanim`.
- The property is already declared as `exact int` with the `bootanim_system_prop` SELinux type.
- The current Lineage animation descriptor generator emits only three top-line fields, so current product output does not enable progress.
- No BaseOS-specific boot animation currently exists in `device/braxos`.

## 17. Review gates and open decisions

The spec remains draft until a human reviewer resolves and records:

1. **Visible product name:** approve `BaseOS` from the mockup or replace it with the current `BraxOS` product branding.
2. **SystemUI-ready definition:** select one stable, testable lifecycle point that means the first usable interface can render.
3. **Milestone truth table:** confirm each init/framework signal on the BraX3 Android 14 branch and remove any row that cannot be authoritative.
4. **Final visual tokens:** approve the wordmark, font size, green/amber/orange values, spacing, and progress-bar dimensions on physical hardware.
5. **Performance baseline:** record the exact build fingerprint, power state, boot method, and measurement tooling used for the 30-boot comparison.

Approval of this spec authorizes implementation of the bounded status overlay only. Raw-log display, pre-SurfaceFlinger graphics, additional health channels, and device-service diagnostics require separate reviewed specifications.
