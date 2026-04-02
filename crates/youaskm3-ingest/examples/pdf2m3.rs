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

    ensure_output_directory(Path::new(&output_path))?;

    fs::write(output_path, markdown)?;
    Ok(())
}

fn ensure_output_directory(output_path: &Path) -> Result<(), Box<dyn Error>> {
    if let Some(parent) = output_path.parent()
        && !parent.as_os_str().is_empty()
    {
        fs::create_dir_all(parent)?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::ensure_output_directory;
    use std::{
        fs,
        path::PathBuf,
        time::{SystemTime, UNIX_EPOCH},
    };

    #[test]
    fn output_in_current_directory_does_not_require_parent_creation() {
        assert!(ensure_output_directory(PathBuf::from("out.md").as_path()).is_ok());
    }

    #[test]
    fn nested_output_path_creates_missing_parent_directory() {
        let unique = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system time should be after unix epoch")
            .as_nanos();
        let root = std::env::temp_dir().join(format!("youaskm3-pdf2m3-{unique}"));
        let output_path = root.join("nested").join("out.md");

        ensure_output_directory(&output_path)
            .expect("creating nested parent directories should succeed");

        assert!(root.join("nested").is_dir());

        fs::remove_dir_all(root).expect("temporary directory cleanup should succeed");
    }
}
