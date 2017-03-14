use strict;
use warnings;

# I use mpg123 for audio streaming.
# The root path we will be following is /music
# since that is where the drive will be mounted.
my $mpg123 = "/usr/bin/mpg123";
my $root = "/music";

# Path will follow this format since the file system is
# organized this way. This is a guaranteed fact with my personal
# system.
# Full potential Path layout:
#   /Music/Artist/Album/Disc/Song
my $path = "";
my @path_layers;
my $last_played = "";

update_path($root);

# open and read a directory, ignoring . and .., as well as any files
# starting with .
# This is default behavior. Other patterns can be passed in.
sub open_read_dir {
	my $path = shift;
	my $pattern = defined $_[0] ? $_[0] : '^(\w|\d).*';
	opendir(my $fh, $path) || die "Cannot open $path. $!";
	my @files = grep { /$pattern/ } readdir($fh);
	return @files;
}

# Determine if there is a majority of directories in the selected Album
# directory. This would establish if the Disc layer is necessary or if we
# can skip straight to the song layer.
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

# Adds the new layer to the path layers array and sets the path
# to the updated path layer array structure.
sub update_path {
	my $new_layer = shift;
	push @path_layers, $new_layer;
	$path = join("/", @path_layers);
}

# Main body to repeat forever until the process is killed
while(1){
	my @artists = open_read_dir($path);
	update_path($artists[int(rand(scalar(@artists)))]);

	my @albums = open_read_dir($path);
	update_path($albums[int(rand(scalar(@albums)))]);

	if(has_discs($path)){
		my @discs = open_read_dir($path);
		update_path($discs[int(rand(scalar(@albums)))]);
	}

	my @songs = sort open_read_dir($path, '\.(mp3|m4a)');
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
    # Save the last path so we dont play it again and reset
    # the current path.
    $last_played = $path;
	$path = "";

    # Clear the path layers to start the process over cleanly
    # and update the path to the root directory (/music)
    undef @path_layers;
	update_path($root);
}
