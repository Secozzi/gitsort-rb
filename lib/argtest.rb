require 'optparse'

options = {}

subtext = <<HELP
Commonly used command are:
   foo :     does something awesome
   baz :     does something fantastic
See 'opt.rb COMMAND --help' for more information on a specific command.
HELP

global = OptionParser.new do |opts|
  opts.banner = "Usage: opt.rb [options] [subcommand [options]]"
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.separator ""
  opts.separator subtext
end
#end.parse!

subcommands = { 
  'foo' => OptionParser.new do |opts|
      opts.banner = "Usage: foo [options]"
      opts.on("-f", "--[no-]force", "force verbosely") do |v|
        options[:force] = v
      end
   end,
   'baz' => OptionParser.new do |opts|
      opts.banner = "Usage: baz [options]"
      opts.on("-q", "--[no-]quiet", "quietly run ") do |v|
        options[:quiet] = v
      end
   end
}


global.order!
command = ARGV.shift
unless command
  STDERR.puts "ERROR: no subcommand"
  STDERR.puts global # prints usage
  exit(-1)
end
subcommands[command].order!

puts "Command: #{command} "
p options
puts "ARGV:"
p ARGV