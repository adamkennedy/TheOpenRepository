use inc::Module::Install::DSL 0.83;

all_from      lib/JSAN/Client2.pm
requires      ORLite          1.20
requires      ORLite::Migrate 0.02
test_requires Test::More      0.47
test_requires File::Remove    1.40
