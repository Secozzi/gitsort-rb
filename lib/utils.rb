module Utils
    def self.humanize_time(time_str)
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