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

/// Metadata and captured text needed to render a URL-backed markdown artifact.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UrlMarkdownInput {
    /// Human-readable title for the generated document.
    pub title: String,
    /// Source URL used for traceability.
    pub source_url: String,
    /// Captured text content fetched from the URL.
    pub captured_text: String,
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

/// Errors returned when URL ingest input is incomplete.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum UrlMarkdownError {
    /// The title was empty after trimming.
    MissingTitle,
    /// The source URL was empty after trimming.
    MissingSourceUrl,
    /// The captured text was empty after trimming.
    MissingCapturedText,
}

impl fmt::Display for UrlMarkdownError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::MissingTitle => f.write_str("missing URL title"),
            Self::MissingSourceUrl => f.write_str("missing source URL"),
            Self::MissingCapturedText => f.write_str("missing captured URL text"),
        }
    }
}

impl std::error::Error for UrlMarkdownError {}

/// Markdown content ready to be split into index-friendly chunks.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MarkdownChunkInput {
    /// Human-readable title shared by generated chunks.
    pub title: String,
    /// Source path used for traceability and deterministic chunk identifiers.
    pub source_path: String,
    /// Markdown body to split into chunks.
    pub markdown: String,
}

/// Configuration for deterministic markdown chunking.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ChunkingOptions {
    /// Maximum number of UTF-8 bytes allowed in each chunk body.
    pub max_chunk_bytes: usize,
}

impl ChunkingOptions {
    /// Creates chunking options from a maximum byte size.
    #[must_use]
    pub const fn new(max_chunk_bytes: usize) -> Self {
        Self { max_chunk_bytes }
    }
}

/// One deterministic markdown chunk produced by the ingest crate.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MarkdownChunk {
    /// Stable chunk identifier derived from the source path and sequence.
    pub id: String,
    /// One-based chunk sequence within the source document.
    pub sequence: usize,
    /// Human-readable source title.
    pub title: String,
    /// Source path copied from the input for traceability.
    pub source_path: String,
    /// Markdown content assigned to this chunk.
    pub markdown: String,
}

/// Errors returned when markdown chunking input is incomplete or invalid.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MarkdownChunkError {
    /// The title was empty after trimming.
    MissingTitle,
    /// The source path was empty after trimming.
    MissingSourcePath,
    /// The markdown body was empty after trimming.
    MissingMarkdown,
    /// The configured chunk size was zero.
    InvalidChunkSize,
}

impl fmt::Display for MarkdownChunkError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::MissingTitle => f.write_str("missing markdown title"),
            Self::MissingSourcePath => f.write_str("missing markdown source path"),
            Self::MissingMarkdown => f.write_str("missing markdown content"),
            Self::InvalidChunkSize => f.write_str("invalid markdown chunk size"),
        }
    }
}

impl std::error::Error for MarkdownChunkError {}

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

/// Builds a stable markdown artifact from URL-captured text.
///
/// # Errors
///
/// Returns an error if the title, source URL, or captured text is empty after trimming.
pub fn render_url_markdown(input: &UrlMarkdownInput) -> Result<String, UrlMarkdownError> {
    let title = input.title.trim();
    let source_url = input.source_url.trim();
    let captured_text = input.captured_text.trim();

    if title.is_empty() {
        return Err(UrlMarkdownError::MissingTitle);
    }

    if source_url.is_empty() {
        return Err(UrlMarkdownError::MissingSourceUrl);
    }

    if captured_text.is_empty() {
        return Err(UrlMarkdownError::MissingCapturedText);
    }

    let paragraphs = normalize_pdf_text(captured_text);
    let body = paragraphs.join("\n\n");

    Ok(format!(
        "# {title}\n\n## Source\n\n- type: url\n- url: {source_url}\n- ingested_by: `url2m3`\n\n## Captured Text\n\n{body}\n"
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

/// Derives a human-readable title from a URL.
#[must_use]
pub fn derive_title_from_url(url: &str) -> String {
    let trimmed = url.trim().trim_end_matches('/');
    let without_fragment = trimmed.split('#').next().unwrap_or(trimmed);
    let without_query = without_fragment
        .split('?')
        .next()
        .unwrap_or(without_fragment);
    let last_segment = without_query
        .rsplit('/')
        .next()
        .filter(|segment| !segment.is_empty())
        .unwrap_or("url capture");

    let normalized = last_segment
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

/// Splits markdown into deterministic source-aware chunks.
///
/// Paragraphs are packed in order until adding another paragraph would exceed
/// `max_chunk_bytes`. Paragraphs larger than the limit become their own chunk
/// so content is never dropped or rewritten.
///
/// # Errors
///
/// Returns an error when the title, source path, or markdown body is empty, or
/// when the configured chunk size is zero.
pub fn chunk_markdown(
    input: &MarkdownChunkInput,
    options: ChunkingOptions,
) -> Result<Vec<MarkdownChunk>, MarkdownChunkError> {
    let title = input.title.trim();
    let source_path = input.source_path.trim();
    let markdown = input.markdown.trim();

    if title.is_empty() {
        return Err(MarkdownChunkError::MissingTitle);
    }

    if source_path.is_empty() {
        return Err(MarkdownChunkError::MissingSourcePath);
    }

    if markdown.is_empty() {
        return Err(MarkdownChunkError::MissingMarkdown);
    }

    if options.max_chunk_bytes == 0 {
        return Err(MarkdownChunkError::InvalidChunkSize);
    }

    let paragraphs = normalize_pdf_text(markdown);
    let chunk_bodies = pack_paragraphs(&paragraphs, options.max_chunk_bytes);

    Ok(chunk_bodies
        .into_iter()
        .enumerate()
        .map(|(index, body)| {
            let sequence = index + 1;
            MarkdownChunk {
                id: format!("{}#chunk-{sequence:04}", stable_source_id(source_path)),
                sequence,
                title: title.to_string(),
                source_path: source_path.to_string(),
                markdown: body,
            }
        })
        .collect())
}

fn pack_paragraphs(paragraphs: &[String], max_chunk_bytes: usize) -> Vec<String> {
    let mut chunks = Vec::new();
    let mut current = String::new();

    for paragraph in paragraphs {
        let candidate_len = if current.is_empty() {
            paragraph.len()
        } else {
            current.len() + 2 + paragraph.len()
        };

        if !current.is_empty() && candidate_len > max_chunk_bytes {
            chunks.push(current);
            current = String::new();
            append_paragraph(&mut current, paragraph);
        } else {
            append_paragraph(&mut current, paragraph);
        }
    }

    if !current.is_empty() {
        chunks.push(current);
    }

    chunks
}

fn append_paragraph(current: &mut String, paragraph: &str) {
    if !current.is_empty() {
        current.push_str("\n\n");
    }

    current.push_str(paragraph);
}

fn stable_source_id(source_path: &str) -> String {
    source_path
        .chars()
        .map(|character| {
            if character.is_ascii_alphanumeric() {
                character.to_ascii_lowercase()
            } else {
                '-'
            }
        })
        .collect::<String>()
        .split('-')
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>()
        .join("-")
}

fn render_source_line(source_path: &str) -> String {
    format!("path: {}", source_path.trim())
}

#[cfg(test)]
mod tests {
    use super::{
        ChunkingOptions, MarkdownChunk, MarkdownChunkError, MarkdownChunkInput, PdfMarkdownError,
        PdfMarkdownInput, UrlMarkdownError, UrlMarkdownInput, chunk_markdown, crate_name,
        derive_title_from_path, derive_title_from_url, normalize_pdf_text, render_pdf_markdown,
        render_url_markdown,
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
    fn derive_title_from_url_uses_last_path_segment() {
        assert_eq!(
            derive_title_from_url("https://example.com/posts/portable-knowledge.html?ref=m3"),
            "portable knowledge html"
        );
        assert_eq!(derive_title_from_url("https://example.com/"), "example com");
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

        let markdown_result = render_pdf_markdown(&input);

        assert!(markdown_result.is_ok());
        let markdown = markdown_result.unwrap_or_default();

        assert!(markdown.contains("- path: notes/`quoted`.pdf\n"));
    }

    #[test]
    fn render_url_markdown_includes_traceability_metadata() {
        let input = UrlMarkdownInput {
            title: "Portable Knowledge".to_string(),
            source_url: "https://example.com/portable-knowledge".to_string(),
            captured_text: "First paragraph.\nStill first paragraph.\n\nSecond paragraph."
                .to_string(),
        };
        let expected = "# Portable Knowledge\n\n## Source\n\n- type: url\n- url: https://example.com/portable-knowledge\n- ingested_by: `url2m3`\n\n## Captured Text\n\nFirst paragraph. Still first paragraph.\n\nSecond paragraph.\n";

        assert_eq!(render_url_markdown(&input), Ok(expected.to_string()));
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

    #[test]
    fn render_pdf_markdown_rejects_missing_title() {
        let input = PdfMarkdownInput {
            title: "   ".to_string(),
            source_path: "ref/example.pdf".to_string(),
            extracted_text: "Paragraph.".to_string(),
        };

        assert_eq!(
            render_pdf_markdown(&input),
            Err(PdfMarkdownError::MissingTitle)
        );
        assert_eq!(
            PdfMarkdownError::MissingTitle.to_string(),
            "missing PDF title"
        );
    }

    #[test]
    fn render_pdf_markdown_rejects_missing_source_path() {
        let input = PdfMarkdownInput {
            title: "Example".to_string(),
            source_path: "   ".to_string(),
            extracted_text: "Paragraph.".to_string(),
        };

        assert_eq!(
            render_pdf_markdown(&input),
            Err(PdfMarkdownError::MissingSourcePath)
        );
        assert_eq!(
            PdfMarkdownError::MissingSourcePath.to_string(),
            "missing PDF source path"
        );
    }

    #[test]
    fn missing_extracted_text_error_has_stable_message() {
        assert_eq!(
            PdfMarkdownError::MissingExtractedText.to_string(),
            "missing extracted PDF text"
        );
    }

    #[test]
    fn render_url_markdown_rejects_incomplete_input() {
        let valid = UrlMarkdownInput {
            title: "Example".to_string(),
            source_url: "https://example.com".to_string(),
            captured_text: "Body.".to_string(),
        };

        assert_eq!(
            render_url_markdown(&UrlMarkdownInput {
                title: " ".to_string(),
                ..valid.clone()
            }),
            Err(UrlMarkdownError::MissingTitle)
        );
        assert_eq!(
            UrlMarkdownError::MissingTitle.to_string(),
            "missing URL title"
        );
        assert_eq!(
            render_url_markdown(&UrlMarkdownInput {
                source_url: " ".to_string(),
                ..valid.clone()
            }),
            Err(UrlMarkdownError::MissingSourceUrl)
        );
        assert_eq!(
            UrlMarkdownError::MissingSourceUrl.to_string(),
            "missing source URL"
        );
        assert_eq!(
            render_url_markdown(&UrlMarkdownInput {
                captured_text: " ".to_string(),
                ..valid
            }),
            Err(UrlMarkdownError::MissingCapturedText)
        );
        assert_eq!(
            UrlMarkdownError::MissingCapturedText.to_string(),
            "missing captured URL text"
        );
    }

    #[test]
    fn chunk_markdown_packs_paragraphs_deterministically() {
        let input = MarkdownChunkInput {
            title: "Portable Knowledge".to_string(),
            source_path: "knowledge/books/Portable Knowledge/index.md".to_string(),
            markdown: "Alpha paragraph.\n\nBeta paragraph is longer.\n\nGamma.".to_string(),
        };

        let chunks = chunk_markdown(&input, ChunkingOptions::new(36));

        assert_eq!(
            chunks,
            Ok(vec![
                MarkdownChunk {
                    id: "knowledge-books-portable-knowledge-index-md#chunk-0001".to_string(),
                    sequence: 1,
                    title: "Portable Knowledge".to_string(),
                    source_path: "knowledge/books/Portable Knowledge/index.md".to_string(),
                    markdown: "Alpha paragraph.".to_string(),
                },
                MarkdownChunk {
                    id: "knowledge-books-portable-knowledge-index-md#chunk-0002".to_string(),
                    sequence: 2,
                    title: "Portable Knowledge".to_string(),
                    source_path: "knowledge/books/Portable Knowledge/index.md".to_string(),
                    markdown: "Beta paragraph is longer.\n\nGamma.".to_string(),
                },
            ])
        );
    }

    #[test]
    fn chunk_markdown_keeps_oversized_paragraph_intact() {
        let input = MarkdownChunkInput {
            title: "Example".to_string(),
            source_path: "knowledge/papers/example.md".to_string(),
            markdown: "A very long paragraph that exceeds the configured limit.".to_string(),
        };

        let chunks = chunk_markdown(&input, ChunkingOptions::new(8));

        assert!(chunks.is_ok());
        assert_eq!(chunks.unwrap_or_default().len(), 1);
    }

    #[test]
    fn chunk_markdown_rejects_incomplete_input() {
        let valid = MarkdownChunkInput {
            title: "Example".to_string(),
            source_path: "knowledge/example.md".to_string(),
            markdown: "Body.".to_string(),
        };

        assert_eq!(
            chunk_markdown(
                &MarkdownChunkInput {
                    title: " ".to_string(),
                    ..valid.clone()
                },
                ChunkingOptions::new(10)
            ),
            Err(MarkdownChunkError::MissingTitle)
        );
        assert_eq!(
            MarkdownChunkError::MissingTitle.to_string(),
            "missing markdown title"
        );
        assert_eq!(
            chunk_markdown(
                &MarkdownChunkInput {
                    source_path: " ".to_string(),
                    ..valid.clone()
                },
                ChunkingOptions::new(10)
            ),
            Err(MarkdownChunkError::MissingSourcePath)
        );
        assert_eq!(
            MarkdownChunkError::MissingSourcePath.to_string(),
            "missing markdown source path"
        );
        assert_eq!(
            chunk_markdown(
                &MarkdownChunkInput {
                    markdown: " ".to_string(),
                    ..valid
                },
                ChunkingOptions::new(10)
            ),
            Err(MarkdownChunkError::MissingMarkdown)
        );
        assert_eq!(
            MarkdownChunkError::MissingMarkdown.to_string(),
            "missing markdown content"
        );
    }

    #[test]
    fn chunk_markdown_rejects_invalid_chunk_size() {
        let input = MarkdownChunkInput {
            title: "Example".to_string(),
            source_path: "knowledge/example.md".to_string(),
            markdown: "Body.".to_string(),
        };

        assert_eq!(
            chunk_markdown(&input, ChunkingOptions::new(0)),
            Err(MarkdownChunkError::InvalidChunkSize)
        );
        assert_eq!(
            MarkdownChunkError::InvalidChunkSize.to_string(),
            "invalid markdown chunk size"
        );
    }
}
