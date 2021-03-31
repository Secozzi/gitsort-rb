=begin
class ConsoleReset
    # Unix
    # Contains a string to clear the line in the shell
    CLR = "\e[0K"
    # ANSI escape sequence for hiding terminal cursor
    ESC_CURS_INVIS = "\e[?25l"
    # ANSI escape sequence for showing terminal cursor
    ESC_CURS_VIS   = "\e[?25h"
    # ANSI escape sequence for clearing line in terminal
    ESC_R_AND_CLR  = "\r#{CLR}"
    # ANSI escape sequence for going up a line in terminal
    ESC_UP_A_LINE = "\e[1A"
  
    def initialize
      @first_call = true
    end
  
    def reset_line(text = '')
      # Initialise ANSI escape string
      escape = ""
  
      # The number of lines the previous message spanned
      lines = text.strip.lines.count - 1
  
      # Clear and go up a line
      lines.times { escape += "#{ESC_R_AND_CLR}#{ESC_UP_A_LINE}" }
  
      # Clear the line that is to be printed on
      # escape += "#{ESC_R_AND_CLR}"
  
      # Console is clear, we can print!
      STDOUT.print escape if !@first_call
      @first_call = false
      print text
    end
  
    def hide_cursor
      STDOUT.print(ESC_CURS_INVIS)
    end
  
    def show_cursor
      STDOUT.print(ESC_CURS_VIS)
    end
  
    def test
      hide_cursor

      5.times do |i|
        line = ['===========================================']
        (1..10).each do |num|
          line << ["#{num}:\t#{rand_num}"]
        end
        line << ['===========================================']
        line = line.join("\n")
        reset_line(line)
        sleep 1
      end
  
      puts ''

      show_cursor
    end
  
    private
      def rand_num
        rand(10 ** rand(10))
      end
end

l = ConsoleReset.new()
l.test

puts "OMEGA".center(winsize[1])
1.upto(12) do |i|
  puts "Hello! \n world#{i}"
  $stdout.flush
  STDOUT.print("\e[1A\e[1A")
  sleep(1)
end
=end

require "ansi/code"
require "ansi/string"
#puts ANSI::Code.rgb_code(12, 145, 12, true){"UWU"}
# "48;5;34"
l = ANSI::String.new("Hello world")
l.ansi!("48;5;34")
puts