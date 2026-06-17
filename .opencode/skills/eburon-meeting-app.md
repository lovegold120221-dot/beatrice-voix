# Orbit Meeting — Complete User Tutorial

**App:** Orbit Meeting
**URL:** `https://meeting.eburon.ai`
**Purpose:** Real-time AI translation for meetings, powered by Eburon AI.
**Tutorial created:** June 17, 2026

Screenshots are saved alongside this file in the `/orbit-tutorial` folder. Each section below references the relevant screenshot file name.

---

## Chapter 1: First Impressions — The Login Page

**Screenshots:** `01-login-page-full.png`, `04-email-filled.png`, `05-password-visible.png`, `06-both-fields-filled.png`, `07-password-hidden.png`, `13-login-validation.png`, `16-login-mobile.png`

Open `https://meeting.eburon.ai/auth/login` to see a clean, dark-themed login page with a modern centered card layout.

### Look & Feel

The page has a midnight-style dark background with a centered panel. The Eburon AI geometric logo appears beside the app name, `Orbit Meeting`.

The panel includes:

- `Sign in` as the main heading.
- `Welcome back. Sign in to start or join meetings.` as supporting copy.

### Form Fields

The login form has two fields:

- Email, with placeholder `you@example.com`.
- Password, masked by default.

The password field includes an eye icon to toggle visibility. Click once to show the password as plain text. Click again to hide it.

Helpful screenshot references:

- `04-email-filled.png`: email entered.
- `05-password-visible.png`: password visible after toggling.
- `07-password-hidden.png`: password masked again.

### Sign In Button

The `Sign in` button is full-width and prominent. If the user submits without filling required fields, browser HTML5 validation appears.

See `13-login-validation.png`.

### Footer Links

Below the sign-in button:

- `Forgot password?` opens the password reset page.
- `Create account` opens the registration page.

### Mobile Experience

See `16-login-mobile.png`. At 375px width, the layout stacks naturally, inputs stretch full-width, and the app remains easy to use on mobile. The viewport is configured for a standalone, mobile-app-like experience.

---

## Chapter 2: When You Forget — The Reset Password Page

**Screenshots:** `02-forgot-password-page.png`, `11-reset-password-filled.png`

The `Forgot password?` link opens the reset flow.

### What Users See

The reset page keeps the same dark theme and Eburon AI + Orbit Meeting header.

It includes:

- `Reset password` heading.
- `Enter your email and we'll send you a reset link.` explanation.
- Email field with `you@example.com` placeholder.
- `Send reset link` button.
- `Back to sign in` link.

See `11-reset-password-filled.png` for the filled-out version.

---

## Chapter 3: Welcome Aboard — The Sign Up Page

**Screenshots:** `03-signup-page.png`, `08-signup-filled.png`, `09-signup-full.png`, `10-signup-passwords-visible.png`, `15-signup-validation.png`, `17-signup-mobile.png`

Click `Create account` from the login page to open signup.

### Signup Form

Fields:

1. Display name, placeholder `Your name`. This is what other participants see.
2. Email, placeholder `you@example.com`.
3. Password, masked by default with visibility toggle.
4. Confirm password, also masked by default with its own visibility toggle.

The signup page has two password visibility toggles, one for each password field. See `10-signup-passwords-visible.png`.

### Create Account Button

The `Create account` button is the main call-to-action. Empty required fields trigger browser validation. See `15-signup-validation.png`.

### Existing Account Link

The bottom link says `Already have an account? Sign in`.

### Mobile View

See `17-signup-mobile.png`. Signup remains clean and usable on mobile.

---

## Chapter 4: The Hub — Dashboard / Home Screen

**Screenshots:** `20-dashboard-full.png`, `27-back-to-dashboard.png`, `31-join-panel-active.png`, `29-join-link-filled.png`, `30-schedule-meeting.png`

After login, users land on the Orbit Meeting Dashboard.

### Header Bar

The top header includes:

- Eburon AI logo + `Orbit Meeting`.
- Current account email, e.g. `test@mail.com`.
- `Sign out` button.

### Three Main Action Buttons

The dashboard has three large primary actions:

- `CREATE`: starts a new meeting immediately.
- `JOIN`: opens the join-meeting panel.
- `SCHEDULE MEETING`: opens the scheduling panel.

### Join Meeting Panel

See `31-join-panel-active.png`.

The panel includes:

- Heading: `Join meeting`.
- Subheading: `Enter a meeting link or ID`.
- Input placeholder: `https://.../session/room-id`.
- `Join meeting` button.

See `29-join-link-filled.png` for a pasted meeting URL.

### Schedule Meeting Panel

See `30-schedule-meeting.png`.

The panel includes:

- `Schedule meeting` heading.
- `Create an invite link` subheading.
- Topic field, auto-filled with `Orbit Meeting`.
- Date and time picker.
- Auto-generated invite link, e.g. `https://meeting.eburon.ai/session/b6d73927-...`.
- `Copy invite` button.
- Share via Email.
- Share via Gmail.
- Share via WhatsApp.

### Upcoming Meeting Section

Below the actions:

- `Next up` label.
- `Ready when you are` heading by default.
- Message: `Create a room now or join with an invite link.`

After scheduling, this area updates with meeting title, date, and time, such as `Orbit Meeting — Jun 17, 2026, 7:53 PM`.

### Dashboard Mobile View

On mobile, the dashboard stacks vertically while keeping the main actions tappable.

---

## Chapter 5: The Pre-Flight — Meeting Lobby / Join Room

**Screenshots:** `21-meeting-room.png`, `22-meeting-room-fresh.png`, `22-language-dropdown.png`, `23-language-french-selected.png`, `24-mic-toggled.png`

After creating or joining a room, Orbit shows a lobby before the user enters the meeting.

### Lobby UI

The lobby includes:

- Heading: `Join the call`.
- Subtitle: `Pick your language — that's what you'll speak and what you'll hear everyone else in.`

This is the core Orbit Meeting feature: real-time translation.

### Language Selector

See `22-language-dropdown.png`.

The language selector includes over 100 languages, with country flag emojis. Examples:

- English, default.
- French.
- Spanish.
- German.
- Japanese.
- Chinese Simplified.
- Arabic.
- Regional variants such as French Canada, Portuguese Brazil, and Portuguese Portugal.
- `None — Native` for hearing original audio without translation.

See `23-language-french-selected.png` for French selected.

### User Name

A name field is pre-filled from the account profile, but users can change it for the session.

### Device Access Panel

Three toggles show on/off status:

- Microphone, off by default.
- Camera, off by default.
- Screen Share, off by default.

If microphone is off, the app prompts: `Grant Microphone access to speak in the meeting.`

See `24-mic-toggled.png` for microphone enabled.

### Lobby Actions

- `Join the call`: primary action.
- `Copy invite link`: secondary action.

Each meeting URL is unique, e.g. `https://meeting.eburon.ai/session/9c02de26-...`.

---

## Chapter 6: The Main Event — Inside the Meeting Room

**Screenshots:** `32-after-joining.png`, `32-meeting-room-lobby.png`, `33-meeting-room-full.png`, `34-chat-panel.png`, `35-people-panel.png`, `36-settings-panel.png`, `37-translate-panel.png`, `38-invite-panel.png`, `39-history-panel.png`, `40-share-panel.png`, `41-record-panel.png`, `42-breakout-panel.png`, `43-react-panel.png`

After clicking `Join the call`, the user enters the live Orbit Meeting room.

### Top Bar

The top bar includes:

- `Orbit Meeting` app name.
- `Translation: French` or the current target language.
- Content mode toggle: `Normal — click for Movie`.
- `Mute Translator` button.

Below the title bar:

- Meeting ID, e.g. `9c02de26-3474-4475-8af5-29fd2c9b8f72`.
- `Copy meeting link` and `Copy` button.

### Main Video Area

The center shows participant tiles. If camera is off, the tile shows the participant initial, e.g. `T` for `test`, and microphone status.

The user tile is labeled `test (You)`.

### Translation Settings Panel

The right sidebar includes:

- Target language dropdown.
- Voice dropdown: Male 1, Male 2, Female 1, Female 2.
- `Mute Translator` button.
- `Close` button.
- `Original Transcription` area.
- `Translated Output` area.

This is the heart of Orbit Meeting: users speak in one language, others hear or read it in their selected language, and transcription scrolls in real time.

### Bottom Control Bar

Media controls:

- Microphone mute/unmute.
- Video on/off.
- Speaker output selection.

Meeting tools:

- People: participant roster with names, mic status, and raised hands.
- Chat: in-meeting chat panel. See `34-chat-panel.png`.
- Share: screen/window/tab sharing. See `40-share-panel.png`.
- Translate: translation panel. See `37-translate-panel.png`.
- Record: meeting recording controls. See `41-record-panel.png`.
- Breakout: breakout room controls. See `42-breakout-panel.png`.
- React: emoji reactions such as thumbs up, heart, laugh, surprise, sad, and prayer. See `43-react-panel.png`.
- Invite: invite and share dialog. See `38-invite-panel.png`.
- Settings: settings panel. See `36-settings-panel.png`.
- History: transcription and translation history. See `39-history-panel.png`.
- More: overflow menu for additional actions.

Exit control:

- Leave: red/danger button to leave the meeting, usually with confirmation.

---

## Chapter 7: Under The Hood — The Settings Panel

**Screenshots:** `44-settings-page.png`, `44-settings-general.png`, `44-settings-preferences.png`, `44-settings-audio.png`, `44-settings-video.png`, `44-settings-translation.png`, `44-settings-glossary.png`, `44-settings-recording.png`

Click the Settings button in the meeting controls to open `https://meeting.eburon.ai/settings`.

The settings page has seven tabs.

### Tab 1: General

See `44-settings-general.png`.

Configure profile and app preferences:

- Display name.
- Profile picture.
- Default language.
- Interface language.

### Tab 2: Preferences

See `44-settings-preferences.png`.

App behavior settings:

- Auto-join audio.
- Auto-join video.
- Show participant names on tiles.
- Noise suppression level.
- Echo cancellation.

### Tab 3: Audio

See `44-settings-audio.png`.

Audio device management:

- Microphone selection.
- Speaker selection.
- Test microphone.
- Test speaker.
- Microphone and speaker volume sliders.

### Tab 4: Video

See `44-settings-video.png`.

Camera settings:

- Camera selection.
- `Mirror my video` toggle.
- `Turn off camera when joining` checkbox.
- Test camera preview.

### Tab 5: Translation

See `44-settings-translation.png`.

Core translation settings:

- Default target language.
- `Translate my speech` toggle.
- `Show original text` toggle.
- AI voice selection: Male 1, Male 2, Female 1, Female 2.
- Voice speed slider.
- Auto-detect language toggle.

### Tab 6: Glossary

See `44-settings-glossary.png`.

Custom vocabulary for businesses and power users:

- Add terms or phrases that Orbit should translate in a specific way.
- Add industry jargon, product names, and acronyms.
- Import/export glossary entries as CSV or JSON.

### Tab 7: Recording

See `44-settings-recording.png`.

Recording preferences:

- Default recording layout, such as video + transcription or transcription only.
- Auto-record on join toggle.
- Storage location, cloud or local.
- Recording file format options.

### Save / Cancel / Active Call Footer

Each tab includes:

- `Save` button, disabled until changes are made.
- `Cancel` button.

At the bottom, a persistent bar can show:

- `Call in progress (meeting-id)`.
- `Return to Room`.
- `End Call`.

---

## Chapter 8: PWA Magic — Orbit As A Standalone App

Orbit Meeting is a Progressive Web App.

PWA capabilities:

- Install on phone or desktop.
- Behaves like a native app.
- Works partially offline depending on feature.
- Has its own app icon.
- Uses standalone display mode without browser chrome.
- Background color: `#11100f`.
- Theme color: `#11100f`.

Manifest details:

- Name: `Orbit Meeting`.
- Short name: `Orbit`.
- Icons: 192x192, 512x512, maskable support, Apple Touch Icon.
- Categories: Communication, Productivity.
- Required permissions: microphone and camera.

Install guidance:

- iOS: Share button -> Add to Home Screen.
- Android: Chrome install prompt.
- Desktop: install icon in the address bar.

---

## Chapter 9: The Grand Finale — Signing Out

**Screenshot:** `46-signed-out.png`

Users can finish by:

1. Clicking `Leave` in the meeting room bottom bar.
2. Clicking `End Call` in the settings page footer.
3. Returning to dashboard and clicking `Sign out`.

Signing out redirects to `https://meeting.eburon.ai/auth/login`.

See `46-signed-out.png`.

---

## Screenshot Reference

### Login & Auth Flow

- `01-login-page-full.png`: full login page desktop.
- `02-forgot-password-page.png`: forgot password reset page.
- `03-signup-page.png`: create account signup page.
- `04-email-filled.png`: email field filled.
- `05-password-visible.png`: password shown after eye icon click.
- `06-both-fields-filled.png`: both fields filled, password visible.
- `07-password-hidden.png`: password hidden again.
- `08-signup-filled.png`: signup form filled.
- `09-signup-full.png`: signup page full view.
- `10-signup-passwords-visible.png`: both password fields visible.
- `11-reset-password-filled.png`: reset password with email filled.
- `12-main-landing-page.png`: root URL redirect to login.
- `13-login-validation.png`: empty form submission validation.
- `14-console-errors.txt`: browser console errors.
- `15-signup-validation.png`: empty signup validation.
- `16-login-mobile.png`: login page mobile 375px.
- `17-signup-mobile.png`: signup mobile 375px.
- `46-signed-out.png`: after signing out.

### Dashboard

- `20-dashboard-full.png`: main dashboard.
- `27-back-to-dashboard.png`: dashboard after meeting.
- `29-join-link-filled.png`: join panel with link pasted.
- `30-schedule-meeting.png`: schedule meeting panel open.
- `31-join-panel-active.png`: join panel active.

### Meeting Lobby

- `21-meeting-room.png`: pre-join meeting lobby.
- `22-meeting-room-fresh.png`: lobby fresh state.
- `22-language-dropdown.png`: language selector dropdown.
- `23-language-french-selected.png`: French selected.
- `24-mic-toggled.png`: microphone toggled on.

### Live Meeting Room

- `32-after-joining.png`: after clicking Join the call.
- `32-meeting-room-lobby.png`: meeting room lobby view.
- `33-meeting-room-full.png`: full meeting room interface.
- `34-chat-panel.png`: chat panel.
- `35-people-panel.png`: people panel.
- `36-settings-panel.png`: settings panel from meeting.
- `37-translate-panel.png`: translation settings panel.
- `38-invite-panel.png`: invite/share dialog.
- `39-history-panel.png`: transcription history.
- `40-share-panel.png`: screen share dialog.
- `41-record-panel.png`: recording controls.
- `42-breakout-panel.png`: breakout rooms.
- `43-react-panel.png`: emoji reactions.

### Settings Full Page

- `44-settings-page.png`: settings overview.
- `44-settings-general.png`: general tab.
- `44-settings-preferences.png`: preferences tab.
- `44-settings-audio.png`: audio devices tab.
- `44-settings-video.png`: camera/video tab.
- `44-settings-translation.png`: translation tab.
- `44-settings-glossary.png`: custom glossary tab.
- `44-settings-recording.png`: recording settings tab.

---

## Keyboard Shortcuts & Power Tips

The app does not expose visible keyboard shortcuts, but common meeting-app patterns apply:

- Spacebar: toggle mute/unmute when not typing in a field.
- Esc: close open panels such as Chat, People, or Settings.
- Tab / Shift+Tab: move between fields.
- Enter: submit active form, send chat, or join meeting.

Power tips:

- Set language before joining the call.
- Use Settings -> Glossary for company product names and industry terms.
- Try both Normal and Movie layout modes.
- Recording captures audio and transcriptions for searchable meeting notes.
- Copy the invite link in the lobby before joining so it can be shared with latecomers.

---

## About Eburon AI & Orbit Meeting

Orbit Meeting is a real-time AI translation platform built by Eburon AI, founded by Joe Lernout.

The platform combines:

- Real-time speech recognition.
- AI language translation to 100+ languages.
- AI voice synthesis for natural spoken translation.
- Video conferencing features: video, chat, screen share, invite, participants, reactions, breakout rooms, recording, and history.
- PWA technology for installation on phones and desktops.

Mission: break down language barriers in meetings so users can collaborate with anyone, anywhere, in any language.

Website: `https://meeting.eburon.ai`
Company: `https://eburon.ai`

Happy meeting.
