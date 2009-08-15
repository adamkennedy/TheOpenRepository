use inc::Module::Install::DSL 0.91;

all_from       lib/CPANDB.pm
requires       Getopt::Long       2.33
requires       Time::HiRes        1.97
requires       Params::Util       1.00
requires       ORLite             1.25
requires       ORLite::Mirror     1.15
requires       ORLite::Statistics 0.01
test_requires  Test::More         0.42
test_requires  LWP::Online        1.07
install_script cpangraph
