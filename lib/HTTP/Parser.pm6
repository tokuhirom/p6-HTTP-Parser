use v6;

unit module HTTP::Parser;

my Buf $http-header-end-marker = Buf.new(13, 10, 13, 10);

# >0: header size
# -1: failed
# -2: request is partial
sub parse-http-request(Blob $req) is export {
    my Int $header-end-pos = 0;
    while ( $header-end-pos < $req.bytes ) {
        if ($http-header-end-marker eq $req.subbuf($header-end-pos, 4)) {
            last;
        }
        $header-end-pos++;
    }

    if ($header-end-pos < $req.bytes) {
        my @header-lines = $req.subbuf(
            0, $header-end-pos
        ).decode('ascii').subst(/^(\r\n)*/, '').split(/\r\n/);

        my $env = {
            :SCRIPT-NAME('')
        };

        my Str $status-line = @header-lines.shift;
        if $status-line ~~ m/^(<[A..Z]>+)\s(\S+)\sHTTP\/1\.(<[01]>)$/ {
            $env<REQUEST-METHOD> = $/[0].Str;
            $env<SERVER-PROTOCOL> = "HTTP/1.{$/[2].Str}";
            my $path-query = $/[1].Str;
            $env<REQUEST-URI> = $path-query;
            if $path-query ~~ m/^ (.*?) [ \? (.*) ]? $/ {
                my $path = $/[0].Str;
                my $query = ($/[1] // '').Str;
                $env<PATH-INFO> = $path.subst(:g, /\%(<[0..9 a..f A..F]> ** 2)/, -> {
                     :16($/[0].Str).chr
                });
                $env<QUERY-STRING> = $query;
            }
        } else {
            return -2,Nil;
        }

        for @header-lines {
            if $_ ~~ m/ ^^ ( <[ A..Z a..z - ]>+ ) \s* \: \s* (.+) $$ / {
                my ($k, $v) = @($/);
                $k = $k.uc;
                if $k ne 'CONTENT-LENGTH' && $k ne 'CONTENT-TYPE' {
                    $k = 'HTTP-' ~ $k;
                }
                $env{$k} = $v.Str;
            } else {
                return -2,Nil;
            }
        }

        return $header-end-pos+4, $env;
    } else {
        return -1,Nil;
    }
}

=begin pod

=head1 NAME

HTTP::Parser - HTTP parser.

=head1 SYNOPSIS

    use HTTP::Parser;

    my ($result, $env) = parse-http-request("GET / HTTP/1.0\r\ncontent-type: text/html\r\n\r\n".encode("ascii"));
    # $result => 43
    # $env => ${:CONTENT-TYPE("text/html"), :PATH-INFO("/"), :QUERY-STRING(""), :REQUEST-METHOD("GET")}

=head1 DESCRIPTION

HTTP::Parser is tiny http request parser library for perl6.

=head1 FUNCTIONS

=item C<my ($result, $env) = sub parse-http-request(Blob $req) is export>

parse http request.

Tries to parse given request string, and if successful, inserts variables into C<$env>.  For the name of the variables inserted, please refer to the PSGI specification.  The return values are:

=item2 >=0

length of the request (request line and the request headers), in bytes

=item2 -1

given request is corrupt

=item2 -2

given request is incomplete

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Tokuhiro Matsuno <tokuhirom@gmail.com>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
