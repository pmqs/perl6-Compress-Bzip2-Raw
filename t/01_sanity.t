use v6;
use Test;
use NativeCall;
use Compress::Bzip2::Raw;
plan *;

constant $file-location = $*TMPDIR.child('test.bz2');

my int32 $bzerror;
my $text = "Text string.";
my buf8 $write_buffer = buf8.new($text.encode);
my $size = $write_buffer.elems;

## Writing.
# Open.
my $handle = fopen($file-location.Str, "wb");
my $bz = bzWriteOpen($bzerror, $handle, 1, 0, 0);
is $bzerror, BZ_OK, 'Stream was opened.'
  or diag "bzWriteOpen returned $bzerror";
if $bzerror != BZ_OK { bzWriteClose($bzerror, $bz) };

# Writing.
BZ2_bzWrite($bzerror, $bz, $write_buffer, $size);
ok $bzerror == BZ_OK, 'No errors in writing.';
if $bzerror == BZ_IO_ERROR { bzWriteClose($bzerror, $bz) }

# Closing.
my uint32 $bytesIn;
my uint32 $bytesOut;
bzWriteClose($bzerror, $bz, 0, $bytesIn, $bytesOut);
ok $bzerror == BZ_OK, 'Stream was closed properly.';
is fclose($handle), 0, "fclose returned 0";

## Reading.
# Opening.
$handle = fopen($file-location.Str, "rb");
$bz = bzReadOpen($bzerror, $handle);
ok $bzerror == BZ_OK, 'Stream was opened.';
if $bzerror != BZ_OK { BZ2_bzReadClose($bzerror, $bz) }

# Reading.
my $read_buffer = buf8.new();
$read_buffer[$size-1] = 0;
my $len = BZ2_bzRead($bzerror, $bz, $read_buffer, $size);
ok $bzerror == BZ_STREAM_END, 'No errors at reading';

my $decoded_text = $read_buffer.decode;
is $decoded_text, $text, 'Text is correct.';

# Closing.
BZ2_bzReadClose($bzerror, $bz);
ok $bzerror == BZ_OK, 'Stream was closed properly.';
is fclose($handle), 0, "fclose returned 0";

done-testing;
