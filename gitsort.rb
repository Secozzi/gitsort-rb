require_relative "lib/argparser"
require_relative "lib/sorters"
require_relative "lib/env"


Env::init


sorters = {
    "repos" => Sorter::RepositoriesSorter,
    "forks" => Sorter::ForkSorter,
    "issues" => Sorter::IssuesSorter,
    "pull_requests" => Sorter::PullReqSorter
}

options, url = SortParser.parse(ARGV)

if options[:command] == "token"
    if Env::key_exists("GITSORT_TOKEN")
        puts "Token is already set, do you want to update it? [y/n]"
        input = STDIN.getch
        if input.downcase == "y"
            Env::update_key("GITSORT_TOKEN", options[:token])
            puts "Successfully updated token."
        elsif input.downcase == "n"
        else
            puts "Error: invalid choice."
        end
    else
        Env::append_key("GITSORT_TOKEN", options[:token])
        puts "Successfully added token."
    end
else
    unless Env::key_exists("GITSORT_TOKEN")
        puts "Cannot locate token, please set it and try again."
        exit(1)
    end
    token = Env::get_value("GITSORT_TOKEN")
    sorter_class = sorters[options[:command]]
    unless sorter_class
        puts "Error: `#{options[:command]}` is not an available command."
    else
        sorter = sorter_class.new(url, options, token)
        sorter.fetch_data
        sorter.create_table
        sorter.start
    end
end
