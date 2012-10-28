package GraphViz2::Marpa::PathUtils::Utils;

use feature qw/say unicode_strings/;
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Config;

use Date::Format; # For time2str().
use Date::Simple;

use File::Spec;
use File::Slurp; # For read_dir().

use GraphViz2::Marpa::PathUtils;
use GraphViz2::Marpa::PathUtils::Config;

use Hash::FieldHash ':all';

use Text::Xslate 'mark_raw';

fieldhash my %config => 'config';

our $VERSION = '1.01';

# -----------------------------------------------

sub find_clusters
{
	my($self, $data_dir, $html_dir, $file_name) = @_;
	my($graph) = GraphViz2::Marpa::PathUtils -> new;

	my($parsed_file_name);
	my($result);
	my($tree_dot_name, $tree_image_name);

	for my $input_file_name (@$file_name)
	{
		print "Processing $input_file_name\n";

		$parsed_file_name = $input_file_name =~ s/gv$/csv/r;
		$tree_dot_name    = $input_file_name =~ s/\.in\./\.out\./r;
		$tree_image_name  = $input_file_name =~ s/in.gv/out.svg/r;

		$graph -> input_file(File::Spec -> catfile($data_dir, $input_file_name) );
		$graph -> parsed_file(File::Spec -> catfile($data_dir, $parsed_file_name) );
		$graph -> tree_dot_file(File::Spec -> catfile($data_dir, $tree_dot_name) );
		$graph -> tree_image_file(File::Spec -> catfile($html_dir, $tree_image_name) );

		$result = $graph -> find_clusters;

		if ($result == 1)
		{
			die "$input_file_name, $parsed_file_name, $tree_dot_name, $tree_image_name\n";
		}
	}

} # End of find_clusters.
# -----------------------------------------------

sub generate_demo
{
	my($self)       = @_;
	my($data_dir)   = 'data';
	my($html_dir)   = 'html';
	my(@demo_file)  = sort grep{! /index/} read_dir($data_dir);
	my(@cluster_in) = grep{/\.clusters.*\.in\.gv/} @demo_file;

	$self -> find_clusters($data_dir, $html_dir, \@cluster_in);

	my(@cluster_out) = grep{/\.clusters.*\.out\.gv/}   @demo_file;
	my(@fixed_in)    = grep{/\.fixed\.paths\.in\./}  @demo_file;
	my(@fixed_out)   = grep{/\.fixed\.paths\.out\./} @demo_file;

	my(@cluster);

	for my $i (0 .. $#cluster_in)
	{
		push @cluster,
		[
			{td => mark_raw qq|<object data="$cluster_in[$i]">|},
			{td => $cluster_in[$i]},
		],
		[
			{td => mark_raw qq|<object data="$cluster_out[$i]">|},
			{td => $cluster_out[$i]},
		];
	}

	my(@fixed_path);

	for my $i (0 .. $#fixed_in)
	{
		push @fixed_path,
		[
			{td => mark_raw qq|<object data="$fixed_in[$i]">|},
			{td => $fixed_in[$i]},
		],
		[
			{td => mark_raw qq|<object data="$fixed_out[$i]">|},
			{td => $fixed_out[$i]},
		];
	}

	my($config)    = $self -> config;
	my($templater) = Text::Xslate -> new
	(
	  input_layer => '',
	  path        => $$config{template_path},
	);
	my($index) = $templater -> render
	(
		'pathutils.report.tx',
		{
			border          => 1,
			cluster_data    => [@cluster],
			date_stamp      => time2str('%Y-%m-%d %T', time),
			default_css     => "$$config{css_url}/default.css",
			environment     => $self -> generate_demo_environment,
			fancy_table_css => "$$config{css_url}/fancy.table.css",
			fixed_data      => [@fixed_path],
			version         => $VERSION,
		}
	);
	my($file_name) = File::Spec -> catfile('html', 'index.html');

	open(OUT, '>', $file_name);
	print OUT $index;
	close OUT;

	print "Wrote: $file_name\n";

} # End of generate_demo.

# ------------------------------------------------

sub generate_demo_environment
{
	my($self) = @_;

	my(@environment);

	# mark_raw() is needed because of the HTML tag <a>.

	push @environment,
	{left => 'Author', right => mark_raw(qq|<a href="http://savage.net.au/">Ron Savage</a>|)},
	{left => 'Date',   right => Date::Simple -> today},
	{left => 'OS',     right => 'Debian V 6'},
	{left => 'Perl',   right => $Config{version} };

	return \@environment;
}
 # End of generate_demo_environment.

# -----------------------------------------------

sub _init
{
	my($self, $arg) = @_;
	$$arg{config}   = GraphViz2::Marpa::PathUtils::Config -> new -> config;
	$self           = from_hash($self, $arg);

	return $self;

} # End of _init.

# --------------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<GraphViz2::Marpa::PathUtils::Demo> - Provide various analyses of Graphviz dot files

=head1 SYNOPSIS

	shell> perl scripts/generate.demo.pl

=head1 DESCRIPTION

GraphViz2::Marpa::PathUtils::Demo generates html/index.html using html/*.svg files.

See scripts/generate.demo.pl.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

See L<GraphViz2::Marpa::PathUtils/Installation>.

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = GraphViz2::Marpa::PathUtils::Demo -> new >>.

It returns a new object of type C<GraphViz2::Marpa::PathUtils::Demo>.

=head1 Methods

=head2 generate_demo()

Generates html/index.html using html/*.svg files.

See scripts/generate.demo.pl.

=head2 _init()

For use by subclasses.

Sets default values for object attributes.

=head2 new()

For use by subclasses.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2::Marpa::PathUtils>.

=head1 Author

L<GraphViz2::Marpa::PathUtils> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
