use inc::Module::Install::DSL 1.04;

all_from      lib/AI/RandomForest.pm
requires_from lib/AI/RandomForest/Tree.pm
requires_from lib/AI/RandomForest/Branch.pm
test_requires Test::More 0.42
test_requires File::Spec 0.80
