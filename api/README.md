# t_automation

A test project for exploring **Spec-Driven Design** with LLM assistance.

Cloned from [benavlabs/fastapi-boilerplate](https://github.com/benavlabs/fastapi-boilerplate) and reworked into a **Vertical Slice + Hexagonal** architecture described in `agent_docs/architecture.md`.

Development is iterative and LLM-driven: each new slice goes through a full specification cycle — PRD → plan → requirements → validation → tests — and is considered done only when the outside-in acceptance test turns green.
