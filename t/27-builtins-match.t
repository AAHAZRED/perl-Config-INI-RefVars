use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;


subtest 'm builtin' => sub {
  my $ini = <<'INI';
[sec]
a = $(=& m,abc123,\d+)
b = $(=& m,abcdef,\d+)
c = $(=& if,$(=& m,foo\.cpp,\.cpp$),yes,no)
INI

  my $obj = Config::INI::RefVars->new();
  $obj->parse_ini(src => $ini);

  my $vars = $obj->variables()->{sec};

  is($vars->{a}, '1', 'm: first match');
  is($vars->{b}, '', 'm: second match');
  is($vars->{c}, 'yes', 'm: use with if-func');
};


done_testing();


