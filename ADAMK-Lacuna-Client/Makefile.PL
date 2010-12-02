use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'ADAMK::Lacuna::Client',
    VERSION_FROM => 'lib/ADAMK/Lacuna/Client.pm',
    PREREQ_PM    => {
        'JSON::RPC::Common' => '0',
        'HTTP::Request'     => '0',
        'HTTP::Response'    => '0',
        'LWP::UserAgent'    => '0',
        'Data::Dumper'      => '0',
        'Class::XSAccessor' => '1.07',
        'Scalar::Util'      => '0',
        'URI'               => '0',
        'Class::MOP'        => '0',
        'YAML::Any'         => '0',
        'AnyEvent'          => '0',
    },
    (
        $] >= 5.005
        ? # Add these new keywords supported since 5.005
            (
                # Retrieve abstract from module
                ABSTRACT_FROM => 'lib/ADAMK/Lacuna/Client.pm',
                AUTHOR        => 'Steffen Mueller <smueller@cpan.org>'
            )
        : ()
    ),
);
