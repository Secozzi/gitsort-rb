require "httparty"
require_relative "table"

def get_info(fork)
    [
        HyperLinkItem.new("Link", fork["html_url"]),
        fork["owner"]["login"].to_s,
        fork["name"].to_s,
        fork["stargazers_count"].to_s,
        fork["open_issues_count"].to_s,
        fork["forks_count"].to_s,
        fork["watchers_count"].to_s,
        fork["size"].to_s,
        fork["pushed_at"].to_s
    ]
end

OWNER = "sympy"
REPO = "sympy"
PARAMS = "?sort=stargazers"

url = "https://api.github.com/repos/#{OWNER}/#{REPO}/forks#{PARAMS}"
master_url = "https://api.github.com/repos/#{OWNER}/#{REPO}"

forks = HTTParty.get(url)
master = HTTParty.get(master_url)

table = Table.new(
    ["Link", "Owner", "Name", "Stars", "Open issues", "Fork count", "Watchers", "Size", "Last push"],
    get_info(master)
)

forks.each do |fork|
    table << get_info(fork)
end

table.render

# link = ["html_url"]
# Owner = ["owner"]["login"]
# Name = ["name"]
# Branch = ["default_branch"]
# Stars = ["stargazers_count"]
# Forks = ["forks_count"]
# Watchers = ["watchers_count"]
# Size = ["size"]
# Pushed at ["pushed_at"]