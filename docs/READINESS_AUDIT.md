# Dermaire readiness audit

Audit date: 2026-09-14

## Result

Final weighted readiness: **58.4/100 — advanced prototype, not ready for human use**.

| Area | Weight | Score | Weighted |
|---|---:|---:|---:|
| Figma/UI fidelity | 15% | 78 | 11.70 |
| Navigation and user flows | 15% | 68 | 10.20 |
| Functional completeness | 15% | 55 | 8.25 |
| Validation and business rules | 15% | 62 | 9.30 |
| Data architecture and persistence | 10% | 58 | 5.80 |
| Doctor portal and permissions | 10% | 38 | 3.80 |
| Chatbot safety and usefulness | 10% | 42 | 4.20 |
| Security and privacy | 5% | 35 | 1.75 |
| Accessibility and usability | 3% | 65 | 1.95 |
| Performance and reliability | 2% | 70 | 1.40 |
| **Total** | **100%** |  | **58.35** |

## Evidence

- Mobile design uses the Figma palette, Fraunces/Karla typography, card geometry, six-tab navigation, dialogs, product states, safety states, experiment states, reports, rewards and doctor-share flow.
- Product data now uses a typed model, replaceable repository, shared controller, local persistence, validation, duplicate detection, search, filters, sorting, archive/restore/delete rules and active-experiment protection.
- Doctor demo applies deny-by-default role checks, authorized-patient checks, consent checks for export, expired-session rejection, append-only notes and audit events.
- The app guide detects English and Arabic red flags and replaces normal education with direct urgent-care guidance. It explicitly avoids diagnosis and prescription.
- Static analysis passes, 15 automated tests pass, and Web and macOS builds pass.

## Figma coverage

| Area | Present | Fidelity | Functional | Status |
|---|---|---|---|---|
| Welcome and authentication | Yes | High | Local demo navigation | Partial |
| Safety and responsibility | Yes | High | Scroll gate persisted | Good prototype |
| Skin profile | Yes | High | Shared selection state | Good prototype |
| Products and interactions | Yes | High | CRUD, search, rules, persistence | Strong prototype |
| Baseline and home | Yes | Medium-high | Simulated measurements | Partial |
| Experiment start/timeline | Yes | Medium-high | Local state only | Partial |
| Daily check-in/camera | Yes | Medium | Simulated camera and analysis | Blocked for production |
| Skin journal | Yes | Medium | In-memory simplified entries | Partial |
| Results and reports | Yes | Medium-high | Calculations and export simulated | Partial |
| Rewards | Yes | Medium-high | Local token logic | Partial |
| Doctor QR access | Yes | High | Link lifecycle simulated | Partial |
| Doctor workspace | Added as required safety flow | Medium | Local demo with RBAC policy | Prototype only |
| Chatbot | Added as required safety flow | Consistent | Deterministic local guide | Prototype only |

Programmatic prototype-connection traversal was blocked by the Figma Starter MCP call limit. The audit used the live Figma canvas, its three pages, and the existing capture manifest containing 51 mobile, 13 web, and 10 doctor frames. Prototype connections still require a final Figma-side review when the quota is available.

## Severity report

### Critical blockers

1. No production authentication, MFA, token refresh, session restoration, password reset service, or server-side route authorization.
2. No production database, encrypted clinical store, backup, retention policy, or verified deletion workflow.
3. Doctor identity, patient relationships, consent, audit logs and exports are local demonstrations; they are not enforceable against a hostile client.
4. Camera analysis, measurement quality, OCR and medical claims are simulated and have not been clinically validated.

### High priority

1. Journal, experiment, rewards and report domains still use shared prototype state instead of repositories with transactional persistence.
2. Notifications, clinician messaging, follow-ups, report export and account deletion do not have connected services.
3. The app has no production offline synchronization, conflict resolution, migration strategy or recovery from corrupted local data.
4. Doctor web layouts and all Figma prototype connections need final screen-by-screen verification.
5. No localization infrastructure; Arabic red-flag recognition exists, but the UI is English-only.

### Medium priority

1. Some older screens remain in a large `app_shell.dart` and should be split by domain.
2. Full keyboard focus order, screen-reader journeys, large-text snapshots and WCAG contrast measurements need device testing.
3. Search is local and immediate; a remote catalogue will need debounce, pagination and cancellation.
4. No telemetry for reliability, with privacy-safe redaction and consent.

### Low priority

1. Replace emoji placeholders with approved image assets where the final design provides them.
2. Add golden tests after the Figma design is frozen.
3. Add production copy review for clinical and consent language by legal and medical reviewers.

## Required production sequence

1. Choose a regulated-data backend and threat model; define residency, encryption, retention, deletion and incident response.
2. Implement OIDC authentication, MFA for clinicians, secure token storage and server-side RBAC/ABAC on every clinical endpoint.
3. Implement versioned patient consent and immutable server audit trails.
4. Move journal, experiment, measurement, report and rewards domains to tested repositories and transactional APIs.
5. Validate camera/measurement algorithms clinically and label intended use, limitations and escalation policy.
6. Connect messaging, notifications, OCR, exports and account deletion with observable error and recovery states.
7. Complete accessibility, localization, device, browser, security, privacy, clinical-safety and penetration testing.
8. Re-run the Figma connection audit, automated integration suite and release builds in CI before a controlled pilot.
