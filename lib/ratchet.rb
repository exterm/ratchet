# frozen_string_literal: true

require "active_support"
# Provides String#pluralize, ends_with?, and others
require "active_support/core_ext/string"

module Ratchet
  extend ActiveSupport::Autoload

  # public API
  # ...

  # private API
  autoload :ConstantDiscovery
  autoload :ConstantContext
end

require "ratchet/version"
