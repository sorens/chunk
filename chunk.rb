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
count = 0
first = true
header = ""
File.foreach(input_file).with_index do |line, line_num|
    if first
        header = line
        first = false
    end
    count = count + 1
    size = 0
    if File.exists?(output)
        size = File.size(output)
    end
    File.write(output, line, size, mode: "a+")

    if count >= @options[:chunk_size]
        # create a new file name
        output_count = output_count + 1
        output_file = sprintf("chunk-%08d.txt", output_count)
        puts output_file
        output = File.expand_path(File.join(@options[:output], output_file))
        size = 0
        if File.exists?(output)
            size = File.size(output)
        end
        File.write(output, header, size, mode: "a+")
        count = 0
    end
end

puts "total lines: #{count}"