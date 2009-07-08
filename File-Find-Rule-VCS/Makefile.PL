use inc::Module::Install::DSL 0.91;

all_from      lib/File/Find/Rule/VCS.pm
requires_from lib/File/Find/Rule/VCS.pm
test_requires File::Spec 0.82
test_requires Test::More 0.47
