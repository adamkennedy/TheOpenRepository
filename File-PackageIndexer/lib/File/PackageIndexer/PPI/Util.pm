package File::PackageIndexer::PPI::Util;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

# try to regenerate a hash or array struct from
# a PPI::Structure::Constructor (anon hash/array constr.)
sub constructor_to_structure {
  my $token = shift;
  
  return() unless $token->isa("PPI::Structure::Constructor");

  my $start = $token->start;
  return() unless $start->isa("PPI::Token::Structure");
  if ($start->content eq '{') {
    return _hash_constructor_to_structure($token);
  }
  elsif ($start->content eq '[') {
    return _array_constructor_to_structure($token);
  }
  return();
}

sub list_structure_to_hash {
  my $token = shift;
  
  return() unless $token->isa("PPI::Structure::List");

  return _hash_constructor_to_structure($token);
  return();
}

sub list_structure_to_array {
  my $token = shift;
  
  return() unless $token->isa("PPI::Structure::List");

  return _array_constructor_to_structure($token);
  return();
}

sub _hash_constructor_to_structure {
  my $hash = shift;

  my $struct = {};
  
  my $state = 'key';
  my $key;

  my @children = $hash->schildren();
  while (@children) {
    my $token = shift @children;
    if ($token->isa("PPI::Statement")) {
      unshift @children, $token->schildren();
      next;
    }

    # special case: qw()
    if ( ($state eq 'key' or $state eq 'value')
         and $token->isa("PPI::Token::QuoteLike::Words") )
    {
      my @values = qw_to_list($token);

      # emulate the state flip flop to end up in a consistent state afterwards
      foreach my $v (@values) {
        if ($state eq 'key') {
          $key = $v;
          $state = 'value';
        }
        else {
          $struct->{$key} = $v;
          $key = undef;
          $state = 'key';
        }
      }
      $state = 'comma';
      next;
    } # end special case 'qw'

    if ($state eq 'key') {
      my $keyname = get_keyname($token);
      return() if not defined $keyname;
      $key = $keyname;
      $state = 'comma';
    }
    elsif ($state eq 'comma') {
      return() unless $token->isa("PPI::Token::Operator");
      return() unless $token->content =~ /^(?:,|=>)$/; # are there other valid comma-likes?
      $state = defined($key) ? 'value' : 'key';
    }
    elsif ($state eq 'value') {
      my $value = token_to_string($token);
      return() unless defined $value;
      $struct->{$key} = $value;
      $key = undef;
      $state = 'comma';
    }
    else {
      die "Sanity check: Unknown state!";
    }
  }

  return($struct);
}

sub _array_constructor_to_structure {
  my $array = shift;

  my $struct = [];
  
  my $state = 'elem';

  my @children = $array->schildren();
  while (@children) {
    my $token = shift @children;
    if ($token->isa("PPI::Statement")) {
      unshift @children, $token->schildren();
      next;
    }

    if ($state eq 'elem') {
      if ($token->isa("PPI::Token::QuoteLike::Words")) {
        my @values = qw_to_list($token);
        push @{$struct}, @values;
      }
      else {
        my $value = token_to_string($token);
        return() unless defined $value;
        push @{$struct}, $value;
      }
      $state = 'comma';
    }
    elsif ($state eq 'comma') {
      return() unless $token->isa("PPI::Token::Operator");
      return() unless $token->content =~ /^(?:,|=>)$/; # are there other valid comma-likes?
      $state = 'elem';
    }
    else {
      die "Sanity check: Unknown state!";
    }
  }

  return($struct);
}

# best guess at turning a qw() into a real list
sub qw_to_list {
  my $token = shift;
  return() if not $token->isa("PPI::Token::QuoteLike::Words");

  # FIXME This breaks PPI encapsulation, but there seems to be no API!
  my $string = substr($token->content, $token->{sections}[0]{position}, $token->{sections}[0]{size});
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return split /\s+/, $string;
}

# best guess at turning a token into the string it represents
sub token_to_string {
  my $token = shift;
  if ($token->isa("PPI::Token::Quote")) {
    return($token->can('literal') ? $token->literal : $token->string);
  }
  elsif ($token->isa("PPI::Token::HereDoc")) {
    return join '', $token->heredoc;
  }
  else {
    return $token->content;
  }
}

# Given a PPI token, try to interpret it as a quoted "key" or word (re fat comma)
sub get_keyname {
  my $token = shift;
  return() unless $token->isa("PPI::Token");
  return $token->content if $token->isa("PPI::Token::Word"); # likely followed by a =>
  return $token->string if $token->isa("PPI::Token::Quote");
  return(); # TODO: what else makes sense here?
}

sub is_class_method_call {
  my $token = shift;
  if ($token->isa("PPI::Token::Word")) {
    return is_method_call($token);
  }
  return();
}

sub is_instance_method_call {
  my $token = shift;
  if ($token->isa("PPI::Token::Symbol")) {
    return is_method_call($token);
  }
  return();
}

sub is_method_call {
  my $token = shift;
  return() unless $token->isa("PPI::Token::Word") or $token->isa("PPI::Token::Symbol");

  my $next = $token->snext_sibling();
  return()
    unless $next
       and $token->content =~ /^[\w:]+$/
       and $next->isa("PPI::Token::Operator")
       and $next->content eq '->';

  my $third = $next->snext_sibling();
  return()
    unless defined $third;

  if ( $third->isa("PPI::Token::Word") or $third->isa("PPI::Token::Symbol") ) {
    return($token->content(), $third->content());
  }
  return();
}


1;

__END__

=head1 NAME

File::PackageIndexer::PPI::Util - PPI-related utility functions

=head1 DESCRIPTION

No user-serviceable parts inside.

=head1 SEE ALSO

L<File::PackageIndexer>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
