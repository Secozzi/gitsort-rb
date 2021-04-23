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

def issue_query(owner, name, orderBy, direction)
    <<-GRAPHQL
    { 
        repository(owner:"#{owner}", name:"#{name}") {
        issues(
            first:100
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

def pr_query(owner, name, orderBy, direction, first = 100)
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

def repo_query(login_type, login, orderBy, direction)
    <<-GRAPHQL
query {
    #{login_type}(login:"#{login}") {
        name
        repositories(
        first: 100
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