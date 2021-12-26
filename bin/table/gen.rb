#!/usr/bin/env ruby

# Generate table of methods in github markdown for README.md.

require 'yaml'

# columns
COLS = [{
  dst: "Name",
  src: "name",
}, {
  dst: "Language",
  src: "lang",
}, {
  dst: "Description",
  src: "text",
}]

# row template
TMPL = '| `%<name>s` | %<lang>s | %<text>s |'

# load data
DATA = YAML.load(File.read(File.join(__dir__, 'bins.yaml'))).map { |row|
  { name: row['name'], lang: row['lang'], text: row['text'] }
}.freeze

# generate table, print to stdout
puts '| %s |' % [COLS.map { |col| col[:dst] }.join(' | ')],
     '| %s |' % [COLS.map { |col| '-' * col[:dst].size }.join(' | ')],
     DATA.map { |row| TMPL % row }
