package Archive::Builder::Generators;

# This package contains a set of default generators 
# for the most common cases.

use strict;
use Params::Util '_INSTANCE',
                 '_SCALAR0',
                 '_HASH0';
use Archive::Builder ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.13';
}





#####################################################################
# Trvial Generators

# Recieves as an argument the exact string the file should contain
sub string {
	my $File   = _INSTANCE(shift, 'Archive::Builder::File' ) or return undef;
	my $string = shift;
	return _SCALAR0($string) ? $string
		: ref $string ? undef
		: defined $string ? \$string
		: undef;
};

# Recieves as an argument the name of a file
sub file {
	my $File     = _INSTANCE(shift, 'Archive::Builder::File') or return undef;
	my $filename = -f $_[0] ? shift : return undef;

	# Slurp in the file
	File::Flat->slurp( $filename )
		or $File->_error( "Failed to load file '$filename'" );
}

# Takes any object derived from class IO::Handle, reads it in
# and returns it. An optional second argument is the number of bytes 
# to read in at a time ( the chunk size ). Default is 8192 ( 8 kilobytes )
sub handle {
        my $File = _INSTANCE(shift, 'Archive::Builder::File') or return undef;

	# Get and check the handle
	my $handle = _INSTANCE(shift, 'IO::Handle')
		or return $File->_error( 'Was not passed an IO::Handle argument' );
	my $chunk_size = shift || (8 * 1024);

	# Read in everything
	my $contents = '';
	my ($rv, $buffer);
	while ( $rv = $handle->sysread( $buffer, $chunk_size ) ) {
		$contents .= $buffer;
	}

	defined $rv ? \$contents
		: $File->_error( 'Error while reading from handle' );
}	





#####################################################################
# Common Advanced Generators

# The template generator will only work if the Template Toolkit is installed.
# The first argument is an instantiation of a Template object.
# The second argument is the file name withing the Template object.
# The third argument is the hash reference to pass to the template.
sub template {
	my $File = _INSTANCE(shift, 'Archive::Builder::File' ) or return undef;

	# Before beginning, test to see if Template toolkit is installed
	unless ( Class::Autouse->load( 'Template' ) ) {
		return $File->_error( 'Template Toolkit is not installed, or could not be loaded' );
	}
	
	# Get and check the arguments
	my $Template = _INSTANCE(shift, 'Template' )
		or return $File->_error( 'First argument was not a Template object' );
	my $toparse = shift
		or return $File->_error( 'You did not specify something to parse' );
	my $args = (_HASH0($_[0]) || ! defined $_[0]) ? shift
		: return $File->_error( 'Invalid argument hashref for Template' );
	
	# Create a string to capture the output into.
	my $output = '';
	
	# Process the template
	$Template->process( $toparse, $args, \$output ) ? \$output
		: $File->_error( "Template Error: " . $Template->error );
}

1;

__END__

=head1 NAME

Archive::Builder::Generators - Default generators, and writing your own

=head1 SYNOPSIS

  # Our own useless generator
  sub generator {
      my $File = isa( $_[0], 'Archive::Builder::File' )
          ? shift : return undef;
      
      # Create the file contents
      my $contents = 'Something trivial';
      
      return \$contents;
  }

=head1 DESCRIPTION

This documentation outlines the default generators available to you, and how
to write generators of your own to extend L<Archive::Builder>.

=head1 DEFAULT GENERATORS

A limited set of generators for the most common situation are provided for you.

=head2 The 'string' Generator

The 'string' default generator is a simple pass-through for when you already
have the contents of the file, generated by another method. The generator
takes one argument, which can be either a scalar containing the file contents,
or a reference to a scalar containing the file contents

=head2 The 'file' Generator

The 'file' generator takes as an argument of a file name, and slurps in the
file as the contents. It should be used when the builder file already exists
on disk, and just needs to be used directly. Most commonly used for binary
files like images and such, that might need to be included, but not modified.

=head2 The 'handle' Generator

The 'handle' generator takes as argument a single object of an IO::Handle 
object. It allows you use something the can only easily be accessed
as an IO handle easily.

The generator will read from the handle until an EOF is reached and then returns
the results.

=head2 The 'template' Generator

The 'template' generator hooks in to the power of Template Toolkit. It takes
three arguments.

The first is a valid L<Template> object. You would be expected to use the same
Template object for multiple files, and can do so without ill effect. The 
generator does not modify the L<Template> object.

The second and third arguments are the path of the template file to process
and a reference to a hash containing the values to provide to the template, 
using the same values as you would for the normal C<Template> C<process>
method.

And error will be caught and passed on, and becomes available from
C<$Archive::Builder::errstr> or one of the C<errstr> methods.

=head1 WRITING GENERATORS

Writing a generator is fairly simple. It consist of a single function,
residing in a module. It takes some arguments, builds the contents of
a file in a single scalar, and then returns a reference to that scalar.

A typical function will look something like this ( you may cut and paste ).

  sub generator {
      # Get the file argument
      my $File = UNIVERSAL::isa( $_[0], 'Archive::Builder::File' )
          ? shift : return undef;
  
      # Get and check any other arguments
      my $argument = shift;
      return $File->_error( 'Bad argument' ) unless defined $argument;
      
      # Build the contents
      my $contents = "Something: $argument";
      
      # Returns the contents
      return \$contents;
  }

=head2 Arguments

The function takes as its first argument the C<Archive::Builder::File>
object it is part of. The first few lines of the function should look
Any remaining arguments are passed as recieved 
from the File object constructor. You should do your own checking on the 
validity of the arguments.

=head2 Returning the Contents

The contents of the file MUST be returned as a reference to a scalar. For
example.

  my $contents = "This\n";
  $content .= "That\n";
  return \$content;

=head2 Returning an Error

The C<Archive::Builder::File> argument we recieve gives us the ability to
set an error that can be retrieved later from the C<$Archive::Builder::errstr>
variable, or through one of the C<errstr> methods.

The method C<_error( message )> sets the error string to the value of 
C<message>, and returns a value of C<undef>. Thus, an easy way to say "Return
this error" is simply to write.

  return $File->_error( 'This is an error' );

The C<_error> method will return C<undef>, which will be returned to our 
caller, signalling an error.

=head1 USING OUR GENERATOR

To use our new generator, assuming it's in package C<Our::New>, simply pass 
its fullyt referenced name as a string.

  $Section->new_file( 'file/path', 'Our::New::generator', $argument );

If the C<Our::New> package is loaded already, the generator will be called
normally. If the C<Our::New> package is NOT loaded, C<Archive::Builder> will 
attempt to load the package C<Our::New> before calling the generator function.

=head1 TO DO

Some more interesting default generators, as needed or requested.

=head1 SUPPORT

Contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>
        
=head1 SEE ALSO

L<Archive::Builder>, L<Archive::Builder::Archive>
L<Archive::Tar>, L<Archive::Zip>.

=head1 COPYRIGHT

Copyright (c) 2002-2004 Adam Kennedy.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
