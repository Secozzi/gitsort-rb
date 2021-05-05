module Table
    CLR = "\e[0K"
    CURS_INVIS = "\e[?25l"
    CURS_VIS = "\e[?25h"
    CLR_AFTER_CURS = "\e[0J"
    def self.UP_N_LINES(n) ; "\e[#{n}A" end
    def self.DOWN_N_LINES(n) ; "\e[#{n}B" end
    def self.DOWN_N_LINES_BEGINNING(n) ; "\e[#{n}E" end


    # Returns number of rows and cols in terminal 
    #
    # @return [Integer, Integer] height and width
    def self.winsize
        require 'io/console'
        IO.console.winsize
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
            @args  = args
        end

        # Returns the size of the displayed string
        def length
            @title.length
        end

        # Removues the last `amount` number of characters
        # and adds an ellipsis
        #
        # @param [Integer] amount Amount of characters to remove
        def constrain(amount)
            "\033[#{@args}m#{@title[0...-amount] + "…"}\033[0m"
        end

        # Wraps the string (@title) with ansi esacpe codes and
        # args
        def to_s
            "\033[#{@args}m#{@title}\033[0m"
        end
    end
    # TODO: Maybe add function add_args() that prepends \033[#{args}, 
    # then when to_s is called append the \e[0m to solve the issue 
    # with nested reset codes.


    # Class to create text with background color
    class BackgroundColor < FancyItem
        def initialize(title, r, g, b)
            super(title, "48;2;#{r};#{g};#{b}")
        end
    end


    # Class to create text with foreground color
    class Foreground < FancyItem
        def initialize(title, r, g, b)
            super(title, "38;2;#{r};#{g};#{b}")
        end
    end


    # Class to create a clickable hyperlink with
    # different title than the link
    class HyperLinkItem < FancyItem
        def initialize(title, link)
            @title = title
            @link  = link
        end

        def constrain(amount)
            "\u001B]8;;#{@link}\u0007#{@title[0...-amount] + "…"}\u001B]8;;\u0007"
        end

        def to_s
            "\u001B]8;;#{@link}\u0007#{@title}\u001B]8;;\u0007"
        end
    end
    

    String.prepend(Module.new do 
        # Removes the last `amount` number of characters
        # and adds an ellipsis
        #
        # @param [Integer] amount Amount of characters to remove
        def constrain(amount)
            self[0...-amount] + "…"
        end
    end)

    # A class to create, render, and update an ascii table
    class TextTable
        include Table

        attr_reader :col_sizes 

        # Initialize the table, with headings, items and optionally
        # a master row, which sits on top the items with underscores
        # except the first, which is a link
        def initialize(headings, items, master = nil)
            @width      = Table::winsize[1]
            @headings   = headings
            @items      = items
            @master     = master
            @col_sizes  = [0] * @headings.length

            # TODO: Maybe split up soft and hard into different
            # hashmaps but with the same keys so it's eaiser to
            # Switch between the two and eventually more styles
            @borders    = {
                tl: "┌", h: "─", tm: "┬", tr: "┐",
                e:  "│", l: "├", r: "┤", m: "┼",
                bl: "└", bm: "┴", br: "┘",
                htl: "┏", hh: "━", htm: "┳", htr: "┓",
                he: "┃", hl: "┡", hr: "┩", hm: "╇"
            }

            @constraints     = []

            # TODO: Maybe put as enviroment variable?
            background_rgb   = [62, 71, 86]
            @bg              = "\033[48;2;#{background_rgb.join(';')}m"
            @rt              = "\033[0m"
            @previous_length = 0
        end

        # If the table is calculated to be wider than the screen, we
        # constrain some of the columns to the whole table fits.
        #
        # This function creates an array with the constraints given 
        # to each column.
        # The constraints are evenly distributed between each column.
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

        # Returns a list of each element in the `index`th column
        #
        # @param [Integer] index The index of column
        # @param [Integer] start Start index of items
        # @param [Integer] no_of_rows Number of items retrieved
        private def get_col(index, start, no_of_rows)
            top = @master ? [@headings] + [@master] : [@headings]
            (top+@items[start...start + no_of_rows]).map {|row| row[index]}
        end

        # Calculates the maximum length of each element in every column
        # and adds it to an array.
        #
        # @param [Integer] start Start index of items
        # @param [Integer] no_of_rows Number of items retrieved
        private def update_col_sizes(start, no_of_rows)
            @headings.length.times do |n|
                @col_sizes[n] = get_col(n, start, no_of_rows).max_by(&:length).length
            end
        end

        # Returns a table seperator
        #
        # @param [String] left The character on the left
        # @param [String] middle The character that separates each column
        # @param [String] right The character on the right
        # @param [String] b The character inbetweem
        # @return [String] The separator
        private def get_separator(left, middle, right, b)
            out = left
            @col_sizes.each_with_index do |w, index|
                out += b * (w+2-@constraints[index])
                out += middle
            end
            out[-1] = right
            out
        end

        # Returns a row to be shown in the table
        #
        # @param [Array] array Array of items, every item in the row
        # @param [Integer] show_bg A flag whether or not to show background color
        # @param [String] edge The character separating each item
        # @return [String] String that holds the items
        private def get_middle(array, show_bg = 0, edge = @borders[:e])
            output = []
            array.each_with_index do |item, index|
                if @constraints[index] != 0 and item.length > (@col_sizes[index] - @constraints[index])
                    _item = item.constrain(
                        @constraints[index] + 1 - (@col_sizes[index] - item.length)
                    )
                    constrain_space = 0

                else
                    _item = item.to_s
                    constrain_space = 1
                end
                # Nested ansi escape codes
                if _item.end_with?("\033[0m") and show_bg == 1
                    _item.delete_suffix!("\033[0m")
                end
                spacing = (@col_sizes[index] - @constraints[index] * constrain_space - item.length + 1)
                if constrain_space == 0
                    spacing -= (@col_sizes[index] - item.length)
                end
                output << (
                    @bg * show_bg + # Background color
                    " " + _item   + # Item
                    " " * spacing + # Spacing
                    @rt * show_bg   # Reset mode
                )
            end
            "#{edge}" + output.join("#{edge}") + "#{edge}"
        end

        # Get the array that holds each item in the table to be printed
        #
        # @param [Integer] start Start index of items to be shown
        # @param [Integer] no_of_rows Number of items retrieved
        # @return [Array] Array of strings, the table
        def get_array(start, no_of_rows)
            update_col_sizes(start, no_of_rows)
            set_constraints
            out_arr = []

            # Top separator
            out_arr << get_separator(
                @borders[:htl],
                @borders[:htm],
                @borders[:htr],
                @borders[:hh]
            )

            # Headers and another separator
            out_arr << get_middle(@headings, 0, @borders[:he])
            out_arr << get_separator(
                @borders[:hl],
                @borders[:hm],
                @borders[:hr],
                @borders[:hh]
            )

            # Master items, top of the array which has underscores.
            # The first two items are always links and doesn't need underscores.
            if @master
                out_arr << get_middle(
                    @master.drop(2).map {|s| FancyItem.new(s, "4")}.unshift(@master[0], @master[1])
                )
            end

            # The rows
            @items[start...start + no_of_rows].each_with_index do |row, i|
                out_arr << get_middle(row, (i-1) % 2)
            end

            # Bottom separator
            out_arr << get_separator(
                @borders[:bl],
                @borders[:bm],
                @borders[:br],
                @borders[:h]
            )

            # Return the array
            out_arr
        end

        # Return total number of items the table holds
        def get_no_of_rows
            @items.length
        end

        # Return the total width of the table with the current items
        def total_width
            @col_sizes.inject(0){|sum,x| sum + x + 2} + @col_sizes.length + 1 - @constraints.inject(0){|sum,x| sum + x} 
        end

        # Renders the table
        # 
        # @param [Integer] start Start index of items to be shown
        # @param [Integer] no_of_rows Number of items retrieved
        def render(start, no_of_rows)
            to_print = get_array(start, no_of_rows)
            @previous_length = to_print.length
            to_print.each do |item|
                puts item + Table::CLR
            end
            $stdout.flush
        end

        # Moves the cursor to the beginning of the table so a new table
        # can be rendered atop of the old one.
        # 
        # @param [Integer] start Start index of items to be shown
        # @param [Integer] no_of_rows Number of items retrieved
        def update_render(start, no_of_rows)
            STDOUT.print(Table::UP_N_LINES(@previous_length))
            to_print = get_array(start, no_of_rows)

            to_print.each do |item|
                puts item + Table::CLR
            end

            if to_print.length < @previous_length
                difference = @previous_length - to_print.length
                difference.times do |i|
                    STDOUT.print(Table::CLR)
                    STDOUT.print(Table::DOWN_N_LINES(1))
                end
                STDOUT.print(Table::UP_N_LINES(difference))
            end

            @previous_length = to_print.length
            $stdout.flush
        end
    end

    # A prompt that allows for text to display both to the left
    # and the right of the cursor. The input cannot exceed available
    # space and can be validated.
    #
    # @param [String] left_text Text to display to the left
    # @param [String] right_text Text to display to the right
    # @param [Integer] width Width of entire prompt
    # @param [Regex] validation Validate input (one char at a time)
    # @return [String] User input
    def self.pretty_prompt(left_text, right_text, width, validation = /\d|q/)
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
end
