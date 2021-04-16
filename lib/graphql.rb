require "json"
require "awesome_print"
require "octokit"

client = Octokit::Client.new()
query = <<-GRAPHQL
{
    repository(owner: "prompt-toolkit", name: "ptpython") {
        name
        forkCount
        forks
        (
            first: 12
            orderBy: {field: PUSHED_AT, direction: DESC}
        ){
            totalCount
            nodes{
                nameWithOwner
            }
        }
    }
}
GRAPHQL

response = client.post "/graphql", {query: query}.to_json
ap response