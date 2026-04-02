#![forbid(unsafe_code)]
#![warn(clippy::all, clippy::pedantic)]

use std::fmt;

/// Returns the stable identifier for the ingest crate.
#[must_use]
pub const fn crate_name() -> &'static str {
    "youaskm3-ingest"
}

/// Metadata and extracted text needed to render a PDF-backed markdown artifact.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PdfMarkdownInput {
    /// Human-readable title for the generated document.
    pub title: String,
    /// Source PDF path or identifier used for traceability.
    pub source_path: String,
    /// Extracted plain text content from the PDF.
    pub extracted_text: String,
}

/// Errors returned when PDF ingest input is incomplete.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PdfMarkdownError {
    /// The title was empty after trimming.
    MissingTitle,
    /// The source path was empty after trimming.
    MissingSourcePath,
    /// The extracted text was empty after trimming.
    MissingExtractedText,
}

impl fmt::Display for PdfMarkdownError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::MissingTitle => f.write_str("missing PDF title"),
            Self::MissingSourcePath => f.write_str("missing PDF source path"),
            Self::MissingExtractedText => f.write_str("missing extracted PDF text"),
        }
    }
}

impl std::error::Error for PdfMarkdownError {}

/// Builds a stable markdown artifact from extracted PDF text.
///
/// # Errors
///
/// Returns an error if the title, source path, or extracted text is empty after trimming.
pub fn render_pdf_markdown(input: &PdfMarkdownInput) -> Result<String, PdfMarkdownError> {
    let title = input.title.trim();
    let source_path = input.source_path.trim();
    let extracted_text = input.extracted_text.trim();

    if title.is_empty() {
        return Err(PdfMarkdownError::MissingTitle);
    }

    if source_path.is_empty() {
        return Err(PdfMarkdownError::MissingSourcePath);
    }

    if extracted_text.is_empty() {
        return Err(PdfMarkdownError::MissingExtractedText);
    }

    let paragraphs = normalize_pdf_text(extracted_text);
    let body = paragraphs.join("\n\n");
    let source_line = render_source_line(source_path);

    Ok(format!(
        "# {title}\n\n## Source\n\n- type: pdf\n- {source_line}\n- ingested_by: `pdf2m3`\n\n## Extracted Text\n\n{body}\n"
    ))
}

/// Derives a human-readable title from a PDF file path or file name.
#[must_use]
pub fn derive_title_from_path(path: &str) -> String {
    let trimmed = path.trim();
    let file_name = trimmed
        .rsplit(['/', '\\'])
        .next()
        .unwrap_or(trimmed)
        .strip_suffix(".pdf")
        .unwrap_or(trimmed);

    let normalized = file_name
        .chars()
        .map(|character| {
            if matches!(character, '-' | '_' | '.') {
                ' '
            } else {
                character
            }
        })
        .collect::<String>();

    normalized.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// Normalizes extracted PDF text into markdown-friendly paragraphs.
#[must_use]
pub fn normalize_pdf_text(text: &str) -> Vec<String> {
    let normalized_newlines = text.replace("\r\n", "\n").replace('\r', "\n");
    let mut paragraphs = Vec::new();
    let mut current_lines: Vec<String> = Vec::new();

    for line in normalized_newlines.lines() {
        let trimmed = line.trim();

        if trimmed.is_empty() {
            if !current_lines.is_empty() {
                paragraphs.push(current_lines.join(" "));
                current_lines.clear();
            }
            continue;
        }

        current_lines.push(trimmed.to_string());
    }

    if !current_lines.is_empty() {
        paragraphs.push(current_lines.join(" "));
    }

    paragraphs
}

fn render_source_line(source_path: &str) -> String {
    format!("path: {}", source_path.trim())
}

#[cfg(test)]
mod tests {
    use super::{
        PdfMarkdownError, PdfMarkdownInput, crate_name, derive_title_from_path, normalize_pdf_text,
        render_pdf_markdown,
    };

    #[test]
    fn crate_name_matches_package() {
        assert_eq!(crate_name(), "youaskm3-ingest");
    }

    #[test]
    fn derive_title_from_path_uses_file_stem() {
        assert_eq!(
            derive_title_from_path("ref/Universal_Microservices-Architecture.pdf"),
            "Universal Microservices Architecture"
        );
    }

    #[test]
    fn normalize_pdf_text_collapses_lines_into_paragraphs() {
        let normalized = normalize_pdf_text("Line one\nline two\n\nLine three\r\nline four\r\n");

        assert_eq!(
            normalized,
            vec![
                "Line one line two".to_string(),
                "Line three line four".to_string()
            ]
        );
    }

    #[test]
    fn render_pdf_markdown_includes_traceability_metadata() {
        let input = PdfMarkdownInput {
            title: "Universal Microservices Architecture".to_string(),
            source_path: "ref/book.pdf".to_string(),
            extracted_text: "First paragraph.\nStill first paragraph.\n\nSecond paragraph."
                .to_string(),
        };
        let expected = "# Universal Microservices Architecture\n\n## Source\n\n- type: pdf\n- path: ref/book.pdf\n- ingested_by: `pdf2m3`\n\n## Extracted Text\n\nFirst paragraph. Still first paragraph.\n\nSecond paragraph.\n";

        assert_eq!(render_pdf_markdown(&input), Ok(expected.to_string()));
    }

    #[test]
    fn render_pdf_markdown_keeps_source_label_with_backticks_stable() {
        let input = PdfMarkdownInput {
            title: "Example".to_string(),
            source_path: "notes/`quoted`.pdf".to_string(),
            extracted_text: "Paragraph.".to_string(),
        };

        let markdown = render_pdf_markdown(&input).expect("rendering markdown should succeed");

        assert!(markdown.contains("- path: notes/`quoted`.pdf\n"));
    }

    #[test]
    fn render_pdf_markdown_rejects_missing_text() {
        let input = PdfMarkdownInput {
            title: "Example".to_string(),
            source_path: "ref/example.pdf".to_string(),
            extracted_text: "   ".to_string(),
        };

        assert_eq!(
            render_pdf_markdown(&input),
            Err(PdfMarkdownError::MissingExtractedText)
        );
    }
}
