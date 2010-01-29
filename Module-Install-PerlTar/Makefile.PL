use inc::Module::Install::DSL 0.92;

all_from       lib/Module/Install/PerlTar.pm
requires       Archive::Tar       1.34
requires       IO::Compress::Gzip 2.005
requires       Module::Install    0.92
test_requires  Test::More         0.42
use_ptar
