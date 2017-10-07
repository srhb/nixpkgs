#!/nix/store/flb9ar1xdd13c606aa4my9miy3iv4vyk-bash-4.4-p12/bin/sh

source lib-cache.sh;

print_meta_yaml () {
	module_name="$1";
	module_basename="${module_name//::/-}";

	./grab-url.sh "$(./retrieve-file-link.sh "$module_basename" "META.yml")" \
		"${module_basename}.meta.yml";
};

module_name="$1";
module_basename="${module_name//::/-}";

cached_output print_meta_yaml "$module_basename" "$module_name" meta.yaml;
