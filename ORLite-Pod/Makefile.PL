use inc::Module::Install::DSL 0.95;

all_from       lib/ORLite/Pod.pm
requires       File::Spec          3.2701
requires       File::Path          2.07
requires       File::Basename      0
requires       Getopt::Long        0
requires       Params::Util        1.00
requires       Class::Inspector    1.23
requires       ORLite              1.23
requires       Template            2.20
requires       SQL::Beautify       0.03
test_requires  Test::More          0.47
test_requires  Test::Script        1.03
test_requires  Test::XT            0.02
test_requires  Test::Pod           1.42
test_requires  Test::Pod::Coverage 1.08
test_requires  File::Remove        1.42
test_requires  File::pushd         1.00
test_requires  autodie             2.10
install_script orlite2pod
