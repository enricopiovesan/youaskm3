# Knowledge Graph Artifact Contract

Status: MVP contract

Knowledge graph artifacts are the source-backed graph representation used by the chat workflow.

The artifact shape is owned by youaskm3. Graph generation tools can be swapped as long as they produce this contract. Graph traversal and graph expansion are runtime behavior and must run behind the `knowledge.graph.expand` capability.

Required properties:

- stable `graph_id`
- deterministic `nodes`
- deterministic `edges`
- source artifact references
- source chunk references
- relationship labels
- extraction method
- confidence

Validation source: `contracts/knowledge-graph.schema.json`.

Example: `contracts/examples/knowledge-graph.example.json`.
