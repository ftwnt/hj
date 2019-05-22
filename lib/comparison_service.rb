require './lib/base/keyword'
require './lib/main_logger'

class ComparisonService < Base::Keyword
  attr_reader :internal_storage_type

  def initialize(internal_storage_type:); end
end
