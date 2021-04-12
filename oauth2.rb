=begin
require "octokit"

# token = a522d6e2f5d630849cd1634921e9919aaef8c81c
client = Octokit::Client.new(:access_token => 'a522d6e2f5d630849cd1634921e9919aaef8c81c')
client.repos.each do |i|
    p i["full_name"]
end
=end

require "dotenv"
Dotenv.load

def get_token
    if ENV["GIT_SORTER_TOKEN"]
        ENV["GIT_SORTER_TOKEN"]
    end

    puts "To access a private repository, an access token is required. Please set it"
    Dotenv.send(gets.chomp.to_s)
end

puts get_token