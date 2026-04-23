# pdf2m3

`pdf2m3` will convert source PDFs into structured markdown that fits the knowledge layout described in [SPEC.md](../../SPEC.md).

The first M1 slice uses `pdftotext` for extraction and the `youaskm3-ingest` crate for deterministic markdown rendering.
`m3 add` uses this path as the repo-level entry point for PDFs and writes the result into `knowledge/papers/<name>/index.md`.

## Usage

```bash
tools/pdf2m3/pdf2m3.sh <input.pdf> <output.md> [source-label]
```

Example:

```bash
tools/pdf2m3/pdf2m3.sh ref/book.pdf knowledge/papers/book/index.md
./scripts/m3.sh add ref/book.pdf
```

The generated markdown includes:

- a document title derived from the PDF file name
- source traceability metadata
- normalized extracted text grouped into markdown paragraphs
