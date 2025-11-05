# frozen_string_literal: true

require "active_support"
# Provides String#pluralize, ends_with?, and others
require "active_support/core_ext/string"

# Ratchet extracts constant references from Ruby code, giving you your implicit application structure as a neat graph.
#
# @example Extract references from a string snippet
#   extractor = Ratchet::Extractor.new(
#     autoloaders: Rails.autoloaders,
#     root_path: Rails.root
#   )
#   references = extractor.references_from_string("Order.find(1)")
#   # => [#<Ratchet::Reference constant=#<Ratchet::ConstantContext name="::Order" ...>>]
#
# @example Extract references from a file
#   references = extractor.references_from_file("app/models/user.rb")
#   # => [#<Ratchet::Reference ...>, ...]
module Ratchet
  extend ActiveSupport::Autoload

  # public API
  autoload :Extractor

  # private API
  autoload :AstReferenceExtractor
  autoload :ConstantDiscovery
  autoload :ConstantContext
  autoload :ConstNodeInspector
  autoload :Node
  autoload :NodeHelpers
  autoload :ParsedConstantDefinitions
  autoload :Parsers
  autoload :Reference
  autoload :UnresolvedReference
end

require "ratchet/version"
