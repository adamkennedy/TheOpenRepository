use inc::Module::Install::DSL 1.00;

all_from      lib/POE/Declare.pm
requires      Scalar::Util        1.19
requires      List::Util          1.19
requires      Params::Util        1.00
requires      IO::File            1.14
requires      Class::Inspector    1.22
requires      Class::ISA          0.33
requires      Class::XSAccessor   1.05
requires      POE                 1.293
test_requires Test::More          0.80
test_requires Test::Exception     0.27
test_requires Test::NoWarnings    0.084
test_requires Test::POE::Stopping 1.05
