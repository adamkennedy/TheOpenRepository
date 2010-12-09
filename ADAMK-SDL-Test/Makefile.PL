use inc::Module::Install::DSL 1.00;

all_from       lib/ADAMK/SDL/Test.pm
requires_from  lib/ADAMK/SDL/Test.pm
test_requires  Test::More 0.80
install_script sdl1
