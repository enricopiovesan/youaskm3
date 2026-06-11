# markitdown2m3

`markitdown2m3` uses [Microsoft MarkItDown](https://github.com/microsoft/markitdown) as a repo-local ingest adapter for supported file types beyond the existing PDF and URL paths.

The first integration slice is intentionally narrow:

- it keeps `youaskm3`'s own markdown structure and source traceability rules
- it pins MarkItDown through a repo-local setup script
- it routes supported local files into `knowledge/inputs/notes/`

## Supported file types in this slice

The MarkItDown-backed path is intended for local files such as:

- `.html`
- `.htm`
- `.docx`
- `.pptx`
- `.xlsx`
- `.xls`
- `.csv`
- `.json`
- `.xml`
- `.epub`
- `.zip`

Support depends on the installed MarkItDown package and any optional dependencies it requires. The first smoke path validates HTML ingest explicitly.

## Usage

```bash
tools/markitdown2m3/markitdown2m3.sh <input-file> <output.md> [title]
```

Example:

```bash
tools/markitdown2m3/markitdown2m3.sh ref/example.html knowledge/inputs/notes/example.md
./scripts/m3.sh add ref/example.html
```

The generated markdown includes:

- a document title derived from the file name or supplied title
- source traceability metadata
- the original file format handled by MarkItDown
- the Markdown body produced by MarkItDown
