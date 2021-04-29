require_relative "table"
require_relative "utils"
require_relative "env"
require_relative "graphql"

require "io/console"
require "net/https"
require "date"
require "json"


# Baseclass for sorters
class BaseSorter
    # Initialize the sorter
    #
    # @param [String] url User input
    # @param [Hash] options Options parsed by optparser
    # @param [String] token Your personal github access token
    def initialize(url, options, token)
        @url        = url
        @options    = options
        @token      = token
        @per_page   = options[:page]

        @table      = nil
        @data       = nil
        @rate_limit = nil
    end

    # Gets either user/organization or owner and repo from a various amount of inputs.
    # These include:
    #   - https://github.com/user/repo/whatever
    #   - https://github.com/user/repo.git
    #   - git@github.com:user/repo.git
    #   - user
    #   - user/repo
    #   - user/repo/whatever
    #
    # @return [Array] Array of user and repo or just user
    def get_url_info
        is_link           = /^(git(hub)?|https?)/
        is_git_path       = /^[a-zA-Z0-9\-_.]+\/[a-zA-Z0-9\-_.]+/
        git_url_regex     = /^(https|git)?(:\/\/|@)?([^\/:]+)[\/:](?<owner>[^\/:]+)\/(?<name>.+)(.git)?$/
        is_git_repo       = /((.git)|\/)$/
        is_valid_username = /^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$/i

        if (is_link =~ @url).nil?
            if @url.count("/") > 0
                @url.split("/").reject(&:empty?)[0..1]
            else
                unless is_valid_username =~ @url
                    raise "Invalid username"
                end
            end
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

    # Returns variablies often used for a graphql query
    #
    # @return [Array] Returns options
    def get_query_variables
        owner, name = get_url_info
        first = @options[:first]
        orderBy = @options[:sort]
        direction = @options[:order]
        if @options[:after]
            after = "after: #{@options[:after]}"
        else
            after = ""
        end
        [owner, name, first, orderBy, direction, after]
    end

    # Return the query from the options given by optparse
    #
    # @return [String] The graphql query as a string
    def get_query
        raise "NotImplemented"
    end

    # Return the data to be displayed in the table from the graphql response.
    # Base class checks if any errors is present and exits accordingly.
    #
    # @param [String] data The data given from the GraphQL response
    # @param [Array] Array containing each headers, items and optionally
    # the masters to be given to the table
    def get_data(data)
        if data.key?("errors")
            puts Table::Foreground.new("ERROR: ", 248, 81, 73).to_s + data["errors"][0]["message"]
            exit(1)
        end
    end

    # Fetches data from graphql.
    # The data is stored in the class variable `@data`
    # and the rate limit is stored in `@rate_limit`
    def fetch_data
        query = get_query
        owner, repo_name = get_url_info
        g = GraphQL.new(query, @token)
        @data = g.get_data
        @rate_limit = g.get_rate_limit
    end

    # Creates the table from the data set earlier.
    # Stores the table in `@table`
    def create_table
        headings, items, master = get_data(@data)
        @table = Table::TextTable.new(headings, items, master)
    end

    # Start the main loop
    def start
        # First render of table
        @table.render(0, @per_page)
        rate_limit = @rate_limit
        table_width = @table.total_width

        to_page = 1
        page_count = (@table.get_no_of_rows.to_f / @per_page).ceil
        while true

            # First clear everything below the cursor, then start the prompt to get the new page
            # Update the render with the new page if the new page isn't out of bounbds.

            STDOUT.print(Table::CLR_AFTER_CURS)
            to_page = Table::pretty_prompt("Go to page: ", "Ratelimit: #{rate_limit} | Page #{to_page}/#{page_count}", table_width).to_i
            if to_page.between?(1, page_count)
                STDOUT.print(Table::DOWN_N_LINES_BEGINNING(1))
                STDOUT.print(Table::UP_N_LINES(1))
                @table.update_render((to_page - 1) * @per_page, @per_page)
                table_width = @table.total_width
            else
                STDOUT.print(Table::DOWN_N_LINES_BEGINNING(1))
                STDOUT.print(Table::UP_N_LINES(1))
            end
        end
    end
end


module Sorter
    class ForkSorter < BaseSorter
        def get_data(data)
            super(data)
            headers = ["Link", "Owner", "Name", "Stars", "Open issues", "Fork count", "Watchers", "Size", "Last updated"]
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
    
            [headers, forks_list, master_list]
        end

        def get_query
            owner, name, first, orderBy, direction, after = get_query_variables
            return <<-GRAPHQL
            {
                repository(owner: "#{owner}", name: "#{name}") {
                    url
                    nameWithOwner
                    stargazerCount
                    openIssues:issues(states:OPEN) {
                        totalCount
                    }
                    forkCount
                    watchers { totalCount }
                    forkCount
                    diskUsage
                    updatedAt
                    forks
                    (
                        first: #{first}
                        #{after}
                        orderBy: {field: #{orderBy}, direction: #{direction}}
                    ){
                        totalCount
                        nodes{
                            url
                            nameWithOwner
                            stargazerCount
                            openIssues:issues(states:OPEN) {
                                totalCount
                            }
                            forkCount
                            watchers { totalCount }
                            diskUsage
                            updatedAt
                        }
                    }
                }
            }
            GRAPHQL
        end
    end


    class IssuesSorter < BaseSorter
        def get_data(data)
            super(data)
            headers = ["Link", "Author", "Participants", "Comment count", "Published at", "Last edit", "Updated at", "State"]
            issues = data["data"]["repository"]["issues"]["nodes"]
            issue_list = []
            color_hash = {
                "CLOSED" => [248, 81, 73],
                "OPEN" => [135, 195, 138]
            }
            issues.each do |is|
                author = is["author"]
                if author
                    author = Table::HyperLinkItem.new(is["author"]["login"], is["author"]["url"])
                else
                    author = "null"
                end
                _state = is["state"]
                issue_list << [
                    Table::HyperLinkItem.new("Link", is["url"]),
                    author,
                    is["participants"]["totalCount"].to_s,
                    is["comments"]["totalCount"].to_s,
                    Utils::humanize_time(is["publishedAt"]),
                    Utils::humanize_time(is["lastEditedAt"]),
                    Utils::humanize_time(is["updatedAt"]),
                    Table::Foreground.new(_state, *color_hash[_state])
                ]
            end
            [headers, issue_list]
        end

        def get_query
            owner, name, first, orderBy, direction, after = get_query_variables
            return <<-GRAPHQL
            {
                repository(owner:"#{owner}", name:"#{name}") {
                issues(
                    first: #{first}
                    #{after}
                    orderBy: {field: #{orderBy}, direction: #{direction}}
                ){
                    nodes {
                            url
                            author { login url }
                            participants { totalCount }
                            comments { totalCount }
                            publishedAt
                            lastEditedAt
                            updatedAt
                            state
                        }
                    }
                }
            }
            GRAPHQL
        end
    end


    class PullReqSorter < BaseSorter
        def get_data(data)
            super(data)
            headers = ["Link", "Author", "Created at", "Additions", "Deletions", "Changed files", "Comments", "State", "Updated at"]
            prs = data["data"]["repository"]["pullRequests"]["nodes"]
            pr_list = []
            color_hash = {
                "MERGED" => [163, 113, 247],
                "CLOSED" => [248, 81, 73],
                "OPEN" => [135, 195, 138]
            }
            prs.each do |pr|
                author = pr["author"]
                if author
                    author = Table::HyperLinkItem.new(pr["author"]["login"], pr["author"]["url"])
                else
                    author = "null"
                end
                _state = pr["state"]
                pr_list << [
                    Table::HyperLinkItem.new("Link", pr["url"]),
                    author,
                    Utils::humanize_time(pr["createdAt"]), pr["additions"].to_s,
                    pr["deletions"].to_s, pr["changedFiles"].to_s,
                    pr["comments"]["totalCount"].to_s,
                    Table::Foreground.new(_state, *color_hash[_state]),
                    Utils::humanize_time(pr["updatedAt"])
                ]
            end
            [headers, pr_list]
        end

        def get_query
            owner, name, first, orderBy, direction, after = get_query_variables
            return <<-GRAPHQL
            {
                repository(owner: "#{owner}", name: "#{name}") {
                    pullRequests
                    (
                        first: #{first}
                        #{after}
                        orderBy: {field: #{orderBy}, direction: #{direction}}
                    ){
                        totalCount
                        nodes{
                            url
                            author { login url }
                            createdAt
                            additions
                            deletions
                            changedFiles
                            comments { totalCount }
                            state
                            updatedAt
                        }
                    }
                }
            }
            GRAPHQL
        end
    end


    class RepositoriesSorter < BaseSorter
        def initialize(*args)
            super(*args)
            @type = get_type
        end

        def get_type
            valid_username = /^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$/i
            unless @url =~ valid_username
                puts "Invalid username"
                exit(1)
            end
            uri = URI.parse("https://api.github.com/users/#{@url}")
            return JSON.parse(Net::HTTP.get(uri))["type"].downcase
        end

        def create_table
            headings, items, master = get_data(@data, @type)
            @table = Table::TextTable.new(headings, items, master)
        end

        def get_query
            login_type = @type
            login = @url
            first = @options[:first]
            orderBy = @options[:sort]
            direction = @options[:order]
            if @options[:after]
                after = "after: #{@options[:after]}"
            else
                after = ""
            end
            return <<-GRAPHQL
            {
                #{login_type}(login:"#{login}") {
                    name
                    repositories(
                    #{after}
                    first: #{first}
                    orderBy: {field:#{orderBy} direction:#{direction}}
                    ){
                        nodes {
                            url
                            name
                            languages(
                                first: 1
                                orderBy: {field:SIZE direction:DESC}
                            ){nodes{name}}
                            stargazerCount
                            openIssues:issues(states:OPEN) {
                                totalCount
                            }
                            forkCount
                            diskUsage
                            pushedAt
                        }
                    }
                }
            }
            GRAPHQL
        end

        def get_data(data, type)
            super(data)
            headers = ["Link", "Repo Name", "Language", "Stars", "Open issues", "Fork count", "Size", "Last push"]
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
            [headers, repo_list]
        end
    end
end