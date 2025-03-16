/*
 * SCCSID=unix.c 3/15/83
 */

#include <sys/param.h>
#include <stdio.h>
#include <time.h>

#ifndef BSD
#	define bcopy(s, d, l) memcpy(d, s, l)
#	define bzero(b, l) memset(b, 0, l)
#endif


#ifdef mips
#	define xargc f77argc
#	define xargv f77argv
#endif

extern	int	xargc;
extern	char	**xargv;


/*
 * loc_ - return the address of arg
 */
int
loc_( arg )
	int *arg;
{
	return( (int) arg );
}

/*
 * time_ - c routine to call library routine time
 */
time_( iarg )
	long *iarg ;
{
	time( iarg );
}

/*
 * times_ - c routine to call library routine times
 */
void
times_( iarg )
	int *iarg ;
{
	times( iarg );
}

/*
 * xtime_ - fortran routine for character time
 */
void
xtime_( chr )
	char *chr;
{
	struct tm	*localtime();
	char		*asctime(),	*character;
	long		time();
	long		tloc,	scum;
	int		i;

        tloc = time( & scum );
        character = asctime( localtime(& tloc) );
        for( i = 11; i < 19; i++ )
                *chr++ = *( character + i );
}

/*
 * itoc
 */
static char  *
itoc( number )
	int	number;
{
	static char string[3];

	/*
	 * make a two digit string from the least significant digits of number
	 */
        string[2] = '\0';
        string[1] = number%10 + '0';
        number /= 10;
        string[0] = number%10 + '0';
        return( string );
}


/*
 * xdate_ - fortran routine for character date
 */
void
xdate_( chr )
	char	*chr;
{
	struct	tm	*localtime(),	*buffer;
	char		*asctime(),	*month,	*day,	*year,	*itoc();
	long		time();
	long		tloc,	scum;

        tloc = time( & scum );
        buffer = localtime( & tloc);
        month = itoc( buffer->tm_mon + 1 );   /* month is zero based */
        while( *month )
                *chr++ = *month++;
        *chr++ = '\/';
        day = itoc( buffer->tm_mday );
        while( *day )
                *chr++ = *day++;
        *chr++ = '\/';
        year = itoc( buffer->tm_year );
        while( *year )
                *chr++ = *year++;
}


/*
 * dblsgl - convert a complex double precision array into
 *  a single precision complex array.
 */
void
dblsgl_( cstar16, numwds )
	double	*cstar16;
	int	*numwds;
{
#if 0
	float	*cstar8;
	int	i;

	cstar8 = (float *) cstar16;
	for ( i = 0; i < (*numwds)/4; i++ ) {
		cstar8[ i ] = cstar16[ 2*i ];
	}
#endif
}

static FILE *rawfile;  /* pointer to raw file  */

/*
 * Open raw data file.  Return 1 if file is opened,
 *  return 0 if file is not opened
 */
int
iopraw_()
{
	int	i;
	char	*filename = NULL;/* name of raw file */

	for ( i=1; i < xargc; i++ ) {
		if ( *xargv[i] == '-' )
			switch ( xargv[i][1] )  {
			case 'r':
				if ( ++i < xargc )
					filename = xargv[i];
				else
					filename = "rawspice";
				break;
			default:
				fprintf( stderr, "SPICE: illegal option -%c - ignored\n",
						xargv[i][1] );
				break;
			}
	}
	if ( filename == NULL )
		return( 0 );
	if  ( (rawfile=fopen( filename, "w" )) == NULL ) {
		fprintf( stderr, "SPICE: unable to open file %s\n", filename );
		fprintf( stderr, "SPICE:  *** program terminated ***\n" );
		exit( 1 );  /* terminate program */
	}
	return( 1 );  /* normal termination */
}

/*
 * Close raw file.
 */
void
clsraw_()
{
	fclose( rawfile );
}

/*
 * Write into raw file numwds 16 bit words starting
 *  at location data
 */
void
fwrite_( data, numwds )
	char	*data;
	int	*numwds;
{
	fflush( stderr );
	fwrite( data, 2, *numwds, rawfile );
	fflush( rawfile );
}


static void mcopy();

#ifndef HASMOVE_
/*
 * Zero, copy and move for vax unix.
 */
void
move_( array1, index1, array2, index2, length )
	register char	*array1, *array2;
	register int	*length;
	int		*index1, *index2;
{
	array1 += *index1 - 1;
	array2 += *index2 - 1;
	mcopy( array2, array1, *length );
}
#endif /* HASMOVE_ */

void
zero4_( array, length )
	char		*array;
	unsigned	*length;
{
	bzero( array, *length * 4 );
}


void
zero8_( array, length )
	char		*array;
	unsigned	*length;
{
	bzero( array, *length * 8 );
}


void
zero16_( array, length )
	char		*array;
	unsigned	*length;
{
	bzero( array, *length * 8 );
}


void
copy4_( from, to, length )
	char		*from, *to;
	int		*length;
{
	mcopy( from, to, *length * 4 );
}


void
copy8_( from, to, length )
	char		*from, *to;
	int		*length;
{
	mcopy( from, to, *length * 8 );
}


void
copy16_( from, to, length )
	char		*from, *to;
	int		*length;
{
	mcopy( from, to, *length * 8 );
}



#ifdef vax

#define VAXMAXSIZE ((2<<15) - 1);

/*
 * mcopy - copy memory.
 */
static void
mcopy( from, to, size )
	char		*from,	*to;
	int		size;
{
	register int		i = VAXMAXSIZE;

	if ( size < i ) {
		asm( "	movc3 12(ap),*4(ap),*8(ap)" );
		return;
	}
	else if ( from >= to ) {
		for ( ; size > i; size -= i, to += i, from += i ) {
			asm( "	movc3 r11,*4(ap),*8(ap)" );
		}
		asm( "	movc3 12(ap),*4(ap),*8(ap)" );
		return;
	}
	else {
		to   += size;
		from += size;
		size -= i;
		for ( ; size > 0; size -= i ) {
			to   -= i;
			from -= i;
			asm( "	movc3 r11,*4(ap),*8(ap)" );
		}
		size += i;
		to   -= size;
		from -= size;
		asm( "	movc3 12(ap),*4(ap),*8(ap)" );
		return;
	}
}

#else

/*
 * mcopy - copy memory.
 */
static void
mcopy (from, to, size)
    register char *from, *to;
    register int size;
{
    register char *frome, *toe;

    if (size <= 0) return;

    frome = from + size;
    if (from >= to || frome <= to) {
	bcopy (from, to, size);
    }
    else {
	/* Source and destination overlap with destination above source.
	   Therefore a forward copy will bash later source to be copied.
	   Use a backward copy instead. */
	toe = to + size;
	if ((((unsigned)to ^ (unsigned)from) & 3) != 0 || size < 4) {
	    /* alignment of source and destination not identical;
	       use a simple byte copy. */
	    do {
		*--toe = *--frome;
	    } while (frome != from);
	}
	else {
	    while (((unsigned)toe & 3) != 0) {
		*--toe = *--frome;
		size -= 1;
	    }
	    size -= 16;
	    while (size >= 0) {
		toe -= 16;
		frome -= 16;
		((int*)toe)[3] = ((int*)frome)[3];
		((int*)toe)[2] = ((int*)frome)[2];
		((int*)toe)[1] = ((int*)frome)[1];
		((int*)toe)[0] = ((int*)frome)[0];
		size -= 16;
	    }
	    size += 16 - 4;
	    while (size >= 0) {
		toe -= 4;
		frome -= 4;
		((int*)toe)[0] = ((int*)frome)[0];
		size -= 4;
	    }
	    size += 4;
	    while (size > 0) {
		*--toe = *--frome;
		size -= 1;
	    }
	}
    }
}
#endif

