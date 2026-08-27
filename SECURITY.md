# Security policy

## Reporting a vulnerability

**Do not open a public issue for a security vulnerability.**

Keelhaven handles repository passwords, storage credentials, and the contents
of the folders a user backs up. A publicly posted vulnerability report is
actionable by anyone who reads it before we have shipped a fix.

Report it privately through GitHub's
[private vulnerability reporting](https://github.com/shenxianpeng/keelhaven/security/advisories/new).

Please include what you found, how to reproduce it, and what an attacker could
do with it. If you have a proof of concept, keep it to the minimum needed to
demonstrate the issue.

## What happens next

- We acknowledge within **3 working days**.
- We confirm or dispute the finding, with reasoning, within **10 working days**.
- Confirmed vulnerabilities are fixed and released as a priority. Keelhaven is
  installed software: a fix ships as a new build, and we will say in the
  advisory which version carries it.
- We will tell you when the fix is live, and we are happy to credit you by name
  unless you prefer otherwise.

## Scope

In scope: Keelhaven itself — the app, KeelhavenCore, the release pipeline, and
how the app drives its bundled restic binary.

Out of scope, because they are not ours to fix:

- Vulnerabilities in [restic](https://restic.net), the backup engine Keelhaven
  bundles — tell us anyway if you find one through Keelhaven, and we will
  handle reporting it upstream. Flaws in how Keelhaven *drives* restic are in
  scope.
- Findings that require already-privileged local access to the user's Mac.

## Good faith

We will not pursue legal action against anyone who reports a vulnerability in
good faith, stays within the scope above, and gives us reasonable time to fix
it before disclosing publicly. We do not currently run a paid bounty programme.
