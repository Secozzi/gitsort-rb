class GraphQL
    # Initializes the class
    #
    # @param [String] query The query to be retireved
    # @param [String] token Your personal Github access token
    def initialize(query, token)
        @query      = query
        @token      = token
        @rate_limit = nil
    end

    # Gets the response from the given query and retrieves the rate limit
    #
    # @return [JSON] the data
    def get_data
        uri = URI.parse("https://api.github.com/graphql")

        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
    
        req = Net::HTTP::Post.new(uri.path)
        req["Authorization"] = "Bearer #{@token}"
        req.body = {"query" => @query}.to_json
    
        res = https.request(req)
        json = JSON.parse(res.body)
        @rate_limit = res["X-RateLimit-Remaining"]

        return json
    end

    # Retrieve the rate limit
    #
    # @return [Integer] Rate limit
    def get_rate_limit
        @rate_limit
    end
end
