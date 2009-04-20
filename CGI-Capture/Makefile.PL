use inc::Module::Install::DSL 0.83;

all_from       lib/CGI/Capture.pm
requires       Storable     2.11
requires       YAML::Tiny   1.21
test_requires  File::Spec   0.80
test_requires  Test::More   0.47
test_requires  Test::Script 1.02
install_script cgicapture
