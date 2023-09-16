#!/usr/bin/perl

use strict;
use File::Basename;
use XML::Simple;

my $program_name = File::Basename::basename $0;
my $release = "";
my $outdir = "";
my $scratch_dir = "";
my $pnor_data_dir = "";
my $pnor_filename = "";
my $payload = "";
my $bootkernel = "";
my $hb_image_dir = "";
my $xml_layout_file = "";
my $targeting_binary_filename = "";
my $targeting_RO_binary_filename = "";
my $targeting_RW_binary_filename = "";
my $sbec_binary_filename = "";
my $sbe_binary_filename = "";
my $wink_binary_filename = "";
my $occ_binary_filename = "";
my $openpower_version_filename = "";
my $wofdata_binary_filename = "";
my $memddata_binary_filename = "";
my $hdat_binary_filename = "";
my $ocmbfw_binary_filename = "";

my $SEPARATOR = ",";

sub write_header_csv {
	my ($csv, $num, $base, $flags) = @_;
	my $S = $SEPARATOR;
	printf $csv "\@%d${S}0x%08x${S}%s\n", $num, $base, $flags;
}

sub write_partition_csv {
	my ($csv, $name, $base, $size, $flags, $tocs, $file) = @_;
	my $S = $SEPARATOR;
	printf $csv "%s${S}0x%08x${S}0x%08x${S}%s${S}%s${S}%s\n",
		$name, $base, $size, $flags, $tocs, $file;
}

while (@ARGV > 0){
    $_ = $ARGV[0];
    chomp($_);
    $_ = &trim_string($_);
    if (/^-h$/i || /^-help$/i || /^--help$/i){
        #print help content
        usage();
        exit 0;
    }
    elsif (/^-release/i){
        $release = $ARGV[1] or die "Bad command line arg given: expecting a release input.\n";
        shift;
    }
    elsif (/^-scratch_dir/i){
        $scratch_dir = $ARGV[1] or die "Bad command line arg given: expecting a scratch dir path.\n";
        shift;
    }
    elsif (/^-outdir/i){
        $outdir = $ARGV[1] or die "Bad command line arg given: expecting a directory for output data.\n";
        shift;
    }
    elsif (/^-pnor_data_dir/i){
        $pnor_data_dir = $ARGV[1] or die "Bad command line arg given: expecting a directory containing pnor data.\n";
        shift;
    }
    elsif (/^-pnor_filename/i){
        $pnor_filename = $ARGV[1] or die "Bad command line arg given: expecting a pnor filename.\n";
        shift;
    }
    elsif (/^-hb_image_dir/i){
        $hb_image_dir = $ARGV[1] or die "Bad command line arg given: expecting an hb image dir path.\n";
        shift;
    }
    elsif (/^-xml_layout_file/i){
        $xml_layout_file = $ARGV[1] or die "Bad command line arg given: expecting an xml layout file.\n";
        shift;
    }
    elsif (/^-payload/i){
        $payload = $ARGV[1] or die "Bad command line arg given: expecting a filepath to payload binary file.\n";
        shift;
    }
    elsif (/^-bootkernel/i){
        $bootkernel = $ARGV[1] or die "Bad command line arg given: expecting a filepath to bootloader kernel image.\n";
        shift;
    }
    elsif (/^-targeting_binary_filename/i){
        $targeting_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a targeting binary filename.\n";
        shift;
    }
    elsif (/^-targeting_RO_binary_filename/i){
        $targeting_RO_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a targeting RW binary filename.\n";
        shift;
    }
    elsif (/^-targeting_RW_binary_filename/i){
        $targeting_RW_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a targeting RW binary filename.\n";
        shift;
    }
    elsif (/^-sbe_binary_filename/i){
        $sbe_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting an sbe binary filename.\n";
        shift;
    }
    elsif (/^-sbec_binary_filename/i){
        $sbec_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting an sbec binary filename.\n";
        shift;
    }
    elsif (/^-wink_binary_filename/i){
        $wink_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting an wink binary filename.\n";
        shift;
    }
    elsif (/^-occ_binary_filename/i){
        $occ_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting an occ binary filename.\n";
        shift;
    }
    elsif (/^-openpower_version_filename/i){
        $openpower_version_filename = $ARGV[1] or die "Bad command line arg given: expecting openpower version filename.\n";
        shift;
    }
    elsif (/^-wofdata_binary_filename/i){
        $wofdata_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a wofdata binary filename.\n";
        shift;
    }
    elsif (/^-memddata_binary_filename/i){
        $memddata_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a memddata binary filename.\n";
        shift;
    }
    elsif (/^-hdat_binary_filename/i){
        $hdat_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting an hdat binary filename.\n";
        shift;
    }
    elsif (/^-ocmbfw_binary_filename/i){
        $ocmbfw_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting an ocmbfw binary filename.\n";
        shift;
    }
    else {
        print "Unrecognized command line arg: $_ \n";
        print "To view all the options and help text run \'$program_name -h\' \n";
        exit 1;
    }
    shift;
}

if ($outdir eq "") {
    die "-outdir <path_to_directory_for_output_files> is a required command line variable. Please run again with this parameter.\n";
}
if ($release eq "") {
    die "-release <p8 or p9> is a required command line variable. Please run again with this parameter.\n";
}


# Verify that pnor_layout file exists and parse it
if ( ! -e "$xml_layout_file")
{
    die "$xml_layout_file does not exist\n";
}
my $xs = new XML::Simple(keyattr=>[], forcearray => 1);
my $parsed_pnor_layout = $xs->XMLin($xml_layout_file);


print "release = $release\n";
print "scratch_dir = $scratch_dir\n";
print "pnor_data_dir = $pnor_data_dir\n";

my $build_pnor_command = "$hb_image_dir/buildpnor.pl";
$build_pnor_command .= " --pnorOutBin $pnor_filename --pnorLayout $xml_layout_file --editedLayoutLocation $hb_image_dir";

# Process HBD section and possibly HBD_RW section
if (checkForPnorPartition("HBD_RW", $parsed_pnor_layout))
{
    $build_pnor_command .= " --binFile_HBD $scratch_dir/$targeting_RO_binary_filename";
    $build_pnor_command .= " --binFile_HBD_RW $scratch_dir/$targeting_RW_binary_filename";
}
else
{
    $build_pnor_command .= " --binFile_HBD $scratch_dir/$targeting_binary_filename";
}

$build_pnor_command .= " --binFile_SBE $scratch_dir/$sbe_binary_filename";
$build_pnor_command .= " --binFile_HBB $scratch_dir/hostboot.header.bin.ecc";
$build_pnor_command .= " --binFile_HBI $scratch_dir/hostboot_extended.header.bin.ecc";
$build_pnor_command .= " --binFile_HBRT $scratch_dir/hostboot_runtime.header.bin.ecc";
$build_pnor_command .= " --binFile_HBEL $scratch_dir/hbel.bin.ecc";
$build_pnor_command .= " --binFile_GUARD $scratch_dir/guard.bin.ecc";
$build_pnor_command .= " --binFile_PAYLOAD $payload";
$build_pnor_command .= " --binFile_BOOTKERNEL $bootkernel";
$build_pnor_command .= " --binFile_NVRAM $scratch_dir/nvram.bin";
$build_pnor_command .= " --binFile_ATTR_TMP $scratch_dir/attr_tmp.bin.ecc";
$build_pnor_command .= " --binFile_OCC $occ_binary_filename.ecc";
$build_pnor_command .= " --binFile_ATTR_PERM $scratch_dir/attr_perm.bin.ecc";
$build_pnor_command .= " --binFile_FIRDATA $scratch_dir/firdata.bin.ecc";
$build_pnor_command .= " --binFile_CAPP $scratch_dir/cappucode.bin.ecc";
$build_pnor_command .= " --binFile_SECBOOT $scratch_dir/secboot.bin.ecc";
$build_pnor_command .= " --binFile_VERSION $scratch_dir/openpower_pnor_version.bin";
$build_pnor_command .= " --binFile_IMA_CATALOG $scratch_dir/ima_catalog.bin.ecc";
my %filenames = (
	'SBE' => "$scratch_dir/$sbe_binary_filename",
	'HBB' => "$scratch_dir/hostboot.header.bin.ecc",
	'HBI' => "$scratch_dir/hostboot_extended.header.bin.ecc",
	'HBRT' => "$scratch_dir/hostboot_runtime.header.bin.ecc",
	'HBEL' => "$scratch_dir/hbel.bin.ecc",
	'GUARD' => "$scratch_dir/guard.bin.ecc",
	'PAYLOAD' => "$payload",
	'BOOTKERNEL' => "$bootkernel",
	'NVRAM' => "$scratch_dir/nvram.bin",
	'MVPD' => "$scratch_dir/mvpd_fill.bin.ecc",
	'DJVPD' => "$scratch_dir/djvpd_fill.bin.ecc",
	'CVPD' => "$scratch_dir/cvpd.bin.ecc",
	'ATTR_TMP' => "$scratch_dir/attr_tmp.bin.ecc",
	'ATTR_PERM' => "$scratch_dir/attr_perm.bin.ecc",
	'OCC' => "$occ_binary_filename.ecc",
	'FIRDATA' => "$scratch_dir/firdata.bin.ecc",
	'CAPP' => "$scratch_dir/cappucode.bin.ecc",
	'SECBOOT' => "$scratch_dir/secboot.bin.ecc",
	'VERSION' => "$openpower_version_filename",
	'IMA_CATALOG' => "$scratch_dir/ima_catalog.bin.ecc"
);

if ($does_HBD_RW_exist eq 0) {
    $filenames{'HBD'} = "$scratch_dir/$targeting_binary_filename";
} else {
    $filenames{'HBD'} = "$scratch_dir/$targeting_RO_binary_filename";
    $filenames{'HBD_RW'} = "$scratch_dir/$targeting_RW_binary_filename";
}

# These are optional sections not tied to a specific processor family type
if (checkForPnorPartition("DJVPD", $parsed_pnor_layout))
{
    $build_pnor_command .= " --binFile_DJVPD $scratch_dir/djvpd_fill.bin.ecc";

}

if (checkForPnorPartition("CVPD", $parsed_pnor_layout))
{
    $build_pnor_command .= " --binFile_CVPD $scratch_dir/cvpd.bin.ecc";
}

if (checkForPnorPartition("MVPD", $parsed_pnor_layout))
{
    $build_pnor_command .= " --binFile_MVPD $scratch_dir/mvpd_fill.bin.ecc";
}

if (checkForPnorPartition("EECACHE", $parsed_pnor_layout))
{
    $build_pnor_command .= " --binFile_EECACHE $scratch_dir/eecache_fill.bin.ecc";
}

if (checkForPnorPartition("OCMBFW", $parsed_pnor_layout))
{
    $build_pnor_command .= " --binFile_OCMBFW $ocmbfw_binary_filename";
}

# Add sections based on processor family type
if ($release eq "p9"){
    $build_pnor_command .= " --binFile_WOFDATA $wofdata_binary_filename" if -e $wofdata_binary_filename;
    if (checkForPnorPartition("MEMD", $parsed_pnor_layout))
    {
        $build_pnor_command .= " --binFile_MEMD $memddata_binary_filename" if -e $memddata_binary_filename;
    }
    $build_pnor_command .= " --binFile_HDAT $hdat_binary_filename" if -e $hdat_binary_filename;
    #Sigh
    $filenames{'WOFDATA'} = "$wofdata_binary_filename" if -e $wofdata_binary_filename;
    $filenames{'MEMD'} = "$memddata_binary_filename" if -e $memddata_binary_filename;
    $filenames{'HDAT'} = "$hdat_binary_filename" if -e $hdat_binary_filename;
}
if ($release eq "p8"){
    $build_pnor_command .= " --binFile_SBEC $scratch_dir/$sbec_binary_filename";
    $build_pnor_command .= " --binFile_WINK $scratch_dir/$wink_binary_filename";
    $filenames{'SBEC'} = "$scratch_dir/$sbec_binary_filename";
    $filenames{'WINK'} = "$scratch_dir/$wink_binary_filename";
} else {
    $build_pnor_command .= " --binFile_SBKT $scratch_dir/SBKT.bin";
    $build_pnor_command .= " --binFile_HCODE $scratch_dir/$wink_binary_filename";
    $build_pnor_command .= " --binFile_HBBL $scratch_dir/hbbl.bin.ecc";
    $build_pnor_command .= " --binFile_RINGOVD $scratch_dir/ringOvd.bin";
    $build_pnor_command .= " --binFile_HB_VOLATILE $scratch_dir/guard.bin.ecc";
    $filenames{'SBKT'} = "$scratch_dir/SBKT.bin";
    $filenames{'HCODE'} = "$scratch_dir/$wink_binary_filename";
    $filenames{'HBBL'} = "$scratch_dir/hbbl.bin.ecc";
    $filenames{'RINGOVD'} = "$scratch_dir/ringOvd.bin";
    $filenames{'HB_VOLATILE'} = "$scratch_dir/guard.bin.ecc";
}
$build_pnor_command .= " --fpartCmd \"fpart\"";
$build_pnor_command .= " --fcpCmd \"fcp\"";
print "###############################";
run_command("$build_pnor_command");

#Generate the CSV
my $ref = XMLin("$xml_layout_file", ForceArray => ['metadata', 'section'], SuppressEmpty => undef);
my $csv;
open($csv, ">", "$scratch_dir/pnor_layout.csv") or die "Can't open > $scratch_dir/pnor_layout.csv $!";

if (${$ref->{'metadata'}}[0]->{'arrangement'} ne "A-D-B") {
	printf STDERR "Found '%s' expecting 'A-D-B'\n",
		${$ref->{'metadata'}}[0]->{'arrangement'};
	die "Unexpected <arrangement> tag";
}

my $image_size = hex (${$ref->{'metadata'}}[0]->{'imageSize'});
my $block_size = hex (${$ref->{'metadata'}}[0]->{'blockSize'});
my $block_count = $image_size / $block_size;
my $toc_size = hex (${$ref->{'metadata'}}[0]->{'tocSize'});
my $side_string = "0";
my $side_count = keys(%{${$ref->{'metadata'}}[0]->{'side'}});

#Please don't ask me why
my $part_offset = 0;
if ($release eq "p9") {
	$part_offset = $block_size;
}

if (@{$ref->{'metadata'}} == 1) {
	if ($side_count == 1) {
		write_header_csv $csv, 0, 0, "";
		write_header_csv $csv, 1, $image_size - $toc_size - $part_offset, "";
		$side_string = "01";
	} elsif ($side_count == 2) {
		write_header_csv $csv, 0, 0, "";
		write_header_csv $csv, 1, ($image_size / 2) - $toc_size - $part_offset, "";
		write_header_csv $csv, 2, ($image_size / 2), "G";
		write_header_csv $csv, 3, $image_size - $toc_size - $part_offset, "G";
		$side_string = "0123";
	} else {
		printf STDERR "Sides not 1 or 2, total: %d\n", $side_count;
		die "Unexpected number of sides\n";
	}
} else {
	printf STDERR "Found %d <metadata> tags\n", @{$ref->{'metadata'}};
	die "There shouldn't be more than one <metadata>\n";
}

foreach my $section (@{$ref->{'section'}}) {
	my $name = $section->{'eyeCatch'};
	my $base = hex($section->{'physicalOffset'});
	my $size = hex($section->{'physicalRegionSize'});
	my $flags = "";
	$flags .= 'E' if (exists($section->{'ecc'}));
	$flags .= 'L' if (exists($section->{'sha512Version'}));
	$flags .= 'F' if (exists($section->{'reprovision'}));
	$flags .= 'I' if (exists($section->{'sha512perEC'}));
	$flags .= 'P' if (exists($section->{'preserved'}));
	$flags .= 'R' if (exists($section->{'readOnly'}));
	$flags .= 'C' if (exists($section->{'clearOnEccErr'}));
	$flags .= 'V' if (exists($section->{'volatile'}));
	my $side = "";
	if (exists($section->{'side'}) and $section->{'side'} ne "sideless") {
		$side = "01" if ($section->{'side'} eq "A");
		$side = "23" if ($section->{'side'} eq "B");
	} else {
		$side = $side_string; #Either "sideless" or no sides at all so all 0 is good
	}
	my $file = "/dev/zero";
	if (exists($filenames{$section->{'eyeCatch'}})) {
		$file = "$filenames{$section->{'eyeCatch'}}";
	} else {
		print STDERR "# Assuming partition $section->{'eyeCatch'} is blank\n";
	}
	write_partition_csv $csv, $name, $base, $size, $flags, $side, $file;
}

#BACKUP_PART should exist in the TOC before OTHER_SIDE. ffspart will
#respect the order of the CSV

#Add the other side and backup part partitions
if ($side_count == 2) {
	write_partition_csv $csv, "BACKUP_PART",
		($image_size / 2) - $toc_size - $part_offset, $toc_size, "B", 0, "/dev/zero";
	write_partition_csv $csv, "BACKUP_PART",
		$image_size - $toc_size - $part_offset, $toc_size, "B", 2, "/dev/zero";

	#BACKUP_PART for OTHER_SIDEs
	write_partition_csv $csv, "BACKUP_PART", 0, $toc_size, "B", 1, "/dev/zero";
	write_partition_csv $csv, "BACKUP_PART", $image_size / 2, $toc_size,
		"B", 3, "/dev/zero";

	write_partition_csv $csv, "OTHER_SIDE", $image_size / 2, $toc_size,
		"B", 0, "/dev/zero";
	write_partition_csv $csv, "OTHER_SIDE", 0, $toc_size, "B", 2, "/dev/zero";

	#OTHER_SIDEs for BACKUP_PARTs
	write_partition_csv $csv, "OTHER_SIDE", $image_size - $toc_size - $part_offset,
		$toc_size, "B", 1, "/dev/zero";
	write_partition_csv $csv, "OTHER_SIDE",
		($image_size / 2) - $toc_size - $part_offset,
		$toc_size, "B", 3, "/dev/zero";
} else {
	#Don't forget those pesky backup parts for the regular TOC
	write_partition_csv $csv, "BACKUP_PART",
		$image_size - $toc_size - $part_offset, $toc_size,
		"B", 0, "/dev/zero";
	write_partition_csv $csv, "BACKUP_PART", 0, $toc_size, "B", 1, "/dev/zero";
}


#ffspart should really learn to make its own output file
run_command("touch $outdir/ffspart.pnor");
run_command("ffspart -e -s $block_size -c $block_count -i $scratch_dir/pnor_layout.csv -p $outdir/ffspart.pnor");

#END MAIN
#-------------------------------------------------------------------------
sub usage {


print <<"ENDUSAGE";


ENDUSAGE

;
}


sub parse_config_file {

}

#trim_string takes one string as input, trims leading and trailing whitespace
# before returning that string
sub trim_string {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub run_command {
    my $command = shift;
    print "$command\n";
    my $rc = system($command);
    if ($rc !=0 ){
        die "Error running command: $command. Nonzero return code of ($rc) returned.\n";
    }
    return $rc;
}

# Function to check if a partition exists in the PNOR XML Layout File
sub checkForPnorPartition {
    my $section = shift;
    my $parsed_layout = shift;

    # default the return as 0 (aka 'false') - partition does NOT exist
    my $does_section_exist = 0;

    #Iterate over the <section> elements.
    foreach my $sectionEl (@{$parsed_layout->{section}})
    {
        my $eyeCatch = $sectionEl->{eyeCatch}[0];

        if($eyeCatch eq $section)
        {
            $does_section_exist = 1;
            last;
        }
    }

    return $does_section_exist;
}

