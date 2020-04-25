#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

@options = {}
@options[:chunk_size] = 1000000
@options[:separator] = ","
@options[:header] = false
@options[:fix_broken_header] = 0

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
    opts.on("-c", "--chunk_size [NO_OF_LINES]", "how many lines should be in each chunk (default '#{@options[:chunk_size]}')") do |chunk_size|
        @options[:chunk_size] = chunk_size.to_i
    end
    opts.on("-h", "--header", "capture a header and include it in every chunk") do |header|
        @options[:header] = header
    end
    opts.on("-s", "--separator [SEPARATOR]", "separator character to use (default '#{@options[:separator]}')") do |separator|
        @options[:separator] = separator
    end
    opts.on("-f", "--fix_header [AMOUNT]", "how many additional separators to look for") do |fix|
        @options[:fix_broken_header] = fix.to_i
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
FileUtils.mkdir_p @options[:output]
output = File.expand_path(File.join(@options[:output], output_file))
total_count = 0
file_count = 0
line_count = 0
first = true
header = ""
size = 0
total_separators = 0
File.foreach(input_file).with_index do |line, line_num|
    line_count = line_count + 1
    if first and @options[:header]
        header = line
        chars = header.split('')
        chars.each do |c|
            if @options[:verbose]
                if c == @options[:separator]
                    puts "👋 found one => '#{c}'"
                else
                    puts "🚫 just a character => '#{c}'"
                end
            end
            total_separators = total_separators + 1 if c == @options[:separator]
        end
        total_separators = total_separators + @options[:fix_broken_header]
        puts "🔎 looking for #{total_separators} => '#{@options[:separator]}'"
        first = false
    else
        count_separator = 0
        line.split('').each do |c|
            count_separator = count_separator + 1 if c == @options[:separator]
        end
        if count_separator != total_separators && total_count > 0
            puts "💥 data corrupted at line #{total_count+line_count}"
            exit
        end
    end
    
    size = size + File.write(output, line, size, mode: "a+")

    if line_count >= @options[:chunk_size]
        # create a new file name
        puts "✏️ chunk file #{output_file} written to #{@options[:output]}"
        output_count = output_count + 1
        output_file = sprintf("chunk-%08d.txt", output_count)
        output = File.expand_path(File.join(@options[:output], output_file))
        if @options[:header] and header != ""
            size = File.write(output, header, size, mode: "a+")
        end
        total_count = total_count + line_count
        line_count = 0
        file_count = file_count + 1
    end
end

puts "total lines:          #{total_count}"
puts "total files created:  #{file_count}"