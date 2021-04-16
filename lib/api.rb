require "httparty"

OWNER = "sympy"
REPO = "sympy"
PARAMS = ""

url = "https://api.github.com/repos/#{OWNER}/#{REPO}/forks#{PARAMS}"

forks = HTTParty.get(url)

forks.each do |fork|
    p fork["owner"]["login"]
end