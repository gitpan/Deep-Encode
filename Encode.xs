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
    char  fastinit;

    int   noskip;
    int   argc;
    int   str_pos;
    int   counter;
    char *method;
    CV   *meth1;
    CV   *meth2;
    p_callback callback;    
    SV* argv[10 + 2];
} *pp_func;

#ifndef ARRAY_SIZE
    #define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))
#endif

void utf8_off_cb( pp_func pf, SV * data){
    if (SvUTF8(data)){
	SvUTF8_off(data);
	++(pf->counter);
    };
}
void from_to_cb( pp_func pf, SV * data){
    int ret_list_size;
    SV *decoded_sv;
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( pf->argv[0] ); //first encoding
    XPUSHs( data );

    PUTBACK;

    if ( !  pf->fastinit ){
	GV * method_glob;
	HV * encoding_stash;
	pf->meth1 = 0;
	pf->meth2 = 0;
	pf->fastinit = -1;

	encoding_stash = SvSTASH( SvRV( pf->argv[0] ) );
	method_glob = gv_fetchmeth( encoding_stash, "decode", 6, 0 );
	pf->meth1 = GvCV( method_glob );
	

	encoding_stash = SvSTASH( SvRV( pf->argv[1] ) );
	method_glob = gv_fetchmeth( encoding_stash, "encode", 6, 0 );
	pf->meth2 = GvCV( method_glob );

	if ( pf->meth1 && pf->meth2 ){
	    pf->fastinit = 1;
	};
    };

    if ( pf->fastinit == 1 ){
    	ret_list_size = call_sv( (SV *) pf->meth1, G_SCALAR);
    }
    else {
    	ret_list_size = call_method("decode", G_SCALAR);
    };

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


    if ( pf->fastinit == 1 ){
    	ret_list_size = call_sv( (SV *) pf->meth2, G_SCALAR);
    }
    else {
	ret_list_size = call_method("encode", G_SCALAR);
    }
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
void from_to_cb_00( pp_func pf, SV * data){
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
    enc_obj = 0;

    if ( SvROK(encoding) &&  sv_isobject( encoding )) {
	enc_obj = encoding;
    };
    if ( !enc_obj ) {
	PUSHMARK(SP);
	XPUSHs(encoding);
	PUTBACK;

	ret_list = call_pv("Encode::find_encoding", G_SCALAR);
	SPAGAIN;
	if (ret_list != 1)
	    croak( "Big trouble with Encode::find_encoding");
	enc_obj = POPs;	    

	if (!SvOK(enc_obj)) {
	    if ( SvPOK(encoding) )
		croak("Unknown encoding '%.*s'", SvCUR(encoding), SvPV_nolen(encoding));
	    else 
		croak("Unknown encoding ??? (is not string)");
	};
	PUTBACK;
    };
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
deep_walk_imp( SV * data, pp_func pf){
    if (SvROK(data)){
	SV * rv = (SV*) SvRV(data);
	if ( SvTYPE(rv) == SVt_PVAV ){
	    int alen;
	    SV **aitem;
	    int i;

	    alen = av_len( (AV*)rv );
	    for ( i=0; i<= alen ;++i ){
		aitem = av_fetch( (AV *) rv , i, 0);
		if (aitem){
			deep_walk_imp( *aitem, pf );
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
	    while(  (he = hv_iternext(hv)) ){
		key_str = HePV( he, key_len);
		value = HeVAL( he );
		deep_walk_imp( value, pf );
	    }	    
	}
	else {
	    deep_walk_imp( rv, pf );
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

	    if ( !pf->noskip ){
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
	    switch( pf->type ){
		case DEEP_FUNCTION:
		    pf->callback( pf, data );
		   break; 
		case DEEP_METHOD_TEMP:
		   {dSP;
		    ENTER;
		    SAVETMPS;
		    if ( ! pf->fastinit ){
			GV * method_glob;
			HV * encoding_stash;
			pf->meth1 = 0;
			pf->fastinit = -1;

			encoding_stash = SvSTASH( SvRV( pf->argv[0] ) );
			method_glob = gv_fetchmeth( encoding_stash, pf->method, strlen(pf->method), 0 );
			pf->meth1 = GvCV( method_glob );
			
			if ( pf->meth1 ){
			    pf->fastinit = 1;
			};

		    };

		    PUSHMARK(SP);

		    for ( argc = 0; argc < pf->argc; ++argc ){
			if ( argc == pf->str_pos ){
			    XPUSHs( data );
			}
			else {
			    XPUSHs( pf->argv[argc] );
			}
		    };
		    PUTBACK;

		    if ( pf->fastinit != 1){
    			ret_list_size = call_method(pf->method, G_SCALAR);
		    }
		    else {
			ret_list_size = call_sv( (SV*) pf->meth1, G_SCALAR );
		    }
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
			for ( argc = 1; argc < pf->argc; ++argc ){
			    if ( argc == pf->str_pos ){
				XPUSHs( data );
			    }
			    else {
				XPUSHs( pf->argv[argc] );
			    }
			};
		    
			// ARGUMENTS
			PUTBACK;
			call_sv( pf->argv[0], G_DISCARD );
			FREETMPS;
			LEAVE;
			};
		    break;
		case 1: // print str
		default:
		    fprintf( stderr, "'%.*s'\n", (int) plen, pstr);
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
	a_args.type = DEEP_CALL_INPLACE ;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = (SV *) get_cv( "utf8::decode", 0); 
	if ( ! a_args.argv[0] )
	    croak ("Fail locate &utf8::decode");
	deep_walk_imp( data, & a_args );        

void
deep_utf8_encode( SV *data )
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = DEEP_CALL_INPLACE ;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = (SV *) get_cv( "utf8::encode", 0); 
	if ( ! a_args.argv[0] )
	    croak ("Fail locate &utf8::encode");
	deep_walk_imp( data, & a_args );        

void
deep_from_to_00( SV *data, SV *from, SV* to )
    PROTOTYPE: $$$
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = DEEP_FUNCTION;
	a_args.callback = from_to_cb_00;
	a_args.argv[0] = find_encoding( &a_args, from );
	a_args.argv[1] = find_encoding( &a_args, to );
	deep_walk_imp( data, & a_args );        

void
deep_from_to( SV *data, SV *from, SV* to )
    PROTOTYPE: $$$
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = DEEP_FUNCTION;
	a_args.fastinit = 0;
	a_args.callback = from_to_cb;
	a_args.argv[0] = find_encoding( &a_args, from );
	a_args.argv[1] = find_encoding( &a_args, to );
	deep_walk_imp( data, & a_args );        

void
deep_encode_00( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.fastinit = -1;
	a_args.method  = "encode";
	a_args.noskip  = 0;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	deep_walk_imp( data, & a_args );        


void
deep_decode_00( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.fastinit = -1;
	a_args.method   = "decode";
	a_args.noskip   = 0;
	a_args.str_pos  = 1;
	a_args.argc     = 2;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	deep_walk_imp( data, & a_args );        



void
deep_encode( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.method  = "encode";
	a_args.noskip  = 0;
	a_args.str_pos = 1;
	a_args.fastinit = 0;
	a_args.argc    = 2;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	deep_walk_imp( data, & a_args );        


void
deep_decode( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.method   = "decode";
	a_args.noskip   = 0;
	a_args.str_pos  = 1;
	a_args.argc     = 2;
	a_args.fastinit = 0;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	deep_walk_imp( data, & a_args );        

void
deep_utf8_off( SV *data)
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
        a_args.noskip  = 1;
        a_args.type = DEEP_FUNCTION;
        a_args.callback = utf8_off_cb;
	a_args.counter = 0;
        deep_walk_imp( data, & a_args );
	mXPUSHi( a_args.counter );

