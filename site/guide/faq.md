# FAQ

::: warning Draft
Keelhaven has not shipped its first public release yet. This page will grow as
real questions come in.
:::

## Does this replace Time Machine?

No — run both. Time Machine is excellent at putting a whole Mac back the way it
was, from a drive on your desk. Keelhaven is for the second copy: the folders
you can't lose, encrypted, somewhere that isn't your desk.

## Do I need to install restic first?

No. Keelhaven ships with its own copy of restic inside the app bundle, so
there's nothing else to install and nothing to keep up to date. If you already
run your own restic build, you can point Keelhaven at it instead.

## Why pay for this if restic is free?

Because restic isn't the part that's missing.

restic is an excellent backup engine, and you are not paying us for it — it's
free, it's open source, and you can use it directly without Keelhaven. What you
get for the price is everything a command-line tool deliberately leaves to you:

- A schedule that actually runs — no `launchd` plist to hand-write and debug.
- Repository passwords and S3 keys held in the macOS Keychain, passed to restic
  through the environment, never written to disk, a log, or a command line.
- A menu bar that stays quiet when backups work, and tells you the real restic
  error when one doesn't — not a red dot that says "problem".
- Setup that doesn't start with reading documentation.

If that's work you enjoy doing yourself, use restic directly — genuinely, it's
a great tool. Keelhaven is for people who want it done for them.

The honest version of this answer is that our lock-in is zero by design, so we
have to be worth paying for every year. That's the intended trade.

## Am I locked into Keelhaven?

No. Keelhaven is a front end, not a file format. Every plan writes an ordinary
restic repository, so you can list, verify, and restore it with the open-source
restic CLI on any Mac or Linux box — with or without Keelhaven installed:

```console
$ restic -r /Volumes/Archive/keelhaven snapshots
enter password for repository:
repository 9f21e4c3 opened (version 2)

ID        Time                 Host          Paths
--------------------------------------------------------
4a1f8b02  2026-08-15 09:00:12  studio.local  /Users/you/Documents
b7c3e910  2026-08-14 09:00:07  studio.local  /Users/you/Documents
--------------------------------------------------------
2 snapshots
```

If Keelhaven disappears tomorrow, your backups don't. That is the whole point.

## Is Keelhaven open source?

The app itself is a paid, closed-source product.

Its backup engine is not: Keelhaven bundles and redistributes
[restic](https://restic.net), which is open source under the BSD 2-Clause
License. See [Open source licenses](/licenses) for the full notice.

So while you can't read Keelhaven's source, you are never dependent on it to
reach your data — the repositories it writes are readable with open source
tools you can inspect yourself.

## Is my data readable by anyone else?

No. Backups are encrypted on your Mac before anything is uploaded, and the
repository password is stored only in your macOS Keychain.

## Where exactly do my files go?

Only to the destination you configured, and only after they're encrypted on
your Mac. There is no Keelhaven server, no account system, and no telemetry —
the app has nowhere else to send anything.

## Which destinations are supported?

An external or network drive mounted on your Mac, any S3-compatible bucket
(AWS, Backblaze B2, Wasabi, Cloudflare R2, MinIO), and SFTP to your own server
or NAS.

## What happens if I forget the repository password?

The backup is unrecoverable, by design. restic repositories are encrypted end
to end, and nobody — not us, not your storage provider — holds a spare key.

Keelhaven stores the password in your macOS Keychain and can copy it back out
after a Touch ID check. Put it in your password manager too.

## Why isn't it on the Mac App Store?

App Store apps must run in the sandbox, and the restic process needs to read
arbitrary folders you point it at and open network and SSH connections.
Keelhaven ships with the hardened runtime enabled and signed builds, just not
through the store.
