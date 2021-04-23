module Env
    ENV_PATH = "./lib/.env"

    def self.key_exists(key)
        text = File.read(ENV_PATH)
        return !!(text =~ /^#{key}/)
    end


    def self.get_value(key)
        text = File.read(ENV_PATH)
        match = /#{key}=(?<value>[a-zA-Z0-9_]+)/.match(text)
        if match
            return match[:value]
        else
            return nil
        end
    end


    def self.update_key(key, value)
        text = File.read(ENV_PATH)
        updated = text.gsub(/^#{key}.*$/, "#{key}=#{value}")
        File.open(ENV_PATH, "w") {|f| f.write updated}
    end


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