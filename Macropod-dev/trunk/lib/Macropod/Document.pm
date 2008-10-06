package Macropod::Document;

use strict;
use warnings;

use Carp qw( confess );
use PPI;
use YAML ();
use PPI::Dumper;
use Data::Dumper;
use Pod::Simple::Search;

use base qw( Class::Accessor );
__PACKAGE__->mk_accessors(
	qw( 
		title
		source
		pod 
		macros 
		
		packages 
		
		includes
		inherits
		requires 
		
	)
);



=pod

=head1 NAME

Macropod::Document

=head1 DESCRIPTION

Represent a perl/pod source's macro document

=head1 SYNOPSIS

   $newdoc 		= Macropod::Document->create( 	name=>'Test::More' );
   $fromfile 	= Macropod::Document->open( 	'./lib/MyModule.pm' );
   $fromdata 	= Macropod::Document->open( 	\$buffer );
   $fromstream 	= Macropod::Document->open(		 $handle )
   
   @depends_on = $doc->depends;
   @required   = $doc->requires;
   @inherits   = $doc->inherits;
   
=head1 ACCESSORS

=head2 depends


=head2 requires


=head2 inherits


=head2 exports


=head2 methods


=head2 inherited_methods


=head1 METHODS


=head2 create

Create a new empty document.

=head2 open

Open an existing document

=head2 save

Save the current document

=head2 serialize 

Serialize the current document into YAML




=cut

sub new {
	confess "Constructors are 'create' and 'open' ";
}

sub create {
	my ($class,%args) = @_;
	my %self;
	
	$self{_created} = 1;
	return bless %self, ref $class || $class;

}

sub open {
	my ($class,%args) = @_;
	
}

sub signature {

}
1;
