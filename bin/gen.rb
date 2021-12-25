#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'

class FileSize
  attr_reader :size, :nice_size

  def initialize(val)
    @size = val
    @nice_size = get_nice_size(val)
  end

  private

  SUFFIXES = [{
    ext: 'B',
    frac: false,
  }, {
    ext: 'k',
    frac: true,
  }, {
    ext: 'M',
    frac: true,
  }, {
    ext: 'G',
    frac: true,
  }]

  def get_nice_size(val)
    SUFFIXES.each_with_index do |ext, i|
      base = 1024 ** i
      if val < (1024 ** (i + 1))
        if ext[:frac]
          return '%3.1<val>f%<ext>s' % {
            val: (val.to_f / base).round(1),
            ext: ext[:ext],
          }
        else
          return '%<val>d%<ext>s' % {
            val: val / base,
            ext: ext[:ext],
          }
        end
      end
    end

    # fall back to full size in bytes
    val.to_s
  end
end

# get destination paths
csv_path = ARGV.shift
all_svg_path = ARGV.shift
tiny_svg_path = ARGV.shift

# generate output csv
File.open(csv_path, 'wb') do |io|
  CSV(io) do |csv|
    # print column headers
    csv << %w{name size nice}

    # print column headers
    Dir['/out/bin/*'].map do |path|
      size = FileSize.new(File.size(path))

      {
        name: File.basename(path),
        size: size.size,
        nice: size.nice_size,
      }
    end.sort do |a, b|
      b[:size] <=> a[:size]
    end.each do |row|
      csv << [row[:name], row[:size], row[:nice]]
    end
  end
end

# dump contents of CSV to standard output
# system('cat', csv_path)

# generate svg
exec('/plot.py', csv_path, all_svg_path, tiny_svg_path)
