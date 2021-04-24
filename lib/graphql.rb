class GraphQL
    def initialize(query, token)
        @query = query
        @token = token
        @rate_limit = nil
    end

    def get_data
        uri = URI.parse("https://api.github.com/graphql")

        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
    
        req = Net::HTTP::Post.new(uri.path)
        req["Authorization"] = "Bearer #{@token}"
        req.body = {"query" => @query}.to_json
    
        res = https.request(req)
        json = JSON.parse(res.body)
        @rate_limit = res["X-RateLimit-Remaining"]
        return json
    end

    def get_rate_limit
        @rate_limit
    end
end

def fork_query(owner, name, orderBy, direction, first = 30)
    <<-GRAPHQL
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

def issue_query(owner, name, orderBy, direction, first = 30)
    <<-GRAPHQL
    { 
        repository(owner:"#{owner}", name:"#{name}") {
        issues(
            first: #{first}
            orderBy: {field: #{orderBy}, direction: #{direction}}
        ){
            nodes {
                permalink
                author { login url }
                participants {totalCount}
                comments {totalCount}
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

def pr_query(owner, name, orderBy, direction, first = 30)
    <<-GRAPHQL
    {
        repository(owner: "#{owner}", name: "#{name}") {
            pullRequests
            (
                first: #{first}
                orderBy: {field: #{orderBy}, direction: #{direction}}
            ){
                totalCount
                nodes{
                    permalink
                    author { login url }
                    createdAt
                    additions
                    deletions
                    changedFiles
                    comments { totalCount } 
                    updatedAt
                }
            }
        }
    }
    GRAPHQL
end

def repo_query(login_type, login, orderBy, direction, first = 30)
    <<-GRAPHQL
    {
        #{login_type}(login:"#{login}") {
            name
            repositories(
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