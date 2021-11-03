use strict;
use warnings;
use Test::More;

use DNS::Resolver;

my $resolver = DNS::Resolver->new;

my $domain = "www.google.com";
my @ip = $resolver->resolve($domain);
ok @ip;
note "$domain -> $_" for @ip;

my $ok;
for my $ip (@ip) {
    my $domain = $resolver->reverse_resolve($ip);
    if ($domain) {
        note "$ip -> $domain";
        $ok++;
    } else {
        note "$ip -> FAIL, " . $resolver->error;
    }
}

ok $ok;

done_testing;
