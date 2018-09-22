#ifndef __COPUS_SHIM_H__
#define __COPUS_SHIM_H__

#include <opus.h>

int configure_encoder(OpusEncoder *enc, int bitrate, int vbr)
{
    int err;

    err = opus_encoder_ctl(enc, OPUS_SET_BITRATE(bitrate));
    err = opus_encoder_ctl(enc, OPUS_SET_VBR(vbr));

    return err;
}

int configure_decoder(OpusDecoder *dec, int gain)
{
    return opus_decoder_ctl(dec, OPUS_SET_GAIN(gain));
}


#endif
