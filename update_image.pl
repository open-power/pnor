#!/usr/bin/perl

use strict;
use File::Basename;

#my $ecc_tool_dir = "/opt/mcp/shared/fr_FLD8-1-20140528/opt/fsp/usr/bin"; #wh_todo

my $release = "";
my $op_target_dir = "";
my $hb_image_dir = "";
my $scratch_dir = "";
my $hb_binary_dir = "";
my $targeting_binary_filename = "";
my $targeting_binary_source = "";
my $sbec_binary_filename = "";
my $sbe_binary_dir = "";
my $wink_binary_filename = "";
my $occ_binary_filename = "";
my $capp_binary_filename = "";
my $ima_catalog_binary_filename = "";
my $openpower_version_filename = "";
my $payload = "";
my $xz_compression = 0;
my @ec_levels = ();
my %ec_val = ("DD1","10","DD2","20");

while (@ARGV > 0){
    $_ = $ARGV[0];
    chomp($_);
    $_ = &trim_string($_);
    if (/^-h$/i || /^-help$/i || /^--help$/i){
        usage(); #print help content
        exit 0;
    }
    elsif (/^-release/i){
        $release = $ARGV[1] or die "Bad command line arg given: expecting a release (p8 or p9).\n";
        shift;
    }
    elsif (/^-op_target_dir/i){
        $op_target_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-hb_image_dir/i){
        $hb_image_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-sbe_binary_dir/i){
        $sbe_binary_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-scratch_dir/i){
        $scratch_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-hb_binary_dir/i){
        $hb_binary_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-ec_levels/i){
        @ec_levels = split(',', $ARGV[1]) or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-targeting_binary_filename/i){
        $targeting_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-targeting_binary_source/i){
        $targeting_binary_source = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-sbec_binary_filename/i){
        $sbec_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-wink_binary_filename/i){
        $wink_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-occ_binary_filename/i){
        $occ_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-capp_binary_filename/i){
        $capp_binary_filename = $ARGV[1] or die "Bad command line arg given: execting a config type.\n";
        shift;
    }
    elsif (/^-ima_catalog_binary_filename/i){
        $ima_catalog_binary_filename = $ARGV[1] or die "Bad command line arg given: execting a config type.\n";
        shift;
    }
    elsif (/^-openpower_version_filename/i){
        $openpower_version_filename = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-payload/i){
        $payload = $ARGV[1] or die "Bad command line arg given: expecting a filepath to payload binary file.\n";
        shift;
    }
    elsif (/^-xz_compression/i){
        $xz_compression = 1;
    }
    else {
        print "Unrecognized command line arg: $_ \n";
        #print "To view all the options and help text run \'$program_name -h\' \n";
        exit 1;
    }
    shift;
}

# Compress the skiboot lid image with lzma
if (($payload ne "") and ($xz_compression))
{
    run_command("xz -fk --check=crc32 $payload");
}

# Pad Targeting binary to 4k page size, then add ECC data
###
### To calculate the pad, ibs=(<partition size>/9)*8
###
if ($release eq "p8") {
    run_command("dd if=$op_target_dir/$targeting_binary_source of=$scratch_dir/$targeting_binary_source ibs=4k conv=sync");
} else {
    run_command("env echo -en VERSION\\\\0 > $scratch_dir/hostboot_data.sha.bin");
    run_command("sha512sum $op_target_dir/$targeting_binary_source | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot_data.sha.bin");
    run_command("dd if=$scratch_dir/hostboot_data.sha.bin of=$scratch_dir/hostboot.temp.bin ibs=4k conv=sync");
    run_command("cat $op_target_dir/$targeting_binary_source >> $scratch_dir/hostboot.temp.bin");
    run_command("dd if=$scratch_dir/hostboot.temp.bin of=$scratch_dir/$targeting_binary_source ibs=4k conv=sync");
}
run_command("ecc --inject $scratch_dir/$targeting_binary_source --output $scratch_dir/$targeting_binary_filename --p8");

if ($release eq "p8") {
    run_command("echo \"00000000001800000000000008000000000000000007EF80\" | xxd -r -ps - $scratch_dir/sbe.header");
}
run_command("env echo -en VERSION\\\\0 > $scratch_dir/hostboot.sha.bin");
run_command("sha512sum $hb_image_dir/img/hostboot.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot.sha.bin");
run_command("dd if=$scratch_dir/hostboot.sha.bin of=$scratch_dir/secureboot.header ibs=4k conv=sync");
run_command("dd if=/dev/zero of=$scratch_dir/hbb.footer count=1 bs=128K");
if ($release eq "p8") {
    run_command("cat $scratch_dir/sbe.header $scratch_dir/secureboot.header $hb_image_dir/img/hostboot.bin $scratch_dir/hbb.footer > $scratch_dir/hostboot.stage.bin");
} else {
    run_command("cat $scratch_dir/secureboot.header $hb_image_dir/img/hostboot.bin $scratch_dir/hbb.footer > $scratch_dir/hostboot.stage.bin");
}
run_command("head -c 524288 $scratch_dir/hostboot.stage.bin > $scratch_dir/hostboot.header.bin");

run_command("ecc --inject $hb_image_dir/img/hostboot.bin --output $scratch_dir/hostboot.bin.ecc --p8");
run_command("ecc --inject $scratch_dir/hostboot.header.bin --output $scratch_dir/hostboot.header.bin.ecc --p8");
run_command("dd if=$hb_image_dir/img/hostboot_extended.bin of=$scratch_dir/hostboot_extended.bin.pad ibs=4k count=1280 conv=sync");
run_command("ecc --inject $scratch_dir/hostboot_extended.bin.pad --output $scratch_dir/hostboot_extended.bin.ecc --p8");

run_command("env echo -en VERSION\\\\0 > $scratch_dir/hostboot_runtime.sha.bin");
run_command("sha512sum $hb_image_dir/img/hostboot_runtime.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot_runtime.sha.bin");
run_command("dd if=$scratch_dir/hostboot_runtime.sha.bin of=$scratch_dir/hostboot.temp.bin ibs=4k conv=sync");
run_command("cat $hb_image_dir/img/hostboot_runtime.bin >> $scratch_dir/hostboot.temp.bin");
run_command("dd if=$scratch_dir/hostboot.temp.bin of=$scratch_dir/hostboot_runtime.header.bin ibs=3072K conv=sync");
run_command("ecc --inject $scratch_dir/hostboot_runtime.header.bin --output $scratch_dir/hostboot_runtime.header.bin.ecc --p8");

run_command("env echo -en VERSION\\\\0 > $scratch_dir/hostboot_extended.sha.bin");
run_command("sha512sum $hb_image_dir/img/hostboot_extended.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot_extended.sha.bin");
run_command("dd if=$scratch_dir/hostboot_extended.sha.bin of=$scratch_dir/hostboot.temp.bin ibs=4k conv=sync");
run_command("cat $hb_image_dir/img/hostboot_extended.bin >> $scratch_dir/hostboot.temp.bin");
run_command("dd if=$scratch_dir/hostboot.temp.bin of=$scratch_dir/hostboot_extended.header.bin ibs=5120k conv=sync");
run_command("ecc --inject $scratch_dir/hostboot_extended.header.bin --output $scratch_dir/hostboot_extended.header.bin.ecc --p8");

#Create HBBL section
if ($release eq "p9") {
    # remove first 12K from bin, then extend.  No secure header yet for HBBL section
    run_command("tail -c +12289 $hb_image_dir/img/hostboot_bootloader.bin > $scratch_dir/hbbl.bin");
    run_command("dd if=$scratch_dir/hbbl.bin of=$scratch_dir/hbbl.bin.pad ibs=20K conv=sync");
    run_command("ecc --inject $scratch_dir/hbbl.bin.pad --output $scratch_dir/hbbl.bin.tmp.ecc --p8");
    run_command("dd if=$scratch_dir/hbbl.bin.tmp.ecc of=$scratch_dir/hbbl.bin.ecc ibs=24K conv=sync");  #0s is good ECC
}

#SBE image prep
if ($release eq "p9") {
    foreach (@ec_levels) {
        my $stop_basename = "p9n_$ec_val{$_}.sbe_seeprom";
        my $sbe_out_image = "nimbus_sbe.img";
        run_command("cp $sbe_binary_dir/$stop_basename.bin $scratch_dir/$stop_basename.bin");
        run_command("p9_ipl_build $scratch_dir/$stop_basename.bin $hb_binary_dir/p9n.ref_image.bin 0x$ec_val{$_}");
        #add pnor header
        run_command("env echo -en VERSION\\\\0 > $scratch_dir/${stop_basename}.sha.bin");
        run_command("sha512sum $scratch_dir/$stop_basename.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/${stop_basename}.sha.bin");
        run_command("dd if=$scratch_dir/${stop_basename}.sha.bin of=$scratch_dir/${stop_basename}.hdr.bin ibs=4k conv=sync");
        run_command("cat $scratch_dir/${stop_basename}.bin >> $scratch_dir/${stop_basename}.hdr.bin");

        run_command("$hb_image_dir/buildSbePart.pl --sbeOutBin $scratch_dir/$sbe_out_image --ecImg_$ec_val{$_} $scratch_dir/$stop_basename.hdr.bin");
        run_command("dd if=$scratch_dir/$sbe_out_image of=$scratch_dir/$sbe_out_image.256K ibs=256K conv=sync");
        run_command("ecc --inject $scratch_dir/$sbe_out_image.256K --output $scratch_dir/$sbe_out_image.ecc --p8");
    }
}

#Create blank binary file for HB Errorlogs (HBEL) Partition
run_command("dd if=/dev/zero bs=128K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/hbel.bin.ecc --p8");\

#Create blank binary file for GUARD Data (GUARD) Partition
run_command("dd if=/dev/zero bs=16K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/guard.bin.ecc --p8");

#Create blank binary file for NVRAM Data (NVRAM) Partition
run_command("dd if=/dev/zero bs=512K count=1 of=$scratch_dir/nvram.bin");

#Create blank binary file for MVPD Partition
run_command("dd if=/dev/zero bs=512K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/mvpd_fill.bin.ecc --p8");

#Create blank binary file for DJVPD Partition
run_command("dd if=/dev/zero bs=256K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/djvpd_fill.bin.ecc --p8");

#Add ECC Data to CVPD Data Partition
run_command("dd if=$hb_binary_dir/cvpd.bin of=$scratch_dir/hostboot.temp.bin ibs=256K conv=sync");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/cvpd.bin.ecc --p8");

#Create blank binary file for ATTR_TMP Partition
run_command("dd if=/dev/zero bs=28K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/attr_tmp.bin.ecc --p8");

#Create blank binary file for ATTR_PERM Partition
run_command("dd if=/dev/zero bs=28K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/attr_perm.bin.ecc --p8");

#Create blank binary file for OCC Partition
run_command("dd if=$occ_binary_filename of=$scratch_dir/hostboot.temp.bin ibs=1M conv=sync");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $occ_binary_filename.ecc --p8");

#Encode Ecc into CAPP Partition
run_command("dd if=$capp_binary_filename bs=144K count=1 > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/cappucode.bin.ecc --p8");

#Create blank binary file for FIRDATA Partition
run_command("dd if=/dev/zero bs=8K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/firdata.bin.ecc --p8");

#Create blank binary file for SECBOOT Partition
run_command("dd if=/dev/zero bs=128K count=1 > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/secboot.bin.ecc --p8");

#Add openpower version file
run_command("dd if=$openpower_version_filename of=$scratch_dir/openpower_version.temp ibs=4K conv=sync");
run_command("cp $scratch_dir/openpower_version.temp $openpower_version_filename");

#Copy Binary Data files for consistency
run_command("cp $hb_binary_dir/$sbec_binary_filename $scratch_dir/");
if ($release eq "p8")
{
    run_command("cp $hb_binary_dir/$wink_binary_filename $scratch_dir/");
}
else
{
    #WINK (STOP) image name is passed in in final form.  Find the pre header/ecc version
    my $stop_basename = $wink_binary_filename;
    $stop_basename =~ s/.hdr.bin.ecc//;
    run_command("env echo -en VERSION\\\\0 > $scratch_dir/${stop_basename}.sha.bin");
    run_command("sha512sum $hb_binary_dir/$stop_basename.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/${stop_basename}.sha.bin");
    run_command("dd if=$scratch_dir/${stop_basename}.sha.bin of=$scratch_dir/${stop_basename}.temp.bin ibs=4k conv=sync");
    run_command("cat $hb_binary_dir/${stop_basename}.bin >> $scratch_dir/${stop_basename}.temp.bin");
    run_command("dd if=$scratch_dir/${stop_basename}.temp.bin of=$scratch_dir/${stop_basename}.hdr.bin ibs=1M conv=sync");
    run_command("ecc --inject $scratch_dir/${stop_basename}.hdr.bin --output $scratch_dir/${stop_basename}.hdr.bin.ecc --p8");
}




#Encode Ecc into IMA_CATALOG Partition
if ($release eq "p8")
{
     run_command("dd if=$ima_catalog_binary_filename bs=36K count=1 > $scratch_dir/hostboot.temp.bin");
}
else
{
    run_command("dd if=$ima_catalog_binary_filename bs=256K count=1 > $scratch_dir/hostboot.temp.bin");
    #Create blank binary file for RINGOVD Partition
    run_command("dd if=/dev/zero bs=64K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/ringOvd.bin");
}

run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/ima_catalog.bin.ecc --p8");

#Create blank binary file for WOF/VFRT (WOFDATA) Partition  (for now)
if ($release eq "p9") {
    run_command("dd if=/dev/zero bs=2730K count=1 | tr \"\\000\" \"\\377\" >    $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/wofdata.bin.ecc --p8");
}


#END MAIN
#-------------------------------------------------------------------------





############# HELPER FUNCTIONS #################################################
# Function to first print, and then run a system command, erroring out if the
#  command does not complete successfully
sub run_command {
    my $command = shift;
    print "$command\n";
    my $rc = system($command);
    if ($rc !=0 ){
        die "Error running command: $command. Nonzero return code of ($rc) returned.\n";
    }
    return $rc;
}

# Function to remove leading and trailing whitespeace before returning that string
sub trim_string {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}
