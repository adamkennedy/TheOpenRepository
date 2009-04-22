use inc::Module::Install::DSL 0.85;

all_from      lib/Test/XT.pm
test_requires Test::More           0.42
test_requires File::Spec           0.80
test_requires File::Remove         1.42
test_requires Pod::Simple          3.07
test_requires Test::Pod            1.26
test_requires Test::CPAN::Meta     0.12
test_requires Perl::MinimumVersion 1.20
test_requires Test::MinimumVersion 0.008
