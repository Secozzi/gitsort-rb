require 'optparse'


class OldParser
    @options = {
        sort: "star",
        page: 10
    }

    def self.parse(args)
        option_parser = OptionParser.new do |opts|
            opts.banner = "Usage: gitsort.rb [SORT_METHOD] [ITEMS_PER_PAGE] [SET_TOKEN]"

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

            opts.on(
                "--set-token [STRING]",
                String,
                "Set access token for listing private repositories"
            )
        end

        option_parser.parse(args)
        @options
    end
end


class Parser
    @opts1 = {
        sort: "star",
        page: 10
    }
    def self.parse(args)
        global_parser = OptionParser.new do |opts|
            opts.banner = "Usage: gitsort.rb [WHAT_TO_SORT [OPTIONS]] [OPTIONS] [SET_TOKEN]"
        end

        sub_commands = {
            "fork" => OptionParser.new do |opts|
                opts.banner = "Usage: fork [SORT_METHOD] [ITEMS PER PAGE] [TOKEN]"
                opts.on(
                    "-u [STRING]",
                    "--url [STRING]",
                    String,
                    "Url of Github Repository."
                )
            end
        }

        global_parser.parse!
        @options
    end
end


require 'optparse'

options = {}

subtext = <<HELP
Available things to sort includes:
    forks | fork | f : Sort forks of a repository
    contributors | c : Sort contributors of a repository
    dependencies | d : Sort dependencies of a repository

See 'opt.rb COMMAND --help' for more information on a specific command.
HELP

global = OptionParser.new do |opts|
    opts.banner = "Usage: opt.rb [sort [options]] [TOKEN]"
    opts.on(
        "--token [STRING]",
        String,
        "Access token for listing private repositories and accessing graphql queries"
    ) do |token|
        options[:token] = token if token
    end
    opts.separator ""
    opts.separator subtext
end

fork_opts = OptionParser.new do |opts|
    opts.banner = "Usage: gitsort.rb fork [SORT_METHOD] [ITEMS_PER_PAGE]"
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

subcommands = { 
   'forks' => fork_opts,
   "fork" => fork_opts,
   "f" => fork_opts,
   'baz' => OptionParser.new do |opts|
      opts.banner = "Usage: baz [options]"
      opts.on("-q", "--[no-]quiet", "quietly run ") do |v|
        options[:quiet] = v
      end
   end
 }

 global.order!
 command = ARGV.shift
 subcommands[command].order!

 puts "Command: #{command} "
 p options
 puts "ARGV:"
 p ARGV