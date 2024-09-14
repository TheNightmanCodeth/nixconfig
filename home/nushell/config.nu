let carapace_completer = {|spans|
carapace $spans.0 nushell $spans | from json
}
$env.config = {
  show_banner: false,
  completions: {
    case_sensitive: false
	quick: true # set to false to prevent aauto-selecting completions
	partial: true # set to false to prevent partial filling of the prompt
	algorithm: "fuzzy" # prefix or fuzzy
	external: {
	# set to false to prevent nushell looking into $env.PATH to find more suggestions
	  enable: true
	# set to lower can improve completion performance at the cost of omitting some options
	  max_results: 100
	  completer: $carapace_completer
	}
  }
}
$env.PATH = ($env.PATH |
split row (char esep) |
append /usr/bin/env
)
