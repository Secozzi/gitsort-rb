require_relative "lib/ratelimiter"
require_relative "lib/sorters"
require_relative "lib/argparser"
require_relative "lib/graphql"
require_relative "lib/table"
require_relative "lib/env"

require "io/console"
require "net/https"
require "date"
require "json"


def humanize_time(time_str)
    time = Time.now.to_i - DateTime.strptime(time_str, "%Y-%m-%dT%H:%M:%SZ").to_time.to_i
    times = [
        1, 60, 3600, 86400, 604800, 2629746, 31556925
    ]
    strings = [
        "Second", "Minute", "Hour", "Day", "Week", "Month", "Year"
    ]
    tmp = []
    times.each { |t| tmp << time / t}
    tmp.reverse.each_with_index do |t, i|
        if t != 0
            return "#{t} #{strings[6-i]}#{"s"*(t==1 ? 0 : 1)} ago"
        end
    end
end


def to_filesize(num)
    {
        'B'  => 1024 ** 1,
        'KB' => 1024 ** 2,
        'MB' => 1024 ** 3,
        'GB' => 1024 ** 4,
        'TB' => 1024 ** 5
    }.each_pair do |e, s|
        return "#{(num.to_f / (s / 1024)).round(2)} #{e}" if num < s 
    end
end


def get_response(query, token)
    uri = URI.parse("https://api.github.com/graphql")

    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true

    req = Net::HTTP::Post.new(uri.path)
    req["Authorization"] = "Bearer #{token}"
    req.body = {"query" => query}.to_json

    res = https.request(req)
    rate_limit = res["X-RateLimit-Remaining"]
    json = JSON.parse(res.body)
    return json
end

=begin
class ForkSorter < BaseSorter
    def get_data(data)
        mr = data["data"]["repository"]
        forks = data["data"]["repository"]["forks"]["nodes"]
        forks_list = []

        forks.each do |fork|
            forks_list << [
                Table::HyperLinkItem.new("Link", fork["url"]), *fork["nameWithOwner"].split("/"),
                fork["stargazerCount"].to_s, fork["openIssues"]["totalCount"].to_s,
                fork["forkCount"].to_s, fork["watchers"]["totalCount"].to_s,
                to_filesize(fork["diskUsage"].to_i * 1024).to_s, 
                humanize_time(fork["updatedAt"])
            ]
        end

        master_list = [
            Table::HyperLinkItem.new("Link", mr["url"]), *mr["nameWithOwner"].split("/"),
            mr["stargazerCount"].to_s, mr["openIssues"]["totalCount"].to_s,
            mr["forkCount"].to_s, mr["watchers"]["totalCount"].to_s,
            to_filesize(mr["diskUsage"].to_i * 1024).to_s, 
            humanize_time(mr["updatedAt"])
        ]

        [forks_list, master_list]
    end
end
class IssuesSorter < BaseSorter ; end
class PullReqSorter < BaseSorter
    def get_data(data)
        pp data
        prs = data["data"]["repository"]["pullRequests"]["nodes"]
        pr_list = []
        prs.each do |pr|
            puts pr["author"]
            pr_list << [
                Table::HyperLinkItem.new("Link", pr["permaLink"]),
                Table::HyperLinkItem.new(pr["author"]["login"], "www.google.com"),
                humanize_time(pr["createdAt"]), pr["additions"].to_s,
                pr["deletions"].to_s, pr["changedFiles"].to_s,
                pr["comments"]["totalCount"].to_s,
                humanize_time(pr["updatedAt"])
            ]
        end
        pr_list
    end
end
class RepositoriesSorter < BaseSorter
    def get_data(data, type)
        repos = data["data"][type]["repositories"]["nodes"]
        repo_list = []
        repos.each do |repo|
            _lang = repo["languages"]["nodes"]
            if _lang.empty?
                lang = "None"
            else
                lang = _lang[0]["name"].to_s
            end
            repo_list << [
                Table::HyperLinkItem.new("Link", repo["url"]), repo["name"],
                lang,
                repo["stargazerCount"].to_s, repo["openIssues"]["totalCount"].to_s,
                repo["forkCount"].to_s, to_filesize(repo["diskUsage"].to_i * 1024).to_s, 
                humanize_time(repo["pushedAt"])
            ]
        end
        repo_list
    end
end
=end


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
    rate_limiter = RateLimiter.new
    sorter = nil
    case options[:command]
    when "forks"
        sorter = Sorter::ForkSorter.new(url, options[:page])
        owner, name = sorter.get_url_info
        query = fork_query(owner, name, options[:sort], options[:order])
        data = get_response(query, token)
        rate_limiter.add_limit(1)
        fork_list, master_list = sorter.get_data(data)
        sorter.create_table(["Link", "Owner", "Name", "Stars", "Open issues", "Fork count", "Watchers", "Size", "Last updated"], master_list)
        sorter.start_loop(fork_list)
    when "repos"
        sorter = Sorter::RepositoriesSorter.new(url, options[:page])
        unless url =~ /^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$/i
            puts "Invalid username"
            exit(1)
        end
        uri = URI.parse("https://api.github.com/users/#{url}")
        type = JSON.parse(Net::HTTP.get(uri))["type"].downcase
        query = repo_query(type, url, options[:sort], options[:order])
        data = get_response(query, token)
        rate_limiter.add_limit(1)
        repo_list = sorter.get_data(data, type)
        sorter.create_table(["Link", "Repo Name", "Language", "Stars", "Open issues", "Fork count", "Size", "Last push"])
        sorter.start_loop(repo_list)
    when "pull_requests"
        sorter = Sorter::PullReqSorter.new(url, options[:page])
        owner, name = sorter.get_url_info
        query = pr_query(owner, name, options[:sort], options[:order])
        data = get_response(query, token)
        rate_limiter.add_limit(1)
        pr_list = sorter.get_data(data)
        sorter.create_table(["Link", "Author", "Created at", "Additions", "Deletions", "Changed files", "Comments", "Updated at"])
        sorter.start_loop(pr_list)
    end
end

=begin
case options[:command]
when "token"
    if key_exists("GITSORT_TOKEN")
        puts "Token is already set, do you want to update it? [y/n]"
        input = STDIN.getch
        if input.downcase == "y"
            update_key("GITSORT_TOKEN", options[:token])
            puts "Successfully updated token."
        elsif input.downcase == "n"
        else
            puts "Error: invalid choice."
        end
    else
        append_key("GITSORT_TOKEN", options[:token])
        puts "Successfully added token."
    end
when "forks"
    unless key_exists("GITSORT_TOKEN")
        puts "Cannot locate token, please set it and try again."
        exit(1)
    end
    token = get_value("GITSORT_TOKEN")
    sorter = ForkSorter.new(url, 10)

    owner, name = sorter.get_url_info
    query = fork_query(owner, name, options[:sort], options[:order])
    data = get_response(query, token)
    fork_list, master_list = sorter.get_data(data)
    sorter.create_table(["Link", "Owner", "Name", "Stars", "Open issues", "Fork count", "Watchers", "Size", "Last updated"], master_list)
    sorter.start_loop(fork_list)

when "repos"
    p options
else
    puts "UWU"
end
#puts options
=end