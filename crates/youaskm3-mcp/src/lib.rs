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
}

/// Structured MCP tool output returned by the local adapter.
#[derive(Debug, Clone, PartialEq)]
pub enum ToolOutput {
    /// Output returned by the `search` tool.
    Search {
        /// Ranked source-aware search results.
        results: Vec<SearchResult>,
    },
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
    /// The search adapter rejected the supplied input.
    Search(SearchError),
}

impl std::fmt::Display for ToolCallError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::UnknownTool { name } => write!(f, "unknown MCP tool: {name}"),
            Self::UnsupportedTool { name } => write!(f, "unsupported MCP tool: {name}"),
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
        (name, _) if is_known_tool(name) => Err(ToolCallError::UnsupportedTool {
            name: name.to_string(),
        }),
        (name, _) => Err(ToolCallError::UnknownTool {
            name: name.to_string(),
        }),
    }
}

#[cfg(test)]
mod tests {
    use super::{
        ToolCallError, ToolInput, ToolOutput, call_tool, crate_name, is_known_tool,
        tool_contract_json, tool_descriptors,
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
    fn separates_unsupported_and_unknown_tools() {
        let input = ToolInput::Search {
            query: "anything",
            documents: &[],
        };

        assert_eq!(
            call_tool("remember", input),
            Err(ToolCallError::UnsupportedTool {
                name: "remember".to_string()
            })
        );
        assert_eq!(
            call_tool("ask", input),
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
            ToolCallError::Search(SearchError::MissingQuery).to_string(),
            "search tool failed: missing search query"
        );
    }
}
