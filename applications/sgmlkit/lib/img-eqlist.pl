#! /usr/bin/perl -w
#
# $Id$
#+
#<func>
#<routinename>img-eqlist.pl
#<purpose>Process the file produced by the img.maths mode of
#    <code>.../slmaths.dsl</code>
#<description>
#  <p>Format of the input is
#  <verbatim>
#   ...LaTeX maths code
#   %%imgmath type1 label1
#   ...LaTeX maths code...
#   %%imgmath type2 label2
#   ...
#  </verbatim>
#  <p>We spit out two files, based on the filename root of the argument.
#  The SGML one conforms to a very simple DTD (with system id
#  'img-eqlist') which maps equation labels to filenames, the the LaTeX
#  one consists of a LaTeX document with one equation per page.  The
#  latter should be processed by LaTeX plus whatever dvi to gif magic
#  you need, making sure that the resulting GIF filenames match those
#  in the img-eqlist document.
#  <p>Note that you don't have complete freedom to select filenames
#  here: the names must be consistent with the names generated in
#  <code>.../slmaths.dsl</code>.  If you use the 
#  <code>pstopnm-s</code> script, then the filenames must be consistent with
#  the filenames that generates, but if you use dvi2bitmap, there's no problem
#  since this allows this script to control the output filenames,
#  so that they're guaranteed to be consistent.
#<returnvalue none>
#<parameter>infile<type>file<description>File generated by
#    <code>.../slmaths.dsl</code>, of the format described above.
#<author id=ng affiliation='Starlink, Glasgow'>Norman Gray
#-

$ident_string = "Starlink SGML system, release ((PKG_VERS))";

($#ARGV eq 0) || Usage ();

$infile = $ARGV[0];
($filenameroot = $infile) =~ s/\..*$//;

$eqcount = '001';

%eqtypes = ( 'start-inline' => '$',
	     'end-inline' => '$',
	     'start-equation' => '\begin{equation}',
	     'end-equation' => '\end{equation}',
	     'start-eqnarray' => '\begin{eqnarray}',
	     'end-eqnarray' => '\end{eqnarray}',
	     );

open (EQIN, "$infile")
    || die "Can't open $infile to read";
open (SGMLOUT, ">$filenameroot.imgeq.sgml")
    || die "Can't open $filenameroot.imgeq-sgml to write";
open (LATEXOUT, ">$filenameroot.imgeq.tex")
    || die "Can't open $filenameroot.imgeq.tex to write";

print LATEXOUT <<'EOT';
\documentclass[fleqn]{article}
\pagestyle{empty}
\mathindent=2cm
\makeatletter
\newif\if@SetEqnNum\@SetEqnNumfalse
\def\SetEqnNum#1{\global\def\Eqn@Number{#1}\global\@SetEqnNumtrue}
%\def\@eqnnum{{\normalfont \normalcolor (\Eqn@Number)}}
% leqno:
\def\@eqnnum{\if@SetEqnNum 
    \hb@xt@.01\p@{}%
    \rlap{\normalfont\normalcolor
      \hskip -\displaywidth(\Eqn@Number)}
    \global\@SetEqnNumfalse
  \else
    \relax
  \fi}
%\def\equation{$$}
%\def\endequation{\if@SetEqnNum\eqno \hbox{\@eqnnum}\global\@SetEqnNumfalse\fi 
%    $$\@ignoretrue}
\def\@@eqncr{\let\reserved@a\relax
    \ifcase\@eqcnt \def\reserved@a{& & &}\or \def\reserved@a{& &}%
     \or \def\reserved@a{&}\else
       \let\reserved@a\@empty
       \@latex@error{Too many columns in eqnarray environment}\@ehc\fi
     \reserved@a \if@SetEqnNum\@eqnnum\global\@SetEqnNumfalse\fi
     \global\@eqcnt\z@\cr}
\makeatother
\begin{document}
EOT

print SGMLOUT "<!doctype img-eqlist system 'img-eqlist'>\n<img-eqlist>\n";

$eqn = '';
while (defined($line = <EQIN>)) {
    if ($line =~ /^%%imgmath/) {
	chop($line);
	($dummy,$eqtype,$label) = split (/ /, $line);
	$outfilename = "$filenameroot.imgeq$eqcount.gif";
	# Calculate checksum.  Base the checksum on the equation type
	# as well as its contents.
	($checkeqn = $eqtype.$eqn) =~ s/\s+//sg;
	$checksum = unpack ("%32C*", $checkeqn);
	if (defined($checklist{$checksum})) {
	    # already seen this equation
	    print SGMLOUT "<img-eq label='$label' sysid='" .
		$checklist{$checksum} . "'>\n";
	} else {
	    $eqn =~ s/\s+$//s;
	    print LATEXOUT $eqtypes{'start-'.$eqtype} .
		$eqn . $eqtypes{'end-'.$eqtype} .
		    "\n\\special{dvi2bitmap outputfile $outfilename}\n\\newpage\n";
	    print SGMLOUT "<img-eq label='$label' sysid='$outfilename'>\n";
	    $checklist{$checksum} = $outfilename;
	    $eqcount++;
	}
	$eqn = '';
    } elsif ($line =~ /^%%eqno/) {
	chop ($line);
	($dummy,$eqno) = split (/ /, $line);
	$eqn .= "\\SetEqnNum{$eqno}";
    } else {
	$eqn .= $line unless ($line =~ /^\s*$/);
    }
}
print LATEXOUT "\\end{document}\n";
print SGMLOUT "</img-eqlist>\n";

close (SGMLOUT);
close (LATEXOUT);
close (EQIN);

exit 0;


sub Usage {
    die "$ident_string\nUsage: $0 filename\n";
}
