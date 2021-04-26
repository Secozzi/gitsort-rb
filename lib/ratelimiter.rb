require_relative "env"


# Creates a ratelimiter that keeps track of the rate limit by
# setting values in the .env file
class RateLimiter
    # Create entries needed if the do not exist
    def initialize
        unless Env.key_exists("LAST_UPDATE")
            Env.append_key("LAST_UPDATE", Time.now.to_i)
        end
        unless Env.key_exists("RATE_LIMIT")
            Env.append_key("RATE_LIMIT", 5000)
        end
    end

    # If an hour has gone past since the last query, refresh the
    # rate limit back to 5000
    private def refresh_limit
        now = Time.now.to_i
        last_refresh = Env.get_value("LAST_UPDATE").to_i
        if now - last_refresh >= 3600
            Env.update_key("LAST_UPDATE", now)
            Env.update_key("RATE_LIMIT", 5000)
        end
    end

    # Returns the rate limit
    #
    # @return [Integer] The rate limit
    public def get_limit
        refresh_limit
        return Env.get_value("RATE_LIMIT")
    end

    # Adds to the rate limit (Decreases the number)
    #
    # @param [Integer] amount The amount to be added
    def add_limit(amount)
        refresh_limit
        rl = Env.get_value("RATE_LIMIT").to_i
        Env.update_key("RATE_LIMIT", rl - amount)
    end
end
