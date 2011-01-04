use inc::Module::Install::DSL 1.00;

all_from      lib/Class/Autouse.pm
requires_from lib/Class/Autouse.pm
requires      File::Spec 0.80
requires      List::Util 1.19
test_requires Test::More 0.47
test_requires File::Temp 0.17
