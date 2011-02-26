use inc::Module::Install::DSL 1.00;

all_from      lib/PITA/POE/SupportServer.pm
requires      MIME::Types                1.15
requires      URI                        1.35
requires      Params::Util               1.00
requires      Process                    0.28
requires      MIME::Types                1.29
requires      POE::Declare               0.51
requires      POE::Declare::HTTP::Server 0.03
test_requires Test::More                 0.47
test_requires IO::Socket::INET           0
test_requires HTTP::Request              0
test_requires LWP::UserAgent             2.033
