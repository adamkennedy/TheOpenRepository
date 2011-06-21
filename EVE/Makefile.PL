use inc::Module::Install::DSL 1.01;

author        Adam Kennedy
license       proprietary
all_from      lib/EVE.pm
requires_from lib/EVE/Game.pm
requires_from lib/EVE/DB.pm
requires_from lib/EVE/Plan.pm
requires_from lib/EVE/Trade.pm
requires_from lib/EVE/MarketLogs.pm
test_requires Test::More 0.47
install_share
