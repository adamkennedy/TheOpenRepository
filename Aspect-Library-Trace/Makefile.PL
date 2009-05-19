use inc::Module::Install::DSL 0.88;

all_from      lib/Aspect/Library/Trace.pm
requires_from lib/Aspect/Library/Trace.pm
test_requires Test::More 0.42
test_requires IPC::Run3  0.042
