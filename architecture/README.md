# MaMpf Architecture Book

This folder contains an mdBook describing a proposal for the architecture that is neceaary to integrate MÜSLI into MaMpf(registration, allocation, assessments, eligibility, administration, workflow, and diagrams).

## Quick Start

Prerequisites:
- Rust toolchain (for installing mdBook)

Install tools:
```
cargo install mdbook mdbook-mermaid mdbook-mermaid
```

Build and serve locally with auto-reload (note that we use port 3003 because port 3000 is used for serving MaMpf locally)

```
cd architecture
mdbook build
mdbook serve --port 3003
```

## Structure
- book/book.toml : mdBook config 
- book/src/       : all chapter markdown + diagrams
- src/features/   : original source planning docs (authoritative originals)