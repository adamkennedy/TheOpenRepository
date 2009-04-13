use inc::Module::Install::DSL 0.82;

all_from      lib/JSAN/Client.pm
requires      ORLite          1.20
requires      ORLite::Migrate 0.02
test_requires Test::More      0.47
test_requires File::Remove    1.40
