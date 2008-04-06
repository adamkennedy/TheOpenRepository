package AutoXS::Setter;

use 5.008;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.03';

BEGIN { require AutoXS; }
use base 'AutoXS';

use B;
use B::Utils qw( opgrep op_or );
use Class::XSAccessor;

CHECK {
  warn "Running AutoXS scanner of " . __PACKAGE__ if $AutoXS::Debug;
  foreach (keys %{$AutoXS::ScanClasses{"".__PACKAGE__}}) {
    __PACKAGE__->replace_setters(
      __PACKAGE__->scan_package_callback($_, \&scan_setter)
    );
  }
}

sub hash_ref_access {
  my $hashref_struct = shift;
  my $capname = shift||'hash_key';
  my $struct = {
    'name' => 'helem', 'flags' => 182,
    'kids' => [
      {
        'name' => 'rv2hv', 'flags' => 22,
        first => $hashref_struct,
      },
      { 'name' => 'const', 'flags' => 2, capture => $capname },
    ],
  };
  return $struct;
}

sub scalar_assign {
  my $source = shift;

  return op_or(
    { name => 'sassign',
      kids => [
        { name => 'null', 'flags' => 6,
          first => {
            'name' => 'null', 'flags' => 22,
            first => { 'flags' => 2, 'name' => 'aelemfast' },
          },
        },
        $source,
      ]
    },
    { name => 'sassign',
      kids => [
        {
          'name' => 'shift', 'flags' => 6,
          first => { name => 'rv2av',
                     first => { 'name' => 'gv', 'flags' => 2, }
                   }
        },
        $source,
      ]
    },
    { name => 'sassign',
      kids => [
        {
          'flags' => 2,
          'name' => 'padsv'
        },
        $source,
      ]
    },

  );
}

sub or_return_nothing {
  my @stuff = @_;
  my $nextstate = {name => 'nextstate'};
  my $struct = op_or(
    { name => 'lineseq',
      'kids' => [
        $nextstate,
        @stuff,
      ]
    },
    { name => 'lineseq',
      'kids' => [
        $nextstate,
        @stuff,
        $nextstate,
        {
          'name' => 'return', 'flags' => 4,
          'kids' => [
                      { name => 'pushmark', 'flags' => 2, },
                      op_or(
                        { name => 'stub', 'flags' => 8, },
                        { name => 'undef', 'flags' => 10, },
                      ),
                    ]
        }
      ]
    },
  );
#use Data::Dumper;  die Dumper($struct);
  return $struct;
}

sub scan_setter {
  my $selfclass = shift;
  my $fullfuncname = shift;
  my $codeobj = shift;

  my $r = $codeobj->ROOT;
  
  my $nextstate = {'name' => 'nextstate' };
  my $array_ref_access =
    {
      'name' => 'aelem', 'flags' => 38,
      'kids' => [
        {
          'name' => 'rv2av', 'flags' => 22,
          first => { 'name' => 'gv', 'flags' => 2 },
        },
        { 'name' => 'const', 'flags' => 2, },
      ]
    };

  my $hash_array_ref_access = hash_ref_access($array_ref_access, 'hash_key');

  my $simple_scalar_assign_from_array = scalar_assign( $hash_array_ref_access );

  my $simple_structure = or_return_nothing($simple_scalar_assign_from_array);

  my $array_assign_two = {
    'name' => 'aassign',
    'kids' => [
      {
        'name' => 'null', 'flags' => 7,
        first => { 'name' => 'pushmark', 'flags' => 2, },
      },
      {
        'name' => 'null',
        first => { 'name' => 'pushmark', },
      }
    ]
  };

  my $array_assign_full_named = or_return_nothing(
    $array_assign_two, $nextstate,
    scalar_assign(
      hash_ref_access(
        { name => 'padsv', 'flags' => 34, },
        'hash_key',
      )
    )
  );

  my $array_assign_simple = or_return_nothing($array_assign_two);

#  use Data::Dumper;
#  warn Dumper $array_assign_full_named;
  my ($matching) = opgrep( {
      capture => 'main',
      name => 'leavesub',
      first => op_or(
        $simple_structure,
        #$array_assign_full_named,
        #$array_assign_simple,
      ),
    }, $r
  );

  if ($matching) {
    warn $fullfuncname;
    die ref($matching) if not ref($matching) eq 'HASH';
    require Data::Dumper;
    die "Could not extract hash key. Sub was: $fullfuncname. Dump:\n" . Data::Dumper::Dumper($r->as_opgrep_pattern()) if not exists $matching->{hash_key};
    my $key_string = $matching->{hash_key}->sv->PV;
    return [$fullfuncname, $key_string];
  }
  else {
    return();
  }
}

sub replace_setters {
  my $selfclass = shift;
  my @to_be_replaced = @_;

  foreach my $struct (@to_be_replaced) {
    my $function = $struct->[0];
    my $key = $struct->[1];
    if ($AutoXS::Debug) {
      warn "Replacing $function with XS accessor for key '$key'.\n";
    }
    Class::XSAccessor->import(
      replace => 1,
      setters => { $function => $key },
    );
  }
}

1;
__END__

=head1 NAME

AutoXS::Setter - Identify setters and replace them with XS

=head1 SYNOPSIS
  
  package MyClass;
  use AutoXS plugins => 'Setter';
  
  # or load all installed optimizing plugins
  use AutoXS ':all';
  
  sub new {...}
  sub get_foo { $_[0]->{foo} }
  sub other_stuff {...}
  
  # get_foo will be auto-replaced with XS and faster

=head1 DESCRIPTION

This is an example plugin module for the L<AutoXS> module. It searches
the user package (C<MyClass> above) for write-only accessor methods of certain forms
and replaces them with faster XS code.

=head1 RECOGNIZED ACCESSORS

Note that whitespace, a trailing semicolon, and the method names don't matter.
Also please realize that this is B<not a source filter>.

  sub set_a { $_[0]->{a} = $_[1] }
  sub set_b { $_[0]->{b} = shift }
  sub set_c { ($_[0]->{c}) = shift }
  sub set_d { ($_[0]->{d}) = @_ }
  sub set_e {
    my ($self, $val) = @_;
    $self->{e}= $val;
  }
  sub set_f {
    my $self = shift;
    my $val = shift;
    $self->{f} = $val;
  }
  sub set_g {
    my $self = $_[0];
    my $val = $_[1];
    $self->{g} = $val;
  }
  sub set_h {
    my $self = shift;
    $self->{h} = shift;
  }
  sub set_i {
    my $self = shift;
    $self->{i} = $_[0]
  }
  sub set_j {
    my $self = $_[0];
    $self->{j} = $_[1]
  }
  sub set_k {
    my $self = shift;
    ($self->{k}) = @_;
  }
  sub set_l { $_[0]->{l} = $_[1]; return() }
  sub set_m { $_[0]->{m} = $_[1]; return(undef) }
 
=head1 SEE ALSO

L<AutoXS>
L<AutoXS::Accessor>
L<AutoXS::Getter>

L<Class::XSAccessor>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

