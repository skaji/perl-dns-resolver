package DNS::Resolver;
use strict;
use warnings;

our $VERSION = '0.001';

use List::Util 1.60 ();
use Socket 2.032 ();

my $HAS_AI_ADDRCONFIG = do {
    local $@;
    eval { my $x = Socket::AI_ADDRCONFIG; 1 };
};

sub new {
    my ($class, %hint) = @_;
    $hint{socktype} = Socket::SOCK_STREAM if !exists $hint{socktype};
    bless { _error => undef, hint => \%hint }, $class;
}

sub error {
    my $self = shift;
    $self->{_error};
}

sub resolve {
    my ($self, $host, %hint) = @_;
    $self->{_error} = undef;
    my ($err, @info) = $self->_resolve_addrinfo($host, %hint);
    if ($err) {
        $self->{_error} = $err;
        return;
    }
    my @ip_string;
    for my $info (@info) {
        my ($family, $addr) = @{$info}{"family", "addr"};
        my $unpack = $family == Socket::AF_INET ?
            \&Socket::unpack_sockaddr_in : \&Socket::unpack_sockaddr_in6;
        my $ip_binary = $unpack->($addr);
        my $ip_string = Socket::inet_ntop $family, $ip_binary;
        push @ip_string, $ip_string;
    }
    List::Util::uniq @ip_string;
}

my $REGEXP_IPv4_DECIMAL = qr/25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}/;
my $REGEXP_IPv4_DOTTEDQUAD = qr/$REGEXP_IPv4_DECIMAL\.$REGEXP_IPv4_DECIMAL\.$REGEXP_IPv4_DECIMAL\.$REGEXP_IPv4_DECIMAL/;

sub reverse_resolve {
    my ($self, $ip_string, %hint) = @_;
    $self->{_error} = undef;
    %hint = (%{$self->{hint}}, %hint);
    my $family = $ip_string =~ m/^$REGEXP_IPv4_DOTTEDQUAD$/ ?
        Socket::AF_INET : Socket::AF_INET6;
    my $port = 0;
    my $ip_binary = Socket::inet_pton $family, $ip_string;
    my $pack = $family == Socket::AF_INET ?
        \&Socket::pack_sockaddr_in : \&Socket::pack_sockaddr_in6;
    my $addr = $pack->($port, $ip_binary);
    my $flags = $hint{socktype} == Socket::SOCK_DGRAM ? Socket::NI_DGRAM : 0;
    my $xflags = Socket::NIx_NOSERV; # not interested in "service"
    my ($err, $host, $service) = Socket::getnameinfo $addr, $flags, $xflags;
    if ($err) {
        $self->{_error} = $err;
        return;
    }
    if (!$host) {
        $self->{_error} = "no reverse entry";
        return;
    }
    if ($host eq $ip_string) {
        $self->{_error} = "no reverse entry";
        return;
    }
    $host;
}

sub _resolve_addrinfo {
    my ($self, $host, %hint) = @_;
    my $service = "0";
    my $flags = $self->{hint}{flags} || $hint{flags} || 0;
    if ($HAS_AI_ADDRCONFIG) {
        $flags = $flags | Socket::AI_ADDRCONFIG;
    }
    %hint = (%{$self->{hint}}, %hint, flags => $flags);
    my ($err, @info) = Socket::getaddrinfo $host, $service, \%hint;
    ($err, @info);
}

1;
__END__

=encoding utf-8

=head1 NAME

DNS::Resolver - a DNS resolver

=head1 SYNOPSIS

  use DNS::Resolver;

  my $resolver = DNS::Resolver->new;

  my @ip = $resolver->resolve("www.google.com");
  # 2404:6800:4004:822::2004
  # 142.250.196.132

  my $domain = $resolver->reverse_resolve("2404:6800:4004:822::2004");
  # nrt12s36-in-x04.1e100.net

=head1 DESCRIPTION

DNS::Resolver is a DNS resolver which is actually a wrapper around L<Socket> module.

=head1 INSTALL

  cpm install -g https://github.com/skaji/perl-dns-resolver.git

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
