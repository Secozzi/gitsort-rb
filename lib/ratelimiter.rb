require_relative "lib/env"


class RateLimiter
    def initialize
        unless key_exists("LAST_UPDATE")
            append_key("LAST_UPDATE", Time.now.to_i)
        end
        unless key_exists("RATE_LIMIT")
            append_key("RATE_LIMIT", 5000)
        end
    end

    private
    def refresh_limit
        now = Time.now.to_i
        last_refresh = get_value("LAST_UPDATE").to_i
        if now - last_refresh >= 3600
            update_key("LAST_UPDATE", now)
            update_key("RATE_LIMIT", 5000)
        end
    end

    public
    def get_limit
        refresh_limit
        return get_value("RATE_LIMIT")
    end

    def add_limit(amount)
        refresh_limit
        rl = get_value("RATE_LIMIT").to_i
        update_key("RATE_LIMIT", rl - amount)
    end
end