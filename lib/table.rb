CLR = "\e[0K"
CURS_INVIS = "\e[?25l"
CURS_VIS = "\e[?25h"
def UP_N_LINES(n) ; "\e[#{n}A" end


# Returns number of rows and cols in terminal 
# @return [Integer, Integer] height and width
def winsize
    require 'io/console'
    IO.console.winsize
end


class String
    def constrain(amout)
        self[0...-amout] + "…"
    end
end

# Class that represents a "fancy" item, i.e
# a piece of text surrounded by ansi escape
# codes. It's almost the same as a normal
# string with the exception of the .length
# method which returns the size of the text
# not sorrounded by escape codes.
class FancyItem < String
    # @title String the string to be displayed
    def initialize(title, args)
        @title = title
        @args = args
    end

    # Returns the size of the displayed string
    def length
        @title.length
    end

    def constrain(amount)
        "\033[#{@args}m#{@title[0...-amount] + "…"}\033[0m"
    end

    # Wraps the string with ansi esacpe codes
    def to_s
        "\033[#{@args}m#{@title}\033[0m"
    end
end


class BackgroundColor < FancyItem
    def initialize(title, r, g, b)
        super(title, "48;2;#{r};#{g};#{b}")
    end
end


class HyperLinkItem < FancyItem
    def initialize(title, link)
        @title = title
        @link = link
    end

    def constrain(amount)
        "\u001B]8;;#{@link}\u0007#{@title[0...-amount] + "…"}\u001B]8;;\u0007"
    end

    def to_s
        "\u001B]8;;#{@link}\u0007#{@title}\u001B]8;;\u0007"
    end
end


# A class to create, render, and update an ascii table
class Table
    attr_reader :col_sizes

    def initialize(headings)
        @width = winsize[1]
        @headings = headings
        @master = nil
        @col_sizes = [0] * @headings.length
        @borders = {
            tl: "┌", h: "─", tm: "┬", tr: "┐",
            e:  "│", l: "├", r: "┤", m: "┼",
            bl: "└", bm: "┴", br: "┘",
            htl: "┏", hh: "━", htm: "┳", htr: "┓",
            he: "┃", hl: "┡", hr: "┩", hm: "╇"
        }

        @items = []
        @constraints = []

        @bg = "\033[48;2;62;71;86m"
        @rt = "\033[0m"
    end

    def set_master(values)
        @master = values
    end

    private def set_constraints
        def table_width(arr)
            arr.inject(0){|sum,x| sum + x + 2} + arr.length + 1
        end
        sizes = @col_sizes.dup
        while table_width(sizes) > @width - 1
            maxi = sizes.index(sizes.max)
            sizes[maxi] -= 1
        end
        @constraints = @col_sizes.zip(sizes).map { |a, b| a - b}
    end

    private def get_col(index)
        if @master
            top = [@headings] + [@master]
        else
            top = [@headings]
        end
        (top+@items).map {|row| row[index]}
    end

    private def update_col_sizes
        @headings.length.times do |n|
            @col_sizes[n] = get_col(n).max_by(&:length).length
        end
    end

    private def get_separator(left, middle, right, b)
        out = left
        @col_sizes.each_with_index do |w, index|
            out += b * (w+2-@constraints[index])
            out += middle
        end
        out[-1] = right
        out
    end

    private def get_middle(array, show_bg = 0, edge = @borders[:e])
        output = []
        array.each_with_index do |item, index|
            if @constraints[index] != 0 and item.length > (@col_sizes[index] - @constraints[index])
                _item = item.constrain(@constraints[index] + 1)
                constrain_space = 0
            else
                _item = item.to_s
                constrain_space = 1
            end
            output << (
                @bg * show_bg + # Show bg
                " " + _item + # Item
                " " * (@col_sizes[index] - @constraints[index] * constrain_space - item.length + 1) + # Spacing
                @rt * show_bg # Reset
            )
        end
        "#{edge}" + output.join("#{edge}") + "#{edge}"
    end

    public def <<(items)
        @items << items
    end

    def get_array
        update_col_sizes
        set_constraints
        out_arr = []

        # Print top
        out_arr << get_separator(
            @borders[:htl],
            @borders[:htm],
            @borders[:htr],
            @borders[:hh]
        )

        # Print header
        out_arr << get_middle(@headings, 0, @borders[:he])
        out_arr << get_separator(
            @borders[:hl],
            @borders[:hm],
            @borders[:hr],
            @borders[:hh]
        )

        # Print underline items (master)
        if @master
            out_arr << get_middle(
                @master.drop(1).map {|s| FancyItem.new(s, "4")}.unshift(@master[0])
            )
        end

        # Print rows
        @items.each_with_index do |row, i|
            out_arr << get_middle(row, (i-1) % 2)
        end

        # Print bottom
        out_arr << get_separator(
            @borders[:bl],
            @borders[:bm],
            @borders[:br],
            @borders[:h]
        )

        out_arr
    end

    def total_width
        @col_sizes.inject(0){|sum,x| sum + x + 2} + @col_sizes.length + 1 - @constraints.inject(0){|sum,x| sum + x} 
    end

    def render
        _, width = winsize
        get_array.each do |item|
            puts item + "\e[0K"
        end
        $stdout.flush
    end

    def clear
        STDOUT.print("\e[#{@items.length + (@master ? 5 : 4)}A")
        @items = []
    end

    def update_render
        STDOUT.print("\e[10A")
        get_array.each do |item|
            puts item + "\e[0K"
        end
        $stdout.flush
    end
end

# A prompt that allows for text to display both to the left
# and the right of the cursor. The input cannot exceed available
# space and can be validated.
# @param [String] left_text Text to display to the left
# @param [String] right_text Text to display to the right
# @param [Integer] width Width of entire prompt
# @param [Regex] validation Validate input (one char at a time)
# @return [String] User input
def pretty_prompt(left_text, right_text, width, validation = /\d|q/)
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
      when "q"
        exit(1)
      when validation
        output += c
        print c
      end
    end
    puts ""
    output
end
# puts "\nUser Input: #{pretty_prompt("Go to page: ", "Ratelimit: 3000", WIDTH)}"

=begin
WIDTH = 125
t = Table.new(["Link", "Owner", "Name", "Stars", "Open issues", "Fork count", "Watchers", "Size", "Last updated"])
t.set_master(["Link", "art1415926535", "PyQt5-syntax-highlighting", "10", "0", "3", "2", "132.0KB", "2021-04-12T08:38:51Z"])
#t << ["Link", "Owner", "Name", "Stars", "Open issues", "Fork count", "Watchers", "Size", "Last updated"].reverse
t.render

puts "COLS_SIZES: #{t.col_sizes}"
puts t.col_sizes.inject(0){|sum,x| sum + x + 2} + t.col_sizes.length - 1
=end


=begin
STDOUT.print(CURS_INVIS)

1.upto(3) do |i|
    sleep(1)
    t.clear
    t << [rand(1..10_000_000).to_s, "Stat"]
    t << [HyperLinkItem.new("Link", "https://www.google.com"), (0...4).map { (65 + rand(26)).chr }.join]
    t << ["1", "3"]
    t << ["9", "2"]
    t.render

    print "Text: " + "\e[0K"
    STDOUT.print(CURS_VIS)
    g = gets.chomp
    STDOUT.print(CURS_INVIS)
    STDOUT.print("\e[1A")
end

STDOUT.print(CURS_VIS)
=end