use inc::Module::Install::DSL 1.01;

author		jeffery@astraaustralis.com.au
all_from	lib/Net/Zoho.pm
requires_from   lib/Net/Zoho/CRM.pm
requires	LWP::UserAgent   6.02
requires	Carp             1.11
requires	Text::Autoformat 1.66
