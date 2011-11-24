package CPAN::WWW::Top100::Dancer;

use Dancer ':syntax';

our $VERSION = '0.01';

get '/' => sub {
    template 'index';
};

true;
