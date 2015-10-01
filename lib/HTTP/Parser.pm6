use v6;

unit module HTTP::Parser;

my Buf $http_header_end_marker = Buf.new(13, 10, 13, 10);

# >0: header size
# -1: failed
# -2: request is partial
sub parse-http-request(Blob $req) is export {
    my Int $header_end_pos = 0;
    while ( $header_end_pos < $req.bytes ) {
        if ($http_header_end_marker eq $req.subbuf($header_end_pos, 4)) {
            last;
        }
        $header_end_pos++;
    }

    if ($header_end_pos < $req.bytes) {
        my @header_lines = $req.subbuf(
            0, $header_end_pos
        ).decode('ascii').split(/\r\n/);

        my $env = { };

        my Str $status_line = @header_lines.shift;
        if $status_line ~~ m/^(<[A..Z]>+)\s(\S+)\sHTTP\/1\.(<[01]>)$/ {
            $env<REQUEST_METHOD> = $/[0].Str;
            $env<SERVER_PROTOCOL> = "HTTP/1.{$/[2].Str}";
            my $path_query = $/[1];
            if $path_query ~~ m/^ (.*?) [ \? (.*) ]? $/ {
                $env<PATH_INFO> = $/[0].Str;
                if $/[1].defined {
                    $env<QUERY_STRING> = $/[1].Str;
                } else {
                    $env<QUERY_STRING> = '';
                }
            }
        } else {
            return -2,Nil;
        }

        for @header_lines {
            if $_ ~~ m/ ^^ ( <[ A..Z a..z - ]>+ ) \s* \: \s* (.+) $$ / {
                my ($k, $v) = @($/);
                $k = $k.subst(/\-/, '_', :g);
                $k = $k.uc;
                if $k ne 'CONTENT_LENGTH' && $k ne 'CONTENT_TYPE' {
                    $k = 'HTTP_' ~ $k;
                }
                $env{$k} = $v.Str;
            } else {
                die "invalid header: $_";
            }
        }

        return $header_end_pos+4, $env;
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
    # $env => ${:CONTENT_TYPE("text/html"), :PATH_INFO("/"), :QUERY_STRING(""), :REQUEST_METHOD("GET")}

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
