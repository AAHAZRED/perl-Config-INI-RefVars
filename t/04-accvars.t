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
X = $(Y)
Y= =
EOT
  my $obj = Config::INI::AccVars->new->parse_ini(src => $src);
  isa_ok($obj, 'Config::INI::AccVars');
  is_deeply($obj->variables,
            {
             'SEC' => {
                       bar  => "bar: foo : This is variable 'info' in section 'SEC'.",
                       foo  => "foo : This is variable 'info' in section 'SEC'.",
                       info => "This is variable 'info' in section 'SEC'.",
                       X    => '=',
                       Y    => '='
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


subtest "Nested variable referencing" => sub {
  my $obj = Config::INI::AccVars->new;
  subtest "empty" => sub {
    my $src = <<'EOT';
[the section]

empty-1 = $()$($())$($($()))$($($($())))
empty-2 = $($(x)$(y))
x = em
y = pty
EOT
    $obj->parse_ini(src => $src);
    is_deeply($obj->variables,
              {
               'the section' => {
                                 'empty-1' => '',
                                 'empty-2' => '',
                                 'y'       => 'pty',
                                 'x'       => 'em'
                                }
              },
              'variables()');
  };
};

subtest "not evaluated again" => sub {
  my $obj = Config::INI::AccVars->new;
  subtest "composed" => sub {
    my $src = <<'EOT';
[ the section ]
dollar=$
open=(
close=)
section=$(=)

; The result looks like a reference but will not be evaluated again.
; So does `make'.
not evaluated again=$(dollar)$(open)$(section)$(close)
same here = $(not evaluated again)

EOT
    $obj->parse_ini(src => $src);
      is_deeply($obj->variables,
                {
                 'the section' => {
                                   'dollar'              => '$',
                                   'open'                => '(',
                                   'close'               => ')',
                                   'section'             => 'the section',
                                   'not evaluated again' => '$(the section)',
                                   'same here'           => '$(the section)',
                                  }
                },
                'variables()');
  };

  subtest 'assign using := and append+prepand later' => sub {
   my $src = <<'EOT';
[section 1]
this = 12345
that := ||| this 1 $(this)
this .= 6789
that += this 2 $(this)
this = abc
that .= _this 3 $(this)
this = DEF
that +>= this -1 $(this)
this = GHI
that .>= this -2 $(this)_

[section 2]
this = 12345
that := |||
that .= $( )this 1 $(th$()is)
this .= 6789
that += this 2 $(this)
this = abc
that .= _this 3 $(this)
this = DEF
that +>= this -1 $(this)
this = GHI
that .>= this -2 $(this)_
EOT
  $obj->parse_ini(src => $src);
  my $exp = {
             'that' => 'this -2 GHI_this -1 DEF ||| this 1 12345 this 2 123456789_this 3 abc',
             'this' => 'GHI'
            };
  is_deeply($obj->variables,
            { 'section 2' => $exp,
              'section 1' => $exp
            },
            'variables()');
 };
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

