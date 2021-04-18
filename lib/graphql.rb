def fork_query(owner, name, orderBy, direction, first = 100)
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

def issue_query
    <<-GRAPHQL
    {

    }
    GRAPHQL
end

def pr_query(owner, name, orderBy, direction, first = 100)
    <<-GRAPHQL
    {
        repository(owner: #{owner}, name: #{name}) {
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
                    updatedAt
                }
            }
        }
    }
    GRAPHQL
end

def repo_query(login_type, login)
    <<-GRAPHQL
    {
        #{login_type}(login:"#{login}") {
            name
            repositories(
            first: 10
            orderBy: {field:STARGAZERS direction:DESC}
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
                    updatedAt
                }
            }
        }
    }
    GRAPHQL
end