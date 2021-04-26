Gitsort
=======
Sorter for Github repositories, forks, issues, and pull requests.

Installation
------------
Clone the repository with `git clone https://github.com/Secozzi/gitsort.git`

Usage
-----
cd into folder, or add it to path, then run `gitsort.rb`

Usage:
```
Usage: opt.rb URL_OR_REPO_PATH [options] COMMAND [command_options]
    -p, --per-page [INTEGER]         Show number of items per page. Defaults to 10
    -o, --order-direction [STRING]   Direction of ordering, either DESC or ASC. Defaults to DESC
    -f, --first [INTEGER]            Select n number of items from list.
                                     If a query fails, it could be the result of a timeout.
                                     To solve this, decrease the number of items with this argument.
    -a, --after [STRING]             Returns the elements in the list that come after the specified cursor.
                                     Defaults to not using this argument in the query.

Available commands:
    set-token     | token | t - Save Github personal access token
    forks         | fork  | f - Sort forks of a repository
    issues        | issue | i - Sort issues of a repository
    pull_requests | pr    | p - Sort pull requests of a repository
    repositories  | repos | r - Sort repositories of an user or organization

See 'gitsort.rb COMMAND --help' for more information on a specific command.
```

How to use each command:

### token
```
gitsort.rb token YOUR_ACCESS_TOKEN
```

### forks
```
gitsort.rb URL_OR_REPO_PATH [options] fork [SORT_METHOD]
    -s, --sort [STRING]              Sort repos by method. Sort methods:
                                     1. name    | n - Sort by name
                                     2. pushed  | p - Sort by push time
                                     3. updated | u - Sort by update time
                                     4. created | c - Sort by creation time
                                     5. stars   | star | s - Sort by star count
                                     Defaults to star count.
```

### issues
```
gitsort.rb URL_OR_REPO_PATH [options] issues [SORT_METHOD]
    -s, --sort [STRING]              Sort repos by method. Sort methods:
                                     1. comment | c - Sort by comment count
                                     2. created | C - Sort by creation time
                                     3. updated | u - Sort by update time
                                     Defaults to updated
```

### pr
```
gitsort.rb URL_OR_REPO_PATH [options] pr [SORT_METHOD]
    -s, --sort [STRING]              Sort repos by method. Sort methods:
                                     1. comment | c - Sort by comment count
                                     2. created | C - Sort by creation time
                                     3. updated | u - Sort by update time
                                     Defaults to updated
```

### repos
```
gitsort.rb URL_OR_REPO_PATH [options] repos [SORT_METHOD]
    -s, --sort [STRING]              Sort repos by method. Sort methods:
                                     1. name    | n - Sort by name
                                     2. pushed  | p - Sort by push time
                                     3. updated | u - Sort by update time
                                     4. created | c - Sort by creation time
                                     5. stars   | star | s - Sort by star count
                                     Defaults to star count.
```