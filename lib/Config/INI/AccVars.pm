package Config::INI::AccVars;

use 5.010;
use strict;
use warnings;
use Carp;

use feature ":5.10";

our $VERSION = '0.01';

sub new {
  state $allowed_keys = {map {$_ => undef} qw(clone sec src_name)};
  state $dflt_src_name = "INI data";
  my $class = shift;
  my $self = { clone => "", @_ };
  delete $self->{src_name} if (exists($self->{src_name}) && !defined($self->{src_name}));
  foreach my $key (keys(%$self)) {
    croak("$key: Unsupported argument") if !exists($allowed_keys->{$key});
  }
  my $src = delete($self->{src}) // croak("'src': Missing mandatory argument");#####
  ref($self->{clone}) and croak("'clone': arg must not be a reference");
  if (my $ref_src = ref($src)) {
    $self->{src_name} = $dflt_src_name if !exists($self->{src_name});
    if ($ref_src eq 'ARRAY') {
      $src = [@$src] if $self->{clone};
      for (my $i = 0; $i < @$i; ++$i) {
        ref($src->[$i]) and croak(_fmt_err($self->{src_name}, $i + 1, "Unexpected data."));
        $src->[$i] //= "";
      }
    } else {
      croak("$ref_src: ref type not allowed for argument 'src'");
    }
  } else {
    if (index($src, "\n") < 0) {
      my $file = $src;
      $src = [do { local (*ARGV); @ARGV = ($file); <> }];
      $self->{src_name} = $file if !exists($self->{src_name});
    } else {
      $src = [split(/\n/, $src)];
      $self->{src_name} = $dflt_src_name if !exists($self->{src_name});
    }
  }
  $self->{sections} = [];
  $self->{variables} = {};
  bless($self, $class);

  return $self;
}

#
# _fmt_err(SRC, LINE_NO, MSG)
#
sub _fmt_err {
  return sprintf("%s at line %d: %s", @_);
}


sub _parse_ini {
  my ($self, $ini_src) = @_;
  if (ref($ini_src)) {
    ref($ini_src) eq 'ARRAY' or croak("Internal error");
  } else {
    $ini_src = [do { local (*ARGV); @ARGV = ($ini_src); <> }];
  }
    # ...= @{{@_}}{qw(src, clone)};
  # my $src_name = "INI data";
  # if (my $ref_src = ref($src)) {
  #   if ($ref_src eq 'ARRAY') {
  #     $src = [@$src] if $clone;
  #   } else {
  #     croak("$ref_src: ref type not allowed for argument 'src'");
  #   }
  # } else {
  #   if (index($src, "\n") < 0) {
  #     $src_name = $src;
  #     $src = [do { local (*ARGV); @ARGV = ($src_name); <> }];
  #   } else {
  #     $src = [split(/\n/, $str)];
  #   }
  # }


}

#
# _error_msg(FILE, LINE_NO, MSG)
#
sub _error_msg {
  return sprintf("", @_)
}

sub _process_INI_data {
  my ($src, $src_name) = @_;
  for (my $i = 0; $i < @$src; ++$i) {
    my $line = $src->[$i];
    $line =~ s/^\s+//;
    next if $line eq "";
    if (index($line, ";!") == 0 || index($line, "=") == 0) {
      croak("'$src_name' Directives are not yet supported");
    }
    if ($line =~ /^[;#]/) {
      $line = "";
      next;
    }
    $line =~ s/\s+$//;
    if (index($line, "[") == 0) {
      index($line, "]") > 0 or croak("Invalid section header at line " . $i + 1);
      $line =~ s/\]\s*[;#][^]]$//;
      next;
    }
    if (my $eq_idx = index($line, "=") < 0) {
      croak("Neither section header not key definition at line " . $i + 1)
    } else {
      1; ##############
    }
  }
}

1; # End of Config::INI::AccVars



__END__


=pod


=head1 NAME

Config::INI::AccVars - The great new Config::INI::AccVars!

=head1 VERSION

Version 0.01



=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Config::INI::AccVars;

    my $foo = Config::INI::AccVars->new();
    ...


=head1 DESCRIPTION

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1



=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>



=head1 BUGS

Please report any bugs or feature requests to C<bug-config-ini-accvars at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-INI-AccVars>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::INI::AccVars


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-INI-AccVars>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Config-INI-AccVars>

=item * Search CPAN

L<https://metacpan.org/release/Config-INI-AccVars>

=item * GitHub Repository

  XXXXXXXXX

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
