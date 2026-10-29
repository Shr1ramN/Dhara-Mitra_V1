# Dhara Mitra (ಧರಾ ಮಿತ್ರ) — Plan v0.2

*Dhara Mitra* means "friend of the earth".

A farm diary app for a South Karnataka mixed garden: **arecanut (chali)** with **coconut**, **pepper** trailed on the areca palms, and **banana** in the gaps.
The goal is to replace the old notebook-and-memory system that our fathers and grandfathers used with something that remembers everything, does the arithmetic, and warns you before it rains on the drying yard.

**Decisions so far**

| Topic | Decision |
|---|---|
| Platform | Android phone app |
| Users | Owner only (one person, one phone; cloud backup) |
| Language | Kannada + English, switchable anytime |
| Arecanut type | Chali (white, sun-dried whole nut) |
| Connectivity | **Offline-first.** Everything works with no internet; only live prices, weather refresh and backup need a connection (section 3). |
| Added in v0.2 | Land & loans (F11, was I4), Insurance & schemes (F12, was I3) |

To ask for changes, refer to the feature IDs below (e.g. "change F4.4", "remove F8.5", "add a new idea under F3").

---

## 1. Features

### F1 — Farm and plots
- **F1.1** Farm profile: name, village, GPS location (used for weather), total acres.
- **F1.2** Plots (ಮೇಲಿನ ತೋಟ, ಕೆಳಗಿನ ತೋಟ, …): area, soil, irrigation type (sprinkler / drip / hose), photo.
- **F1.3** Crops per plot: areca palm count, age, variety, bearing or not yet bearing; coconut trees; pepper vines (variety, trailed on which palms); banana clumps (variety, planting date, ratoon number).
- **F1.4** Season setup: a season runs June → May (configurable). Every record is tagged with its season so years can be compared.

### F2 — Farm diary (ದಿನಚರಿ)
- **F2.1** Log any work: fertiliser, spray (Bordeaux, pesticide), irrigation, weeding / slashing, mulching, harvest, crop care, other.
- **F2.2** Quick entry with big tap-chips instead of typing: type, crop(s), plot(s), date(s), number of days.
- **F2.3** Products used (urea, MOP, copper sulphate, lime, …) are picked from stock, auto-deducted, and costed at purchase price.
- **F2.4** Labour on the activity is automatically added to each worker's ledger (F3.4).
- **F2.5** Kannada voice notes and photos on every entry.
- **F2.6** "Remind me for the next round" (e.g. Bordeaux again after 40 days, next fertiliser split after 6 months).
- **F2.7** Timeline with filters by crop, plot, work type, and date range; search.

### F3 — Labour (ಕೆಲಸಗಾರರು)
- **F3.1** Worker list: name, phone, village, role(s) — climber, sprayer, peeler, daily labour, coconut plucker.
- **F3.2** Wage types: per day, half day, per palm, per tree, per kg, or contract (lump sum). A worker can have different rates for different work.
- **F3.3** Daily attendance: present / half-day / absent and which work they did.
- **F3.4** Ledger per worker: work done, advances, payments (cash / UPI), running balance.
- **F3.5** Dues screen: who is owed how much; settle in one tap.
- **F3.6** Send a worker their statement on WhatsApp, in Kannada.
- **F3.7** Labour reports: totals by worker, by work type, by season.

### F4 — Harvest lots (ಫಸಲು) — the heart of the app
Every harvest round becomes a **lot** that is tracked until the last kg is sold.
- **F4.1** Lot list per crop and season, with the current stage shown on each lot.
- **F4.2** Arecanut chali journey: **Harvest → Drying → Peeling → Grading → Storage → Sale**.
- **F4.3** Harvest: plot, palms climbed, fresh nut quantity, climbers and collectors with their cost.
- **F4.4** Drying: start and end date, **automatic day counter** (day 21 of ~40), yard used, rain-cover log, turning log.
- **F4.5** Peeling (ಸುಲಿಯುವಿಕೆ): who peeled, kg each, rate per kg, total cost, out-turn % (dried in husk → chali).
- **F4.6** Grading: chali, patora, ulli gadde, karigotu, koka (kg of each).
- **F4.7** Storage: place, number of bags, **days in storage**, moisture / pest checks, price when stored vs. price today, current value.
- **F4.8** Sale linked to the lot (see F6.1), so every lot shows its true profit.
- **F4.9** Pepper journey: harvest → threshing → drying (dry-weight %) → storage → sale.
- **F4.10** Coconut journey: plucking round (nut count) → sale as nuts, or dehusk → copra.
- **F4.11** Banana journey: bunch harvest → sale by bunch or by kg.
- **F4.12** Partial sales (sell part of a lot now, the rest later).

### F5 — Inputs and stock (ದಾಸ್ತಾನು)
- **F5.1** Stock list: quantity, unit, low-stock level.
- **F5.2** Purchase entry: shop, bill photo, price; usage is auto-deducted from diary entries (F2.3).
- **F5.3** Low-stock alert (e.g. not enough copper sulphate for the next Bordeaux round).

### F6 — Sales and money
- **F6.1** Sale entry: buyer, grade lines, quantity, rate, deductions (moisture cut, commission, hamali, transport), net amount.
- **F6.2** Buyers: CAMPCO, private traders, APMC agents; amount still to receive.
- **F6.3** Other expenses: pump electricity, diesel, repairs, tools, transport.
- **F6.4** Money snapshot on the home screen: owed to workers, to receive from buyers, spent this month, **loan dues coming up (F11.4)**.

### F7 — Daily prices (ಧಾರಣೆ) — refreshes only when online
- **F7.1** Today's prices for each crop and grade (old chali, new chali, double chali, patora, copra, pepper, Nendran, Elakki, …) across the markets you choose.
- **F7.2** Trend charts (7 days / 30 days / 1 year) built from the history we store every day.
- **F7.3** Price alert ("tell me when old chali reaches ₹500/kg").
- **F7.4** Value of your stored stock at today's price.
- **F7.5** Manual entry for CAMPCO / local trader rates when no automatic feed is available (works offline).
- **F7.6** When offline, the last downloaded prices are shown with a clear stamp: "Prices as of 23 Oct, 7:30 AM".

### F8 — Weather, reminders, calendar
- **F8.1** Hourly and 7-day forecast for the farm's location (refreshes when online; last forecast kept offline).
- **F8.2** **Rain alert linked to drying lots**: "Rain likely at 4 PM — Lot A-01 is on the yard, cover it." The alert is scheduled on the phone as soon as the forecast is downloaded, so it still fires if the signal drops later.
- **F8.3** Reminders: next spray / fertiliser round, seasonal tasks, low stock, unpaid dues, loan dues, insurance enrolment.
- **F8.4** Crop calendar (ಕೃಷಿ ಪಂಚಾಂಗ): month-by-month work for all four crops.
- **F8.5** Rain gauge log (daily mm), the way elders kept it in the diary.

### F9 — Reports (ವರದಿ)
- **F9.1** Season profit and loss: income, expenses (including loan interest and insurance premium), profit.
- **F9.2** By crop and by plot.
- **F9.3** Key numbers: cost per kg of chali, profit per acre, labour share of cost, chali per palm.
- **F9.4** Year-on-year comparison (yield, price, cost).
- **F9.5** Export to PDF / Excel; share on WhatsApp.

### F10 — Works everywhere
- **F10.1** Offline-first: everything is saved on the phone first; nothing waits for the network (section 3).
- **F10.2** Kannada / English switch.
- **F10.3** Kannada voice input for notes and quick entries.
- **F10.4** Automatic cloud backup whenever internet is available; restore on a new phone.
- **F10.5** App lock (PIN / fingerprint) — important now that loan and land records are inside.
- **F10.6** Big buttons and simple screens; runs on a budget Android phone.
- **F10.7** Units: kg / quintal, acres / guntas; ₹ in Indian format (₹4,62,480 and "₹4.62 L").

### F11 — Land and loans (ಜಮೀನು ಮತ್ತು ಸಾಲ) — new in v0.2
- **F11.1** Land parcels: survey number / hissa, village, extent (acres + guntas), which plots lie on it, RTC (pahani) and other document photos.
- **F11.2** Loans: lender (cooperative society / PACS, bank, CAMPCO, private), type (crop loan / KCC, term loan for pumpset, land development, vehicle, gold loan, hand loan), sanctioned amount and date, interest rate and type (simple / compound), tenure, land parcel given as security.
- **F11.3** Every withdrawal and repayment on a loan; **outstanding principal and interest accrued up to today**, worked out by the app.
- **F11.4** Due-date reminders: instalments, yearly KCC renewal, interest due. Marks loans where paying on time keeps a lower interest rate.
- **F11.5** Loan summary: total owed across all lenders, interest paid this season (flows into F9 expenses), history of closed loans.
- **F11.6** CAMPCO / society membership: member number, shares held, dividends received.

### F12 — Insurance and schemes (ವಿಮೆ ಮತ್ತು ಯೋಜನೆಗಳು) — new in v0.2
- **F12.1** Crop insurance policies: scheme, crop, season, insured area, premium paid, application / policy number, document photo.
- **F12.2** Enrolment reminders before the yearly last date for each crop (date entered by you, or from a list the app downloads when online).
- **F12.3** Claims: date of loss, photos, claim filed, amount received, status.
- **F12.4** Government schemes and subsidies applied for (e.g. horticulture department drip / sprinkler, farm machinery): application date, status, subsidy received.
- **F12.5** Document vault: RTC, loan papers, policy papers, bills — kept on the phone and included in the backup.

Scheme rules and dates change every year. The app keeps your records and reminds you; it does not decide eligibility.

### Ideas not yet included (say yes / no)
- **I1** Photo-based disease check (koleroga, yellow leaf disease, quick wilt, bud rot). *Needs internet for the analysis.*
- **I2** Palm-level marking on a plot map (diseased, replaced, top-dead palms).
- **I5** Pump log (running hours, power cuts) and irrigation schedule.
- **I6** Mechanical dryer usage log (if a dryer is used instead of / along with the yard).
- **I7** Read-only family access.

(I3 → F12, I4 → F11.)

---

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| App | **Flutter** (Dart), Android first | One codebase, smooth on budget phones, good Kannada text rendering; iOS later without a rewrite. |
| Local database | **SQLite via Drift** (optionally encrypted with SQLCipher) | The phone is the source of truth: all data lives here, so the app never needs the network to work. Typed queries and safe migrations. |
| State / navigation | Riverpod, go_router | Standard, testable Flutter patterns. |
| Languages | Flutter `intl` with `app_en.arb` / `app_kn.arb` | Every label in both languages; switch at runtime. |
| Fonts | Noto Sans Kannada + Inter **bundled in the app** | Fonts downloaded at runtime would break offline. |
| Connectivity | `connectivity_plus` + `workmanager` | Detects when internet returns and runs price / weather refresh and backup in the background. |
| Cloud | **Supabase** (Postgres, Auth, Storage, Edge Functions, cron) | Free tier is enough. Phone-OTP login, backup of data and photos, and the twice-daily price job. |
| Backup / sync | Outbox table on the phone → pushed to Supabase when online | Owner-only, one phone, so this is backup / restore, not multi-user conflict handling. |
| Prices | Supabase cron → Edge Function → `price_snapshot` table | Runs every day even if the phone is off, so trend history has no gaps (section 4). |
| Weather | **Open-Meteo** (free, no key), called from the app | Hourly rain probability for the farm's GPS point. |
| Notifications | `flutter_local_notifications` | All reminders and rain alerts are scheduled on the phone, so they work offline. |
| Security | `local_auth` (fingerprint / PIN), Supabase row-level security | Loan, land and money data stay private. |
| Voice | Android speech-to-text, `kn-IN` | Kannada dictation. Works offline if the Kannada offline speech pack is installed in Android settings. |
| Photos / documents | `image_picker`, files stored in app storage | RTC, bills, policy papers, lot photos. |
| Charts / exports | fl_chart, `pdf` + `printing`, `excel`, `share_plus` | Trend charts, PDF / Excel reports, WhatsApp sharing. |
| Distribution | Signed APK installed directly; later Play Store | Fast to start. |

### How the pieces fit

```
 PHONE — works with no internet                          CLOUD — used only when online
┌──────────────────────────────────────────┐          ┌───────────────────────────────────┐
│ Flutter screens (Kannada / English)      │          │ Supabase                          │
│        │                                 │          │  • Auth (phone OTP)               │
│ Riverpod state                           │  backup  │  • Postgres: your backup copy     │
│        │                                 │ ───────► │  • Storage: photos, documents     │
│ Repositories + calculations              │          │  • price_snapshot table           │
│        │                                 │  prices  │  • Cron + Edge Function, 2× a day │
│ SQLite (Drift) — ALL data, source of truth│ ◄─────── │      ← Agmarknet (data.gov.in)    │
│ Outbox queue · local notifications       │          │      ← Spices Board               │
└──────────────────────────────────────────┘          └───────────────────────────────────┘
        │  when online
        └──────────► Open-Meteo (weather forecast)
```

---

## 3. Offline and online

**Rule: the app never blocks on the network.** Every entry is saved to the phone immediately. Internet is used only to *bring in* fresh outside data (prices, weather) and to *send out* a backup.

| Works fully offline | Needs internet (runs automatically when connected) |
|---|---|
| All entry and viewing: diary, labour, lots, stock, sales, loans, insurance, documents | Live price refresh and trend history (F7.1–F7.3) |
| All calculations: drying days, wages, ledgers, out-turn, loan interest, reports | Weather forecast refresh (F8.1) |
| Reminders and rain alerts already scheduled | Cloud backup and restore (F10.4) |
| Crop calendar | Downloading the yearly insurance / scheme date list (F12.2) |
| PDF / Excel export (the file is created on the phone) | Sending to WhatsApp (prepared offline, sent when connected) |
| Last known prices and forecast, shown with "as of" time | First login on a new phone |
| Manual CAMPCO / trader rate entry (F7.5) | Kannada voice typing, unless the offline speech pack is installed |

How it behaves:
- A small banner shows **"Offline · prices as of 23 Oct, 7:30 AM"** instead of an error.
- When the connection returns, a background job refreshes prices and weather, reschedules rain alerts, and uploads the backup. No button needs pressing.
- Backup can be limited to Wi-Fi only, to save mobile data.

---

## 4. How daily prices will work

1. A **scheduled job** (Supabase cron → Edge Function) runs every morning and afternoon, whether or not your phone is on.
2. It pulls from:
   - **Agmarknet via data.gov.in**: the government's open API for daily mandi prices (free API key, kept on the server). It covers Karnataka APMC markets for arecanut (Mangaluru, Puttur, Bantwal, Belthangady, Shivamogga, Sirsi, …), coconut and copra, pepper, and banana. Prices come in ₹/quintal and are converted to ₹/kg.
   - **Spices Board** daily pepper prices (Kochi and others).
   - **CAMPCO / society / local trader rates**: no official API. These are either read from their published daily rate pages (only where their terms allow) or **entered manually** (F7.5) from the daily WhatsApp / newspaper rate.
3. Every reading is stored in `price_snapshot`. The data.gov.in feed only gives *today's* prices, so **keeping our own history is what makes trend charts possible**.
4. When the phone is online, the app downloads only the snapshots it doesn't have yet (small, cheap on data) and saves them locally. Offline, it shows the last saved prices with their time (F7.6).
5. Price alerts (F7.3) are checked on the phone each time new prices arrive.

---

## 5. Data model (first draft)

Every table also has `id` (UUID), `updated_at` and `deleted` columns so changes can be backed up.

```
farm (id, name, village, lat, lng, acres, season_start_month)
plot (id, farm_id, name, acres, soil, irrigation, notes)
plot_crop (id, plot_id, crop[areca|coconut|pepper|banana], count, variety, planted_on, bearing)

activity (id, date, days, type, title, notes, voice_note_path, next_reminder_on)
activity_plot (activity_id, plot_id)          activity_crop (activity_id, crop)
activity_input (activity_id, stock_item_id, qty, cost)
activity_labour (activity_id, worker_id, qty, unit, rate, amount)

worker (id, name, phone, village, roles[], default_rates json)
attendance (id, date, worker_id, status[present|half|absent], work)
worker_txn (id, worker_id, date, kind[work|advance|payment], amount, mode, ref_type, ref_id)

lot (id, code, crop, season, title, stage)
lot_stage (id, lot_id, stage, started_on, ended_on, data json)   -- drying yard, covers, kg in/out…
lot_grade (lot_id, grade, kg)
lot_labour (lot_id, stage, worker_id, qty, unit, rate, amount)

stock_item (id, name, unit, qty, min_qty, last_price)
purchase (id, stock_item_id, date, qty, price, shop, bill_photo_path)
buyer (id, name, type[campco|trader|apmc], phone)
sale (id, date, buyer_id, lot_id, gross, deductions json, net, received)
sale_line (sale_id, grade, qty, unit, rate)
expense (id, date, category, amount, notes)

land_parcel (id, survey_no, hissa, village, acres, guntas, notes)
land_parcel_plot (land_parcel_id, plot_id)
loan (id, lender, lender_type[society|bank|campco|private], kind[crop_kcc|term|gold|hand],
      sanctioned_amount, sanctioned_on, rate_pct, interest_type[simple|compound],
      tenure_months, land_parcel_id, status[active|closed])
loan_txn (id, loan_id, date, kind[withdrawal|repayment|interest|charge], amount, mode, note)
loan_due (id, loan_id, due_on, amount, kind[instalment|interest|renewal], paid)
membership (id, org, member_no, shares, share_value, joined_on)
membership_txn (id, membership_id, date, kind[share_purchase|dividend], amount)

insurance_policy (id, scheme, crop, season, area_acres, premium, policy_no, enrol_by, status)
insurance_claim (id, policy_id, loss_on, filed_on, amount_claimed, amount_received, status)
scheme_application (id, scheme, department, applied_on, status, subsidy_amount, received_on)
document (id, kind[rtc|loan|policy|bill|other], title, file_path, ref_type, ref_id)

price_snapshot (id, date, source, market, commodity, grade, min, max, modal, unit)
price_alert (id, commodity, grade, op, target, active)
weather_cache (fetched_at, hourly json, daily json)
reminder (id, due_on, title, ref_type, ref_id, done)
rain_log (date, mm)
sync_outbox (id, table_name, row_id, op, queued_at)
```

---

## 6. How we build it

### 6.1 One-time setup (Windows laptop)

**Needed now (Phase 1a)**

| What | Why | Notes |
|---|---|---|
| Git | Version control | Already installed (this repo uses it). |
| Cursor + **Flutter** and **Dart** extensions | Writing and running the code | Install both extensions from the Extensions panel. |
| **Flutter SDK** (stable) | Builds the app | Unzip to a path without spaces, e.g. `C:\dev\flutter`, and add `C:\dev\flutter\bin` to PATH. |
| **Android Studio** | Android SDK, build tools, emulator, Java (bundled) | In SDK Manager also tick *Android SDK Command-line Tools*. Open it once so it finishes downloading. |
| Windows **Developer Mode** | Flutter plugins need symlink support on Windows | Settings → System → For developers → Developer Mode: On. |
| Android phone + USB data cable | Running each build on the real phone | Settings → About phone → tap *Build number* 7 times → Developer options → *USB debugging* on. |

Check with `flutter doctor` and accept licences with `flutter doctor --android-licenses`; every line should be green except the Visual Studio and Chrome ones, which aren't needed for an Android app.

**Needed later (no install today)**

| What | When | Notes |
|---|---|---|
| Supabase account (web) | Phase 1b — backup | Free tier; create one project. |
| Supabase CLI | Phase 2 — price job | Deploys the database tables and the price function. Docker Desktop is only needed to run Supabase locally, which is optional. |
| data.gov.in account (web) | Phase 2 — prices | Free API key for Agmarknet prices. |
| GitHub or Cursor-hosted repo | Anytime | Off-laptop copy of the code. |
| Google Play Console | Only if publishing | One-time registration fee; direct APK install needs nothing. |

Machine: 8 GB RAM minimum (16 GB if you use the emulator instead of your phone), about 15 GB free disk for Android Studio, the SDK and Flutter.

### 6.2 Repository layout

```
Karavali-Krishi/
  .github/workflows/          CI: analyze, test, build the APK on every push
  app/                        Flutter app (Android id: in.dharamitra.app)
    lib/
      main.dart, app.dart     start-up, router, bottom navigation
      core/                   database (Drift tables), providers, theme, l10n helpers, ₹/date utils
      l10n/                   app_en.arb, app_kn.arb (+ generated Dart, committed)
      features/
        farm/  home/  labour/  lots/  settings/      (Phase 1a)
        diary/  stock/  sales/  prices/  weather/  reports/  loans/  insurance/   (later)
          data/               repository
          domain/             models + calculations (pure Dart, fully tested)
          ui/                 screens + widgets
    assets/fonts/             Inter, Space Grotesk, Noto Sans Kannada (bundled for offline)
    test/                     core/, domain/, data/ (in-memory DB), widget/
  supabase/
    migrations/               cloud tables (backup + prices)
    functions/fetch-prices/   the twice-daily price job
  docs/                       this plan, screenshots
  prototype/                  clickable HTML prototype
```

### 6.3 Way of working
- **Branches:** `master` = what's installed on your phone; `develop` = current work; one `feature/F4-lots`-style branch per slice, merged into `develop`, then `develop` → `master` for each release (tagged `v0.1.0`, `v0.2.0`, …).
- **Vertical slices:** each feature is built end to end (database table → repository → calculations → screen → tests) before the next starts, so every build you install is usable.
- **Loop:** I build a slice → you install the APK and use it in the garden → you send feedback using the feature IDs → next slice.
- **The prototype stays the design reference;** screens are built to match it, and it gets updated first when a design changes.

### 6.4 Testing
- **Unit tests on every calculation**, because these must never be wrong: drying day counter, out-turn %, wage and ledger balances, loan interest and outstanding, cost per kg, season totals.
- **Database tests** on an in-memory SQLite, including migrations (so an update never loses data).
- **Widget tests** for the main forms (add activity, peeling entry, loan repayment).
- **Offline test on every release:** airplane mode on, use the app for a full "day", then turn the network on and confirm backup + price refresh happen by themselves.
- Manual check on a budget Android phone, in Kannada and English.

### 6.5 Release and safety
- Debug builds during development; a **signed release APK** for real use (the signing key is backed up, otherwise future updates can't install over the old app).
- Database migrations are versioned; an update never wipes data.
- Cloud backup from Phase 1b onward; before that, a one-tap "export database file" to share to Google Drive / WhatsApp as a safety copy.

### 6.6 Phases — timed to the harvest season
The main chali harvest starts in November, so the parts you need during harvest come first. Then this season's lots, labour and peeling costs are recorded from day one.

| Phase | Scope | Rough time | Ready by |
|---|---|---|---|
| 1a — Harvest essentials | Project setup, F1 (basic), F3 labour, F4.1–F4.8 areca lots, F10.1–F10.2, database export | ~3 weeks | mid-Nov |
| 1b — Diary & money | F2 (without voice), F5, F6, F10.4 cloud backup, F10.5 app lock | ~2 weeks | end Nov |
| 2 — Prices & weather | F7 with the Supabase price job, F8, offline banners | ~2–3 weeks | mid-Dec |
| 3 — Land, loans, insurance, reports | F11, F12, F9, F4.9–F4.12 (pepper before its Dec–Feb harvest) | ~3 weeks | early Jan |
| 4 — Polish | F2.5 / F10.3 voice, performance on budget phones, chosen ideas (I1, I2, I5–I7) | ongoing | — |

---

## 7. Prototype

Open `prototype/index.html` in any browser (no install). It is a clickable phone mock-up with sample data from a typical Puttur-area garden; use the English / ಕನ್ನಡ switch at the top. The panel on the right of the phone lists which feature IDs each screen covers.

The **Simulate offline** button next to the language switch shows how the app behaves with no signal (section 3): prices carry an "as of" time, the cached forecast and rain alert stay, backup waits, and every entry screen keeps working. Land & loans (F11) and Insurance & schemes (F12) open from the Home grid or from Settings.
