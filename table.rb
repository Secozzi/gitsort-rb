CLR = "\e[0K"
UP_A_LINE = "\e[1A"

def winsize
    require 'io/console'
    IO.console.winsize
  end
  

class FancyItemBase < String
    def initialize(title)
        @title = title
    end

    def length
        @title.length
    end

    def to_s(args)
        "\033[#{args}m#{@title}\033[0m"
    end
end


class UnderLine < FancyItemBase
    def to_s
        super("4")
    end
end


class BackgroundColor < FancyItemBase
    def initialize(title, r, g, b)
        super(title)
        @r = r
        @g = g
        @b = b
    end
    
    def to_s
        super("48;2;#{@r};#{@g};#{@b}")
    end
end


class HyperLinkItem < FancyItemBase
    def initialize(title, link)
        super(title)
        @link = link
    end

    def to_s
        "\u001B]8;;#{@link}\u0007#{@title}\u001B]8;;\u0007"
    end
end


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

        @items = [@headings, @master]

        @bg = "\033[48;2;62;71;86m"
        @rt = "\033[0m"
    end

    private
    def get_col(index)
        @items.map {|row| row[index]}
    end

    def update_col_sizes
        @headings.length.times do |n|
            @col_sizes[n] = get_col(n).max_by(&:length).length
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
                @bg * show_bg + # Show bg
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
        @items.drop(2).each_with_index do |row, i|
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
            puts item
        end
    end
end

def center(string, string_width, width)
    
end

t = Table.new(["A", "B"], ["Test 1", "Test 22"])
t << ["1", "12"]
t << ["Hello", "there"]
t.render
puts "-" * t.total_width