require_relative "lib/ratelimiter"
require_relative "lib/argparser"
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
end

class ForkSorter < BaseSorter
    def query(owner, name, orderBy, direction, first = 100)
        <<-GRAPHQL
        {
            repository(owner: #{owner}, name: #{name}) {
                url
                nameWithOwner
                stargazerCount
                watchers { totalCount }
                forkCount
                diskUsage
                updatedAt
                forks
                (
                    first: #{first}
                    orderBy: {field: #{orderBy}, direction: #{direction}}
                ){
                    totalCount
                    nodes{
                        url
                        nameWithOwner
                        stargazerCount
                        watchers { totalCount }
                        forkCount
                        diskUsage
                        updatedAt
                    }
                }
            }
        }
        GRAPHQL
    end
end
class IssuesSorter < BaseSorter ; end
class PullReqSorter < BaseSorter ; end
class DependentSorter < BaseSorter ; end
class DependenciesSorter < BaseSorter ; end
class RepositoriesSorter < BaseSorter ; end

options, args = SortParser.parse(ARGV)

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
    sorter = ForkSorter.new(args[0], 10)
    name, owner = sorter.get_url_info
    p options
    query = sorter.query(owner, name, options[:order], options[:direction])
    p get_response(query, token)
else
    puts "UWU"
end
#puts options