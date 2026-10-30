# Test discipline

What tests must prove. A test that passes without proving the behavior it names
is worse than no test: it turns a gap into a green check. Reviewing tests
someone else wrote is `ai/08-adversarial-review.md` rule 5; this module is the
same standard from the side of the one writing them.

> Placeholders in `<angle-brackets>` are bound in the repository's Bindings.

## 1. Verify persistence by reading it back

For any interaction that should persist something (a form submit, an API write,
a background job's output, a message consumed and stored), integration and
end-to-end tests **read the record back from the real store** and assert on
what was stored. Asserting on the response, the UI's confirmation, a log line,
or a mock is not verification.

**Why:** a response or a success message proves the request was handled, not
that the write happened. Writes get lost, stored with the wrong shape, attached
to the wrong record, or silently dropped by a mocked or misconfigured store.
Each of those passes a test that only checks what the caller saw.

**How:**

- Read back through the store's own access path: the repository's data layer,
  or a test handle on the real database (`<read-back>`). Never read it back
  through a cache that the code under test also uses.
- Assert on the stored fields that matter, including those the caller never
  sees: owner, status, timestamps, foreign keys.
- Updates and deletes get a read-back too. The new value, or the absence of the
  record, is the stored state to assert on.
- Unit tests with a fake store don't satisfy this rule. They show the code
  called the store, not that the store kept anything.
- A test of a persisting interaction with no read-back is unfinished. In review,
  it's a finding (`ai/08` rule 5).

## 2. A test must be able to fail

- **Check it fails without the change.** Reason it through, or run it against
  a revert when that is cheap. A test that passes either way pins nothing.
- **Derive expected values from their source.** Never paste in what the code
  happens to output today.
- **Don't weaken a test to make it pass.** Deleting an assertion, loosening it,
  or skipping the test lowers a gate (`ai/00` rule 4).
