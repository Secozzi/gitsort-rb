require_relative "lib/argparser"
require_relative "lib/table"
require_relative "lib/env"
require "io/console"


class BaseSorter
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

            # Vissa av url kommer ge en path som har fler än ett element, så ta bara första elementet ur path
            name = m[:name].split("/").reject(&:empty?)[0]

            # Regexen kan inte hantera om elementet slutar på .git eller med / så ta bort dem från slutet
            [m[:owner], name].map {|item| item.gsub(/((.git)|\/)$/, "")}
        end
    end

    def display_table

    end
end

class ForkSorter < BaseSorter ; end
class IssuesSorter < BaseSorter ; end
class PullReqSorter < BaseSorter ; end
class DependentSorter < BaseSorter ; end
class DependenciesSorter < BaseSorter ; end
class RepositoriesSorter < BaseSorter ; end

options = SortParser.parse(ARGV)

case options[:command]
when "token"
    if key_exists("GITSORT_TOKEN")
        puts "Token is already set, do you want to update it? [y/n]"
        input = STDIN.getch
        if input.downcase == "y"
            update_key("GITSORT_TOKEN", options[:token])
            puts "Successfully updated token."
        elsif input.downcase == "n"
        else
            puts "Error: invalid choice."
        end
    else
        append_key("GITSORT_TOKEN", options[:token])
        puts "Successfully added token."
    end
when "forks"
    puts "SORTING FORKS"
else
    puts "UWU"
end
#puts options