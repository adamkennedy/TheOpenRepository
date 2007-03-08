use strict;
use inc::Module::Install;

name           'PITA-POE-SupportServer';
all_from       'lib/PITA/POE/SupportServer.pm';
requires       'Carp'                                  => 0;
requires       'MIME::Types'                           => '1.15';
requires       'URI'                                   => '1.35';
requires       'Params::Util'                          => '0.22';
requires       'Process'                               => '0.18';
requires       'MIME::Types'                           => 0;
requires       'POE'                                   => '0.38';
requires       'POE::Component::Server::SimpleHTTP'    => '1.19';
requires       'POE::Component::Server::SimpleContent' => '1.05';
build_requires 'Test::More'                            => '0.47';
build_requires 'IO::Socket::INET'                      => 0;
build_requires 'HTTP::Request'                         => 0;
build_requires 'LWP::UserAgent'                        => '2.033';

WriteAll;
