use inc::Module::Install::DSL 1.00;

all_from      lib/PITA/POE/SupportServer.pm
requires_from lib/PITA/SupportServer.pm
requires      POE::Declare               0.51
requires      POE::Declare::HTTP::Server 0.03
test_requires Test::More                 0.47
test_requires Test::POE::Stopping        1.07
