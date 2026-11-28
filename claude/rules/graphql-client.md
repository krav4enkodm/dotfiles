---
paths:
  - "**/*.{graphql,gql}"
  - "**/*.{tsx,jsx}"
  - "**/use[A-Z]*.{ts,js}"
---

# GraphQL on the client

Only for a repo whose frontend talks to its API through a GraphQL client
(Apollo, urql, Relay or similar). Ignore this file otherwise. The general
rules on types, state and data still apply; this adds what is specific to
GraphQL.

## Types

- **Type props from fragments, never from the query.** When a component needs
  part of a query result, define a fragment for it instead of `Pick<>` chains
  or `NonNullable<Q['a']['b']>['nodes'][number]`. Any query that spreads the
  fragment then fits the component, and a schema type holds fields the query
  never fetched. Pass the fragment object through (`item={edge.node}`) instead
  of rebuilding it; a component that uses most of a fragment's fields takes the
  fragment object as one prop.
- **A field the types lack is added to the fragment or selection,** never cast
  in.

## Fetching

- **Reuse an existing query or fragment** before adding a near-copy. Keep a
  single-use fragment next to its query.
- **A field added to a shared fragment loads everywhere it's spread,** lists
  included. When a component starts fetching its own data, remove those fields
  from the parent's fragment.

## After a mutation

- **With a normalised cache, select back the changed fields and the entity's
  id,** so only that entity updates. Refetch only what the cache can't update
  that way, through the `refetch` of the component that owns the query, rather
  than a list of query names that hides which screens are affected.

## Tests and stories

- **Type mocks with the generated fragment or operation types**
  (`const user: UserFragment = …`), and keep them next to the operation they
  mock.
