use inc::Module::Install::DSL 0.85;

all_from      lib/DBIx/Publish.pm
requires_from lib/DBIx/Publish.pm
test_requires Test::More   0.42
test_requires File::Spec   0.80
test_requires File::Remove 1.42
