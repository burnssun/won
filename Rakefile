

begin; require 'rubygems'; rescue LoadError; end

require 'rake'
require 'rake/clean'
require 'time'
require 'date'

task :default => [:gem]

task :up do
  ver_file = "lib/won/base.rb"
  orig = IO.read( ver_file  )
  if orig[ /VERSION = '(.*)'/ ] && $1
    new_ver = $1.succ
    File.open( ver_file, "w") { |f| f.write(orig.gsub( $1, new_ver)) }
    puts "version up to #{new_ver}"
  end
end


CLEAN.include %w[
  **/.*.sw?
  *.gem
  .config
  **/*~
  **/*.tmp
  **/{data.db,cache.yaml}
  *.yaml
  pkg
  rdoc
  ydoc
  .#*
  .yardoc
  *coverage*
]
