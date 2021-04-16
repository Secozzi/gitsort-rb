CLR = "\e[0m"
CURS_INVIS = "\e[?25l"
CURS_VIS = "\e[?25h"
def UP_N_LINES(n) ; "\e[#{n}A" end

def winsize
    require 'io/console'
    IO.console.winsize
end

def underline
    "\e[4m"
end

def background(r, g, b)
    "\e[48;2;#{r};#{g};#{b}m"
end

def foreground(r, g, b)
    "\e[38;2;#{r};#{g};#{b}m"
end

def up(no=1)
    "\e[#{no.to_i}]"
end

def link(title, url)
    "\e]8;;#{url}\a#{title}\e]8;;\a"
end

class AnsiStr
    def initialize(text, size_list = nil)
        @text = text
        @string_list = [@text]
        @size_list = size_list || [text.size]
    end

    def enclose!(start_code)
        @string_list = @string_list.unshift(start_code) << CLR
    end

    def enclose(start_code)
        AnsiStr.new(
            start_code + @string_list.join("") + CLR,
            @size_list
        )
    end

    def +(other)
        new_str = (@string_list + [other.to_s]).join("")
        if other.instance_of? AnsiStr
            size_l = @size_list + [other.size]
        else
            size_l = @size_list + [other.to_s.size]
        end
        AnsiStr.new(new_str, size_l)
    end

    def size
        @size_list.inject(0){|sum,x| sum + x}
    end

    def to_s
        @string_list.join("")
    end
end

=begin
l = AnsiStr.new("Hello ").enclose(underline)
# l.enclose!(underline)
n = AnsiStr.new("World")
n.enclose!(background(117, 124, 89))

b = l + "Stuck" + n
puts b.to_s
p "SIZE: #{b.size}"
=end

class Table
    attr_reader :col_sizes

    def initialize(headings, master)
        @headings = headings
        @master = master
        @col_sizes = [0] * @headings.length
        @borders = {
            tl: "┌", h: "─", tm: "┬", tr: "┐",
            e:  "│", l: "├", r: "┤", m: "┼",
            bl: "└", bm: "┴", br: "┘",
            htl: "┏", hh: "━", htm: "┳", htr: "┓",
            he: "┃", hl: "┡", hr: "┩", hm: "╇"
        }

        @top = [@headings, @master]
        @items = []

        @bg = "\033[48;2;62;71;86m"
        @rt = "\033[0m"
    end

    private
    def get_col(index)
        (@top+@items).map {|row| row[index]}
    end

    def update_col_sizes
        @headings.length.times do |n|
            @col_sizes[n] = get_col(n).max_by(&:size).length
        end
    end

    def get_separator(left, middle, right, b)
        out = left
        @col_sizes.each do |w|
            out += b * (w+2)
            out += middle
        end
        out[-1] = right
        out
    end

    def get_middle(array, show_bg = 0, edge = @borders[:e])
        output = []
        array.each_with_index do |item, index|
            output << (
                Ansi(@bg * show_bg) + # Show bg
                " " + item.to_s + # Item
                " " * (@col_sizes[index] - item.length + 1) + # Spacing
                @rt * show_bg # Reset
            )
        end
        "#{edge}" + output.join("#{edge}") + "#{edge}"
    end

    public
    def <<(items)
        @items << items
    end

    def total_width
        @col_sizes.inject(0){|sum,x| sum + x + 2} + @col_sizes.length + 1
    end

    def get_array
        update_col_sizes
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

        # Print underline items
        out_arr << get_middle(
            @master.drop(1).map {|s| UnderLine.new(s)}.unshift(@master[0])
        )

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

    def render
        _, width = winsize
        get_array.each do |item|
            puts item + "\e[0K"
        end
        $stdout.flush
    end

    def clear
        STDOUT.print("\e[#{@items.length + 5}A")
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
