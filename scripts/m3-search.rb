#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

ROOT_DIR = File.expand_path("..", __dir__)
INDEX_PATH = File.join(ROOT_DIR, "app/site/search-index.json")

def abort_with(message)
  warn(message)
  exit 1
end

def normalize_terms(query)
  query.downcase.split.map do |term|
    normalized = term.strip
    normalized
  end.reject(&:empty?)
end

def score_document(document, terms)
  title = document.fetch("title", "").downcase
  excerpt = document.fetch("excerpt", "").downcase
  category = document.fetch("category", "").downcase
  source_path = document.fetch("source_path", "").downcase

  terms.sum do |term|
    score = 0
    score += 3 if title.include?(term)
    score += 2 if category.include?(term)
    score += 1 if excerpt.include?(term)
    score += 1 if source_path.include?(term)
    score
  end
end

query = ARGV.join(" ").strip
abort_with("Usage: ./scripts/m3.sh search <query>") if query.empty?
abort_with("Search index is missing. Run ./scripts/m3.sh sync first.") unless File.file?(INDEX_PATH)

index = JSON.parse(File.read(INDEX_PATH))
documents = index.fetch("documents")
terms = normalize_terms(query)

results = documents.map do |document|
  score = score_document(document, terms)
  next if score.zero?

  document.merge("score" => score)
end.compact

results.sort_by! do |document|
  [-document.fetch("score"), document.fetch("title", ""), document.fetch("id", "")]
end

if results.empty?
  puts "No search results for: #{query}"
  exit 0
end

results.first(10).each_with_index do |document, index|
  puts "#{index + 1}. #{document.fetch("title")} [score #{document.fetch("score")}]"
  puts "   #{document.fetch("source_path")}"
  excerpt = document.fetch("excerpt", "").strip
  puts "   #{excerpt}" unless excerpt.empty?
end
