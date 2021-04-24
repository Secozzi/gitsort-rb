require 'optparse'


class SortParser
    def self.parse(args)
        args << "--help" if args.empty?
        unless args.include? "--help"
            url = args.shift
        end

        options = {sort: "STARGAZERS", first: 30, after: nil, page: 10, order: "DESC"}

        commands = Hash.new "invalid_command"
        command_list = {
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
            "p" => "pull_requests",
            "set-token" => "token",
            "token" => "token",
            "t" => "token"
        }
        commands.merge! command_list

        subtext = <<HELP
Available commands:
    set-token     | token | t - Save Github personal access token
    forks         | fork  | f - Sort forks of a repository
    issues        | issue | i - Sort issues of a repository
    pull_requests | pr    | p - Sort pull requests of a repository
    repositories  | repos | r - Sort repositories of an user or organization

See 'gitsort.rb COMMAND --help' for more information on a specific command.
HELP

        global = OptionParser.new do |opts|
            opts.banner = "Usage: opt.rb URL_OR_REPO_PATH [ITEMS_PER_PAGE] [ORDER_DIRECTION] COMMAND [command_options]"
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

            opts.on(
                "-f [INTEGER]",
                "--first [INTEGER]",
                Integer,
                "Select n number of items from list.",
                "If a query fails, it could be the result of a timeout.",
                "To solve this, decrease the number of items with this argument."
            ) do |first|
                options[:first] = first
            end

            opts.on(
                "-a [STRING]",
                "--after [STRING]",
                String,
                "Returns the elements in the list that come after the specified cursor.",
                "Defaults to not using this argument in the query."
            ) do |after|
                options[:after] = after
            end

            opts.separator ""
            opts.separator subtext
        end

        issues_opts = OptionParser.new do |opts|
            if commands[args[0]] == "issues"
                options[:sort] = "COMMENTS"
            end

            opts.banner = "Usage: gitsort.rb issues [SORT_METHOD]"
            
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
            if commands[args[0]] == "pull_requests"
                options[:sort] = "COMMENTS"
            end

            opts.banner = "Usage: gitsort.rb <url> pr [SORT_METHOD]"
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

        token_opts = OptionParser.new do |opts|
            opts.banner = "Usage: gitsort.rb token YOUR_ACCESS_TOKEN"

            opts.on(
                "token STRING",
                String,
                "Your Github personal access token"
            ) do |token|
                #unless token
                #    raise "The command `token` requires one argument"
                #end
                options[:token] = token.to_s
            end
        end

        subcommands = {
            "repos" => repo_opts,
            "forks" => fork_opts,
            "issues" => issues_opts,
            "pull_requests" => pr_opts,
            "token" => token_opts
        }

        global.order!

        command = args.shift

        if commands[command] == "invalid_command"
            options[:command] = command
            return [options, url]
        end

        subcommands[commands[command]].order!
        options[:command] = commands[command]

        [options, url]
    end
end