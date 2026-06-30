#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "rbconfig"
require "tmpdir"
require "time"

ROOT = Pathname.new(__dir__).join("..").expand_path
DEFAULT_KNOWLEDGE_ROOT = ROOT.join("knowledge")
SITE_DIR = ROOT.join("app", "site")

def parse_args(argv)
  flags = { "knowledge_root" => DEFAULT_KNOWLEDGE_ROOT.to_s, "json" => false, "write_conflicts" => false }
  until argv.empty?
    flag = argv.shift
    case flag
    when "--knowledge-root"
      flags["knowledge_root"] = argv.shift || abort("Missing value for --knowledge-root")
    when "--json"
      flags["json"] = true
    when "--write-conflicts"
      flags["write_conflicts"] = true
    else
      abort "Usage: ruby scripts/sync-preflight.rb [--knowledge-root PATH] [--json] [--write-conflicts]"
    end
  end
  flags
end

def slug(value)
  value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
end

def relative(path)
  Pathname.new(path).relative_path_from(ROOT).to_s
rescue ArgumentError
  Pathname.new(path).to_s
end

def conflict_marker_files(knowledge_root)
  roots = [knowledge_root, SITE_DIR].select(&:exist?)
  roots.flat_map do |root|
    Dir.glob(root.join("**", "*")).select do |path|
      File.file?(path) && File.read(path, 4096).include?("<<<<<<<")
    rescue ArgumentError
      false
    end
  end.sort
end

def append_files(knowledge_root)
  Dir.glob(knowledge_root.join("inputs", "notes", "*.append.md")).sort
end

def auto_merge_append_files(paths)
  merged = []
  paths.each do |path_string|
    path = Pathname.new(path_string)
    target = path.sub(/\.append\.md\z/, ".md")
    FileUtils.mkdir_p(target.dirname)
    existing = target.file? ? target.read : ""
    append = path.read
    target.write([existing.strip, append.strip].reject(&:empty?).join("\n\n") + "\n")
    path.delete
    merged << { "source" => relative(path), "target" => relative(target) }
  end
  merged
end

def generated_sync_state
  Dir.mktmpdir do |tmpdir|
    ok = system(RbConfig.ruby, ROOT.join("scripts", "generate-site-artifacts.rb").to_s, tmpdir, out: File::NULL, err: File::NULL)
    return nil unless ok
    Pathname.new(tmpdir).join("sync-state.json").read
  end
end

def metadata_dirty?
  sync_state = SITE_DIR.join("sync-state.json")
  return false unless sync_state.file?

  generated = generated_sync_state
  return true if generated.nil?

  generated != sync_state.read
end

def write_conflict_reports(knowledge_root, paths)
  paths.map do |path|
    conflict_id = "conflict-sync-#{slug(relative(path))[0, 56].gsub(/-\z/, "")}"
    summary = "File-system sync conflict markers detected in #{relative(path)}."
    system(
      RbConfig.ruby,
      ROOT.join("scripts", "knowledge-gap-lifecycle.rb").to_s,
      "create-conflict",
      "--knowledge-root", knowledge_root.to_s,
      "--conflict-id", conflict_id,
      "--summary", summary,
      out: File::NULL
    )
    knowledge_root.join("conflicts", "open", "#{conflict_id}.md")
  end
end

flags = parse_args(ARGV)
knowledge_root = Pathname.new(flags.fetch("knowledge_root")).expand_path
FileUtils.mkdir_p(knowledge_root)

merged = auto_merge_append_files(append_files(knowledge_root))
marker_conflicts = conflict_marker_files(knowledge_root)
written_conflicts = flags.fetch("write_conflicts") && !marker_conflicts.empty? ? write_conflict_reports(knowledge_root, marker_conflicts) : []
open_conflicts = Dir.glob(knowledge_root.join("conflicts", "open", "*.md")).sort
dirty = metadata_dirty?

status, code, message = if !marker_conflicts.empty? || !open_conflicts.empty?
                          ["open_conflict", "SYNC_CONFLICT_OPEN", "Open sync conflicts must be resolved before knowledge writes."]
                        elsif !merged.empty?
                          ["auto_merged", "SYNC_AUTO_MERGED", "Append-only sync artifacts were auto-merged."]
                        elsif dirty
                          ["blocked", "SYNC_METADATA_DIRTY", "Generated sync metadata is stale. Run ./scripts/m3.sh sync before writing knowledge."]
                        else
                          ["clean", "SYNC_CLEAN", "Sync preflight clean."]
                        end

result = {
  "status" => status,
  "code" => code,
  "message" => message,
  "knowledge_root" => knowledge_root.to_s,
  "auto_merged" => merged,
  "conflict_marker_paths" => marker_conflicts.map { |path| relative(path) },
  "written_conflict_paths" => written_conflicts.map { |path| relative(path) },
  "open_conflict_paths" => open_conflicts.map { |path| relative(path) },
  "metadata_dirty" => dirty
}

if flags.fetch("json")
  puts JSON.pretty_generate(result)
else
  puts "#{status}: #{message}"
  result.fetch("auto_merged").each { |entry| puts "- merged #{entry.fetch("source")} -> #{entry.fetch("target")}" }
  result.fetch("open_conflict_paths").each { |path| puts "- open conflict #{path}" }
end

exit(status == "clean" || status == "auto_merged" ? 0 : 1)
