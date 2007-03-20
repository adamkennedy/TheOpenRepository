package Object::Tiny;

use strict;

use vars qw{$VERSION};
BEGIN {
	require 5.004;
	$VERSION = '1.00';
}





#####################################################################
# Class Generator

sub import {
	return unless shift eq 'Object::Tiny';
	my $pkg = caller;
	eval join '',
		"package $pkg;\n\@${pkg}::ISA = 'Object::Tiny';\n",
		map {
			defined and ! ref and /^[^\W\d]\w*$/s
			or die "Invalid accessor name '$_'";
			"sub $_ {\n\t\$_[0]->{$_};\n}\n"
		} @_;
	die "Failed to generate $pkg" if $@;
	return 1;
}





#####################################################################
# Default Constructor

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

1;

__END__

=pod

=head1 NAME

Object::Tiny - Class building as simple as it gets

=head1 SYNOPSIS

  # Define a class
  package Foo;
  
  use Object::Tiny qw{ bar baz };
  
  1;
   
  
  # Use the class
  my $object = Foo->new( bar => 1 );
  
  print "bar is " . $object->bar . "\n";

=head1 DESCRIPTION

There's a whole bunch of class builders out there. In fact, creating
a class builder seems to be something of a right of passage (this is
my fifth, at least).

Unfortunately, most of the time I want a class builder I'm in a
hurry and sketching out lots of fairly simple data classes with fairly
simple structure, mostly just read-only accessors, and that's about it.

Often this is for code that won't end up on CPAN, so adding a small
dependency doesn't matter much. I just want to be able to define these
classes FAST.

By which I mean LESS typing than writing them by hand, not more. And
I don't need all those weird complex features that bloat out the code
and take over the whole way I build modules.

And so, I present yet another member of the Tiny family of modules,
Object::Tiny.

The goal here is really just to save me some typing. There's others
that could do the job just fine, but I want something that does as little
as possible and creates code the same way I'd have written it by hand
anyway.

To use Object::Tiny, just call it with a list of accessors to be created.

  use Object::Tiny 'foo', 'bar';

For a large list, I lay it out like this...

  use Object::Tiny qw{
      item_font_face
      item_font_color
      item_font_size
      item_text_content
      item_display_time
      seperator_font_face
      seperator_font_color
      seperator_font_size
      seperator_text_content
      };

This will create a bunch of simple accessors, and set the inheritance to
be the child of Object::Tiny.

Object::Tiny is empty other than a basic C<new> constructor which
does the following

  sub new {
      my $class = shift;
      return bless { @_ }, $class;
  }

In fact, if doing the following in your class gets annoying...

  sub new {
      my $class = shift;
      my $self  = $class->SUPER::new( @_ );
  
      # Extra checking and such
      ...
  
      return $self;
  }

... then feel free to ditch the SUPER call and just create the hash
yourself! It's not going to make a lick of different and there's nothing
magic going on under the covers you might break.

And that's really all there is to it. Let a million simple data classes
bloom. Features? We don't need no stinking features.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Simple>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Config::Tiny>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
