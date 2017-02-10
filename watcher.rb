#!/bin/ruby

require 'listen'
require_relative 'convert'
require_relative 'helpers'

include CommonHelpers

def convert_paths(paths)
  paths.map { |p| path_to_id(p) }
end

listener = Listen.to('data/teachings',
                       only: /.xml$/,
                       relative: true) do |updated, added, deleted|
  update_table(:teachings,
               convert_paths(updated),
               convert_paths(added),
               convert_paths(deleted)) { |url| load_teachings_url(url) }
end

listener.start
sleep