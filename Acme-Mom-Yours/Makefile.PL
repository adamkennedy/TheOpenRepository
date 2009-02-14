use inc::Module::Install 0.79;

all_from 'lib/Acme/Mom/Yours.pm';
requires 'MojoMojo'                 => 0;
requires 'Task::Catalyst::Tutorial' => 0;
requires 'Task-Email-PEP-All'       => 0;
requires 'Parley'                   => 0;
requires 'Foorum'                   => 0;
requires 'Angerwhale'               => 0;
requires 'CommitBit'                => 0;
requires 'Jifty'                    => 0;
requires 'Reaction'                 => 0;
requires 'Buscador'                 => 0;
requires 'Task::CatInABox'          => 0;
requires 'App::CamelPKI'            => 0;
requires 'Task::SOSA'               => 0;
requires 'App::HistHub'             => 0;
requires 'Test::Apocalypse'         => 0;
requires 'Devel::ebug::HTTP'        => 0;
requires 'Padre'                    => 0;
requires 'Pod::Browser'             => 0;
requires 'Titanium'                 => 0;
requires 'Handle'                   => 0;

WriteAll;
