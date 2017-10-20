#!/usr/bin/perl -w
#
# ref, http://perldoc.perl.org/perlipc.html#Sockets%3a-Client%2fServer-Communication
# modified by wadelau on 20061031
# updatetime 20070112 wadelau
# updatetime 20080225 wadelau
# https support added by wadelau in Tue Jul 21 16:00:15 CST 2015
# chunk size remedy, by wadelau in Tue Aug 11 14:56:11 CST 2015
# recv-date, ssl imprvs, by Xenxin on Thu Aug 25 12:23:11 CST 2016
# 

use strict;
use IO::Socket;
use IO::Socket::INET;
use IO::Socket::INET6;
use IO::Socket::SSL;
use IO::Socket::Timeout;
use POSIX qw(strftime);

my $ver = 6.1;

if (@ARGV < 1) { 
	print "Usage: \n\n webget /servicelist.jsp \n  \n";
	print " webget http://wap.ufqi.com/servicelist.jsp \n  \n";
	print " webget wap.ufqi.com/servicelist.jsp \n  \n";
	print " webget \"http://172.24.100.4/servicelist.jsp?a=1&b=2\" \n \n";
	print "Version: $ver\n";
	exit ;
	#die "usage: $0 document ..." 
}

my $host = "" ;
my $port = "http(80)";
my $file = "";
if( $ARGV[0]=~/^\/(.*)/ ){
	$host = "localhost"; $file = $1;
}
else{
	if( $ARGV[0]=~/^(http:|https:)\/\/([^(\/|:)]+)[:]*([0-9]*)[\/]*(.*)/ ){
		$host =  $2 ; $port = $3;  $file = $4;
	}
	elsif( $ARGV[0]=~/([^\/]+)[:]([0-9]*)\/(.*)/ ){
		$host = $1; $port = $2;  $file = $3;
	}
}

if(!defined($host) || $host eq "" ){
	print " Usage: webget /servicelist.jsp \n or \n";
	print " Usage: webget http://wap.ufqi.com/servicelist.jsp \n or \n";
	print " Usage: wap.ufqi.com/servicelist.jsp \n or \n";
	print " Usage: 172.24.100.4/servicelist.jsp \n ";
	print " \n@ARGV\n\n";
	exit ;
}
elsif($ARGV[0]=~/^https/){
	$port="https(443)";
}

if( $port eq ''){ $port = '80'; }
$file = '/'.$file;
print "host:$host port:$port file:$file\n";

my $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"
	." Chrome/52.0.2743.116 Safari/537.36 WebGet/$ver";
my $EOL = "\015\012";
my $BLANK = $EOL x 2;
my $document = ""; 
my $line = "";
my $time_bgn = 0;
my $time_end = 0;
my $time_out = 3 * 60; # seconds
foreach $document ( @ARGV ){ # need remedy for multiple requests
	my $remote = undef;
	
	if($port eq "https(443)"){
		$remote = IO::Socket::SSL->new( Proto     => "tcp",
			PeerHost  => $host,
			PeerPort  => $port,
			#SSL_verify_mode => SSL_VERIFY_PEER, 
			SSL_verify_mode => SSL_VERIFY_NONE, 
			IO::Socket::SSL::default_ca(),
			SSL_verifycn_scheme => 'http',
			Timeout	=> $time_out,
		) or die ($SSL_ERROR);
	}
	elsif( 1 ){
		$remote = IO::Socket::INET->new( Proto     => "tcp",
			PeerHost  => $host,
			PeerPort  => $port,
			Timeout	=> $time_out,
		);
	}
	IO::Socket::Timeout->enable_timeouts_on($remote);
        $remote->timeout($time_out);
        $remote->read_timeout($time_out);
	
	unless ($remote) { die "cannot connect to http daemon on $host ." }
	$remote->autoflush(1);
	$time_bgn = time();
	my $sendCmd = "GET $file HTTP/1.1".$EOL."Host: $host".$EOL;
	$sendCmd .= "Date: ".(strftime("%a %Y-%m-%d %H:%M:%S UTC", gmtime())).$EOL;
	$sendCmd .= "User-Agent: $ua".$EOL;
	$sendCmd .= "Connection: close".$BLANK;
	print "sendCmd:\n$sendCmd";
	print $remote $sendCmd;

	# pay attention to chunk size header per part of its message body
	my $isChunk = 0; my $isCont = 0;
	while ( defined( $line = <$remote>) ) { 
		my $line2 = <$remote> ;
		if(!defined($line2)){ $line2 = ''; }
		#print "original:[$line] [$line2]";

		if($line=~/Transfer-Encoding: chunked/){
			$isChunk = 1; 
		}
		elsif($line2=~/Transfer-Encoding: chunked/){
			$isChunk = 1; 
		}
		if($line=~/^\r\n$/){
			$isCont = 1; 
		}
		elsif($line2=~/^\r\n$/){
			$isCont = 1; 
		}

		if($isChunk){
			if($isCont){
				if($line=~/^[0-9a-fA-F]+\r\n$/){ # chunk size line
					print substr($line2, 0, length($line2)-2); # remove \r\n
				}
				elsif($line2=~/^[0-9a-fA-F]+\r\n$/){
					if($line ne "\r\n"){
						print substr($line, 0, length($line)-2);
					}
					else{
						print $line;	
					}
				}
				else{
					print $line;	
					print $line2;	
				}
			}
			else{
				print $line;
				print $line2;
			}
		}
		else{
			print $line;	
			print $line2;	
		}
	}

	close $remote;

	$time_end = time();
	print "\n\nRecv-Date: ".strftime("%a %Y-%m-%d %H:%M:%S UTC", gmtime())
		.", ".($time_end - $time_bgn)." Seconds";

	print "\n\n";

}
