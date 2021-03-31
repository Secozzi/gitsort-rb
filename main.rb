class ForkSorter
    def initialize(url, sort_method, per_page)
        @url = url
        @sort_method = sort_method
        @per_page = per_page
    end

    # Returnerar en lista med [ägare, repo_namn] från olika typer av Github urls och vissa icke-urls.
    def get_url_info
        # Test om det är en länk eller [/]owner/repo[...]
        if (/^(git(hub)?|https?)/ =~ @url).nil?
            # Testa om bara en sträng och inte path
            raise "Invliad repo, must be of form [/]owner/repo[...]" if url.count("/") == 0
            @url.split("/").reject(&:empty?)[0..1]
        else
            # En fin regex för att få ut <owner> och <repo_name> från en länk
            m = /^(https|git)?(:\/\/|@)?([^\/:]+)[\/:](?<owner>[^\/:]+)\/(?<name>.+)(.git)?$/.match(@url)
            raise "Invalid URL" if m.nil?

            # Vissa av url kommer ge en path som är längre än ett, så ta bara första elementet ur path
            name = m[:name].split("/").reject(&:empty?)[0]

            # Regexen kan inte hantera om elementet slutar på .git eller med / så ta bort dem från slutet
            [m[:owner], name].map {|item| item.gsub(/((.git)|\/)$/, "")}
        end
    end
end

