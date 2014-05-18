#! /usr/bin/perl

package Validate;

use JSON;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5 qw(md5_hex);
use FindBin qw($Bin);
use Text::MediawikiFormat qw(wikiformat);
use strict;

#use Net::DNS::Resolver;
use Socket;
use Socket6;

my %curl_exitcodes = (
    1 => "Unsupported protocol. This build of curl has no support for this protocol.",
    2 => "Failed to initialize.",
    3 => "URL malformed. The syntax was not correct.",
    5 => "Couldn't resolve proxy.  The  given  proxy  host	could  not  be resolved.",
    6 => "Couldn't resolve host. The given remote host was not resolved.",
    7 => "Failed to connect to host.",
    8 => "FTP  weird  server  reply.  The  server  sent data curl couldn't parse.",
    9 =>
      "FTP access denied. The server denied login or denied  access  to the particular resource or directory you wanted to reach.  Most often you tried to change to a directory that doesn't exist on the server.",
    11 => "FTP  weird PASS reply. Curl couldn't parse the reply sent to the PASS request.",
    13 => "FTP weird PASV reply, Curl couldn't parse the reply sent to  the PASV request.",
    14 => "FTP  weird  227  format.	Curl  couldn't	parse the 227-line the server sent.",
    15 => "FTP can't get host. Couldn't resolve the host IP we got  in  the 227-line.",
    17 => "FTP  couldn't  set  binary.  Couldn't  change transfer method to binary.",
    18 => "Partial file. Only a part of the file was transferred.",
    19 => "FTP couldn't download/access the given file, the RETR (or  simi- lar) command failed.",
    21 => "FTP quote error. A quote command returned error from the server.",
    22 =>
      "HTTP page not retrieved. The requested  url  was	not  found  or returned another error with the HTTP error code being 400 or above.  This return code only appears if -f/--fail is used.",
    23 => "Write error. Curl couldn't write data to a local	filesystem  or similar.",
    25 => "FTP  couldn't  STOR  file. The server denied the STOR operation, used for FTP uploading.",
    26 => "Read error. Various reading problems.",
    27 => "Out of memory. A memory allocation request failed.",
    28 => "Operation timeout. The specified	time-out  period  was  reached according to the conditions.",
    30 =>
      "FTP  PORT  failed.  The PORT command failed. Not all FTP servers support the PORT command, try doing a transfer using PASV instead!",
    31 => "FTP  couldn't use REST. The REST command failed. This command is used for resumed FTP transfers.",
    33 => "HTTP range error. The range  command  didn't work.",
    34 => "HTTP post error. Internal post-request generation error.",
    35 => "SSL connect error. The SSL handshaking failed.",
    36 => "FTP bad download resume. Couldn't continue  an  earlier  aborted download.",
    37 => "FILE couldn't read file. Failed to open the file. Permissions?",
    38 => "LDAP cannot bind. LDAP bind operation failed.",
    39 => "LDAP search failed.",
    41 => "Function not found. A required LDAP function was not found.",
    42 => "Aborted by callback. An application told curl to abort the oper- ation.",
    43 => "Internal error. A function was called with a bad parameter.",
    45 => "Interface error. A specified outgoing  interface	could  not  be used.",
    47 => "Too many redirects. When following redirects, curl hit the maximum amount.",
    48 => "Unknown TELNET option specified.",
    49 => "Malformed telnet option.",
    51 => "The peer's SSL certificate or SSH MD5 fingerprint was not ok.",
    52 => "The server didn't reply anything, which here  is	considered  an error.",
    53 => "SSL crypto engine not found.",
    54 => "Cannot set SSL crypto engine as default.",
    55 => "Failed sending network data.",
    56 => "Failure in receiving network data.",
    58 => "Problem with the local certificate.",
    59 => "Couldn't use specified SSL cipher.",
    60 => "Peer  certificate cannot be authenticated with known CA certifi- cates.",
    61 => "Unrecognized transfer encoding.",
    62 => "Invalid LDAP URL.",
    63 => "Maximum file size exceeded.",
    64 => "Requested FTP SSL level failed.",
    65 => "Sending the data requires a rewind that failed.",
    66 => "Failed to initialise SSL Engine.",
    67 => "The user name, password, or similar was not  accepted  and  curl failed to log in.",
    68 => "File not found on TFTP server.",
    69 => "Permission problem on TFTP server.",
    70 => "Out of disk space on TFTP server.",
    71 => "Illegal TFTP operation.",
    72 => "Unknown TFTP transfer ID.",
    73 => "File already exists (TFTP).",
    74 => "No such user (TFTP).",
    75 => "Character conversion failed.",
    76 => "Character conversion functions required.",
    77 => "Problem with reading the SSL CA cert (path? access rights?).",
    78 => "The resource referenced in the URL does not exist.",
    79 => "An unspecified error occurred during the SSH session.",
    80 => "Failed to shut down the SSL connection.",
    82 => "Could  not  load	CRL  file,  missing  or wrong format (added in 7.19.0).",
    83 => "Issuer check failed (added in 7.19.0).",
    84 => "The FTP PRET command failed",
    85 => "RTSP: mismatch of CSeq numbers",
    86 => "RTSP: mismatch of Session Identifiers",
    87 => "unable to parse FTP file list",
    88 => "FTP chunk callback reported error",
);

sub new {
    my $classname = shift;
    my $self      = {};
    bless( $self, $classname );
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;
    $self->{START} = time();
    $self->{AGE}   = 0;
    if (@_) {
        my %extra = @_;
        @$self{ keys %extra } = values %extra;
    }

    $self->{cgi}    ||= new CGI;
    $self->{plugin} ||= $self->{cgi}->param("plugin");
    $self->{server} ||= $self->{cgi}->param("server");
    $self->{ipv4}   ||= $self->{cgi}->param("ipv4");
    $self->{ipv6}   ||= $self->{cgi}->param("ipv6");
    $self->{cache}  ||= "$Bin/cache";
    $self->validate_variables();
    
    $self->get_site_config();
    $self->validate_variables();
    $self->run_plugin();
} ## end sub _init

sub run_plugin {
    my $self   = shift;
    my $plugin = shift;
    $plugin ||= $self->{plugin};
    $plugin ||= "_list";
    my $module = "Validate::Plugin::$plugin";
    print "eval use $module;\n";
    eval "use $module;";
    if ($@) {
        $self->json_report( { "error" => "plugin error trying to load $module: $@" } );
        return;
    }
    my $m = $module->new($self);
    my $r = $m->run();
    
    foreach my $reformat (qw( expect found notes error)) {
    if (exists $r->{$reformat}) {
     if (!exists $r->{$reformat . "_html"}) {
       my $html = wikiformat($r->{$reformat}, {}, {implicit_links=>0,extended=>1,absolute_links=>1});
       $r->{$reformat . "_html"} = $html;
     }
    }
    }
    
    
    $self->json_report($r);
}

sub validate_variables {
    my $self = shift;
    if ( $self->{ipv4} ) {
        my $i = inet_pton( AF_INET, $self->{ipv4} );
        $self->error_400("Bad ipv4= value") unless ($i);
        $self->{ipv4} = inet_ntop( AF_INET, $i );
    }
    if ( $self->{ipv6} ) {
        my $i = inet_pton( AF_INET6, $self->{ipv6} );
        $self->error_400("bad ipv6= value") unless ($i);
        $self->{ipv6} = inet_ntop(AF_INET6,$i);
    }
    if ( $self->{plugin} ) {
        if ( $self->{plugin} =~ /[^a-z0-9_]/ ) {
            $self->error_400("bad plugin= value");
        }
    } else {
        $self->{plugin} = "_list";    # Show list of plugins
    }
    if ( $self->{server} ) {
    } else {
        $self->error_400("bad or missing server= value");
    }
} ## end sub validate_variables

sub get_site_config {
    my $self   = shift;
    my $server = $self->{server};
    my $url    = "http://$server/site/config.js";
    my (@request);
    my ( $content, $headers ) = $self->curl( $url, "--get" );  #TODO connect ot a specific IP; and specifiy the Host header
    my($status) = split(/[\r\n]/,$headers);
    
    if ((!$content ) || ($status !~ /200/)) {
        $self->json_report( { "error" => "Could not read $url", abort => 1, status=>"bad" } );
    }
    if ($content !~ m/MirrorConfig/) {
        $self->json_report({"error"=>"Did not see MirrorConfig in $url",abort=>1, status=>"bad"});
    }
    my $config = $self->parse_config( $content, "MirrorConfig" );
    if ( !$config ) {
        $self->json_report( { "error" => "Could not json parse the insides of $url", abort => 1, status=>"bad" } );
    }
    $self->{config} = $config;
    
}

sub json_report {
    my $self     = shift;
    my $ref      = shift;
    my $encoded  = encode_json($ref);
    my $callback = $self->{cgi}->param("callback");
    if ($callback) {
        print <<"EOF";
Content-type: text/javascript;charset=UTF-8"
Pramga: no-cache
Expires: Thu, 01 Jan 1971 00:00:00 GMT

$callback\($encoded\);
EOF
    } else {
        print <<"EOF";
Content-Type: text/plain;charset=UTF-8
Pragma: no-cache
Expires: Thu, 01 Jan 1971 00:00:00 GMT

$encoded
EOF
    }
    exit 1;
} ## end sub json_report

sub error_400 {
    my $self = shift;
    my $text = shift;
    print $self->{cgi}->header( -type => "text/plain" -status => "400 Error" );
    print $text;
    exit 1;
}

sub load_file {
    my ($self)     = shift;
    my ($filename) = shift;
    my $buffer;
    open( LOADFILE, "<$filename" ) or return undef;
    read LOADFILE, $buffer, 100000;
    close LOADFILE;
    return $buffer;
}

sub curl {
    my $self = shift;
    my ( $url,@extra ) = @_;

    # for now, just fix $url     #TODO take optional IP, for the host header?
    # If the IP was specified we should connect to it instead, but pass a Host header
    
    if ( $url =~ m#\[# ) {
        my (@parts) = split( m#/#, $url, 4 );
        $parts[2] =~ s#\[#\\[#;
        $parts[2] =~ s#\]#\\]#;
        $url = join( "/", @parts );
    }

    my (@cmd) = "curl";
    push( @cmd, $url );
    push( @cmd, @extra ) if (@extra);
 
$DB::single=1;
    my $md5          = md5_hex( join( "\n", @cmd ) );
    my $cache        = $self->{cache} . "/" .  $<;
    my $content_file = "$cache/$md5.content";
    my $headers_file = "$cache/$md5.headers";
    
    system("mkdir","-p","$cache") unless (-p $cache);

    push( @cmd, "--silent" );
    push( @cmd, "--max-time", 30 );
    push( @cmd, "--output", $content_file );
    push( @cmd, "--dump-header", $headers_file );

    # Can we use the cached content?
    if ( ( !-f $headers_file ) || ( !-s $headers_file ) || ( !-s $content_file ) || ( -M $headers_file > 30 / 86400 ) || ($url !~ m#config#) )
    {

        # Better re-fetch.
        unlink($headers_file);
        my $i = system(@cmd);
        open( HEADERS, ">>$headers_file" );
        if ( $i == 0 ) {
            my $exitcode = 0;
            print HEADERS "Exit-Code: $exitcode\n";
            print HEADERS "Exit-Reason: $curl_exitcodes{$exitcode}\n" if ( exists $curl_exitcodes{$exitcode} );
        } else {
            my $exitcode = $? >> 8;
            print HEADERS "Exit-Code: $exitcode\n";
            print HEADERS "Exit-Reason: $curl_exitcodes{$exitcode}\n" if ( exists $curl_exitcodes{$exitcode} );
        }
        close HEADERS;
    }
    return ( $self->load_file($content_file), $self->load_file($headers_file) );
} ## end sub curl

sub parse_config {
    my $self    = shift;
    my $got     = shift;
    my $varname = shift;

    # Remove varname
    $got =~ s#^\s*$varname\s*=\s*##ms;

    # Remove comments like /* and */  and //
    $got =~ s#(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|([\s\t](//).*)##g;

    # And trailing commas
    $got =~ s/,\s*([\]}])/$1/mg;

    # And the trailing semicolon at the end
    $got =~ s/;\s*$//s;

    my $ref;
    eval { $ref = decode_json($got); };
    if ( !$ref ) {
        $self->{config_bad} = 1;
        $ref = {};
    }
    return $ref;

} ## end sub parse_config

sub indent {
 my $self = shift;
 my $s = shift;
 $s =~ s/^/ /gsm;
 return $s;
}


1;

__END__

        my $config = $self->parse_config( $content, "MirrorConfig" );
        
