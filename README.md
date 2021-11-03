# NAME

DNS::Resolver - a DNS resolver

# SYNOPSIS

    use DNS::Resolver;

    my $resolver = DNS::Resolver->new;

    my @ip = $resolver->resolve("www.google.com");
    # 2404:6800:4004:822::2004
    # 142.250.196.132

    my $domain = $resolver->reverse_resolve("2404:6800:4004:822::2004");
    # nrt12s36-in-x04.1e100.net

# DESCRIPTION

DNS::Resolver is a DNS resolver which is actually a wrapper around [Socket](https://metacpan.org/pod/Socket) module.

# INSTALL

    cpm install -g https://github.com/skaji/perl-dns-resolver.git

# COPYRIGHT AND LICENSE

Copyright 2021 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
