# frozen_string_literal: true

module Ratchet
  # Public API for extracting constant references from Ruby code (that is autoloaded via Zeitwerk).
  #
  # @example
  #   extractor = Ratchet::Extractor.new(autoloaders: Rails.autoloaders, root_path: Rails.root)
  #   references = extractor.references_from_string("Order.find(1)")
  #   references = extractor.references_from_file("app/models/user.rb")
  class Extractor
    attr_reader :root_path

    # @param autoloaders [Enumerable] Collection of Zeitwerk loaders, e.g. from `Rails.autoloaders`
    # @param root_path [String, Pathname] The root path of the application, e.g. from `Rails.root`
    def initialize(autoloaders:, root_path:)
      @autoloaders = autoloaders
      @root_path = Pathname.new(root_path)
      @context_provider = ConstantDiscovery.new(root_path:, loaders: @autoloaders)
    end

    # Extract constant references from a Ruby code string.
    #
    # @param snippet [String] The Ruby code to analyze
    # @return [Array<Reference>] Array of references to autoloaded constants in project files
    def references_from_string(snippet)
      ast = parse_ruby_string(snippet)
      return [] unless ast

      extract_references(ast, relative_path: "<snippet>")
    end

    # Extract constant references from a Ruby file.
    #
    # @param file_path [String, Pathname] Path to the Ruby file (relative to root_path or absolute)
    # @return [Array<Reference>] Array of references to autoloaded constants in project files
    def references_from_file(file_path)
      absolute_path = Pathname.new(file_path).expand_path(root_path)
      return [] unless File.exist?(absolute_path)

      ast = parse_file(absolute_path)
      return [] unless ast

      relative_path = Pathname.new(absolute_path).relative_path_from(root_path).to_s
      extract_references(ast, relative_path:)
    end

    private

    def parse_ruby_string(snippet)
      parser = Parsers::Ruby.new
      parser.call(io: StringIO.new(snippet))
    end

    def parse_file(file_path)
      parser = Parsers::Factory.instance.for_path(file_path.to_s)
      raise ArgumentError, "Unsupported file type: #{file_path}" unless parser

      File.open(file_path, "r") do |io|
        parser.call(io:, file_path: file_path.to_s)
      end
    end

    def extract_references(root_node, relative_path:)
      extractor = AstReferenceExtractor.new(
        # TO DO: Add association inspector
        constant_name_inspectors: [ConstNodeInspector.new],
        root_node:,
        root_path:
      )

      # TO DO: Should these two steps be combined?
      unresolved_references = collect_references(
        root_node,
        extractor:,
        relative_path:
      )

      AstReferenceExtractor.get_fully_qualified_references_from(
        unresolved_references,
        @context_provider
      )
    end

    # TO DO: Move this recursion into the extractor
    def collect_references(node, ancestors: [], extractor:, relative_path:)
      reference = extractor.reference_from_node(
        node,
        ancestors:,
        relative_path:
      )

      child_references = NodeHelpers.each_child(node).flat_map do |child|
        collect_references(child, ancestors: [node] + ancestors, extractor:, relative_path:)
      end

      ([reference] + child_references).compact
    end
  end
end
