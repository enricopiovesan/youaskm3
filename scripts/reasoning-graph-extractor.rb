# frozen_string_literal: true

require "json"
require "pathname"

module ReasoningGraphExtractor
  REQUIRED_TYPES = [
    "concept",
    "question",
    "option",
    "tradeoff",
    "assumption",
    "decision",
    "claim",
    "open_question",
    "source_gap",
    "knowledge_note",
    "citation",
    "source_artifact",
    "confidence_assessment",
    "validation_result"
  ].freeze

  SECTION_BY_TYPE = {
    "question" => "Questions Asked",
    "option" => "Options Considered",
    "tradeoff" => "Pros and Cons",
    "assumption" => "Assumptions",
    "decision" => "Decisions",
    "claim" => "Claims",
    "open_question" => "Remaining Non-Blocking Open Questions",
    "citation" => "Citations"
  }.freeze

  def self.extract(package_dir, root)
    package_path = Pathname.new(package_dir)
    root_path = Pathname.new(root)
    metadata = JSON.parse(package_path.join("metadata.json").read)
    package_id = metadata.fetch("package_id")
    decision = section_map(package_path.join("decision-log.md").read)
    note = section_map(package_path.join("knowledge-note.md").read)
    provenance_path = package_path.join("ingestion-provenance.json")
    provenance = provenance_path.file? ? JSON.parse(provenance_path.read) : {}
    validation = provenance.fetch("validation_evidence", { "deterministic" => "fixture", "semantic" => { "status" => "unavailable" } })

    nodes = []
    edges = []
    source_paths = [
      relative_path(package_path.join("decision-log.md"), root_path),
      relative_path(package_path.join("knowledge-note.md"), root_path),
      relative_path(package_path.join("metadata.json"), root_path)
    ]
    source_paths << relative_path(provenance_path, root_path) if provenance_path.file?

    source_node_id = node_id(package_id, "source_artifact", 0)
    nodes << node(source_node_id, package_id, "source_artifact", package_id, source_paths, { "mode" => metadata.fetch("mode") })

    concept_label = first_line(decision.fetch("Conversation Goal", ""))
    nodes << node(node_id(package_id, "concept", 0), concept_label, "concept", package_id, source_paths, { "mode" => metadata.fetch("mode") })

    SECTION_BY_TYPE.each do |type, section|
      values = bullets(decision.fetch(section, ""))
      fail "Missing extractable #{type} in #{package_path}" if values.empty?

      values.each_with_index do |value, index|
        nodes << node(node_id(package_id, type, index), value, type, package_id, source_paths, { "section" => section })
      end
    end

    source_gap_label = metadata["source_gap_id"] || "No linked source gap"
    nodes << node(node_id(package_id, "source_gap", 0), source_gap_label, "source_gap", package_id, source_paths, { "source_gap_id" => metadata["source_gap_id"] })

    nodes << node(node_id(package_id, "knowledge_note", 0), first_line(note.fetch("Title", "")), "knowledge_note", package_id, source_paths, { "note_path" => source_paths[1] })
    nodes << node(node_id(package_id, "confidence_assessment", 0), first_line(decision.fetch("Confidence Assessment", "")), "confidence_assessment", package_id, source_paths, {})
    nodes << node(node_id(package_id, "validation_result", 0), "Deterministic validation #{validation.fetch("deterministic", "unknown")}", "validation_result", package_id, source_paths, validation)

    present_types = nodes.map { |entry| entry.fetch("type") }.uniq
    missing_types = REQUIRED_TYPES - present_types
    fail "Reasoning graph extraction missing node types: #{missing_types.join(", ")}" unless missing_types.empty?

    nodes.reject { |entry| entry.fetch("node_id") == source_node_id }.each do |target|
      edges << edge(
        package_id,
        source_node_id,
        target.fetch("node_id"),
        "contains_reasoning_element",
        source_paths,
        { "target_type" => target.fetch("type") }
      )
    end

    {
      "generated_from" => [package_id],
      "nodes" => nodes.sort_by { |entry| entry.fetch("node_id") },
      "edges" => edges.sort_by { |entry| entry.fetch("edge_id") }
    }
  end

  def self.section_map(markdown)
    sections = {}
    current = nil

    markdown.each_line do |line|
      if (match = line.match(/\A##\s+(.+?)\s*\z/))
        current = match[1]
        sections[current] = +""
      elsif current
        sections[current] << line
      end
    end

    sections.transform_values(&:strip)
  end

  def self.bullets(section)
    section.each_line.each_with_object([]) do |line, values|
      match = line.match(/\A-\s+(.+?)\s*\z/)
      values << match[1].strip if match
    end
  end

  def self.first_line(section)
    section.each_line.map(&:strip).reject(&:empty?).first.to_s
  end

  def self.relative_path(path, root)
    Pathname.new(path).relative_path_from(root).to_s
  rescue ArgumentError
    Pathname.new(path).to_s
  end

  def self.node_id(package_id, type, index)
    "reasoning:#{package_id}:#{type}:#{index}"
  end

  def self.node(id, label, type, package_id, source_paths, metadata)
    fail "Missing label for #{type}" if label.nil? || label.empty?

    {
      "node_id" => id,
      "label" => label,
      "type" => type,
      "source_artifact_ids" => [package_id],
      "source_chunk_ids" => [],
      "source_paths" => source_paths,
      "metadata" => metadata
    }
  end

  def self.edge(package_id, from_node_id, to_node_id, relationship, source_paths, metadata)
    {
      "edge_id" => "edge:#{from_node_id}:#{relationship}:#{to_node_id}",
      "from_node_id" => from_node_id,
      "to_node_id" => to_node_id,
      "relationship" => relationship,
      "source_artifact_ids" => [package_id],
      "source_chunk_ids" => [],
      "source_paths" => source_paths,
      "extraction_method" => "deterministic-reasoning-graph-extractor",
      "confidence" => 1.0,
      "metadata" => metadata
    }
  end
end
