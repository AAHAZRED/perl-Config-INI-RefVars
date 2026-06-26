use strict;
use warnings;

use Test::More;
use Config::INI::RefVars;

subtest 'Line continuation' => sub {
  my $ini = <<'END_INI';
[my section]
single = one\

multi \= foo\
  bar\
  baz

expand :\= $(multi)\
!

append +\= abc\
def

normal = x\
y = separate

last \= last line\
END_INI

  my $parser = Config::INI::RefVars->new;
  my $vars = $parser->parse_ini(src => $ini)->variables()->{'my section'};

  is($vars->{single}, 'one\\',
    'ordinary assignment does not use continuation');

  is($vars->{multi}, 'foo  bar  baz',
    'continued assignment');

  is($vars->{expand}, 'foo  bar  baz!',
    'continuation also works with := assignments');

  is($vars->{append}, 'abcdef',
    'continuation also works with += assignments');

  is($vars->{normal}, 'x\\',
    'continuation is disabled unless modifier contains backslash');

  is($vars->{y}, 'separate',
     'following line is parsed as separate assignment');

  is($vars->{last}, 'last line',
    'continuation stops cleanly at end of file');
};

subtest 'Line continuation edge cases' => sub {
  my $ini = <<'END_INI';
[my section]
a \= abc\
def\
ghi

b \= xyz\
END_INI

  my $parser = Config::INI::RefVars->new;
  my $vars = $parser->parse_ini(src => $ini)->variables()->{'my section'};

  is($vars->{a}, 'abcdefghi',
    'multiple continuation lines');

  is($vars->{b}, 'xyz',
    'EOF after trailing backslash');
};


done_testing;
