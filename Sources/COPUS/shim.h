#ifndef __COPUS_SHIM_H__
#define __COPUS_SHIM_H__

#include <opus.h>

#define OPUS_SHIM_GENERIC_CTL0(macroname, funcname) \
static inline int opus_encoder_##funcname(OpusEncoder *st) {\
	return opus_encoder_ctl(st, OPUS_##macroname);\
}

#define OPUS_SHIM_GENERIC_CTL1(macroname, funcname, vartype, varname) \
static inline int opus_encoder_##funcname(OpusEncoder *st, vartype varname) {\
	return opus_encoder_ctl(st, OPUS_##macroname(varname));\
}

#define OPUS_SHIM_ENCODER_CTL1(macroname, funcname, vartype, varname) OPUS_SHIM_GENERIC_CTL1(macroname, funcname, vartype, varname)

#define OPUS_SHIM_DECODER_CTL1(macroname, funcname, vartype, varname)

#include "ctl_shim.h"

#define OPUS_SHIM_GENERIC_CTL0(macroname, funcname) \
static inline int opus_decoder_##funcname(OpusDecoder *st) {\
	return opus_decoder_ctl(st, OPUS_##macroname);\
}

#define OPUS_SHIM_GENERIC_CTL1(macroname, funcname, vartype, varname) \
static inline int opus_decoder_##funcname(OpusDecoder *st, vartype varname) {\
	return opus_decoder_ctl(st, OPUS_##macroname(varname));\
}

#define OPUS_SHIM_ENCODER_CTL1(macroname, funcname, vartype, varname)

#define OPUS_SHIM_DECODER_CTL1(macroname, funcname, vartype, varname) OPUS_SHIM_GENERIC_CTL1(macroname, funcname, vartype, varname)

#include "ctl_shim.h"

#endif
