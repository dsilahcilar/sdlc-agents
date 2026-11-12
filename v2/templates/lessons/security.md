# Security lessons

Traps this repository has fallen into that a general security review would not know about. Hand this file to the security review when the gate asks for one.

- One entry is one or two lines: the date, the pull request or incident it came from, and what to look for.
- At most 40 lines of entries. To add one when the file is full, take one out.
- An entry leaves when a check in code covers it, or after 90 days in which no review used it.
- Entries arrive in their own pull request, never inside a change they would judge.
- Describe the trap, never a working exploit, and never a secret.

<!-- Entry format.

- 2026-01-31 (#123): Uploaded file names end up in a storage path. Check that a change to uploads still strips path separators. uses: 0

-->
