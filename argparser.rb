require 'optparse'


class Parser
    @options = {
        sort: "star",
        page: 10
    }

    def self.parse(args)
        option_parser = OptionParser.new do |opts|
            opts.banner = "Usage: gitsort.rb [SORT_METHOD] [ITEMS_PER_PAGE]"

            opts.on(
                "-u [STRING]",
                "--url [STRING]",
                String,
                "Url of Github Repository."
            )

            opts.on(
                '-s [STRING]',
                '--sort [STRING]',
                String,
                "Sort forks by method. Sort methods:",
                "1.\tstars | star | s - sort by star count",
                "2.\tforks | fork | f - sort by fork count",
                "3.\tupdated | activity | up | u | a - sort by last updated",
                "Defaults to star count."
                ) do |sort|

                case sort
                when "star", "stars", "s"
                    @options[:sort] = "stargazers"
                when "fork", "forks", "f"
                    @options[:sort] = "fork"
                when "newest", "n"
                    @options[:sort] = "newest"
                else
                    raise "Invalid sort method"
                end
            end

            opts.on(
                "-p [INTEGER]",
                "--per-page [INTEGER]",
                Integer,
                "Show number of items per page. Defaults to 10"
            ) do |page|
                @options[:page] = page if page
            end
        end

        option_parser.parse(args)
        @options
    end
end


options = Parser.parse(ARGV)
p options