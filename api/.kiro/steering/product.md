# Product

`t_automation` is a test/exploration project for **Spec-Driven Development with LLM assistance**. It is built on top of the `benavlabs/fastapi-boilerplate` and serves as a working laboratory for iterating on the full spec-to-implementation workflow.

The API provides user management, authentication, posts (with moderation), rate limiting, and tiered access. Each capability is implemented as a vertical slice and is considered "done" only when its outside-in acceptance test is green.

Development is intentionally LLM-driven: every new slice goes through a full specification cycle (PRD → plan → requirements → validation → tests) before any code is written.
