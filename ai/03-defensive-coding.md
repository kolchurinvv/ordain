# Defensive coding

**The application must never crash from an upstream, external, or system
failure.** Networks time out, peers return malformed payloads, local storage
isn't writable (no permission, disk full, missing entitlement), native/FFI
modules throw. The correct response is always graceful degradation: safe
default, no-op, fall back, log and continue. Never a crash, never an unhandled
rejection.

This is language-agnostic; the canonical patterns differ but the boundaries are
the same.

## The six boundaries

1. **Every call into native / FFI / external code has a failure boundary.**
   Synchronous calls into native code are especially dangerous — an exception
   can propagate across the language bridge and abort the process. Wrap them;
   log a warning; return a safe fallback (`null`/`None` for reads, no-op for
   writes). Factor the wrapper once (a `safeStorage`-style helper) rather than
   scattering try/catch.

2. **Every parsed external payload is schema-validated before use.** Anything
   crossing a trust boundary — HTTP response, config file, deserialized
   storage, IPC/queue message — is validated against a schema before you touch
   its fields. Trusting `JSON.parse(...)` / a backend response to be the right
   shape is a defect waiting to happen. Reuse the project's validation library.

3. **Every storage read assumes the value might be missing OR malformed.**
   Coerce and validate after reading. Old/legacy shapes must degrade
   gracefully, not throw.

4. **Every async path has a failure branch.** A promise/future without a
   rejection handler is a bug. An `await` without a surrounding guard is a bug.
   Background tasks and effect callbacks that can reject need their own internal
   handling — an unhandled rejection there can still take down the process.

5. **Failure logs are debuggable.** Include the operation, sanitized inputs (no
   tokens, no passwords, no PII), and the error. Use `warn` for "recovered, but
   worth knowing"; `error` for "recovered to a degraded state that matters."

6. **Crash deliberately only for invariant violations.** Programmer-error
   assertions — unreachable states, exhaustive type-narrowing defaults,
   "this can't happen" — are *fine* to throw; they catch bugs early. **External
   failure is never an invariant violation** and must never be modeled as one.

The distinction in rule 6 is the whole point: fail loud on *your* bugs, fail
soft on *the world's* failures.
