require_relative "lib/ratelimiter"
require_relative "lib/argparser"
require_relative "lib/graphql"
require_relative "lib/table"
require_relative "lib/env"

require "io/console"
require 'net/https'
require "uri"
require 'json'


def humanize_time(time)
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
            return "#{t} #{strings[6-i]}#{'s'*(t==1 ? 0 : 1)}"
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
    }.each_pair { |e, s| return "#{(num.to_f / (s / 1024)).round(2)}#{e}" if num < s }
end


def get_response(query, token)
    uri = URI.parse("https://api.github.com/graphql")

    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true

    req = Net::HTTP::Post.new(uri.path)
    req["Authorization"] = "Bearer #{token}"
    req.body = {"query" => query}.to_json

    res = https.request(req)
    json = JSON.parse(res.body)
    return json
end


class BaseSorter
    def initialize(url, per_page)
        @url = url
        @per_page = per_page
        @table = nil
    end

    # Returnerar en lista med [ägare, repo_namn] från olika typer av Github urls och vissa icke-urls.
    def get_url_info
        if (/^(git(hub)?|https?)/ =~ @url).nil?
            raise "Invliad repo, must be of form [/]owner/repo[...]" if @url.count("/") == 0
            @url.split("/").reject(&:empty?)[0..1]
        else
            if (/^[a-zA-Z0-9\-_.]+\/[a-zA-Z0-9\-_.]+/ =~ @url).nil?
                m = /^(https|git)?(:\/\/|@)?([^\/:]+)[\/:](?<owner>[^\/:]+)\/(?<name>.+)(.git)?$/.match(@url)
                raise "Invalid URL" if m.nil?

                name = m[:name].split("/").reject(&:empty?)[0]
                [m[:owner], name].map {|item| item.gsub(/((.git)|\/)$/, "")}
            else
                @url.split("/").reject(&:empty?)[0..1]
            end
        end
    end

    def create_table(headings, master = nil)
        @table = Table.new(headings)
        @table.set_master(master) if master
    end

    def start_loop(items)
        items[0..9].each do |i|
            @table << i
        end
        @table.render
        table_width = @table.total_width

        while true
            to_page = pretty_prompt("Go to page: ", "Ratelimit: 3000", table_width).to_i - 1
            STDOUT.print("\e[1E")
            STDOUT.print("\e[1A")
            @table.clear
            items[0+10*to_page..9+10*to_page].each do |i|
                @table << i
            end
            @table.render
            table_width = @table.total_width
        end
    end
end

class ForkSorter < BaseSorter
    def get_data(data)
        puts "DATA: #{data}"
        mr = data["data"]["repository"]
        forks = data["data"]["repository"]["forks"]["nodes"]
        forks_list = []

        forks.each do |fork|
            forks_list << [
                HyperLinkItem.new("Link", fork["url"]), *fork["nameWithOwner"].split("/"),
                fork["stargazerCount"].to_s, fork["openIssues"]["totalCount"].to_s,
                fork["forkCount"].to_s, fork["watchers"]["totalCount"].to_s,
                to_filesize(fork["diskUsage"].to_i * 1024).to_s, fork["updatedAt"]
            ]
        end

        master_list = [
            HyperLinkItem.new("Link", mr["url"]), *mr["nameWithOwner"].split("/"),
            mr["stargazerCount"].to_s, mr["openIssues"]["totalCount"].to_s,
            mr["forkCount"].to_s, mr["watchers"]["totalCount"].to_s,
            to_filesize(mr["diskUsage"].to_i * 1024).to_s, mr["updatedAt"]
        ]

        [forks_list, master_list]

        #table = Table.new(
        #    ["Link", "Owner", "Name", "Stars", "Open issues", "Fork count", "Watchers", "Size", "Last updated"]
        #)
        #table.set_master([
        #    HyperLinkItem.new("Link", mr["url"]), *mr["nameWithOwner"].split("/"),
        #    mr["stargazerCount"].to_s, mr["openIssues"]["totalCount"].to_s,
        #    mr["forkCount"].to_s, mr["watchers"]["totalCount"].to_s,
        #    to_filesize(mr["diskUsage"].to_i * 1024).to_s, mr["updatedAt"]
        #])
        #table.render
    end
end
class IssuesSorter < BaseSorter ; end
class PullReqSorter < BaseSorter ; end
class RepositoriesSorter < BaseSorter ; end

options, url = SortParser.parse(ARGV)

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