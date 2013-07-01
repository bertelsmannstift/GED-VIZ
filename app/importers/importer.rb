require 'csv'

class Importer
  attr_reader :folder

  def initialize(folder = 'import')
    @folder = Pathname.new(folder)
    setup
  end

  def setup

  end

end