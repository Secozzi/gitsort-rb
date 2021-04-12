require "json"
require "awesome_print"
require "octokit"

client = Octokit::Client.new(:access_token => 'a522d6e2f5d630849cd1634921e9919aaef8c81c')
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