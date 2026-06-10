# t/14-function-call-errors.t
use strict;
use warnings;

use Test::More;

use Config::INI::RefVars;

subtest 'empty function call dies' => sub {
    my $ini = <<'INI';
[paths]
bad := $(=&)
INI

    my $ok = eval {
        my $obj = Config::INI::RefVars->new();
        $obj->parse_ini(src => $ini);
        1;
    };

    ok(!$ok, 'parse_ini dies for empty function call');
    like($@, qr/empty function call/, 'error mentions empty function call');
};

subtest 'blank function call dies' => sub {
    my $ini = <<'INI';
[paths]
bad := $(=&   )
INI

    my $ok = eval {
        my $obj = Config::INI::RefVars->new();
        $obj->parse_ini(src => $ini);
        1;
    };

    ok(!$ok, 'parse_ini dies for blank function call');
    like($@, qr/empty function call/, 'error mentions empty function call');
};

subtest 'unterminated function call dies' => sub {
    my $ini = <<'INI';
[paths]
bad := $(=& catdir, foo, bar
INI

    my $ok = eval {
        my $obj = Config::INI::RefVars->new();
        $obj->parse_ini(src => $ini);
        1;
    };

    ok(!$ok, 'parse_ini dies for unterminated function call');
    like($@, qr/unterminated variable reference/, 'error mentions unterminated variable reference');
};

subtest 'unterminated nested function call dies' => sub {
    my $ini = <<'INI';
[paths]
bad := $(=& catfile, $(=& catdir, foo, bar), $(=& catdir, x, y)
INI

    my $ok = eval {
        my $obj = Config::INI::RefVars->new();
        $obj->parse_ini(src => $ini);
        1;
    };

    ok(!$ok, 'parse_ini dies for unterminated nested function call');
    like($@, qr/unterminated variable reference/, 'error mentions unterminated variable reference');
};

#==================================================================================================
done_testing();
