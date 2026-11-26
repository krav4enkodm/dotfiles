---
paths:
  - "**/*.{tsx,jsx}"
---

# Frontend feature layers

How to lay out a data-backed feature (page, screen, drawer, modal, widget). The
container reads top to bottom as **fetch → derive → compose**; every other
component is presentational: data and callbacks arrive as props.

## Layers

1. **Data**: the API operations and their generated types. Reuse an existing
   operation before adding one.
2. **Services**: the logic, unit-tested without React.
   - Pure `get*`/`to*` functions map the API's shape to the view's shape (sort,
     group, format, label) and export the view types.
   - A `use*` data hook is worth having only when it adds something to the
     operation, such as building its variables. It then returns the client's
     result unchanged. A hook that only calls the client's query hook is
     inlined. One hook per file.
   - Services may import types from the data layer, never from components or
     containers.
3. **Presentational components** receive data, loading state and callbacks as
   props, and never touch the data layer.
   - Each owns its own loading, empty and error rendering: pass it `loading`
     rather than wrapping it in a spinner.
   - One per visual section (header, chart, table…).
   - Callback props are `on<Event>`, internal handlers `handle<Event>`.
4. **Container**: calls the hooks, passes results through services, holds the
   loading and error state, and composes the components. No section JSX, no
   `.map()`, no mapping logic.
