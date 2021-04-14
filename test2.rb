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
=end
require 'io/console'

# Returns size of windows 
# @return [Integer, Integer] height and width
def winsize
  IO.console.winsize
end


# A prompt that allows for text to display both to the left
# and the right of the cursor. The input cannot exceed available
# space and can be validated.
# @param [String] left_text Text to display to the left
# @param [String] right_text Text to display to the right
# @param [Integer] width Width of entire prompt
# @param [Regex] validation Validate input (one char at a time)
# @return [String] User input
def pretty_prompt(left_text, right_text, width, validation = /\d/)
  # Calculate available space
  input_width = width - left_text.size - right_text.size
  puts left_text + " " * input_width + right_text
  
  # Move cursor
  STDOUT.print("\e[1A")
  STDOUT.print("\e[#{left_text.size}C")

  output = ""
  while output.size < input_width
    c = STDIN.getch
    case c
    when "\b"
      if output.size > 0
        STDOUT.print("\b \b")
        output = output[0...-1]
      end
    when "\r"
      return output
    when "\u0003"
      exit
    when validation
      output += c
      print c
    end
  end
  output
end

WIDTH = winsize[1]

puts " Header ".center(WIDTH, "-")
puts "\nUser Input: #{pretty_prompt("Go to page: ", "Ratelimit: 3000", WIDTH)}"