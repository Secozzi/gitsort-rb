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