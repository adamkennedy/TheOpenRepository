use inc::Module::Install::DSL 0.91;

all_from       lib/Perl/Shell.pm
requires       Params::Util         1.00
requires       Term::ReadLine       0
requires       PPI                  1.205
requires       Lexical::Persistence 1.01
build_requires Test::More           0.42
build_requires Test::Script         1.07
install_script perlthon
