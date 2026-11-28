---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
  - "**/package.json"
  - "**/tsconfig*.json"
  - "**/project.json"
---

# Package boundaries

How code in a multi-package repo depends on other code.

- **Import a package through its public entry point** (`@scope/utils`), never
  its `src/` internals, and mock the entry point in tests too. Export from the
  entry point only what other packages consume.
- **Inside a package, import from the defining file,** never from the package's
  own index: it creates cycles. Don't add `index.ts` re-export files below the
  package root unless the package already uses them: each one is another way
  into the same code and a common source of cycles. When two modules import each
  other, move the shared types into their own file.
- **Dependencies point one way.**
  - A shared library never imports from an app or a feature library; it
    receives what it needs through props or config.
  - Sibling domains don't import each other. Move the shared part into a
    library both depend on, after checking what its other consumers need.
  - Feature-only code stays out of top-level shared libraries.
  - A page never imports from another page, and shared code never imports
    from a page; a shared hook takes the feature's callback as a parameter.
  - If a dependency would create a cycle, move the helper down to a lower-level
    library. Duplicating a tiny mock beats a cross-import.
- **Honest manifests.**
  - Runtime packages in `dependencies`, test and story tooling in
    `devDependencies`, and a peer dependency not listed again in `dependencies`.
  - No unused dependencies, and no new package for one small function a
    library already in use provides.
  - Scripts and config at package level unless they run across packages.
  - Prefer fixing the code over extending build config.
- **Generated or fetched files change at their source** (a schema in its own
  repo, generated types through the codegen command), never by hand.
- **Name a library after what it provides,** and keep its README in step with
  what it exports.
