require 'net/https'
require "uri"
require 'json'

query = <<-GRAPHQL
{
    repository(owner: "prompt-toolkit", name: "ptpython") {
        name
        forkCount
        forks
        (
            first: 4
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

uri = URI.parse("https://api.github.com/graphql")

https = Net::HTTP.new(uri.host,uri.port)
https.use_ssl = true

req = Net::HTTP::Post.new(uri.path)
req["Authorization"] = "Bearer <Token>"
req.body = {"query" => query}.to_json

res = https.request(req)
json = JSON.parse(res.body)
puts json