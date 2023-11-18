use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::AccVars;

use File::Spec::Functions;

sub test_data_file { catfile(qw(t 03_data), $_[0]) }

#
# For heredocs containing INI data always use the single quote variant!
#

subtest "basic assignments" => sub {
  my $obj = Config::INI::AccVars->new;
  foreach my $file (test_data_file('basic.ini'), test_data_file('basic_spaces.ini')) {
    subtest $file => sub {
      $obj->parse_ini(src => $file);
      is_deeply($obj->sections, [Config::INI::AccVars::DFLT_COMMON_SECTION, "this section"],
                "sections()");
      is_deeply($obj->sections_h, { Config::INI::AccVars::DFLT_COMMON_SECTION => 0,
                                    "this section"                            => 1 },
                "sections_h()");
      is_deeply($obj->variables, { Config::INI::AccVars::DFLT_COMMON_SECTION => {foo => 'foo_val'},
                                   "this section" => {foo => 'foo_val',
                                                      str => "hello world"}
                                 },
                "variables()");
    };
  }
};

subtest "empty and one blank string" => sub {
  my $obj = Config::INI::AccVars->new;
  my $src = <<'EOT';
[the section]
empty-1 =
empty-2.=
empty-3 +=
empty-4=$()
empty-5 = $()$()$()$()$()$()
empty-6 = $(empty-4)
empty-6 ?= 1234567
blank-1 = $( )
blank-2 = $() $()
blank-3 +=
blank-3 +=
blank-4 = $(blank-3)
blank-5 := $(blank-3)$()$()$()
blank-5 ?= 98765421
EOT
  #Don't append a semicolon to the line above!
  $obj->parse_ini(src => $src);
  is_deeply($obj->sections, ["the section"], "sections()");
  my $sec_vars = $obj->variables->{'the section'};
  while (my ($var, $val) = each(%$sec_vars)) {
    my $prefix = substr($var, 0, 5);
    if ($prefix eq 'empty') {
      is($val, '', "$var: epmty value");
    } elsif ($prefix eq 'blank') {
      is($val, ' ', "$var: a blank");
    } else {
      die("$var: unexpected variable");
    }
  }
};

#subtest "multiple blanks" => sub {};

#==================================================================================================
done_testing();

