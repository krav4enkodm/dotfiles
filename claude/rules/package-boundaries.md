---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
  - "**/package.json"
  - "**/tsconfig*.json"
  - "**/project.json"
---

# Package boundaries

How code in a monorepo or multi-package repo depends on other code. Boundaries
are hard to undo once crossed, so treat a crossed boundary as a defect, not a
style choice. The repo's own rules and lint config win where they differ.

- **Import a package through its public entry point** (`@scope/utils`), never
  its `src/` internals, and mock the entry point in tests too. Export from the
  entry point only what other packages consume.
- **Inside a package, import from the defining file,** never from the
  package's own index: it hides cycles. When two modules import each other,
  move the shared types into their own file.
- **Dependencies point one way.**
  - A shared library never imports from an app or a feature library. Inject
    what it needs through props or config where it's used.
  - Sibling domains don't import each other. Move the shared part into its own
    library that both depend on, and promote it to a cross-team library only
    after checking the other consumers' needs.
  - Implementations depend on the abstraction, not the reverse.
  - Feature-only code stays out of top-level shared libraries.
- **No cycles.** If a dependency would create one, move the helper down to a
  lower-level library. Duplicating a tiny mock beats a cross-import.
- **Honest manifests.**
  - Runtime packages in `dependencies`, test and story tooling in
    `devDependencies`, and a peer dependency not listed again in `dependencies`.
  - No unused dependencies, and no new package for one small function a
    library already in use provides.
  - Scripts and config at package level unless they run across packages.
  - No stray `tsconfig` includes or copied build plugins you can't justify;
    prefer fixing the code over extending build config.
- **Generated or fetched files change at their source** (a schema in its own
  repo, generated types through the codegen command), never by hand.
- **Name a library after what it provides,** and keep its README in step with
  what it exports.
