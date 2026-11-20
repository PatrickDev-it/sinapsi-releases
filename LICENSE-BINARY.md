# Sinapsi Binary License

This license governs the compiled `sinapsi` executable ("the Binary") distributed
for macOS and Windows. It does not apply to the source code in this repository,
which remains proprietary under `LICENSE`.

## Grant

Copyright (c) 2026 Patrick Simonetti. Subject to the terms below, you are
granted a free, worldwide, non-exclusive, non-transferable license to:

- download and install the Binary on any number of machines you own or control;
- use the Binary for any purpose, including commercial use, at no charge;
- redistribute the **unmodified** Binary, provided this license file accompanies
  it and no fee is charged for the redistribution itself.

## Restrictions

You may not:

- modify, patch, or create derivative works of the Binary;
- reverse engineer, decompile, or disassemble the Binary, except to the extent
  such restriction is prohibited by applicable law in your jurisdiction;
- remove or alter any copyright, trademark, or attribution notice embedded in
  the Binary or its output;
- use the Binary to build a competing product whose primary function is to
  extract, replicate, or re-expose Sinapsi's source code or internal data
  formats beyond the documented `graph.json` schema and MCP tool contract.

## No warranty

THE BINARY IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED. THE COPYRIGHT HOLDER IS NOT LIABLE FOR ANY DAMAGES ARISING FROM ITS
USE, TO THE MAXIMUM EXTENT PERMITTED BY LAW.

## What stays open

This license covers the binary only. Two things are not covered because they
are not proprietary:

- **`validation/`** — the benchmark corpus and harness that produce every
  number this project publishes — is MIT-licensed and lives in the public
  validation repository, so anyone can rerun the measurements independently.
- **The four-line context format** (`RELEVANCE`/`COVERAGE`/`STRUCTURE`/
  `FRESHNESS`) is an openly documented specification. Any tool is free to
  implement and emit it; only Sinapsi's own implementation is proprietary.

## Termination

This license terminates automatically if you breach any restriction above.
Upon termination you must stop using and delete all copies of the Binary.

---

*This is a plain-language license drafted for a small software project. It has
not been reviewed by legal counsel and should not be treated as a substitute
for professional legal advice, particularly for enterprise, government, or
regulated-industry deployments — contact the copyright holder for a reviewed
commercial agreement in those cases.*
