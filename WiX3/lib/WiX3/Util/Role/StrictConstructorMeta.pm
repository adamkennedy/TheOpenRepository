package                                # Hide from PAUSE.
  WiX3::Util::Role::StrictConstructorMeta;

# Corresponds to MooseX::StrictConstructor::Role::Meta::Method::Constructor

use 5.008001;
use strict;
use warnings;
use B qw();
use Moose::Role;
use WiX3::Exceptions;

our $VERSION = '0.010';
$VERSION =~ s/_//ms;

around '_generate_BUILDALL' => sub {
	my $orig = shift;
	my $self = shift;

	my $source = $self->$orig();
	$source .= ";\n" if $source;

	my @attrs = (
		'__INSTANCE__ => 1,',
		map    { B::perlstring($_) . ' => 1,' }
		  grep {defined}
		  map  { $_->init_arg() } @{ $self->_attributes() } );

	$source .= <<"EOF";
my \%attrs = (@attrs);

my \@bad = sort grep { ! \$attrs{\$_} }  keys \%{ \$params };

if (\@bad) {
		WiX3::Exception::Parameter->throw(
"Found unknown attribute(s) passed to the constructor: \@bad"
		);
}
EOF

	return $source;
};

no Moose::Role;

1;
