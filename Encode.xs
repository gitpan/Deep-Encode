#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#define DEEP_FUNCTION      4
#define DEEP_METHOD_TEMP   3
#define DEEP_CALL_INPLACE  2
#define DEEP_PRINT_STRING  1 
struct pp_args;
typedef void (*p_callback)(struct pp_args*, SV *);

typedef struct pp_args{
    char  type;
    int   noskip;
    int   argc;
    int   str_pos;
    char *method;
    p_callback callback;    
    SV* argv[10 + 2];
} *pp_func;

#ifndef ARRAY_SIZE
    #define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))
#endif

void from_to_cb( pp_func pf, SV * data){
    int argc;
    int ret_list_size;
    SV *decoded_sv;
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( pf->argv[0] ); //first encoding
    XPUSHs( data );

    PUTBACK;

    ret_list_size = call_method("decode", G_SCALAR);
    SPAGAIN;
    if (ret_list_size != 1){
	croak( "A big trouble");
    }
    decoded_sv = POPs;
    PUTBACK;

    PUSHMARK(SP);
    XPUSHs( pf->argv[1] );
    XPUSHs( decoded_sv );
    PUTBACK;


    ret_list_size = call_method("encode", G_SCALAR);
    SPAGAIN;
    if (ret_list_size != 1){
	croak( "A big trouble");
    }
    decoded_sv = POPs;
    sv_setsv( data , decoded_sv );
    PUTBACK;
    FREETMPS;
    LEAVE;
};

//static U8* good_encoding=",cp1251,latin1,utf8,windows1251,cp866,";
SV *find_encoding(pp_func pfunc, SV* encoding )
{
    int ret_list;
    SV *enc_obj;

    dSP;
    PUSHMARK(SP);
    XPUSHs(encoding);
    PUTBACK;

    ret_list = call_pv("Encode::find_encoding", G_SCALAR);
    SPAGAIN;
    if (ret_list != 1)
	croak( "Big trouble with Encode::find_encoding");
    enc_obj = POPs;	    

    if (!SvOK(enc_obj))
	if ( SvPOK(encoding) )
	    croak("Unknown encoding '%.*s'", SvCUR(encoding), SvPV_nolen(encoding));
	else 
	    croak("Unknown encoding ??? (is not string)");

    PUTBACK;
    if (! pfunc->noskip ){
	SV *name_sv;
	char *name;
	STRLEN name_len;

	PUSHMARK(SP);
	XPUSHs(enc_obj);
	PUTBACK;

	ret_list = call_method("name", G_SCALAR);
	SPAGAIN;
	if (ret_list != 1)
	    croak( "Big trouble with Encode::find_encoding");
	name_sv = POPs;	    
	PUTBACK;
	name = SvPV(name_sv, name_len);
	switch( name_len ){
	    case 6:
		if (strEQ("cp1251", name ))
		    return enc_obj;
		break;
	    case 5:
		if (strEQ("cp866", name ))
		    return enc_obj;
		break;
	    case 4:
		if (strEQ("utf8", name ))
		    return enc_obj;
		break;
	    case 10:
		if (strEQ("iso-8859-1", name)){
		    return enc_obj;
		};
		break;
	    default:
		break;
	};
	pfunc->noskip = 1;
	
    };
    return enc_obj;
};

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
	    int ret_list_size;
	    pstr = (unsigned char *) SvPV(data, plen);

	    if ( !p_func->noskip ){
		skip = 1;
		for( curr = 0; curr < plen; ++ curr ){
		    if ( pstr[curr] >= 128 ){
			skip = 0;
			break;
		    };			
		}
	    }
	    else {
		skip = 0;
	    };
	    if (!skip) {
	    switch( p_func->type ){
		case DEEP_FUNCTION:
		    p_func->callback( p_func, data );
		   break; 
		case DEEP_METHOD_TEMP:
		   {dSP;
		    ENTER;
		    SAVETMPS;

		    PUSHMARK(SP);
		    for ( argc = 0; argc < p_func->argc; ++argc ){
			if ( argc == p_func->str_pos ){
			    XPUSHs( data );
			}
			else {
			    XPUSHs( p_func->argv[argc] );
			}
		    };
		    PUTBACK;

		    ret_list_size = call_method(p_func->method, G_SCALAR);
		    SPAGAIN;
		    if (ret_list_size != 1){
			croak( "A big trouble");
		    }
		    sv_setsv( data, POPs );
		    PUTBACK;

		    FREETMPS;
		    LEAVE;
		   };
		    break;
		case DEEP_CALL_INPLACE:
		    {
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
			};
		    break;
		case 1: // print str
		default:
		    fprintf( stderr, "'%.*s'\n", plen, pstr);
		    break;
		}
	    }
	}
    }
};

MODULE = Deep::Encode		PACKAGE = Deep::Encode		


void 
deep_utf8_decode( SV *data )
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = 2;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = sv_2mortal( newSVpv("utf8::decode",0) );
	print_str_imp( data, & a_args );        

void
deep_utf8_encode( SV *data )
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = 2;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = sv_2mortal( newSVpv("utf8::encode",0) );
	print_str_imp( data, & a_args );        

void
deep_from_to( SV *data, SV *from, SV* to )
    PROTOTYPE: $$$
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = DEEP_FUNCTION;
	a_args.callback = from_to_cb;
	a_args.argv[0] = find_encoding( &a_args, from );
	a_args.argv[1] = find_encoding( &a_args, to );
	print_str_imp( data, & a_args );        

void
deep_from_to_( SV *data, SV *from, SV* to )
    PROTOTYPE: $$$
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = DEEP_CALL_INPLACE;
	a_args.str_pos = 1;
	a_args.argc    = 4;
	a_args.argv[0] = sv_2mortal( newSVpv("Encode::from_to",0) );
	a_args.argv[1] = 0;
	a_args.argv[2] = from;
	a_args.argv[3] = to;

	print_str_imp( data, & a_args );        

void
deep_encode( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	int ret_list;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.method  = "encode";
	a_args.noskip  = 0;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	print_str_imp( data, & a_args );        

void
deep_decode( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	int ret_list;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.method  = "decode";
	a_args.noskip  = 0;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	print_str_imp( data, & a_args );        

void
deep_str_process( SV *data, SV* sub, ... )
    PROTOTYPE: $&;@
    INIT: 
    int i;
    PPCODE:
	struct pp_args a_args;
	a_args.type = DEEP_CALL_INPLACE;
	a_args.noskip  = 1;
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

