#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

@options = {}

# ruby chunk.rb --input file --output dir --chunk_size size
op = OptionParser.new do |opts|
    opts.banner = "usage: chunk --input file.csv --output dir"
    opts.on("-v", "--verbose", "show extra information") do
        @options[:verbose] = true
    end
    opts.on("-i", "--input [INPUT_FILE]", "absolute path to the input file") do |input_file|
        @options[:input] = input_file
    end
    opts.on("-e", "--output [OUTPUT_DIR]", "name of the output directory") do |output|
        @options[:output] = output
    end
    opts.on("-c", "--chunk_size [NO_OF_LINES]", "how many lines should be in each chunk") do |chunk_size|
        @options[:chunk_size] = chunk_size.to_i
    end
    opts.on("-h", "--header", "") do |header|
        @options[:header] = header
    end
end

begin
    op.parse!
    missing = [:input, :output].select{ |param| @options[param].nil? }
    unless missing.empty?
        raise OptionParser::MissingArgument.new(missing.join(', '))
    end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
    puts $!.to_s
    puts op
    exit
end

input_file = File.expand_path(@options[:input])
output_count = 1
output_file = sprintf("chunk-%08d.txt", output_count)
puts output_file
FileUtils.mkdir_p @options[:output]
output = File.expand_path(File.join(@options[:output], output_file))
total_count = 0
file_count = 0
count = 0
first = true
header = ""
size = 0
File.foreach(input_file).with_index do |line, line_num|
    if first and @options[:header]
        header = line
        first = false
    end
    count = count + 1
    size = size + File.write(output, line, size, mode: "a+")

    if count >= @options[:chunk_size]
        # create a new file name
        output_count = output_count + 1
        output_file = sprintf("chunk-%08d.txt", output_count)
        output = File.expand_path(File.join(@options[:output], output_file))
        if @options[:header] and header != ""
            size = File.write(output, header, size, mode: "a+")
        end
        total_count = total_count + count
        count = 0
        file_count = file_count + 1
        puts output_file
    end
end

puts "total lines:          #{total_count}"
puts "total files created:  #{file_count}"