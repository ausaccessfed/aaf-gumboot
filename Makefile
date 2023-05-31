publish-gem:
	gem build aaf-gumboot.gemspec
	gem push aaf-gumboot-*.gem
	rm aaf-gumboot-*.gem