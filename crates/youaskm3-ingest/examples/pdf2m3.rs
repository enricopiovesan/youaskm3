use std::{env, error::Error, fs, path::Path};

use youaskm3_ingest::{PdfMarkdownInput, derive_title_from_path, render_pdf_markdown};

fn main() {
    if let Err(error) = run() {
        eprintln!("pdf2m3 example failed: {error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn Error>> {
    let mut arguments = env::args().skip(1);
    let input_path = arguments
        .next()
        .ok_or("usage: cargo run -p youaskm3-ingest --example pdf2m3 -- <input.txt> <output.md> [source.pdf]")?;
    let output_path = arguments
        .next()
        .ok_or("usage: cargo run -p youaskm3-ingest --example pdf2m3 -- <input.txt> <output.md> [source.pdf]")?;
    let source_path = arguments.next().unwrap_or_else(|| input_path.clone());

    let extracted_text = fs::read_to_string(&input_path)?;
    let markdown = render_pdf_markdown(&PdfMarkdownInput {
        title: derive_title_from_path(&source_path),
        source_path,
        extracted_text,
    })?;

    if let Some(parent) = Path::new(&output_path).parent() {
        fs::create_dir_all(parent)?;
    }

    fs::write(output_path, markdown)?;
    Ok(())
}
