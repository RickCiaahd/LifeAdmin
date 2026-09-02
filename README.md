# LifeAdmin

LifeAdmin is a local-first Flutter app for managing personal deadlines, renewals, bills, documents, and recurring responsibilities.

## Product idea

The app is designed around **things you are responsible for**, not around generic calendar events.

Examples:

- Car → insurance, road tax, inspection, service
- Home → electricity, gas, internet, taxes, boiler maintenance
- Person → ID card, driving licence, passport, PEC
- Subscriptions → renewals and recurring payments

A responsibility remains visible until it is actually resolved. Completing or renewing it can create the next due date and preserve a history of dates and amounts.

## MVP

- Dashboard with overdue and upcoming responsibilities
- Objects such as Home, Car, Person
- One-off and recurring deadlines
- States: pending, overdue, paid/completed, renewed
- Completion / renewal flow with optional amount and notes
- Local history
- Local notifications
- Offline-first persistence
- No account, backend, AI, OCR, or banking integration required

## Technical direction

- Flutter
- Android-first
- Local-first storage
- Material 3
- Architecture kept intentionally simple for the first personal-use MVP

## Status

Initial project setup in progress.
