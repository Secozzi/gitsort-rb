require 'optparse'


class SortParser
    def self.parse(args)
        args << "--help" if args.empty?

        options = {sort: "STARGAZERS", page: 10, order: "DESC"}

        subtext = <<HELP
Available things to sort includes:
    forks         | fork  | f - Sort forks of a repository
    issues        | issue | i - Sort issues of a repository
    pull_requests | pr    | p - Sort pull requests of a repository
    repositories  | repos | r - Sort repositories of an user or organization

See 'opt.rb COMMAND --help' for more information on a specific command.
HELP

        global = OptionParser.new do |opts|
            opts.banner = "Usage: opt.rb sort [options] [ITEMS_PER_PAGE] [ORDER_DIRECTION] "
            opts.on(
                "-p [INTEGER]",
                "--per-page [INTEGER]",
                Integer,
                "Show number of items per page. Defaults to 10"
            ) do |page|
                options[:page] = page if page
            end

            opts.on(
                "-o [STRING]",
                "--order-direction [STRING]",
                String,
                "Direction of ordering, either DESC or ASC. Defaults to DESC"
            ) do |direction|
                if ["ASC", "DESC"].include? direction.upcase
                    options[:order] = direction.upcase
                else
                    raise "Invalid order method"
                end
            end

            opts.separator ""
            opts.separator subtext
        end

        issues_opts = OptionParser.new do |opts|
            options[:sort] = "UPDATED_AT"
            opts.banner = "Usage: gitsort.rb issues [SORT_METHOD]"
            opts.on(
                "-u [STRING]",
                "--url [STRING]",
                String,
                "Url of Github Repository"
            )
            
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

        fork_opts = OptionParser.new do |opts|
            opts.banner = "Usage: gitsort.rb fork [SORT_METHOD]"
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
                "Sort repos by method. Sort methods:",
                "1.\tname    | n - Sort by name",
                "2.\tpushed  | p - Sort by push time",
                "3.\tupdated | u - Sort by update time",
                "4.\tcreated | c - Sort by creation time",
                "5.\tstars   | star | s - Sort by star count",
                "Defaults to star count."
            ) do |sort|

                case sort.downcase
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
            options[:sort] = "UPDATED_AT"
            opts.banner = "Usage: gitsort.rb pr [SORT_METHOD]"
            opts.on(
                "-u [STRING]",
                "--url [STRING]",
                String,
                "Url of Github Repository"
            )
            
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
                "-u [STRING]",
                "--user [STRING]",
                String,
                "Name of user or organization."
            )

            opts.on(
                '-s [STRING]',
                '--sort [STRING]',
                String,
                "Sort repos by method. Sort methods:",
                "1.\tname    | n - Sort by name",
                "2.\tpushed  | p - Sort by push time",
                "3.\tupdated | u - Sort by update time",
                "4.\tcreated | c - Sort by creation time",
                "5.\tstars   | star | s - Sort by star count",
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

        commands = {
            "repositories" => "repos",
            "repos" => "repos",
            "r" => "repos",
            "forks" => "forks",
            "fork" => "forks",
            "f" => "forks",
            "issues" => "issues",
            "i" => "issues",
            "pull_requests" => "pull_requests",
            "pr" => "pull_requests",
            "P" => "pull_requests"
        }

        subcommands = {
            "repos" => repo_opts,
            "forks" => fork_opts,
            "issues" => issues_opts,
            "pull_requests" => pr_opts
        }

        global.parse!
        global.order!
        command = args.shift
        subcommands[commands[command]].order!
        options[:command] = commands[command]

        options
    end
end