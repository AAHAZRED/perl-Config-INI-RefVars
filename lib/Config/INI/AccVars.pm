package Config::INI::AccVars;
#use Object::InsideOut;
use 5.010;
use strict;
use warnings;
use Carp;

use feature ":5.10";

our $VERSION = '0.01';

use constant DFLT_COMMON_SECTION  => "__COMMON__";

use constant FLD_KEY_PREFIX => __PACKAGE__ . ' __ ';

use constant {EXPANDED          => FLD_KEY_PREFIX . 'EXPANDED',

              COMMON_SECTION    => FLD_KEY_PREFIX . 'COMMON_SECTION',
              GLOBAL            => FLD_KEY_PREFIX . 'GLOBAL',
              SECTIONS          => FLD_KEY_PREFIX . 'SECTIONS',
              SECTIONS_H        => FLD_KEY_PREFIX . 'SECTIONS_H',
              SRC_NAME          => FLD_KEY_PREFIX . 'SRC_NAME',
              VARIABLES         => FLD_KEY_PREFIX . 'VARIABLES',
             };

our %Arg_Map = map {$_ => (FLD_KEY_PREFIX . uc($_))} qw (common_section expanded global sections
                                                         sections_h src_name variables);

# Match punctuation chars, but not the underscores.
my $Modifier_Char = '[^_[:^punct:]]';

sub new { bless {}, ref($_[0]) || $_[0] }

my $_expand_value = sub {
  return $_[0]->_expand_vars($_[1], undef, $_[2]);
};

my $_parse_ini = sub {
  my ($self, $src) = @_;
  my $src_name;
  if (ref($src)) {
    ref($src) eq 'ARRAY' or croak("Internal error");
    $src_name = $self->{+SRC_NAME};
  }
  else {
    $src_name = $src;
    $src = [do { local (*ARGV); @ARGV = ($src_name); <> }];
  }
  my $curr_section;
  my $sections    = $self->{+SECTIONS};
  my $sections_h  = $self->{+SECTIONS_H};
  my $expanded    = $self->{+EXPANDED};
  my $variables   = $self->{+VARIABLES};
  my $common_sec  = $self->{+COMMON_SECTION};
  my $common_vars = $variables->{$common_sec}; # hash key need not to exist!

  my $set_curr_section = sub {
    $curr_section = shift;
    if ($curr_section eq $common_sec) {
      die("common section '$common_sec' must be first section") if @$sections;
      $common_vars = $variables->{$common_sec} = {} if !$common_vars;
    } elsif ($common_vars) {
      %{$variables->{$curr_section}} = %{$common_vars};
    } else {
      $variables->{$curr_section} = {};
    }
    $sections_h->{$curr_section} = @$sections;#undef;       #### index!!!!!!
    push(@$sections, $curr_section);
  };

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
      $set_curr_section->($1);
      next;
    }
    if (index($line, "=") < 0) {
      croak("Neither section header not key definition at line ", $i + 1)
    }
    else {
      # var = val
      $set_curr_section->($common_sec) if !defined($curr_section);
      $line =~ /^(.*?)\s*($Modifier_Char*?)=(?:\s*)(.*)/ or
        croak("Neither section header not key definition at line ", $i + 1);
      my ($var_name, $modifier, $value) = ($1, $2, $3);
      # delete $expanded->{$self->_x_var_name($curr_section, #########################
      #                                       $var_name)};       ## _expand_vars() my set this
      my $exp_flag = exists($expanded->{$self->_x_var_name($curr_section, $var_name)});
      croak("Empty variable name at line ", $i + 1) if $var_name eq "";
      my $sect_vars = $variables->{$curr_section} //= {};
      if ($modifier eq "") {
        $sect_vars->{$var_name} = $value;
      }
      elsif ($modifier eq '?') {
        $sect_vars->{$var_name} = $value if !exists($sect_vars->{$var_name});
      }
      elsif ($modifier eq '+') {
        if (exists($sect_vars->{$var_name})) {
          $sect_vars->{$var_name} .= " "
            . ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value);
        }
        else {
          $sect_vars->{$var_name} = $value;
        }
      }
      elsif ($modifier eq '.') {
        $sect_vars->{$var_name} = ($sect_vars->{$var_name} // "")
          . ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value);
      }
      elsif ($modifier eq ':') {
        $sect_vars->{$var_name} = $self->_expand_vars($curr_section, $var_name, $value);
      }
      elsif ($modifier eq '+>') {
        if (exists($sect_vars->{$var_name})) {
          $sect_vars->{$var_name} =
            ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value)
            . ' ' . $sect_vars->{$var_name};
        }
        else {
          $sect_vars->{$var_name} = $value;
        }
      }
      elsif ($modifier eq '.>') {
        $sect_vars->{$var_name} =
          ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value)
          . ($sect_vars->{$var_name} // "");
      }
      else {
        die("$modifier: unsupported modifier");
      }
    }
  }
  return $curr_section;
};


sub parse_ini {
  state $allowed_keys = {map {$_ => undef} qw(clone src src_name global
                                              common_section common_vars)};
  state $dflt_src_name = "INI data";  ### our???
  my $self = shift;
  my %args = (clone => "", global => {},
            common_section => DFLT_COMMON_SECTION,
              @_ );
  foreach my $key (keys(%args)) {
    croak("$key: Unsupported argument") if !exists($allowed_keys->{$key});
  }
  delete @args{ grep { !defined($args{$_}) } keys(%args) };
  foreach my $scalar_arg (qw(clone src_name common_section)) {
     croak("'$scalar_arg': must not be a reference") if ref($args{$scalar_arg});
   }
  my $common_vars = delete $args{common_vars};
  my $clone       = delete $args{clone};
  my $src         = delete($args{src}) // croak("'src': Missing mandatory argument");#####
  $self->{$Arg_Map{$_}} = $args{$_} for keys(%args);

  if (my $ref_src = ref($src)) {
    $self->{+SRC_NAME} = $dflt_src_name if !exists($self->{+SRC_NAME});
    if ($ref_src eq 'ARRAY') {
      $src = [@$src] if $clone;
      for (my $i = 0; $i < @$src; ++$i) {
        croak(_fmt_err($self->{+SRC_NAME}, $i + 1, "Unexpected ref type.")) if ref($src->[$i]);
        $src->[$i] //= "";
      }
    }
    else {
      croak("$ref_src: ref type not allowed for argument 'src'");
    }
  }
  else {
    if (index($src, "\n") < 0) {
      my $file = $src;
      $src = [do { local (*ARGV); @ARGV = ($file); <> }];
      $self->{+SRC_NAME} = $file if !exists($self->{+SRC_NAME});
    }
    else {
      $src = [split(/\n/, $src)];
      $self->{+SRC_NAME} = $dflt_src_name if !exists($self->{+SRC_NAME});
    }
  }
  if (exists($self->{+GLOBAL})) {
    croak("'global': must be a HASH ref") if ref($self->{+GLOBAL}) ne 'HASH';
    while (my ($var, $val) = each(%{$self->{+GLOBAL}})) {
      croak("'global': unexpected ref type for variable $var") if ref($val);
    }
    $self->{+GLOBAL} = {%{$self->{+GLOBAL}}} if $clone;
  }
  else {
    $self->{+GLOBAL} = {};
  }
  $self->{+SECTIONS}   = [];
  $self->{+SECTIONS_H} = {};
  $self->{+VARIABLES}  = {};
  $self->{+EXPANDED}  = {};
  if ($common_vars) {
    croak("'common_vars': expected HASH ref") if ref($common_vars) ne 'HASH';
    ### CLONE !!!
##    my $variables = $self->{+VARIABLES}
    while (my ($var, $value) = each(%$common_vars)) {
      croak("'common_vars': value of '$var' is a ref, expected scalar") if ref($value);
      if (!defined($value)) {
        carp("'common_vars': removing '$var' since its value is undef");
        delete $common_vars->{$var};
      }
      croak("'common_vars': variable '$var': value '$value' is not permitted")
        if ($value =~ /^(?:=|;[^;])/ || $value =~ /^(?:\s*|[#;$])$/);
    }
    %{$self->{+VARIABLES}{$self->{+COMMON_SECTION}}} = %$common_vars;
  }

  $self->$_parse_ini($src);

  while (my ($section, $variables) = each(%{$self->{+VARIABLES}})) {
    while (my ($variable, $value) = each(%$variables)) {
      $variables->{$variable} = $self->_expand_vars($section, $variable, $value);
    }
  }
  return $self;
}


sub sections        {$_[0]->{+SECTIONS}}
sub sections_h      {$_[0]->{+SECTIONS_H}}
sub variables       {$_[0]->{+VARIABLES}}
sub src_name        {$_[0]->{+SRC_NAME}}
sub global          {$_[0]->{+GLOBAL}}
sub common_section  {$_[0]->{+COMMON_SECTION}}


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
  my $matched = $variable =~ $vre;
  my ($v_section, $v_basename) = $matched ? ($1, $2) : ($curr_sect, $variable);
  if ($v_basename !~ /\S/) {
    return $v_basename;
  }
  elsif ($v_basename eq '=') {
    return $v_section;
  }
  my $variables = $self->{+VARIABLES};
  if ($matched) {
    return "" if !exists($variables->{$v_section});
    return "" if !exists($variables->{$v_section}{$v_basename});
    return $variables->{$v_section}{$v_basename};
  } else {
    die("Internal error") if !exists($variables->{$v_section});
    if (exists($variables->{$v_section}{$v_basename})) {
      return $variables->{$v_section}{$v_basename};
    } else {
      return $self->{+GLOBAL}{$v_basename} // "";
    }
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
    croak("???? ", (caller)[2]) unless defined $curr_sect;
    return "[$curr_sect]$variable";
  }
}

sub _expand_vars {
  my ($self, $curr_sect, $variable, $value, $seen) = @_;
  my $top = !$seen;
  my @result = ("");
  my $level = 0;
  my $expanded = $self->{+EXPANDED};
  my $x_variable_name;
  if (defined($variable)) {
    $x_variable_name = $self->_x_var_name($curr_sect, $variable);
    return $value if exists($expanded->{$x_variable_name});
    die("Recursive variable '", $x_variable_name, "' references itself")
      if exists($seen->{$x_variable_name});
    $seen->{$x_variable_name} = undef;
  }
  foreach my $token (split(/(\$\(|\))/, $value)) {
    if ($token eq '$(') {
      ++$level;
    }
    elsif ($token eq ')' && $level) {
      my $ref_var = $result[$level];
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
    }
    else {
      $result[$level] .= $token;
    }
  }
  die("unterminated variable reference") if $level;
  $value = $result[0];
  if ($x_variable_name) {
    $expanded->{$x_variable_name} = undef if $top;
    delete $seen->{$x_variable_name};
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

https://stackoverflow.com/questions/11581893/prepend-to-simply-expanded-variable

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
