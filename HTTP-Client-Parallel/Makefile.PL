use inc::Module::Install;

all_from 'lib/HTTP/Client/Parallel.pm';
requires 'Exporter'                     => 0;
requires 'IO::File'                     => 0;
requires 'Scalar::Util'                 => 0;
requires 'File::Spec'                   => '0.80';
requires 'HTTP::Request'                => 0;
requires 'POE'                          => '1.000';
requires 'POE::Component::Client::HTTP' => 0;

WriteAll;
