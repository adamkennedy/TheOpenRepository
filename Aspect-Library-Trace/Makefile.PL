use inc::Module::Install::DSL 0.83;

all_from      lib/Aspect/Library/Trace.pm
requires      Aspect     0.14
test_requires Test::More 0.42
test_requires IPC::Run3  0.042
