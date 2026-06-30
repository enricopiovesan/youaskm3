#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "reasoning-graph-extractor"

if ARGV.length != 1
  warn "Usage: ruby scripts/extract-reasoning-graph.rb <decision-log-package-dir>"
  exit 1
end

root = File.expand_path("..", __dir__)
graph = ReasoningGraphExtractor.extract(ARGV.fetch(0), root)
puts JSON.pretty_generate(graph)
