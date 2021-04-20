require 'optparse'


class SortParser
    def per_page_option(parser)
        parser.on(
            "-p [INTEGER]",
            "--per-page [INTEGER]",
            Integer,
            "Show number of items per page. Defaults to 10"
        ) do |page|
            self.per_page = page
            options[:per_page] = page if page
        end
    end

    def self.parse(args)
        args << "--help" if args.empty?
        url = args.shift

        options = {sort: "STARGAZERS", per_page: 10}

        subtext = <<HELP
Available things to sort includes:
    forks | fork | f : Sort forks of a repository
    dependencies | d : Sort dependencies of a repository
    dependents   | depend : Sort depenedents of a repository
    contributors | contrib | c : Sort contributors of a repository
    repositories | repos   | r : Sort repositories of an user or organization

See 'opt.rb COMMAND --help' for more information on a specific command.
HELP

        global = OptionParser.new do |opts|
            opts.banner = "Usage: opt.rb URL_OR_REPO_PATH [sort [options]] [ITEMS_PER_PAGE]"
            
            opts.separator ""
            opts.separator subtext
        end

        fork_opts = OptionParser.new do |opts|
            opts.banner = "Usage: gitsort.rb fork [SORT_METHOD]"

            opts.on(
                '-s [STRING]',
                '--sort [STRING]',
                String,
                "Sort repos by method. Sort methods:",
                "1.\tName | n - Sort by name",
                "2.\tPushed | p - Sort by push time",
                "3.\tUpdated | u - Sort by update time",
                "4.\tCreated | c - Sort by creation time",
                "5.\tStars | star | s - Sort by star count",
                "Defaults to star count."
            ) do |sort|

                case sort
                when "name", "n"
                    options[:sort] = "NAME"
                when "pushed", "p"
                    options[:sort] = "PUSHED_AT"
                when "updated", "u"
                    options[:sort] = "UPDATED_AT"
                when "created", "c"
                    options[:sort] = "CREATED_AT"
                when "stars", "star", "s"
                    options[:sort] = "STARGAZERS"
                else
                    raise "Invalid sort method"
                end
            end
        end

        pr_opts = OptionParser.new do |opts|
            opts.banner = "Usage: gitsort.rb pr [SORT_METHOD]"

            opts.on(
                '-s [STRING]',
                '--sort [STRING]',
                String,
                "Sort repos by method. Sort methods:",
                "1.\tcomment | c - Sort by comment count",
                "2.\tcreated | C - Sort by creation time",
                "3.\tupdated | u - Sort by update time",
                "Defaults to updated"
            ) do |sort|
                case sort
                when "comment", "c"
                    options[:sort] = "COMMENTS"
                when "created", "C"
                    options[:sort] = "CREATED_AT"
                when "updated", "u"
                    options[:sort] = "UPDATED_AT"
                else
                    raise "Invalid sort method"
                end
            end
        end

        repo_opts = OptionParser.new do |opts|
            opts.banner = "Usage: gitsort.rb repos [SORT_METHOD]"

            opts.on(
                '-s [STRING]',
                '--sort [STRING]',
                String,
                "Sort repos by method. Sort methods:",
                "1.\tName | n - Sort by name",
                "2.\tPushed | p - Sort by push time",
                "3.\tUpdated | u - Sort by update time",
                "4.\tCreated | c - Sort by creation time",
                "5.\tStars | star | s - Sort by star count",
                "Defaults to star count."
            ) do |sort|

                case sort
                when "name", "n"
                    options[:sort] = "NAME"
                when "pushed", "p"
                    options[:sort] = "PUSHED_AT"
                when "updated", "u"
                    options[:sort] = "UPDATED_AT"
                when "created", "c"
                    options[:sort] = "CREATED_AT"
                when "stars", "star", "s"
                    options[:sort] = "STARGAZERS"
                else
                    raise "Invalid sort method"
                end
            end
        end

        subcommands = {
            "repositories" => repo_opts,
            "repos" => repo_opts,
            "r" => repo_opts,
            "forks" => fork_opts,
            "fork" => fork_opts,
            "f" => fork_opts,
            "pr" => pr_opts
        }

        global.order!
        command = args.shift
        subcommands[command].order!

        [options, url]
    end
end

options, url = SortParser.parse(ARGV)
p options
p "ARGS: #{url}"