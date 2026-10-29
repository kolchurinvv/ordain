---
name: verify-persistence-by-read-back
description: Integration and e2e tests verify every persisting interaction by reading the record back from the real store
metadata:
  type: feedback
status: candidate
scope: baseline
target: a testing rule beside ai/03-defensive-coding.md; a review check under ai/08 rule 5
---

**Rule:** For any interaction that should persist something (a form submit, an
API write, a background job's output), integration and e2e tests read the record
back from the real store and assert on what was stored. Asserting on the HTTP
response, the UI's confirmation, or a mock is not verification.

**Why:** A response or a success toast proves the request was handled, not that
the write happened. Writes get lost, stored with the wrong shape, written to the
wrong record, or silently dropped by a mocked or misconfigured store, and every
one of those passes a test that only checks what the caller saw.

**How to apply:** When writing or reviewing a test of a persisting interaction,
add a read-back through the store's real access path and assert on the stored
fields that matter. Treat a test without one as unfinished, and a review that
finds one missing as a finding.

**Binding:** How this repository reads a record back in tests: the store, the
access helper or test handle to use, and how test data is isolated.
