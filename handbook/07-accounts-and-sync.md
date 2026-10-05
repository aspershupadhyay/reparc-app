---
title: Accounts and sync
status: proposed
owner: product-and-security
updated: 2026-10-05
---

# Section 8: Accounts and sync

## 8.1 Purpose

An account can identify a user. Sync can copy app records between devices. Backup can help restore records. These are separate functions.

## 8.2 No-account use

Let a user try core logging without sign-in. Tell the user that data stored only on one phone may be lost if that phone is lost, damaged, or erased.

Offer export before asking the user to create an account.

## 8.3 Sign-in

If accounts are added, support Apple and Google sign-in through a reviewed OpenID Connect flow. Use platform rules for sign-in buttons and account deletion.

Signing in does not mean that workout or meal records are backed up. Apple or Google sign-in provides identity. It does not automatically save app records to the user's Apple or Google storage. Choose a separate storage and sync service if records must move between devices. Explain the difference before sign-in.

Give each app account a stable internal user ID. Link Apple or Google identities to that ID after the user proves access to both accounts. Do not merge accounts only because email addresses match. Apple can provide a private relay address. Give the user a safe way to merge or keep separate records.

If Google sign-in is offered as the primary account sign-in on iPhone, review current App Store rule 4.8. It may require an equivalent sign-in option with privacy features, such as Sign in with Apple. Re-check the rule before submission.

**To confirm:** Whether email sign-in is needed. Do not add it without a user need.

## 8.4 Sync setup

Before sync starts:

1. Explain which records will leave the phone.
2. Explain where records will be stored.
3. Explain how the user can stop sync.
4. Explain export and deletion.
5. Ask for a separate choice to enable sync.

Do not make sync mandatory for core logging.

## 8.5 Sync behavior

- Send only changed records.
- Use record IDs and revision numbers.
- Make retries safe.
- Detect edits made on two devices.
- Do not merge identities or records by email alone.
- Do not silently replace one user's edit with another.
- Keep a deletion marker until the server confirms deletion.
- Show when sync last succeeded.
- Keep local logging available during a server outage.

## 8.6 Recovery and device change

Before release, decide how the user gets records on a new device. Test account recovery and restore from backup.

**To confirm:** The recovery model. Account sign-in alone is not enough if the data is encrypted with a key the user cannot restore. Test Apple-to-Android and Android-to-iPhone account linking and restore.

Official source: [Apple App Review Guidelines, section 4.8](https://developer.apple.com/app-store/review/guidelines/).

## 8.7 AI context

- **Purpose:** Give users optional account and device continuity.
- **Separate:** Identity, sync, backup, and encryption.
- **Default:** Core logging does not require an account.
- **Consent:** Sync is a separate choice.
- **Safety:** Do not promise recovery before testing it.
- **To confirm:** Identity provider, cloud provider, key recovery, retention, and deletion timing.
