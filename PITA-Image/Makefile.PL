use inc::Module::Install::DSL 1.00;

all_from      lib/PITA/Image.pm
requires      Carp         0
requires      File::Spec   0.80
requires      File::Temp   0
requires      File::Which  0.05
requires      File::Remove 0.34
requires      Params::Util 0.10
requires      Process      0.16
requires      Config::Tiny 2.00
requires      PITA::XML    0.43
requires      PITA::Scheme 0.43
requires      URI          0
requires      LWP          5.69
test_requires Test::More   0.47
