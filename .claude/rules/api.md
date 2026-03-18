---
paths: ["docs/api.md", "disco-science-lite.d.*"]
---

# API Rules

- Always update `docs/api.md`, `disco-science-lite.d.lua` and `disco-science-lite.d.ts` for any API changes. Keep them consistent.

## Compatibility with original DiscoScience

- Design the API with compatibility with the original DiscoScience mod in mind. The original DiscoScience provides: `prepareLab`, `setLabScale`, `setIngredientColor`, and `getIngredientColor`.
- Make it easy for other mod authors to support both DiscoScience and disco-science-lite at the same time (dual-support). Prefer matching the original API's function names and signatures wherever it makes sense.
- When deviating from the original API (e.g. adding new parameters or functions), do so in a way that does not break dual-support patterns.

## API Documentation Style

- Write in plain, simple English. Avoid overly technical language or jargon.
- Write from the perspective of another mod author integrating this API. Focus on what they need to know to use the function, not on internal implementation details.
- Keep descriptions concise and easy to understand.
