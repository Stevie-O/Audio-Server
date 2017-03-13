use strict;
use warnings;

my $mpg123 = "/usr/bin/mpg123";
my $root = "/music";
my $path = "";
my @path_layers;
my $last_played = "";

update_path($root);

sub open_read_dir {
	my $path = shift;
	my $pattern = defined $_[0] ? $_[0] : "^(\w|\d).*";
	opendir(my $fh, $path) || die "Cannot open $path. $!";
	my @files = grep { /$pattern/ } readdir($fh);
	return @files;
}

sub has_discs {
	my $path = shift;
	my @files = open_read_dir($path);
	my $dir = 0; 
	my $ndir = 0;
	
	foreach(@files){
		if( -d $_ ){
			$dir++;
		} else {
			$ndir++;
		}
	}

	return ( $dir > $ndir ? 1 : 0 );
}

sub update_path {
	my $new_layer = shift;
	push @path_layers, $new_layer;
	$path = join("/", @path_layers);
}

while(1){
	my @artists = open_read_dir($path);
	update_path($artists[int(rand(scalar(@artists)))]);

	my @albums = open_read_dir($path);
	update_path($albums[int(rand(scalar(@albums)))]);

	if(has_discs($path)){
		my @discs = open_read_dir($path);
		update_path($discs[int(rand(scalar(@albums)))]);
	}

	my @songs = open_read_dir($path, "\.mp3");
	if(@songs && $path ne $last_played){	
		my $count = 1;
		foreach(@songs){
			print "Playing $_  (" . 
			sprintf("%03d", $count) . "/" . 
			sprintf("%03d", scalar(@songs)) . ")\n";
			system($mpg123, "-q", "$path/$_");
			$count++;
		}
	}
	$last_played = $path;
	$path = "";
	undef @path_layers;
	update_path($root);
}
