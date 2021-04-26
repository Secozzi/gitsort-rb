module Env
    # Path of .env file
    ENV_PATH = "./lib/.env"

    # Checks if an entry exists for a key
    #
    # @param [String] key Key to be checked
    # @return [Boolean] Bool for whether or not it exists
    def self.key_exists(key)
        text = File.read(ENV_PATH)
        return !!(text =~ /^#{key}/)
    end

    # Returns the value for a specific key
    #
    # @param [String] key The key for whatever value is requested
    # @return [String] The value for the specific key
    def self.get_value(key)
        text = File.read(ENV_PATH)
        match = /#{key}=(?<value>[a-zA-Z0-9_]+)/.match(text)
        if match
            return match[:value]
        else
            return nil
        end
    end

    # Updates the value of an entry
    #
    # @param [String] key The key to be updated
    # @param [String] value The new value
    def self.update_key(key, value)
        text = File.read(ENV_PATH)
        updated = text.gsub(/^#{key}.*$/, "#{key}=#{value}")
        File.open(ENV_PATH, "w") {|f| f.write updated}
    end

    # Adds an entry with key and value
    #
    # @param [String] key New key
    # @param [String] value The value for the key
    def self.append_key(key, value)
        if key_exists(key)
            raise "Key '#{key}' already exists!"
        end
        text = File.read(ENV_PATH)
        if text.end_with? "\n"
            text += "#{key}=#{value}\n"
        else
            text += "\n#{key}=#{value}"
        end
        File.open(ENV_PATH, "w") {|f| f.write text}
    end
end