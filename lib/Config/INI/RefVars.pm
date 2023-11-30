package Config::INI::RefVars;
#use Object::InsideOut;
use 5.010;
use strict;
use warnings;
use Carp;

use feature ":5.10";

use File::Spec::Functions qw(catdir rel2abs splitpath);

our $VERSION = '0.01';

use constant DFLT_COMMON_SECTION  => "__COMMON__";

use constant FLD_KEY_PREFIX => __PACKAGE__ . ' __ ';

use constant {EXPANDED          => FLD_KEY_PREFIX . 'EXPANDED',

              COMMON_SECTION    => FLD_KEY_PREFIX . 'COMMON_SECTION',
              COMMON_VARS       => FLD_KEY_PREFIX . 'COMMON_VARS',
              NOT_COMMON        => FLD_KEY_PREFIX . 'NOT_COMMON',
              SECTIONS          => FLD_KEY_PREFIX . 'SECTIONS',
              SECTIONS_H        => FLD_KEY_PREFIX . 'SECTIONS_H',
              SRC_NAME          => FLD_KEY_PREFIX . 'SRC_NAME',
              VARIABLES         => FLD_KEY_PREFIX . 'VARIABLES',
              GLOBAL_VARS       => FLD_KEY_PREFIX . 'GLOBAL_VARS',
              VREF_RE           => FLD_KEY_PREFIX . 'VREF_RE',
              BACKUP            => FLD_KEY_PREFIX . 'BACKUP',
             };

my %Globals = ('=:' => catdir("", ""));


# Match punctuation chars, but not the underscores.
my $Modifier_Char = '[^_[:^punct:]]';

my $_check_common_vars = sub {
  my ($self, $common_vars, $set) = @_;
  croak("'common_vars': expected HASH ref") if ref($common_vars) ne 'HASH';
  $common_vars = { %$common_vars };
  while (my ($var, $value) = each(%$common_vars)) {
    croak("'common_vars': value of '$var' is a ref, expected scalar") if ref($value);
    if (!defined($value)) {
      carp("'common_vars': removing '$var' since its value is undef");
      delete $common_vars->{$var};
    }
    croak("'common_vars': variable '$var': name is not permitted")
      if ($var =~ /^\s*$/ || $var =~ /^[[=;]/);
  }
  #  @{$self->{+COMMON_VARS}}{keys(%$common_vars)} = values(%$common_vars) if $set;
  $self->{+COMMON_VARS} = {%$common_vars} if $set;
  return $common_vars;
};


my $_check_not_common = sub {
  my ($self, $not_common, $set) = @_;
  my $ref = ref($not_common);
  if ($ref eq 'ARRAY') {
    foreach my $v (@$not_common) {
      croak("'not_common': undefined value in array") if !defined($v);
      croak("'not_common': unexpected ref value in array") if ref($v);
    }
    $not_common = {map {$_ => undef} @$not_common};
  }
  elsif ($ref eq 'HASH') {
    $not_common = %{$not_common};
  }
  else {
    croak("'not_common': unexpected ref type");
  }
  $self->{+NOT_COMMON}= $not_common if $set;
  return $not_common;
};



sub new {
  my ($class, %args) = @_;
  state $allowed_keys = {map {$_ => undef} qw(common_section common_vars not_common
                                              separator)};
  _check_args(\%args, $allowed_keys);
  my $self = {};
  if (exists($args{separator})) {
    my $sep = $args{separator};
    croak("separator: invalid value") if $sep !~ /^[\/:'#~%!=]+$/;
    $self->{+VREF_RE} = qr/^(.*?)(?:\Q$sep\E)(.*)$/;
  }
  else {
    $self->{+VREF_RE} = qr/^\[\s*(.*?)\s*\](.*)$/;
  }
  $self->{+COMMON_SECTION} = $args{common_section} // DFLT_COMMON_SECTION;
  $self->$_check_common_vars($args{common_vars}, 1) if exists($args{common_vars});
  $self->$_check_not_common($args{not_common},   1) if exists($args{not_common});
  return bless($self, $class) ;
}


my $_expand_value = sub {
  return $_[0]->_expand_vars($_[1], undef, $_[2]);
};

#
# We assume that this is called when the target section is still empty and if
# common vars exist.
#
my $_cp_common_vars = sub {
  my ($self, $to_sect_name) = @_;
  my $comm_sec   = $self->{+VARIABLES}{$self->{+COMMON_SECTION}} // die("no common vars");
  my $not_common = $self->{+NOT_COMMON};
  my $to_sec     = $self->{+VARIABLES}{$to_sect_name} //= {};
  my $expanded   = $self->{+EXPANDED};
  foreach my $comm_var (keys(%$comm_sec)) {
    next if exists($not_common->{$comm_var});
    $to_sec->{$comm_var} = $comm_sec->{$comm_var};
    my $comm_x_var_name = "[$comm_sec]$comm_var";   # see _x_var_name()
    $expanded->{"[$to_sect_name]$comm_var"} = undef if exists($expanded->{$comm_x_var_name});
  }
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
    }
    elsif ($common_vars) {
      $self->$_cp_common_vars($curr_section);
    }
    else {
      $variables->{$curr_section} = {};
    }
    $sections_h->{$curr_section} = @$sections; # Index!
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
      my $x_var_name = $self->_x_var_name($curr_section, $var_name);
      my $exp_flag = exists($expanded->{$x_var_name});
      croak("Empty variable name at line ", $i + 1) if $var_name eq "";
      my $sect_vars = $variables->{$curr_section} //= {};
      if ($modifier eq "") {
        delete $expanded->{$x_var_name} if $exp_flag;
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
        delete $expanded->{$x_var_name} if $exp_flag; # Needed to make _expand_vars corectly!
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
  my $self = shift;
  my %args = (cleanup => 1,
              @_ );
  state $allowed_keys = {map {$_ => undef} qw(cleanup src src_name
                                              common_section common_vars not_common)};
  state $dflt_src_name = "INI data";
  _check_args(\%args, $allowed_keys);
  foreach my $scalar_arg (qw(src_name common_section)) {
     croak("'$scalar_arg': must not be a reference") if ref($args{$scalar_arg});
   }
  $self->{+SRC_NAME} = $args{src_name} if exists($args{src_name});
  my (      $cleanup, $src, $common_section, $common_vars, $not_common) =
    @args{qw(cleanup   src   common_section   common_vars   not_common)};

  croak("'src': missing mandatory argument") if !defined($src);
  my $backup = $self->{+BACKUP} //= {};
  if (defined($common_section)) {
    $backup->{common_section} = $self->{+COMMON_SECTION};
    $self->{+COMMON_SECTION}  = $common_section;
  }
  else {
    $common_section = $self->{+COMMON_SECTION};
  }
  if ($common_vars) {
    $backup->{common_vars} = $self->{+COMMON_VARS};
    $self->$_check_common_vars($common_vars, 1);
  }
  if ($not_common) {
    $backup->{not_common} = $self->{+NOT_COMMON};
    $self->$_check_not_common($not_common, 1)
  }
  $self->{+SECTIONS}   = [];
  $self->{+SECTIONS_H} = {};
  $self->{+EXPANDED}   = {};
  $self->{+VARIABLES}  =
    {$common_section => ($self->{+COMMON_VARS} ? {%{$self->{+COMMON_VARS}}} : {})};

  my $global_vars = $self->{+GLOBAL_VARS} = {%Globals};
  my $common_sec_vars = $self->{+VARIABLES}{$common_section};
  if (my $ref_src = ref($src)) {
    $self->{+SRC_NAME} = $dflt_src_name if !exists($self->{+SRC_NAME});
    if ($ref_src eq 'ARRAY') {
      $src = [@$src];
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
      my $path = $src;
      $src = [do { local (*ARGV); @ARGV = ($path); <> }];
      $self->{+SRC_NAME} = $path if !exists($self->{+SRC_NAME});
      my ($vol, $dirs, $file) = splitpath(rel2abs($path));
      @{$global_vars}{'=INIfile', '=INIdir'} = ($file, catdir(length($vol // "") ? $vol : (),
                                                              $dirs));
    }
    else {
      $src = [split(/\n/, $src)];
      $self->{+SRC_NAME} = $dflt_src_name if !exists($self->{+SRC_NAME});
    }
  }
  $global_vars->{'=INIname'} = $self->{+SRC_NAME};

  $self->$_parse_ini($src);

  while (my ($section, $variables) = each(%{$self->{+VARIABLES}})) {
    while (my ($variable, $value) = each(%$variables)) {
      $variables->{$variable} = $self->_expand_vars($section, $variable, $value);
    }
  }
  if ($cleanup) {
    while (my ($section, $variables) = each(%{$self->{+VARIABLES}})) {
      foreach my $var (keys(%$variables)) {
        delete $variables->{$var} if index($var, '=') >= 0;
      }
    }
    delete $self->{+VARIABLES}{$self->{+COMMON_SECTION}} if !%$common_sec_vars;
  }
  else {
    while (my ($section, $variables) = each(%{$self->{+VARIABLES}})) {
      $variables->{'='} = $section;
      @{$variables}{keys(%$global_vars)} = values(%$global_vars);
    }
  }
  $self->{+COMMON_SECTION} = $backup->{common_section} if exists($backup->{common_section});
  $self->{+COMMON_VARS}    = $backup->{common_vars}    if exists($backup->{common_vars});
  $self->{+NOT_COMMON}     = $backup->{not_common}     if exists($backup->{not_common});
  $backup = {};
  return $self;
}


sub sections        { defined($_[0]->{+SECTIONS})   ? [@{$_[0]->{+SECTIONS}}]     : undef}

sub sections_h      { defined($_[0]->{+SECTIONS_H}) ? { %{$_[0]->{+SECTIONS_H}} } : undef }

sub variables       { my $vars = $_[0]->{+VARIABLES} // return undef;
                      return  {map {$_ => {%{$vars->{$_}}}} keys(%$vars)};
                    }

sub src_name        {$_[0]->{+SRC_NAME}}
sub common_section  {$_[0]->{+COMMON_SECTION}}


#
# _fmt_err(SRC, LINE_NO, MSG)
#
sub _fmt_err {
  return sprintf("%s at line %d: %s", @_);
}


sub _look_up {
  my ($self, $curr_sect, $variable) = @_;
  my $matched = $variable =~ $self->{+VREF_RE};
  my ($v_section, $v_basename) = $matched ? ($1, $2) : ($curr_sect, $variable);
  my $v_value;
  my $variables = $self->{+VARIABLES};
  if (!exists($variables->{$v_section})) {
    $v_value = "";
  } elsif ($v_basename !~ /\S/) {
    $v_value = $v_basename;
  }
  elsif ($v_basename eq '=') {
    $v_value = $v_section;
  }
  elsif ($v_basename =~ /^=(?:ENV|env):\s*(.*)$/) {
    $v_value = $ENV{$1} // "";
  }
  elsif (exists($self->{+GLOBAL_VARS}{$v_basename})) {
    $v_value = $self->{+GLOBAL_VARS}{$v_basename};
  }
  else {
    if (exists($variables->{$v_section}{$v_basename})) {
      $v_value = $variables->{$v_section}{$v_basename};
    } else {
      $v_value = "";
    }
  }
  die("Internal error") if !defined($v_value);
  return wantarray ? ($v_section, $v_basename, $v_value) : $v_value;
}

# extended var name
sub _x_var_name {
  my ($self, $curr_sect, $variable) = @_;

  if ($variable =~ $self->{+VREF_RE}) {
    return ($2, "[$1]$2");
  }
  else {
    return ($variable, "[$curr_sect]$variable");
  }
}


sub _expand_vars {
  my ($self, $curr_sect, $variable, $value, $seen) = @_;
  my $top = !$seen;
  my @result = ("");
  my $level = 0;
  my $x_variable_name;
  if (defined($variable)) {
    ((my $var_basename), $x_variable_name) = $self->_x_var_name($curr_sect, $variable);
    return $self->_look_up($curr_sect, $variable) if (exists($self->{+EXPANDED}{$x_variable_name})
                                                      || $var_basename =~ /^=ENV:/);
    die("Recursive variable '", $x_variable_name, "' references itself")
      if exists($seen->{$x_variable_name});
    $seen->{$x_variable_name} = undef;
  }
  foreach my $token (split(/(\$\(|\))/, $value)) {
    if ($token eq '$(') {
      ++$level;
    }
    elsif ($token eq ')' && $level) {
      # Now $result[$level] contains the name of a referenced variable.
      if ($result[$level] eq '==') {
        $result[$level - 1] .= $variable;
      }
      else {
        $result[$level - 1] .=
          $self->_expand_vars($self->_look_up($curr_sect, $result[$level]), $seen);
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
    $self->{+EXPANDED}{$x_variable_name} = undef if $top;
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


sub _check_args {
  my ($args, $allowed_args) = @_;
  foreach my $key (keys(%$args)) {
    croak("$key: Unsupported argument") if !exists($allowed_args->{$key});
  }
  delete @{$args}{ grep { !defined($args->{$_}) } keys(%$args) };
}


1; # End of Config::INI::RefVars



__END__


=pod


=head1 NAME

Config::INI::RefVars - The great new Config::INI::RefVars!

=head1 VERSION

Version 0.01



=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Config::INI::RefVars;

    my $foo = Config::INI::RefVars->new();
    ...


=head1 DESCRIPTION

Sections without any vars do not appear in 'variables' hash.

https://stackoverflow.com/questions/11581893/prepend-to-simply-expanded-variable

Do not write something like

   while (my ($sec, $val) = each(%{$ini_obj->variables})) {
   # ...

since this will result in an infinite loop. Instead, write:

   my $vars = $ini_obj->variables;
   while (my ($sec, $val) = each(%$vars)) {
   # ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1



=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>



=head1 BUGS

Please report any bugs or feature requests to C<bug-config-ini-accvars at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-INI-RefVars>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::INI::RefVars


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-INI-RefVars>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Config-INI-RefVars>

=item * Search CPAN

L<https://metacpan.org/release/Config-INI-RefVars>

=item * GitHub Repository

  XXXXXXXXX

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
