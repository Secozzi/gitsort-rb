class Ansi
    CLR = "\e[0m"

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

    def self.link(title, url)
        "\e]8;;#{url}\a#{title}\e]8;;\a"
    end
end


class AnsiStr
    def initialize(text=nil)
        @text = (text || "").to_s
        @string_list = [text]
    end

    def +(other)
        @string_list << other
    end

    def to_s
        @string_list
    end
end

l = AnsiStr.new("g")
l + "j"
p l.to_s
