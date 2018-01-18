#!/usr/bin/perl

use strict;
use File::Basename;

#my $ecc_tool_dir = "/opt/mcp/shared/fr_FLD8-1-20140528/opt/fsp/usr/bin"; #wh_todo

my $release = "";
my $op_target_dir = "";
my $hb_image_dir = "";
my $scratch_dir = "";
my $hb_binary_dir = "";
my $sbe_binary_dir = "";
my $targeting_binary_filename = "";
my $targeting_binary_source = "";
my $sbe_binary_filename = "";
my $sbec_binary_filename = "";
my $wink_binary_filename = "";
my $occ_binary_filename = "";
my $capp_binary_filename = "";
my $ima_catalog_binary_filename = "";
my $openpower_version_filename = "";
my $payload = "";
my $xz_compression = 0;
my $wof_binary_filename = "";
my $memd_binary_filename = "";
my $payload_filename = "";
my $bootkernel_filename = "";
my $binary_dir = "";
my $secureboot = 0;
my $key_transition = "";
my $pnor_layout = "";
my $debug = 0;
my $sign_mode = "";
my $hdat_binary_filename = "";

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
    elsif (/^-scratch_dir/i){
        $scratch_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-hb_binary_dir/i){
        $hb_binary_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-sbe_binary_dir/i){
        $sbe_binary_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
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
    elsif (/^-sbe_binary_filename/i){
        $sbe_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
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
    elsif (/^-payload$/i){
        $payload = $ARGV[1] or die "Bad command line arg given: expecting a filepath to payload binary file.\n";
        shift;
    }
    elsif (/^-xz_compression/i){
        $xz_compression = 1;
    }
    elsif (/^-payload_filename/i){
        $payload_filename = $ARGV[1] or die "Bad command line arg given: expecting a filepath to payload binary file.\n";
        shift;
    }
    elsif (/^-binary_dir/i){
        $binary_dir = $ARGV[1] or die "Bad command line arg given: expecting binary dir.\n";
        shift;
    }
    elsif (/^-bootkernel_filename/i){
        $bootkernel_filename = $ARGV[1] or die "Bad command line arg given: expecting a filepath to boot kernel binary file.\n";
        shift;
    }
    elsif (/^-key_transition/i){
        $key_transition = $ARGV[1] or die "Bad command line arg given: expecting string imprint or production.\n";
        shift;
    }
    elsif (/^-pnor_layout/i){
        $pnor_layout = $ARGV[1] or die "Bad command line arg given: expecting a filepath to PNOR layout file.\n";
        shift;
    }
    elsif (/^-sign_mode/i){
        $sign_mode = $ARGV[1] or die "Bad command line arg given: expecting string development or production.\n";
        shift;
    }
    elsif (/^-wof_binary_filename/i){
        #This filename is necessary if the file exists, but if it's not given, we add a blank partition
        $wof_binary_filename = $ARGV[1];
        shift;
    }
    elsif (/^-memd_binary_filename/i){
        #This filename is necessary if the file exists, but if it's not given, we add in a blank partition
        $memd_binary_filename = $ARGV[1];
        shift;
    }
    elsif(/^-hdat_binary_filename/i){
        # This filename is necessary if the file exists, but if its not given, we add blank partition
        $hdat_binary_filename = $ARGV[1];
        shift;
    }
    else {
        print "Unrecognized command line arg: $_ \n";
        #print "To view all the options and help text run \'$program_name -h\' \n";
        exit 1;
    }
    shift;
}

# If OpenPOWER hostboot is compiled with secureboot, then -always- build with
# secure signatures (and hash page tables for applicable partitions), otherwise
# use "dummy" secure headers which lack signatures, and don't do any page table
# processing
if($release eq "p9")
{
    my $hbConfigFile = "$hb_image_dir/config.h";
    open (HB_CONFIG_FILE, "<", "$hbConfigFile")
        or die "Error opening $hbConfigFile: $!\n";
    while(<HB_CONFIG_FILE>)
    {
        if($_ =~ m/^#define +CONFIG_SECUREBOOT +1$/)
        {
            $secureboot = 1;
            last;
        }
    }
    close HB_CONFIG_FILE or die "Error closing $hbConfigFile: $!\n";
}

# Compress the skiboot lid image with lzma
if ($payload ne "")
{
    if($xz_compression)
    {
        run_command("xz -fk --stdout --check=crc32 $payload > "
            . "$payload.bin");
    }
    else
    {
        run_command("cp $payload $payload.bin");
    }
}

# Finalize HBBL logical content
if ($release eq "p9") {
    # Strip first 12k (reserved for exception vectors) off the bootloader binary
    # Note: ibs=8 conv=sync to ensure bootloader binary ends at an 8-byte
    #     boundary to align the Secure Boot cryptographic algorithms code size
    run_command("dd if=$hb_image_dir/img/hostboot_bootloader.bin of=$scratch_dir/hbbl.bin ibs=8 skip=1536 conv=sync");

    # Append Secure Boot cryptographic algorithms code size to bootloader binary
    run_command("du -b $hb_image_dir/img/hostboot_securerom.bin | cut -f1 | xargs printf \"%016x\" | sed 's/.\\{2\\}/\\\\\\\\x&/g' | xargs echo -n -e >> $scratch_dir/hbbl.bin");

    # Append Secure Boot cryptographic algorithms code to bootloader binary
    # Result:
    #    [HBBL]
    #    [padding to 8 byte alignment, 0-7 bytes (if needed)]
    #    [Secure Boot cryptographic algorithms code size, 8 bytes]
    #    [Secure Boot cryptographic algorithms code binary]
    run_command("cat $hb_image_dir/img/hostboot_securerom.bin >> $scratch_dir/hbbl.bin");
}

# SBE image prep
if ($release eq "p9") {
    run_command("python $sbe_binary_dir/sbeOpDistribute.py --install --buildSbePart $hb_image_dir/buildSbePart.pl --hw_ref_image $hb_binary_dir/p9n.ref_image.bin --sbe_binary_filename $sbe_binary_filename --scratch_dir $scratch_dir --sbe_binary_dir $sbe_binary_dir");
}
else {
    run_command("cp $hb_binary_dir/$sbe_binary_filename $scratch_dir/");
}

sub processConvergedSections {

    use constant EMPTY => "EMPTY";

    my $stop_basename = $wink_binary_filename;
    $stop_basename =~ s/.hdr.bin.ecc//;

    my $sbePreEcc = "$scratch_dir/$sbe_binary_filename";
    $sbePreEcc =~ s/.ecc//;

    # Source and destination file for each supported section
    my %sections=();
    $sections{HBBL}{in}         = "$scratch_dir/hbbl.bin";
    $sections{HBBL}{out}        = "$scratch_dir/hbbl.bin.ecc";
    $sections{HBB}{in}          = "$hb_image_dir/img/hostboot.bin";
    $sections{HBB}{out}         = "$scratch_dir/hostboot.header.bin.ecc";
    $sections{HBI}{in}          = "$hb_image_dir/img/hostboot_extended.bin";
    $sections{HBI}{out}         = "$scratch_dir/hostboot_extended.header.bin.ecc";
    $sections{HBD}{in}          = "$op_target_dir/$targeting_binary_source";
    $sections{HBD}{out}         = "$scratch_dir/$targeting_binary_filename";
    $sections{SBE}{in}          = "$sbePreEcc";
    $sections{SBE}{out}         = "$scratch_dir/$sbe_binary_filename";
    $sections{PAYLOAD}{in}      = "$payload.bin";
    $sections{PAYLOAD}{out}     = "$scratch_dir/$payload_filename";
    $sections{HCODE}{in}        = "$hb_binary_dir/${stop_basename}.bin";
    $sections{HCODE}{out}       = "$scratch_dir/${stop_basename}.hdr.bin.ecc";
    $sections{HBRT}{in}         = "$hb_image_dir/img/hostboot_runtime.bin";
    $sections{HBRT}{out}        = "$scratch_dir/hostboot_runtime.header.bin.ecc";
    $sections{OCC}{in}          = "$occ_binary_filename";
    $sections{OCC}{out}         = "$occ_binary_filename.ecc";
    $sections{BOOTKERNEL}{in}   = "$binary_dir/$bootkernel_filename";
    $sections{BOOTKERNEL}{out}  = "$scratch_dir/$bootkernel_filename";
    $sections{CAPP}{in}         = "$capp_binary_filename";
    $sections{CAPP}{out}        = "$scratch_dir/cappucode.bin.ecc";
    $sections{CVPD}{in}         = "$hb_binary_dir/cvpd.bin";
    $sections{CVPD}{out}        = "$scratch_dir/cvpd.bin.ecc";
    $sections{VERSION}{in}      = "$openpower_version_filename";
    $sections{VERSION}{out}     = "$openpower_version_filename";
    $sections{IMA_CATALOG}{in}  = "$ima_catalog_binary_filename";
    $sections{IMA_CATALOG}{out} = "$scratch_dir/ima_catalog.bin.ecc";

    # No input file, but special processing to emit optional content
    $sections{SBKT}{out}        = "$scratch_dir/SBKT.bin";

    # Blank partitions
    $sections{HBEL}{out}        = "$scratch_dir/hbel.bin.ecc";
    $sections{GUARD}{out}       = "$scratch_dir/guard.bin.ecc";
    $sections{NVRAM}{out}       = "$scratch_dir/nvram.bin";
    $sections{MVPD}{out}        = "$scratch_dir/mvpd_fill.bin.ecc";
    $sections{DJVPD}{out}       = "$scratch_dir/djvpd_fill.bin.ecc";
    $sections{ATTR_TMP}{out}    = "$scratch_dir/attr_tmp.bin.ecc";
    $sections{ATTR_PERM}{out}   = "$scratch_dir/attr_perm.bin.ecc";
    $sections{FIRDATA}{out}     = "$scratch_dir/firdata.bin.ecc";
    $sections{SECBOOT}{out}     = "$scratch_dir/secboot.bin.ecc";
    $sections{RINGOVD}{out}     = "$scratch_dir/ringOvd.bin";

    if(-e $wof_binary_filename)
    {
        $sections{WOFDATA}{in} = "$wof_binary_filename";
    }
    else
    {
        print "WARNING: WOFDATA partition is not found, including blank binary instead\n";
    }
    $sections{WOFDATA}{out}    = "$scratch_dir/wofdata.bin.ecc";

    if(-e $memd_binary_filename)
    {
        $sections{MEMD}{in}    = "$memd_binary_filename";
    }
    else
    {
        print "WARNING: MEMD partition is not found, including blank binary instead\n";
    }
    $sections{MEMD}{out}       = "$scratch_dir/memd_extra_data.bin.ecc";
   
    # SMC COPY SAME ideas for hdat 
    if(-e $hdat_binary_filename)
    {
        $sections{HDAT}{in}    = "$hdat_binary_filename";
    }
    else
    {
        print "WARNING: HDAT partition is not found, including blank binary instead\n";
    }
    $sections{HDAT}{out}       = "$scratch_dir/hdat.bin.ecc";

    # Build up the system bin files specification
    my $system_bin_files;
    foreach my $section (keys %sections)
    {
        if(exists $sections{$section}{in})
        {
            $_ = $sections{$section}{in};
            if((/ecc/i) || (/pad/i))
            {
                die "Input file's name, $sections{$section}{in}, suggests padding "
                    . "or ECC, neither of which is allowed.";
            }
        }

        # If the system bin files specification has nothing in it yet, avoid
        # adding a separator
        my $separator = length($system_bin_files) ? "," : "";

        # If no input bin file then the pnor script handles creating the content
        if(!exists $sections{$section}{in})
        {
             # Build up the systemBinFiles argument
             $system_bin_files .= "$separator$section=".EMPTY;
        }
        else
        {
            # Stage the input file
            run_command("cp $sections{$section}{in} "
             . "$scratch_dir/$section.staged");

            # If secureboot compile, there can be extra protected
            # and unprotected versions of the input to stage
            if(-e "$sections{$section}{in}.protected")
            {
                run_command("cp $sections{$section}{in}.protected "
                    . "$scratch_dir/$section.staged.protected");
            }

            if(-e "$sections{$section}{in}.unprotected")
            {
                run_command("cp $sections{$section}{in}.unprotected "
                    . "$scratch_dir/$section.staged.unprotected");
            }
            # Build up the systemBinFiles argument
            $system_bin_files .= "$separator$section=$scratch_dir/"
                . "$section.staged";
        }
    }

    if(length($system_bin_files))
    {
        # Point to the location of the signing tools
        $ENV{'DEV_KEY_DIR'}="$ENV{'HOST_DIR'}/etc/keys/";
        $ENV{'SIGNING_DIR'} = "$ENV{'HOST_DIR'}/usr/bin/";
        $ENV{'SIGNING_TOOL_EDITION'} = "community";

        # Determine whether to securely sign the images
        my $securebootArg = $secureboot ? "--secureboot" : "";

        # Determine whether a key transition should take place
        my $keyTransitionArg = $key_transition ne "" ? "--key-transition $key_transition" : "";
        # Determine which type of signing to use
        my $signModeArg = $sign_mode ne "" ? "--sign-mode $sign_mode" : "";

        # Process each image
        my $cmd =   "cd $scratch_dir && "
                  . "$hb_image_dir/genPnorImages.pl "
                      . "--binDir $scratch_dir "
                      . "--systemBinFiles $system_bin_files "
                      . "--pnorLayout $pnor_layout "
                      . "$securebootArg $keyTransitionArg $signModeArg "
                      . "--hwKeyHashFile $hb_image_dir/imprintHwKeyHash";

        # Print context not visible in the actual command
        if($debug)
        {
            print STDOUT "SIGNING_DIR: " . $ENV{'SIGNING_DIR'} . "\n";
            print STDOUT "DEV_KEY_DIR: " . $ENV{'DEV_KEY_DIR'} . "\n";
            print STDOUT "SIGNING_TOOL_EDITION: "
                . $ENV{'SIGNING_TOOL_EDITION'} . "\n";
        }

        run_command($cmd);

        # Copy each output file to its final destination
        foreach my $section (keys %sections)
        {
            # Don't copy if output file path is same as generated file
            next if("$sections{$section}{out}" eq "$scratch_dir/$section.bin");
            run_command("cp $scratch_dir/$section.bin "
                . "$sections{$section}{out}");
        }
    }
}

if ($release ne "p8") {
    processConvergedSections();
}
else
{
    # Inject ECC into HBD (hostboot targeting) output binary
    run_command("dd if=$op_target_dir/$targeting_binary_source of=$scratch_dir/$targeting_binary_source ibs=4k conv=sync");
    run_command("ecc --inject $scratch_dir/$targeting_binary_source --output $scratch_dir/$targeting_binary_filename --p8");

    # Add SBE/normal headers and inject ECC into HBB (hostboot base) partition binary
    run_command("echo \"00000000001800000000000008000000000000000007EF80\" | xxd -r -ps - $scratch_dir/sbe.header");
    run_command("env echo -en VERSION\\\\0 > $scratch_dir/hostboot.sha.bin");
    run_command("sha512sum $hb_image_dir/img/hostboot.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot.sha.bin");
    run_command("dd if=$scratch_dir/hostboot.sha.bin of=$scratch_dir/secureboot.header ibs=4k conv=sync");
    run_command("cat $scratch_dir/sbe.header $scratch_dir/secureboot.header $hb_image_dir/img/hostboot.bin > $scratch_dir/hostboot.stage.bin");
    run_command("dd if=$scratch_dir/hostboot.stage.bin of=$scratch_dir/hostboot.header.bin ibs=512k conv=sync");
    run_command("ecc --inject $hb_image_dir/img/hostboot.bin --output $scratch_dir/hostboot.bin.ecc --p8");
    run_command("ecc --inject $scratch_dir/hostboot.header.bin --output $scratch_dir/hostboot.header.bin.ecc --p8");

    # Inject ECC into HBI (hostboot extended) output binary
    run_command("dd if=$hb_image_dir/img/hostboot_extended.bin of=$scratch_dir/hostboot_extended.bin.pad ibs=4k count=1280 conv=sync");
    run_command("ecc --inject $scratch_dir/hostboot_extended.bin.pad --output $scratch_dir/hostboot_extended.bin.ecc --p8");

    # Add header and inject ECC into HBRT (hostboot runtime) partition binary
    run_command("env echo -en VERSION\\\\0 > $scratch_dir/hostboot_runtime.sha.bin");
    run_command("sha512sum $hb_image_dir/img/hostboot_runtime.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot_runtime.sha.bin");
    run_command("dd if=$scratch_dir/hostboot_runtime.sha.bin of=$scratch_dir/hostboot.temp.bin ibs=4k conv=sync");
    run_command("cat $hb_image_dir/img/hostboot_runtime.bin >> $scratch_dir/hostboot.temp.bin");
    run_command("dd if=$scratch_dir/hostboot.temp.bin of=$scratch_dir/hostboot_runtime.header.bin ibs=3072K conv=sync");
    run_command("ecc --inject $scratch_dir/hostboot_runtime.header.bin --output $scratch_dir/hostboot_runtime.header.bin.ecc --p8");

    # Add header and inject ECC into HBI (hostboot extended) partition binary
    run_command("env echo -en VERSION\\\\0 > $scratch_dir/hostboot_extended.sha.bin");
    run_command("sha512sum $hb_image_dir/img/hostboot_extended.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot_extended.sha.bin");
    run_command("dd if=$scratch_dir/hostboot_extended.sha.bin of=$scratch_dir/hostboot.temp.bin ibs=4k conv=sync");
    run_command("cat $hb_image_dir/img/hostboot_extended.bin >> $scratch_dir/hostboot.temp.bin");
    run_command("dd if=$scratch_dir/hostboot.temp.bin of=$scratch_dir/hostboot_extended.header.bin ibs=5120k conv=sync");
    run_command("ecc --inject $scratch_dir/hostboot_extended.header.bin --output $scratch_dir/hostboot_extended.header.bin.ecc --p8");

    # Inject ECC into OCC partition binary
    run_command("dd if=$occ_binary_filename of=$scratch_dir/hostboot.temp.bin ibs=1M conv=sync");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $occ_binary_filename.ecc --p8");

    # Inject ECC into CAPP partition binary
    run_command("dd if=$capp_binary_filename bs=144K count=1 > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/cappucode.bin.ecc --p8");

    # Stage PAYLOAD partition
    run_command("cp $payload.bin $scratch_dir/$payload_filename");

    # Stage BOOTKERNEL partition
    run_command("cp $binary_dir/$bootkernel_filename $scratch_dir/$bootkernel_filename");

    # Stage WINK partition
    run_command("cp $hb_binary_dir/$wink_binary_filename $scratch_dir/");

    # Inject ECC into CVPD partition binary
    run_command("dd if=$hb_binary_dir/cvpd.bin of=$scratch_dir/hostboot.temp.bin ibs=256K conv=sync");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/cvpd.bin.ecc --p8");

    # Stage VERSION partition
    run_command("dd if=$openpower_version_filename of=$scratch_dir/openpower_version.temp ibs=4K conv=sync");
    run_command("cp $scratch_dir/openpower_version.temp $openpower_version_filename");

    # Inject ECC into IMA_CATALOG partition binary
    run_command("dd if=$ima_catalog_binary_filename bs=36K count=1 > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/ima_catalog.bin.ecc --p8");

    # Create blank binary file for HBEL (Hostboot error logs) partition
    run_command("dd if=/dev/zero bs=128K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/hbel.bin.ecc --p8");\

    # Create blank binary file for GUARD partition
    run_command("dd if=/dev/zero bs=16K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/guard.bin.ecc --p8");

    # Create blank binary file for NVRAM partition
    run_command("dd if=/dev/zero bs=512K count=1 of=$scratch_dir/nvram.bin");

    # Create blank binary file for MVPD partition
    run_command("dd if=/dev/zero bs=512K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/mvpd_fill.bin.ecc --p8");

    # Create blank binary file for DJVPD partition
    run_command("dd if=/dev/zero bs=256K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/djvpd_fill.bin.ecc --p8");

    # Create blank binary file for ATTR_TMP partition
    run_command("dd if=/dev/zero bs=28K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/attr_tmp.bin.ecc --p8");
    
    # Create blank binary file for ATTR_PERM partition
    run_command("dd if=/dev/zero bs=28K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/attr_perm.bin.ecc --p8");

    # Create blank binary file for FIRDATA partition
    run_command("dd if=/dev/zero bs=8K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/firdata.bin.ecc --p8");

    # Create blank binary file for SECBOOT partition
    run_command("dd if=/dev/zero bs=128K count=1 > $scratch_dir/hostboot.temp.bin");
    run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/secboot.bin.ecc --p8");
}

#Stage SBEC image
run_command("cp $hb_binary_dir/$sbec_binary_filename $scratch_dir/");

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
