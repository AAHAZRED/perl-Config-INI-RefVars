use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::AccVars;

use File::Spec::Functions;


sub test_data_file { catfile(qw(t 03_data), $_[0]) }

subtest "basic assignments" => sub {
  my $obj = Config::INI::AccVars->new;
  foreach my $file (test_data_file('basic.ini'), test_data_file('basic_spaces.ini')) {
    subtest $file => sub {
      $obj->parse_ini(src => $file);
      is_deeply($obj->sections, [$Config::INI::AccVars::Default_Section, "this section"],
                "sections()");
      is_deeply($obj->sections_h, { $Config::INI::AccVars::Default_Section => undef,
                                    "this section"                         => undef },
                "sections_h()");
      is_deeply($obj->variables, { $Config::INI::AccVars::Default_Section => {foo => 'foo_val'},
                                   "this section" => {str => "hello world"}
                                 },
                "variables()");
    };
  }
};

#==================================================================================================
done_testing();

