---
paths:
  - "**/*.{graphql,gql}"
  - "**/{graphql,resolvers}/**"
  - "**/*.resolver.{ts,js}"
---

# Publishing a GraphQL API

Only for a backend that publishes a GraphQL API. Ignore this file otherwise.
The backend rules on API contracts still apply; this adds what is specific to
GraphQL.

- **Namespace new root fields under their domain** instead of adding them flat
  to `Query` or `Mutation`.
- **A mutation returns the objects the client re-renders,** usually the parent
  of what changed, with their ids, so a normalised client cache updates them
  without a refetch.
