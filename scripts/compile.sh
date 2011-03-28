#!/bin/bash 
set -o errexit
set -o nounset
newFilenames=
FILENAMESHIFT=0
#trap cleanup SIGHUP SIGINT SIGTERM
tabs="\t\t\t"
usage="Usage: %s: [options] file... [options]\n"
usage+="Options:\n"

function addOption {
	len=${#1}
	padding=$((25 - len))
	format="  $1%${padding}s%s\n"
	newline=
	printf -v newline "$format" "" "$2"
	usage+=$newline
}

addOption "-c" "Compile and assemble, but do not link"
#addOption "-d" "Compile with semantic profiling"
addOption "-i" "Include support for runtime file io"
addOption "-l <name>" "This option is completely ignored"
addOption "-s" "Do not link against the standard library"
addOption "-o <file>" "Place the output into <file>"
addOption "-v" "Do not delete intermediate files"
#addOption "-v" "Prints version information"
addOption "-w" "Do not print warning messages"

usage+="\nThere are additional options available at runtime.  Try running your compiled program with HELP set (HELP=1 ./a.out) to see these.\n"


compileOnlyFlag=
dumpFlag=
inputFile=
ioFlag=
libFlag=
modelFlag=
oflag=
oval=
warnFlag=

myDirectory=`dirname $0`
username=`id -un`
baseMaterial=`mktemp -t $username-fsl-c-base.XXXXXXXXXXX`
programTemp=`mktemp -t $username-fsl-c-prog.XXXXXXXXXXX`
linkTemp=`mktemp -t $username-fsl-c-link.XXXXXXXXXXX`
stdlib="$myDirectory/lib/clib.o"
baseName=

function die {
	cleanup
	echo "$1" >&2
	exit $2
}
function cleanup {
	rm -f $baseMaterial
	rm -f $programTemp
	rm -f $linkTemp
}
function usage {
	die "`printf \"$usage\" $(basename $0)`" 2
}

function getoptsFunc {
	while getopts ':cil:mo:svw' OPTION
	do
		case $OPTION in
		c)	compileOnlyFlag="-c";;
		#d)	
		i)	ioFlag=1;;
		l)	;;
		m)	modelFlag="-m";;
		o)	oflag=1
			oval="$OPTARG"
			;;
		s)	libFlag="-s";;
		v)	dumpFlag="-v";;
			# printf "kcc version 0.0.1"
			# exit 0
			# ;;
		w)	warnFlag="-w";;
		?)	usage;;
	  esac
	done
}

function setNewFilenames {
	newFilenames=
	FILENAMESHIFT=0
	set +o nounset
	
	# while the argument doesn't start with a hyphen and it is an existant file...
	#echo "file1=$1"
	while [[ ! "$1" == -* ]] && [ ! -z "$1" ]
	do
		if [ ! -f "$1" ]; then
			echo "$1: No such file or directory"
			newFilenames=
			return
		fi
		((FILENAMESHIFT++))
		#echo "file=$1"
		newFilenames="$newFilenames $1"
		shift 1
	done
	#echo "inner newFilenames=$newFilenames"
	set -o nounset
}
# this gets generated by the gcc tests
# kcc ./gcc.full/20000112-1.c  -w    -lm   -o /tmp/20000112-1.x0

getoptsFunc "$@"
shift $(($OPTIND - 1))
OPTIND=1
setNewFilenames "$@"
shift $FILENAMESHIFT
arguments="$newFilenames"

getoptsFunc "$@"
shift $(($OPTIND - 1))

if [ -z "$arguments" ]; then # if after reading a round of arguments there isn't anything left that could be a filename...
	usage
fi



#echo "Checking readlink version..."
READLINK=
set +o errexit
READLINK=`which greadlink 2> /dev/null`
if [ "$?" -ne 0 ]; then
	#echo "You don't have greadlink.  I'll look for readlink."
	READLINK=`which readlink 2> /dev/null`
	if [ "$?" -ne 0 ]; then
		die "No readlink/greadlink program found.  Cannot continue." 9
	fi 
fi
set -o errexit
#echo $READLINK
# echo "before: $linkTemp"
# this helps set the path correctly on windows
set +o errexit
newLinkTemp=`cygpath -u $linkTemp &> /dev/null` 
if [ "$?" -eq 0 ]; then
	linkTemp=`cygpath -u $linkTemp`
fi
set -o errexit
# echo "after: $linkTemp"
#echo "arguments=$arguments"
compiledPrograms=
for ARG in $arguments
do
	#echo "compiling $ARG"
	set +o errexit
	inputFile=`$READLINK -f $ARG`
	if [ "$?" -ne 0 ]; then
		die "`printf \"Input file %s does not exist\n\" $ARG`" 1
	fi
	inputDirectory=`dirname $inputFile`
	baseName=`basename $inputFile .c`
	maudeInput=$inputDirectory/$baseName.gen.maude
	localOval="$baseName.o"
	set -o errexit

	set +o errexit
	$myDirectory/compileProgram.sh $warnFlag $dumpFlag $modelFlag $inputFile
	if [ "$?" -ne 0 ]; then
		die "compilation failed" 3
	fi
	set -o errexit
	
	mv program-$baseName-compiled.maude $localOval
	compiledPrograms="$compiledPrograms $localOval"
	if [ "$compileOnlyFlag" ]; then
		if [ "$oflag" ]; then
			mv $localOval $oval
		fi
	fi
done

#echo "compiledPrograms=$compiledPrograms"
if [ ! "$compileOnlyFlag" ]; then
	if [ ! "$oflag" ]; then
		oval="a.out"
	fi
	mv $linkTemp "$linkTemp.maude"
	linkTemp="$linkTemp.maude"
	echo "mod C-program-linked is including C ." > $linkTemp
	if [ "$libFlag" ]; then
		perl $myDirectory/link.pl $compiledPrograms >> $linkTemp
	else
		perl $myDirectory/link.pl $compiledPrograms $stdlib >> $linkTemp
	fi
	echo "endm" >> $linkTemp
	#echo $linkTemp
	#mv program-$baseName-linked.tmp program-$baseName-linked.maude
	if [ ! "$dumpFlag" ]; then
		rm -f $compiledPrograms
	fi
	echo "load $myDirectory/c-total" > $baseMaterial
	echo "load $linkTemp" >> $baseMaterial
	
	# no more polyglot :(  now we use a script that copies all the maude to its own file
	cat $myDirectory/programRunner.sh \
		| sed "s?EXTERN_WRAPPER?$myDirectory/wrapper.pl?g" \
		| sed "s?EXTERN_SEARCH_GRAPH_WRAPPER?$myDirectory/graphSearch.pl?g" \
		| sed "s?EXTERN_COMPILED_WITH_IO?$ioFlag?g" \
		| sed "s?EXTERN_IO_SERVER?$myDirectory/fileserver.pl?g" \
		| sed "s?EXTERN_SCRIPTS_DIR?$myDirectory?g" \
		> $programTemp
	echo >> $programTemp
	cat $baseMaterial | perl $myDirectory/slurp.pl >> $programTemp
	if [ ! "$dumpFlag" ]; then
		rm -f $linkTemp
	fi
	chmod u+x $programTemp
	mv $programTemp $oval
fi
cleanup




