#![forbid(unsafe_code)]
#![warn(clippy::all, clippy::pedantic)]

use youaskm3_search::{SearchDocument, SearchError, SearchResult, search_documents};

/// JSON contract manifest used for MCP tool discovery.
pub const MCP_TOOLS_CONTRACT_JSON: &str = include_str!("../../../contracts/mcp-tools.json");

/// Describes one MCP tool exposed by youaskm3.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ToolDescriptor {
    /// Stable MCP tool name clients use when invoking the tool.
    pub name: &'static str,
    /// Human-readable summary of the tool's purpose.
    pub description: &'static str,
}

/// Initial MCP tools defined by `contracts/mcp-tools.json`.
pub const INITIAL_TOOLS: &[ToolDescriptor] = &[
    ToolDescriptor {
        name: "search",
        description: "Semantic and keyword hybrid search across indexed knowledge.",
    },
    ToolDescriptor {
        name: "remember",
        description: "Ingest and index new content from text, URLs, or files.",
    },
    ToolDescriptor {
        name: "recall",
        description: "Retrieve knowledge by topic, date, source, or tag.",
    },
    ToolDescriptor {
        name: "connect",
        description: "Surface connections between concepts across the knowledge base.",
    },
    ToolDescriptor {
        name: "list_sources",
        description: "List all indexed sources with metadata.",
    },
    ToolDescriptor {
        name: "status",
        description: "Report index status, last sync, and coverage information.",
    },
];

/// Structured MCP tool input accepted by the local adapter.
#[derive(Debug, Clone, Copy)]
pub enum ToolInput<'a> {
    /// Input for the `search` tool.
    Search {
        /// Query text supplied by the client.
        query: &'a str,
        /// Documents available to the local search adapter.
        documents: &'a [SearchDocument],
    },
    /// Input for the `remember` tool.
    Remember {
        /// Source content, URL, or file path to accept into the local memory flow.
        source: &'a str,
        /// Contract-defined source type: text, url, or file.
        source_type: &'a str,
        /// Optional tags supplied by the caller.
        tags: &'a [&'a str],
    },
    /// Input for the `recall` tool.
    Recall {
        /// Topic, source, or tag-like filter supplied by the caller.
        filter: &'a str,
        /// Documents available to the local recall adapter.
        documents: &'a [SearchDocument],
    },
    /// Input for the `connect` tool.
    Connect {
        /// Topic to connect across local documents.
        topic: &'a str,
        /// Documents available to the local connection adapter.
        documents: &'a [SearchDocument],
    },
}

/// Structured MCP tool output returned by the local adapter.
#[derive(Debug, Clone, PartialEq)]
pub enum ToolOutput {
    /// Output returned by the `search` tool.
    Search {
        /// Ranked source-aware search results.
        results: Vec<SearchResult>,
    },
    /// Output returned by the `remember` tool.
    Remember {
        /// Whether the source was accepted by the deterministic local adapter.
        accepted: bool,
        /// Stable entry identifier derived from the source metadata.
        entry_id: String,
        /// Repository-relative storage path the source would use.
        stored_path: String,
    },
    /// Output returned by the `recall` tool.
    Recall {
        /// Source-aware matches for the supplied filter.
        matches: Vec<RecallMatch>,
    },
    /// Output returned by the `connect` tool.
    Connect {
        /// Source-backed topic connections.
        connections: Vec<Connection>,
    },
}

/// One recall match returned by the local adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RecallMatch {
    /// Stable document identifier.
    pub id: String,
    /// Human-readable document title.
    pub title: String,
    /// Source path used for attribution.
    pub source_path: String,
    /// Field that matched the recall filter.
    pub matched_on: String,
}

/// One connection returned by the local adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Connection {
    /// Topic supplied by the caller.
    pub from: String,
    /// Document title connected to the topic.
    pub to: String,
    /// Deterministic relationship label.
    pub relationship: String,
    /// Source path supporting the connection.
    pub supporting_source_path: String,
}

/// Errors returned by the local MCP adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ToolCallError {
    /// The requested tool is not part of the contract-defined surface.
    UnknownTool {
        /// Tool name supplied by the caller.
        name: String,
    },
    /// The requested tool is discoverable but not implemented by the local adapter yet.
    UnsupportedTool {
        /// Tool name supplied by the caller.
        name: String,
    },
    /// A supported tool received incomplete or unsupported input.
    InvalidInput {
        /// Tool name supplied by the caller.
        tool: String,
        /// Stable validation message.
        message: String,
    },
    /// The search adapter rejected the supplied input.
    Search(SearchError),
}

impl std::fmt::Display for ToolCallError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::UnknownTool { name } => write!(f, "unknown MCP tool: {name}"),
            Self::UnsupportedTool { name } => write!(f, "unsupported MCP tool: {name}"),
            Self::InvalidInput { tool, message } => {
                write!(f, "{tool} tool rejected input: {message}")
            }
            Self::Search(error) => write!(f, "search tool failed: {error}"),
        }
    }
}

impl std::error::Error for ToolCallError {}

impl From<SearchError> for ToolCallError {
    fn from(error: SearchError) -> Self {
        Self::Search(error)
    }
}

/// Returns the stable identifier for the MCP crate.
#[must_use]
pub const fn crate_name() -> &'static str {
    "youaskm3-mcp"
}

/// Returns the contract-defined tools exposed through MCP discovery.
#[must_use]
pub const fn tool_descriptors() -> &'static [ToolDescriptor] {
    INITIAL_TOOLS
}

/// Returns the JSON contract manifest used by hosts for tool discovery.
#[must_use]
pub const fn tool_contract_json() -> &'static str {
    MCP_TOOLS_CONTRACT_JSON
}

/// Returns whether a tool name is part of the contract-defined surface.
#[must_use]
pub fn is_known_tool(name: &str) -> bool {
    tool_descriptors().iter().any(|tool| tool.name == name)
}

/// Calls a supported MCP tool through the local adapter.
///
/// The adapter is intentionally thin: it exposes the contract surface now and
/// can be replaced with Traverse public MCP/library integration when that
/// dependency is introduced for M2.
///
/// # Errors
///
/// Returns an error when the tool name is unknown, when the tool is known but
/// not implemented by the local adapter yet, or when the delegated tool rejects
/// its input.
pub fn call_tool(tool_name: &str, input: ToolInput<'_>) -> Result<ToolOutput, ToolCallError> {
    match (tool_name, input) {
        ("search", ToolInput::Search { query, documents }) => {
            let results = search_documents(query, documents)?;
            Ok(ToolOutput::Search { results })
        }
        (
            "remember",
            ToolInput::Remember {
                source,
                source_type,
                tags,
            },
        ) => remember_source(source, source_type, tags),
        ("recall", ToolInput::Recall { filter, documents }) => recall_documents(filter, documents),
        ("connect", ToolInput::Connect { topic, documents }) => connect_documents(topic, documents),
        (name, _) if is_known_tool(name) => Err(ToolCallError::UnsupportedTool {
            name: name.to_string(),
        }),
        (name, _) => Err(ToolCallError::UnknownTool {
            name: name.to_string(),
        }),
    }
}

fn remember_source(
    source: &str,
    source_type: &str,
    tags: &[&str],
) -> Result<ToolOutput, ToolCallError> {
    let source = require_non_empty("remember", "source", source)?;
    let source_type = require_supported_source_type(source_type)?;
    let slug = slugify(source);
    let entry_id = format!("{source_type}-{slug}");
    let stored_path = if tags.is_empty() {
        format!("knowledge/inputs/{entry_id}.md")
    } else {
        format!(
            "knowledge/inputs/{}-{entry_id}.md",
            slugify(&tags.join("-"))
        )
    };

    Ok(ToolOutput::Remember {
        accepted: true,
        entry_id,
        stored_path,
    })
}

fn recall_documents(
    filter: &str,
    documents: &[SearchDocument],
) -> Result<ToolOutput, ToolCallError> {
    let terms = normalize_terms("recall", "filter", filter)?;
    let matches = documents
        .iter()
        .filter_map(|document| recall_match(document, &terms))
        .collect::<Vec<_>>();

    Ok(ToolOutput::Recall { matches })
}

fn connect_documents(
    topic: &str,
    documents: &[SearchDocument],
) -> Result<ToolOutput, ToolCallError> {
    let topic = require_non_empty("connect", "topic", topic)?;
    let terms = normalize_terms("connect", "topic", topic)?;
    let connections = documents
        .iter()
        .filter(|document| document_matches(document, &terms))
        .map(|document| Connection {
            from: topic.to_string(),
            to: document.title.clone(),
            relationship: "mentioned-in".to_string(),
            supporting_source_path: document.source_path.clone(),
        })
        .collect::<Vec<_>>();

    Ok(ToolOutput::Connect { connections })
}

fn recall_match(document: &SearchDocument, terms: &[String]) -> Option<RecallMatch> {
    let matched_on = if contains_all_terms(&document.title, terms) {
        "title"
    } else if contains_all_terms(&document.source_path, terms) {
        "source_path"
    } else if contains_all_terms(&document.excerpt, terms) {
        "excerpt"
    } else {
        return None;
    };

    Some(RecallMatch {
        id: document.id.clone(),
        title: document.title.clone(),
        source_path: document.source_path.clone(),
        matched_on: matched_on.to_string(),
    })
}

fn document_matches(document: &SearchDocument, terms: &[String]) -> bool {
    contains_all_terms(&document.title, terms)
        || contains_all_terms(&document.excerpt, terms)
        || contains_all_terms(&document.source_path, terms)
}

fn contains_all_terms(value: &str, terms: &[String]) -> bool {
    let value = value.to_ascii_lowercase();
    terms.iter().all(|term| value.contains(term))
}

fn normalize_terms(tool: &str, field: &str, value: &str) -> Result<Vec<String>, ToolCallError> {
    let value = require_non_empty(tool, field, value)?;

    Ok(value
        .split_whitespace()
        .map(str::to_ascii_lowercase)
        .collect())
}

fn require_non_empty<'a>(
    tool: &str,
    field: &str,
    value: &'a str,
) -> Result<&'a str, ToolCallError> {
    let value = value.trim();
    if value.is_empty() {
        return Err(ToolCallError::InvalidInput {
            tool: tool.to_string(),
            message: format!("missing {field}"),
        });
    }

    Ok(value)
}

fn require_supported_source_type(source_type: &str) -> Result<&str, ToolCallError> {
    let source_type = require_non_empty("remember", "source_type", source_type)?;
    match source_type {
        "text" | "url" | "file" => Ok(source_type),
        _ => Err(ToolCallError::InvalidInput {
            tool: "remember".to_string(),
            message: format!("unsupported source_type: {source_type}"),
        }),
    }
}

fn slugify(value: &str) -> String {
    let slug = value
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
        .filter(|segment| !segment.is_empty())
        .collect::<Vec<_>>()
        .join("-");

    if slug.is_empty() {
        "entry".to_string()
    } else {
        slug
    }
}

#[cfg(test)]
mod tests {
    use super::{
        Connection, RecallMatch, ToolCallError, ToolInput, ToolOutput, call_tool, crate_name,
        is_known_tool, tool_contract_json, tool_descriptors,
    };
    use youaskm3_search::{SearchDocument, SearchError};

    #[test]
    fn crate_name_matches_package() {
        assert_eq!(crate_name(), "youaskm3-mcp");
    }

    #[test]
    fn exposes_contract_defined_tool_descriptors() {
        let names = tool_descriptors()
            .iter()
            .map(|tool| tool.name)
            .collect::<Vec<_>>();

        assert_eq!(
            names,
            vec![
                "search",
                "remember",
                "recall",
                "connect",
                "list_sources",
                "status"
            ]
        );
        assert!(is_known_tool("search"));
        assert!(!is_known_tool("ask"));
    }

    #[test]
    fn contract_json_contains_the_discovery_surface() {
        let contract = tool_contract_json();

        assert!(contract.contains("\"tools\""));
        for tool in tool_descriptors() {
            assert!(contract.contains(&format!("\"name\": \"{}\"", tool.name)));
        }
    }

    #[test]
    fn calls_search_tool_with_structured_input() {
        let documents = vec![SearchDocument {
            id: "book-1".to_string(),
            title: "Portable MCP".to_string(),
            excerpt: "WASM-native clients can discover tools.".to_string(),
            source_path: "knowledge/books/portable-mcp.md".to_string(),
        }];

        let output = call_tool(
            "search",
            ToolInput::Search {
                query: "discover",
                documents: &documents,
            },
        );

        assert!(output.is_ok());
        assert_eq!(
            output.unwrap_or(ToolOutput::Search {
                results: Vec::new()
            }),
            ToolOutput::Search {
                results: vec![youaskm3_search::SearchResult {
                    id: "book-1".to_string(),
                    title: "Portable MCP".to_string(),
                    excerpt: "WASM-native clients can discover tools.".to_string(),
                    source_path: "knowledge/books/portable-mcp.md".to_string(),
                    score: 1.0,
                }]
            }
        );
    }

    #[test]
    fn returns_search_input_errors() {
        let output = call_tool(
            "search",
            ToolInput::Search {
                query: " ",
                documents: &[],
            },
        );

        assert_eq!(
            output,
            Err(ToolCallError::Search(SearchError::MissingQuery))
        );
    }

    #[test]
    fn remembers_sources_with_stable_storage_metadata() {
        let output = call_tool(
            "remember",
            ToolInput::Remember {
                source: "https://example.com/Portable MCP",
                source_type: "url",
                tags: &["mcp", "Traverse"],
            },
        );

        assert_eq!(
            output,
            Ok(ToolOutput::Remember {
                accepted: true,
                entry_id: "url-https-example-com-portable-mcp".to_string(),
                stored_path: "knowledge/inputs/mcp-traverse-url-https-example-com-portable-mcp.md"
                    .to_string(),
            })
        );
    }

    #[test]
    fn rejects_invalid_remember_input() {
        assert_eq!(
            call_tool(
                "remember",
                ToolInput::Remember {
                    source: "notes",
                    source_type: "audio",
                    tags: &[],
                },
            ),
            Err(ToolCallError::InvalidInput {
                tool: "remember".to_string(),
                message: "unsupported source_type: audio".to_string(),
            })
        );
    }

    #[test]
    fn recalls_documents_by_title_excerpt_or_source() {
        let documents = sample_documents();

        let output = call_tool(
            "recall",
            ToolInput::Recall {
                filter: "portable",
                documents: &documents,
            },
        );

        assert_eq!(
            output,
            Ok(ToolOutput::Recall {
                matches: vec![RecallMatch {
                    id: "book-1".to_string(),
                    title: "Portable MCP".to_string(),
                    source_path: "knowledge/books/portable-mcp.md".to_string(),
                    matched_on: "title".to_string(),
                }]
            })
        );
    }

    #[test]
    fn connects_topics_to_supporting_sources() {
        let documents = sample_documents();

        let output = call_tool(
            "connect",
            ToolInput::Connect {
                topic: "Traverse",
                documents: &documents,
            },
        );

        assert_eq!(
            output,
            Ok(ToolOutput::Connect {
                connections: vec![Connection {
                    from: "Traverse".to_string(),
                    to: "Portable MCP".to_string(),
                    relationship: "mentioned-in".to_string(),
                    supporting_source_path: "knowledge/books/portable-mcp.md".to_string(),
                }]
            })
        );
    }

    #[test]
    fn validates_recall_and_connect_inputs() {
        assert_eq!(
            call_tool(
                "recall",
                ToolInput::Recall {
                    filter: " ",
                    documents: &[],
                },
            ),
            Err(ToolCallError::InvalidInput {
                tool: "recall".to_string(),
                message: "missing filter".to_string(),
            })
        );
        assert_eq!(
            call_tool(
                "connect",
                ToolInput::Connect {
                    topic: "",
                    documents: &[],
                },
            ),
            Err(ToolCallError::InvalidInput {
                tool: "connect".to_string(),
                message: "missing topic".to_string(),
            })
        );
    }

    #[test]
    fn separates_unsupported_input_shapes_and_unknown_tools() {
        assert_eq!(
            call_tool(
                "remember",
                ToolInput::Search {
                    query: "anything",
                    documents: &[],
                },
            ),
            Err(ToolCallError::UnsupportedTool {
                name: "remember".to_string()
            })
        );
        assert_eq!(
            call_tool(
                "ask",
                ToolInput::Search {
                    query: "anything",
                    documents: &[],
                },
            ),
            Err(ToolCallError::UnknownTool {
                name: "ask".to_string()
            })
        );
    }

    #[test]
    fn formats_tool_call_errors() {
        assert_eq!(
            ToolCallError::UnknownTool {
                name: "ask".to_string()
            }
            .to_string(),
            "unknown MCP tool: ask"
        );
        assert_eq!(
            ToolCallError::UnsupportedTool {
                name: "remember".to_string()
            }
            .to_string(),
            "unsupported MCP tool: remember"
        );
        assert_eq!(
            ToolCallError::InvalidInput {
                tool: "recall".to_string(),
                message: "missing filter".to_string(),
            }
            .to_string(),
            "recall tool rejected input: missing filter"
        );
        assert_eq!(
            ToolCallError::Search(SearchError::MissingQuery).to_string(),
            "search tool failed: missing search query"
        );
    }

    fn sample_documents() -> Vec<SearchDocument> {
        vec![
            SearchDocument {
                id: "book-1".to_string(),
                title: "Portable MCP".to_string(),
                excerpt: "Traverse-compatible clients can discover tools.".to_string(),
                source_path: "knowledge/books/portable-mcp.md".to_string(),
            },
            SearchDocument {
                id: "note-1".to_string(),
                title: "Garden notes".to_string(),
                excerpt: "Seedlings and irrigation plans.".to_string(),
                source_path: "knowledge/notes/garden.md".to_string(),
            },
        ]
    }
}
