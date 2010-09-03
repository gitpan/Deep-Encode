#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct pp_args{
    char  type;
    int   argc;
    int   str_pos;
    SV* argv[10 + 2];
} *pp_func;

#ifndef ARRAY_SIZE
    #define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))
#endif

//typedef struct pp_args *pp_func;

void 
print_str_imp( SV * data, pp_func p_func){
    if (SvROK(data)){
	SV * rv = (SV*) SvRV(data);
	if ( SvTYPE(rv) == SVt_PVAV ){
	    int alen;
	    int i;
	    SV **aitem;
	    alen = av_len( (AV*)rv );
	    for ( i=0; i<= alen ;++i ){
		SV** aitem = av_fetch( (AV *) rv , i, 0);
		if (aitem){
		    print_str_imp( *aitem, p_func );
		}
	    }
	}
	else if ( SvTYPE(rv) == SVt_PVHV ){
	    STRLEN key_len;
	    HV *hv;
	    HE *he;
	    SV * value;
	    char * key_str;
	    hv = (HV *) rv;
	    hv_iterinit(hv);
	    while( he = hv_iternext(hv)){
		key_str = HePV( he, key_len);
		value = HeVAL( he );
		print_str_imp( value, p_func );
	    }	    
	}
	else {
	    print_str_imp( rv, p_func );
	}
    }
    else {
	if ( SvPOK(data) ){
	    unsigned char *pstr;
	    int argc;
	    STRLEN plen;
	    STRLEN curr;
	    int skip;
	    pstr = (unsigned char *) SvPV(data, plen);
	    switch( p_func->type ){
		case 2:
		    skip = 1;
		    for( curr = 0; curr < plen; ++ curr ){
			if ( pstr[curr] >= 128 ){
			    skip = 0;
			    break;
			};			
		    }
		    // fprintf( stderr, "Skip=%d\n", skip );
		    if (! skip ){
			dSP;
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			for ( argc = 1; argc < p_func->argc; ++argc ){
			    if ( argc == p_func->str_pos ){
				XPUSHs( data );
			    }
			    else {
    				XPUSHs( p_func->argv[argc] );
			    }
			};
			
			// ARGUMENTS
			PUTBACK;
			call_sv( p_func->argv[0], G_DISCARD );
			FREETMPS;
			LEAVE;
		    }
		    break;
		case 1: // print str
		default:
		    fprintf( stderr, "'%.*s'\n", plen, pstr);
		    break;
	    }
	}
    }
}

MODULE = Deep::Encode		PACKAGE = Deep::Encode		

void 
print_str( SV * data)
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
	a_args.type = 1;
	print_str_imp( data, & a_args );        


void deep_utf8_decode( SV *data )
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
	a_args.type = 2;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = sv_2mortal( newSVpv("utf8::decode",0) );
	print_str_imp( data, & a_args );        


void deep_utf8_encode( SV *data )
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
	a_args.type = 2;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = sv_2mortal( newSVpv("utf8::encode",0) );
	print_str_imp( data, & a_args );        

void deep_from_to( SV *data, SV *from, SV* to )
    PROTOTYPE: $$$
    PPCODE:
	struct pp_args a_args;
	a_args.type = 2;
	a_args.str_pos = 1;
	a_args.argc    = 4;
	a_args.argv[0] = sv_2mortal( newSVpv("Encode::from_to",0) );
	a_args.argv[1] = 0;
	a_args.argv[2] = from;
	a_args.argv[3] = to;

	print_str_imp( data, & a_args );        

void deep_str_process( SV *data, SV* sub, ... )
    PROTOTYPE: $&;@
    INIT: 
    int i;
    PPCODE:
	struct pp_args a_args;
	a_args.type = 2;
	a_args.str_pos = 1;
	a_args.argc    = 4;
	a_args.argv[0] = sub;
	a_args.argv[1] = 0;
	if ( items > ARRAY_SIZE( a_args.argv) ){
	    croak("deep_str_process don't allow more than %d arguments", ARRAY_SIZE( a_args.argv) -2 );
	}
	for (i=2; i< ARRAY_SIZE( a_args.argv); ++i ){
	    a_args.argv[i] = ST(i);
	}

	print_str_imp( data, & a_args );        

