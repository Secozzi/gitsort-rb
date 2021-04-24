require_relative "table"
require_relative "utils"
require_relative "env"


class BaseSorter
    def initialize(url, options)
        @url = url
        @options = options
        @per_page = options[:page]
        @table = nil
    end

    def get_url_info
        is_link = /^(git(hub)?|https?)/
        is_git_path = /^[a-zA-Z0-9\-_.]+\/[a-zA-Z0-9\-_.]+/
        git_url_regex = /^(https|git)?(:\/\/|@)?([^\/:]+)[\/:](?<owner>[^\/:]+)\/(?<name>.+)(.git)?$/
        is_git_repo = /((.git)|\/)$/

        if (is_link =~ @url).nil?
            raise "Invliad repo, must be of form (/)owner/repo(...)" if @url.count("/") == 0
            @url.split("/").reject(&:empty?)[0..1]
        else
            if (is_git_path =~ @url).nil?
                match = git_url_regex.match(@url)
                raise "Invalid URL" if match.nil?

                name = match[:name].split("/").reject(&:empty?)[0]
                [match[:owner], name].map {|item| item.gsub(is_git_repo, "")}
            else
                @url.split("/").reject(&:empty?)[0..1]
            end
        end
    end

    def create_table(headings, master = nil)
        @table = Table::TextTable.new(headings)
        @table.set_master(master) if master
    end

    def start_loop(items)
        items[0..(@per_page-1)].each do |i|
            @table << i
        end
        @table.render
        table_width = @table.total_width

        to_page = 0
        page_count = (items.length.to_f / @per_page).ceil
        rate_limit = Env::get_value("RATE_LIMIT")
        while true
            STDOUT.print("\e[0J")
            to_page = Table.pretty_prompt("Go to page: ", "Ratelimit: #{rate_limit} | Page #{to_page+1}/#{page_count}", table_width).to_i - 1
            unless to_page > page_count - 1
                STDOUT.print("\e[1E")
                STDOUT.print("\e[1A")
                @table.clear
                items[0+@per_page*to_page..(@per_page-1)+10*to_page].each do |i|
                    @table << i
                end
                @table.render
                table_width = @table.total_width
            else
                STDOUT.print("\e[1E")
                STDOUT.print("\e[1A")
            end
        end
    end
end


module Sorter
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
                    Utils::to_filesize(fork["diskUsage"].to_i * 1024).to_s, 
                    Utils::humanize_time(fork["updatedAt"])
                ]
            end
    
            master_list = [
                Table::HyperLinkItem.new("Link", mr["url"]), *mr["nameWithOwner"].split("/"),
                mr["stargazerCount"].to_s, mr["openIssues"]["totalCount"].to_s,
                mr["forkCount"].to_s, mr["watchers"]["totalCount"].to_s,
                Utils::to_filesize(mr["diskUsage"].to_i * 1024).to_s, 
                Utils::humanize_time(mr["updatedAt"])
            ]
    
            [forks_list, master_list]
        end
    end
    class IssuesSorter < BaseSorter ; end
    class PullReqSorter < BaseSorter
        def get_data(data)
            prs = data["data"]["repository"]["pullRequests"]["nodes"]
            pr_list = []
            prs.each do |pr|
                pr_list << [
                    Table::HyperLinkItem.new("Link", pr["permaLink"]),
                    Table::HyperLinkItem.new(pr["author"]["login"], "www.google.com"),
                    Utils::humanize_time(pr["createdAt"]), pr["additions"].to_s,
                    pr["deletions"].to_s, pr["changedFiles"].to_s,
                    pr["comments"]["totalCount"].to_s,
                    Utils::humanize_time(pr["updatedAt"])
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
                    repo["forkCount"].to_s, Utils::to_filesize(repo["diskUsage"].to_i * 1024).to_s, 
                    Utils::humanize_time(repo["pushedAt"])
                ]
            end
            repo_list
        end
    end
end