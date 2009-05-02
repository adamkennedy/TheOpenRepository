use inc::Module::Install::DSL 0.86;

all_from      lib/Alien/Win32/LZMA.pm
requires_from lib/Alien/Win32/LZMA.pm
test_requires Test::More   0.42
test_requires File::Remove 1.42
install_share
