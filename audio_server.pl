use strict;
use warnings;

# I use cvlc for audio streaming.
# The root path we will be following is /music
# since that is where the drive will be mounted.
my $vlc = "/usr/bin/cvlc";
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
	opendir(my $fh, $path) || return;
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

	my @songs = open_read_dir($path, '\.(mp3|m4a|wav|flac)');

	if(@songs && $path ne $last_played){	
		# Ensure that the songs are sorted.
		@songs = sort @songs;

		# Print out which Artist and which Album are queued up.
		print "\nPlaying $path_layers[1]'s $path_layers[2]\n";

		my $count = 1;
		foreach(@songs){
			# Make a pretty output to tell which song
			# is currently playing.
			my $cur_status = " - Playing $_  (" . 
			sprintf("%03d", $count) . "/" . 
			sprintf("%03d", scalar(@songs)) . ")\n";
			s/\.mp3// for $cur_status;
			print $cur_status;
		
			system($vlc, "--no-video", "-q", "$path/$_");
		
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
