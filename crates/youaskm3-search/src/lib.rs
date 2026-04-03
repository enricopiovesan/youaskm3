#![forbid(unsafe_code)]
#![warn(clippy::all, clippy::pedantic)]

use std::cmp::Ordering;

/// Returns the stable identifier for the search crate.
#[must_use]
pub const fn crate_name() -> &'static str {
    "youaskm3-search"
}

/// A searchable knowledge entry sourced from the local index.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SearchDocument {
    /// Stable identifier for the indexed entry.
    pub id: String,
    /// Human-readable title for the entry.
    pub title: String,
    /// Short text content used for local matching.
    pub excerpt: String,
    /// Source path used for downstream attribution.
    pub source_path: String,
}

/// A ranked search result with source-aware metadata.
#[derive(Debug, Clone, PartialEq)]
pub struct SearchResult {
    /// Stable identifier copied from the matched document.
    pub id: String,
    /// Human-readable title copied from the matched document.
    pub title: String,
    /// Excerpt copied from the matched document.
    pub excerpt: String,
    /// Source path copied from the matched document.
    pub source_path: String,
    /// Deterministic relevance score for the query.
    pub score: f32,
}

/// Errors returned when local search input is incomplete.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SearchError {
    /// The query was empty after trimming.
    MissingQuery,
}

impl std::fmt::Display for SearchError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::MissingQuery => f.write_str("missing search query"),
        }
    }
}

impl std::error::Error for SearchError {}

/// Searches local documents using a deterministic keyword-aware score.
///
/// # Errors
///
/// Returns an error when the query is empty after trimming.
pub fn search_documents(
    query: &str,
    documents: &[SearchDocument],
) -> Result<Vec<SearchResult>, SearchError> {
    let normalized_query = normalize_query(query)?;
    let mut results = documents
        .iter()
        .filter_map(|document| score_document(document, &normalized_query))
        .collect::<Vec<_>>();

    results.sort_by(compare_results);

    Ok(results)
}

fn normalize_query(query: &str) -> Result<Vec<String>, SearchError> {
    let terms = query
        .split_whitespace()
        .map(|term| term.trim().to_ascii_lowercase())
        .filter(|term| !term.is_empty())
        .collect::<Vec<_>>();

    if terms.is_empty() {
        return Err(SearchError::MissingQuery);
    }

    Ok(terms)
}

fn score_document(document: &SearchDocument, query_terms: &[String]) -> Option<SearchResult> {
    let haystack_title = document.title.to_ascii_lowercase();
    let haystack_excerpt = document.excerpt.to_ascii_lowercase();

    let score = query_terms.iter().fold(0.0_f32, |current, term| {
        current
            + if haystack_title.contains(term) {
                3.0
            } else {
                0.0
            }
            + if haystack_excerpt.contains(term) {
                1.0
            } else {
                0.0
            }
    });

    if score <= 0.0 {
        return None;
    }

    Some(SearchResult {
        id: document.id.clone(),
        title: document.title.clone(),
        excerpt: document.excerpt.clone(),
        source_path: document.source_path.clone(),
        score,
    })
}

fn compare_results(left: &SearchResult, right: &SearchResult) -> Ordering {
    right
        .score
        .partial_cmp(&left.score)
        .unwrap_or(Ordering::Equal)
        .then_with(|| left.title.cmp(&right.title))
        .then_with(|| left.id.cmp(&right.id))
}

#[cfg(test)]
mod tests {
    use super::{SearchDocument, SearchError, crate_name, search_documents};
    use super::{SearchResult, compare_results};
    use std::cmp::Ordering;

    #[test]
    fn crate_name_matches_package() {
        assert_eq!(crate_name(), "youaskm3-search");
    }

    #[test]
    fn search_documents_rejects_empty_query() {
        assert_eq!(search_documents("   ", &[]), Err(SearchError::MissingQuery));
        assert_eq!(
            SearchError::MissingQuery.to_string(),
            "missing search query"
        );
    }

    #[test]
    fn search_documents_returns_source_aware_matches() {
        let documents = vec![
            SearchDocument {
                id: "book-1".to_string(),
                title: "Portable Knowledge Systems".to_string(),
                excerpt: "Git-native search makes local retrieval easy.".to_string(),
                source_path: "knowledge/books/portable-knowledge/index.md".to_string(),
            },
            SearchDocument {
                id: "note-1".to_string(),
                title: "Weekend notes".to_string(),
                excerpt: "Ideas about gardening and trail snacks.".to_string(),
                source_path: "knowledge/notes/weekend.md".to_string(),
            },
        ];

        let results = search_documents("retrieval", &documents);

        assert!(results.is_ok());
        let results = results.unwrap_or_default();

        assert_eq!(results.len(), 1);
        assert_eq!(results[0].id, "book-1");
        assert_eq!(
            results[0].source_path,
            "knowledge/books/portable-knowledge/index.md"
        );
        assert!((results[0].score - 1.0).abs() < f32::EPSILON);
    }

    #[test]
    fn search_documents_prefers_title_hits_over_excerpt_hits() {
        let documents = vec![
            SearchDocument {
                id: "title-hit".to_string(),
                title: "Search Architecture".to_string(),
                excerpt: "General notes about indexing.".to_string(),
                source_path: "knowledge/books/search-architecture.md".to_string(),
            },
            SearchDocument {
                id: "excerpt-hit".to_string(),
                title: "Architecture notes".to_string(),
                excerpt: "Search appears here but only in the excerpt.".to_string(),
                source_path: "knowledge/notes/architecture.md".to_string(),
            },
        ];

        let results = search_documents("search", &documents);

        assert!(results.is_ok());
        let results = results.unwrap_or_default();

        assert_eq!(results[0].id, "title-hit");
        assert!(results[0].score > results[1].score);
    }

    #[test]
    fn search_documents_omits_non_matching_documents() {
        let documents = vec![SearchDocument {
            id: "note-1".to_string(),
            title: "Weekend notes".to_string(),
            excerpt: "Ideas about gardening and trail snacks.".to_string(),
            source_path: "knowledge/notes/weekend.md".to_string(),
        }];

        let results = search_documents("retrieval", &documents);

        assert!(results.is_ok());
        let results = results.unwrap_or_default();

        assert!(results.is_empty());
    }

    #[test]
    fn compare_results_breaks_ties_by_title_then_id() {
        let left = SearchResult {
            id: "a".to_string(),
            title: "Alpha".to_string(),
            excerpt: "Excerpt".to_string(),
            source_path: "knowledge/a.md".to_string(),
            score: 4.0,
        };
        let right = SearchResult {
            id: "b".to_string(),
            title: "Beta".to_string(),
            excerpt: "Excerpt".to_string(),
            source_path: "knowledge/b.md".to_string(),
            score: 4.0,
        };

        assert_eq!(compare_results(&left, &right), Ordering::Less);
    }

    #[test]
    fn compare_results_handles_non_comparable_scores() {
        let left = SearchResult {
            id: "a".to_string(),
            title: "Alpha".to_string(),
            excerpt: "Excerpt".to_string(),
            source_path: "knowledge/a.md".to_string(),
            score: f32::NAN,
        };
        let right = SearchResult {
            id: "a".to_string(),
            title: "Alpha".to_string(),
            excerpt: "Excerpt".to_string(),
            source_path: "knowledge/a.md".to_string(),
            score: f32::NAN,
        };

        assert_eq!(compare_results(&left, &right), Ordering::Equal);
    }
}
