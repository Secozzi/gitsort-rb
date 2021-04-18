def fork_query(owner, name, orderBy, direction, first = 100)
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

def issue_query
    <<-GRAPHQL
    {

    }
    GRAPHQL
end

def pr_query
    <<-GRAPHQL
    {
        
    }
    GRAPHQL
end

def repo_query
    <<-GRAPHQL
    {
        
    }
    GRAPHQL
end