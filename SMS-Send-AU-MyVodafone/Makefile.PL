use inc::Module::Install::DSL 1.04;

all_from      lib/SMS/Send/AU/MyVodafone.pm
requires_from lib/SMS/Send/AU/MyVodafone.pm
requires      IO::Socket::SSL => 0.97
requires      LWP             => 5.69
test_requires Test::More      => 0.47
