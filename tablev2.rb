CLR = "\e[0m"
CURS_INVIS = "\e[?25l"
CURS_VIS = "\e[?25h"
def UP_N_LINES(n) ; "\e[#{n}A" end


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
    def initialize(text=nil)
        @text = (text || "").to_s
        @string_list = [@text]
        @size_list = [text.size]
    end

    def enclose!(start_code)
        @string_list = @string_list.unshift(start_code) << CLR
    end

    def +(other)
        @string_list << other.to_s
        @size_list << other.size
    end

    def size
        @size_list.inject(0){|sum,x| sum + x}
    end

    def to_s
        @string_list.join("")
    end
end

l = AnsiStr.new("Hello ")
l.enclose!(underline)
n = AnsiStr.new("World")
n.enclose!(background(117, 124, 89))
puts l.to_s
p "SIZE: #{l.size}"
