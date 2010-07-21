use inc::Module::Install::DSL 1.00;

all_from      lib/Aspect/Library/Timer.pm
requires_from lib/Aspect/Library/Timer.pm
requires      Params::Util 1.00
test_requires Test::More   0.47
