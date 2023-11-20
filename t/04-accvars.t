use 5.010;
use strict;
use warnings;
use Test::More;

use Config::INI::AccVars;

use File::Spec::Functions;

#sub test_data_file { catfile(qw(t 04_data), $_[0]) }


note("Testing assignments with and without auto vars");

#
# For heredocs containing INI data always use the single quote variant!
#

subtest 'section name, variable name' => sub {
  my $src = <<'EOT';
[SEC]
info = This is variable '$(==)' in section '$(=)'.
foo = $(==) : $(info)
bar = $($(X)$()$(X)): $(foo)
X = =
EOT
  my $obj = Config::INI::AccVars->new->parse_ini(src => $src);
  isa_ok($obj, 'Config::INI::AccVars');
  is_deeply($obj->variables,
            {
             'SEC' => {
                       bar  => "bar: foo : This is variable 'info' in section 'SEC'.",
                       foo  => "foo : This is variable 'info' in section 'SEC'.",
                       info => "This is variable 'info' in section 'SEC'.",
                       X    => '='
                      }
            },
            'variables()');
};


subtest "simple, using .=, +=, .>=, +>=" => sub {
  my $src = <<'EOT';
[the section]
foo = 27
bar=42
foo-bar-1=$(foo) - $(bar)

foo-bar-2 = $(foo)
foo-bar-2 += -
foo-bar-2 += $(bar)

foo-bar-3 = $(foo)
foo-bar-3 .= $( )-$( )
foo-bar-3 .= $(bar)

foo-bar-4 = $(bar)
foo-bar-4 .>= $( )-$( )
foo-bar-4 .>= $(foo)

foo-bar-5 = $(bar)
foo-bar-5 +>= -
foo-bar-5 +>= $(foo)
EOT
  my $obj = Config::INI::AccVars->new->parse_ini(src => $src);
  isa_ok($obj, 'Config::INI::AccVars');
  is_deeply($obj->variables,
            {
             'the section' => {
                               'foo'       => '27',
                               'bar'       => '42',
                               'foo-bar-1' => '27 - 42',
                               'foo-bar-2' => '27 - 42',
                               'foo-bar-3' => '27 - 42',
                               'foo-bar-4' => '27 - 42',
                               'foo-bar-5' => '27 - 42',
                              }
            },
            'variables()');
};


subtest 'section name, variable name' => sub {
  my $src = <<'EOT';
[SEC]
info = This is variable '$(==)' in section '$(=)'.
foo = $(==) : $(info)
bar = $($(X)$()$(X)): $(foo)
X = =
EOT
  my $obj = Config::INI::AccVars->new->parse_ini(src => $src);
  isa_ok($obj, 'Config::INI::AccVars');
  is_deeply($obj->variables,
            {
             'SEC' => {
                       bar  => "bar: foo : This is variable 'info' in section 'SEC'.",
                       foo  => "foo : This is variable 'info' in section 'SEC'.",
                       info => "This is variable 'info' in section 'SEC'.",
                       X    => '='
                      }
            },
            'variables()');
};


#==================================================================================================
done_testing();

