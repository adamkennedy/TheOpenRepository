# use strict;
# $^W = 1; # Can't use "use warnings", see perl_version below.
use inc::Module::Build::Functions;

module_name         'Module::Build::Functions';
license             'perl';
perl_version        '5.005';
dist_author         'Curtis Jewell <csjewell@cpan.org>';
dist_version_from   'lib/Module/Build/Functions.pm';
autosplit           'lib/Module/Build/Functions.pm';
requires 		    'File::Slurp';
test_requires       'Test::More';
test_requires       'Test::Compile';
add_to_cleanup      'Module-Build-Functions-*';
create_makefile_pl  'passthrough';
create_readme       1;
create_license      1;
functions_self_bundler;
create_build_script;