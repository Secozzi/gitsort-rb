module Utils
    # Humanizes time. Input is time and it returns 
    # 'number `time_unit`(s) ago' where time unit is the nearest
    # time unit, such as second, minute, or week
    #
    # @param [String] time_str A string of time of the format %Y-%m-%dT%H:%M:%SZ
    # @return [String] Returns 'number `time_unit`(s) ago'
    def self.humanize_time(time_str)
        unless time_str
            return "null"
        end
        time = Time.now.to_i - DateTime.strptime(time_str, "%Y-%m-%dT%H:%M:%SZ").to_time.to_i
        times = [
            1, 60, 3600, 86400, 604800, 2629746, 31556925
        ]
        strings = [
            "Second", "Minute", "Hour", "Day", "Week", "Month", "Year"
        ]
        tmp = []
        times.each { |t| tmp << time / t}
        tmp.reverse.each_with_index do |t, i|
            if t != 0
                return "#{t} #{strings[6-i]}#{"s"*(t==1 ? 0 : 1)} ago"
            end
        end
    end
    
    # Format the number of bytes into KiloByte, MegaByte etc
    #
    # @param [Integer] num The number of bytes
    # @return [String] Formatted size
    def self.to_filesize(num)
        {
            'B'  => 1024 ** 1,
            'KB' => 1024 ** 2,
            'MB' => 1024 ** 3,
            'GB' => 1024 ** 4,
            'TB' => 1024 ** 5
        }.each_pair do |e, s|
            return "#{(num.to_f / (s / 1024)).round(2)} #{e}" if num < s 
        end
    end
end
