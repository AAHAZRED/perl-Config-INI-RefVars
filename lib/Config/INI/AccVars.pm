package Config::INI::AccVars;

use 5.010;
use strict;
use warnings;
use Carp;

use feature ":5.10";

our $VERSION = '0.01';

our $Default_Section = "__COMMON__";
our $Common_Section  = $Default_Section;


sub new { bless {}, ref($_[0]) || $_[0] }


my $_parse_ini = sub {
  my ($self, $src) = @_;
  my $src_name;
  if (ref($src)) {
    ref($src) eq 'ARRAY' or croak("Internal error");
    $src_name = $self->{src_name};
  } else {
    $src_name = $src;
    $src = [do { local (*ARGV); @ARGV = ($src_name); <> }];
  }
  my $curr_section;
  my $sections   = $self->{sections};
  my $sections_h = $self->{sections_h};
  my $expanded   = $self->{expanded};
  for (my $i = 0; $i < @$src; ++$i) {
    my $line = $src->[$i];
    if (index($line, ";!") == 0 || index($line, "=") == 0) {
      croak("'$src_name' Directives are not yet supported");
    }
    $line =~ s/^\s+//;
    next if $line eq "" || $line =~ /^[;#]/;
    $line =~ s/\s+$//;
    # section header
    if (index($line, "[") == 0) {
      croak("Invalid section header at line ", $i + 1) if index($line, "]") < 0;
      $line =~ s/\s*[#;][^\]]*$//;
      $line =~ /^\[\s*(.*?)\s*\]$/ or croak("Invalid section header at line ", $i + 1);
      $curr_section = $1;
      croak("'$curr_section': duplicate section name at line ", $i + 1)
        if exists($sections_h->{curr_section});
      $sections_h->{$curr_section} = undef;
      push(@$sections, $curr_section);
      next;
    }
    if (index($line, "=") < 0) {
      croak("Neither section header not key definition at line ", $i + 1)
    } else {
      # var = val
      $line =~ /^(.*?)\s*([[:punct:]]*?)=(?:\s*)(.*)/ or
        croak("Neither section header not key definition at line ", $i + 1);
      my ($var_name, $modifier, $value) = ($1, $2, $3);
      delete $expanded->{$self->_x_var_name($curr_section, #########################
                                            $var_name)};       ## _expand_vars() my set this
      croak("Empty variable name at line ", $i + 1) if $var_name eq "";
      if (!defined($curr_section)) {
        $curr_section = $self->{default_section};
        $sections_h->{$curr_section} = undef;
        push(@$sections, $curr_section);
      }
      my $sect_vars = $self->{variables}{$curr_section} //= {};
      if ($modifier eq "") {
        $sect_vars->{$var_name} = $value;
      }
      elsif ($modifier eq "?") {
        $sect_vars->{$var_name} = $value if !exists($sect_vars->{$var_name});
      }
      elsif ($modifier eq "+") {
        $sect_vars->{$var_name} = ($sect_vars->{$var_name} // "") . " " . $value;
      }
      elsif ($modifier eq ".") {
        $sect_vars->{$var_name} = ($sect_vars->{$var_name} // "") . $value;
      }
      elsif ($modifier eq ":") {
        $sect_vars->{$var_name} = $self->_expand_vars($curr_section, $var_name, $value);
      }
      else {
        die("$modifier: unsupported modifier");
      }
    }
  }
  return $curr_section;
};


sub parse_ini {
  state $allowed_keys = {map {$_ => undef} qw(clone src src_name predef
                                              default_section common_section)};
  state $dflt_src_name = "INI data";  ### our???
  my $self = shift;
  %$self = (clone => "", predef => {},
            default_section => $Default_Section, common_section => $Common_Section,
            @_ );
  foreach my $key (keys(%$self)) {
    croak("$key: Unsupported argument") if !exists($allowed_keys->{$key});
  }
  delete @$self{ grep { !defined($self->{$_}) } keys(%$self) };
  foreach my $scalar_arg (qw(clone src_name default_section common_section)) {
     croak("'$scalar_arg': must not be a reference") if ref($self->{$scalar_arg});
  }
  my $clone = delete $self->{clone};
  my $src = delete($self->{src}) // croak("'src': Missing mandatory argument");#####
  if (my $ref_src = ref($src)) {
    $self->{src_name} = $dflt_src_name if !exists($self->{src_name});
    if ($ref_src eq 'ARRAY') {
      $src = [@$src] if $clone;
      for (my $i = 0; $i < @$src; ++$i) {
        croak(_fmt_err($self->{src_name}, $i + 1, "Unexpected ref type.")) if ref($src->[$i]);
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
  if (exists($self->{predef})) {
    croak("'predef': must be a HASH ref") if ref($self->{predef}) ne 'HASH';
    while (my ($var, $val) = each(%{$self->{predef}})) {
      croak("'predef': unexpected ref type for variable $var") if ref($val);
    }
    $self->{predef} = {%{$self->{predef}}} if $clone;
  } else {
    $self->{predef} = {};
  }
  $self->{globals}    = {};
  $self->{sections}   = [];
  $self->{sections_h} = {};
  $self->{variables}  = {};
  $self->{expanded}  = {};
  $self->$_parse_ini($src);
  while (my ($section, $variables) = each(%{$self->{variables}})) {
    while (my ($variable, $value) = each(%$variables)) {
      $variables->{$variable} = $self->_expand_vars($section, $variable, $value);
    }
  }
  return $self;
}


sub sections        {$_[0]->{sections}}
sub sections_h      {$_[0]->{sections_h}}
sub variables       {$_[0]->{variables}}
sub src_name        {$_[0]->{src_name}}
sub predef          {$_[0]->{predef}}
sub default_section {$_[0]->{default_section}}
sub common_section  {$_[0]->{common_section}}


#
# _fmt_err(SRC, LINE_NO, MSG)
#
sub _fmt_err {
  return sprintf("%s at line %d: %s", @_);
}


sub _look_up {
  my ($self, $curr_sect, $variable) = @_;
  #state $vre = qr{^(.*?)/(.*)$};
  state $vre = qr/^\[\s*(.*?)\s*\](.+)$/;
  my ($v_section, $v_basename) = $variable =~ $vre ? ($1, $2) : ($curr_sect, $variable);
  if ($v_basename !~ /\S/) {
    return $v_basename;
  } elsif ($v_basename eq '=') {
    return $v_section;
  } else {
    my $variables = $self->{variables};
    return "" if !exists($variables->{$v_section});
    return "" if !exists($variables->{$v_section}{$v_basename});
    return $variables->{$v_section}{$v_basename};
  }
}

# extended var name
sub _x_var_name {
  my ($self, $curr_sect, $variable) = @_;
  state $vre = qr/^\[\s*(.*?)\s*\](.+)$/;
  if ($variable =~ $vre) {
    return "[$1]$2";
  }
  else {
    return "[$curr_sect]$variable";
  }
}

sub _expand_vars {
  my ($self, $curr_sect, $variable, $value, $seen) = @_;
  my $top = !$seen;
  $seen = {"[$curr_sect]$variable" => undef} if !$seen;
  my @result = ("");
  my $level = 0;
  my $expanded = $self->{expanded};
  my $x_variable_name = $self->_x_var_name($curr_sect, $variable);
  return $value if exists($expanded->{$x_variable_name});
  foreach my $token (split(/(\$\(|\))/, $value)) {
    if ($token eq '$(') {
      ++$level;
    } elsif ($token eq ')' && $level) {
      my $ref_var = $result[$level];
      my $x_varname = $self->_x_var_name($curr_sect, $ref_var);
      die("Recursive variable '" . $x_varname . "' references itself")
        if exists($seen->{$x_varname});
      $seen->{$x_varname} = undef;
      if ($ref_var eq '==') {
        $result[$level - 1] .= $variable;
      }
      else {
        $result[$level - 1] .=
          $self->_expand_vars($curr_sect, $ref_var, ###$variable,
                              $self->_look_up($curr_sect, $ref_var),
                              $seen);
      }
      pop(@result);
      --$level;
    } else {
      $result[$level] .= $token;
    }
  }
  die("unterminated variable reference") if $level;
  $value = $result[0];
  if ($top) {
    $expanded->{$x_variable_name} = undef;
  }
  return $value;
}

#
# _error_msg(FILE, LINE_NO, MSG)
#
sub _error_msg {
  return sprintf("", @_)
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

Sections without any vars do not appear in 'variables' hash.

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
