// Define macros for OPUS_SHIM_GENERIC_CTL0, OPUS_SHIM_GENERIC_CTL1, OPUS_SHIM_ENCODER_CTL1, and OPUS_SHIM_DECODER_CTL1 and then include this file
// GENERIC are for both decoders and encoders, ENCODER is for encoders only, DECODER is for decoders only.  0/1 is the number of arguments
// Arguments are name of opus macro minus the OPUS_ prefix, the same name lowercased, the type of the argument, and the argument variable name

#ifndef OPUS_SHIM_GENERIC_CTL0
#  error "Must define OPUS_SHIM_GENERIC_CTL0(macroname, funcname) before including this file."
#endif

#ifndef OPUS_SHIM_GENERIC_CTL1
#  error "Must define OPUS_SHIM_GENERIC_CTL1(macroname, funcname, vartype, varname) before including this file."
#endif

#ifndef OPUS_SHIM_ENCODER_CTL1
#  error "Must define OPUS_SHIM_ENCODER_CTL1(macroname, funcname, vartype, varname) before including this file."
#endif

#ifndef OPUS_SHIM_DECODER_CTL1
#  error "Must define OPUS_SHIM_DECODER_CTL1(macroname, funcname, vartype, varname) before including this file."
#endif

OPUS_SHIM_GENERIC_CTL0(RESET_STATE, reset_state)
OPUS_SHIM_GENERIC_CTL1(GET_FINAL_RANGE, get_final_range, opus_uint32*, range)
OPUS_SHIM_GENERIC_CTL1(GET_BANDWIDTH, get_bandwidth, opus_int32*, bandwidth)
OPUS_SHIM_GENERIC_CTL1(GET_SAMPLE_RATE, get_sample_rate, opus_int32*, sampleRate)
OPUS_SHIM_GENERIC_CTL1(SET_PHASE_INVERSION_DISABLED, set_phase_inversion_disabled, opus_int32, phaseInversionDisabled)
OPUS_SHIM_GENERIC_CTL1(GET_PHASE_INVERSION_DISABLED, get_phase_inversion_disabled, opus_int32*, phaseInversionDisabled)
OPUS_SHIM_ENCODER_CTL1(SET_COMPLEXITY, set_complexity, opus_int32, complexity)
OPUS_SHIM_ENCODER_CTL1(GET_COMPLEXITY, get_complexity, opus_int32*, complexity)
OPUS_SHIM_ENCODER_CTL1(SET_BITRATE, set_bitrate, opus_int32, bitrate)
OPUS_SHIM_ENCODER_CTL1(GET_BITRATE, get_bitrate, opus_int32*, bitrate)
OPUS_SHIM_ENCODER_CTL1(SET_VBR, set_vbr, opus_int32, vbr)
OPUS_SHIM_ENCODER_CTL1(GET_VBR, get_vbr, opus_int32*, vbr)
OPUS_SHIM_ENCODER_CTL1(SET_VBR_CONSTRAINT, set_vbr_constraint, opus_int32, constraint)
OPUS_SHIM_ENCODER_CTL1(GET_VBR_CONSTRAINT, get_vbr_constraint, opus_int32*, constraint)
OPUS_SHIM_ENCODER_CTL1(SET_FORCE_CHANNELS, set_force_channels, opus_int32, channels)
OPUS_SHIM_ENCODER_CTL1(GET_FORCE_CHANNELS, get_force_channels, opus_int32*, channels)
OPUS_SHIM_ENCODER_CTL1(SET_MAX_BANDWIDTH, set_max_bandwidth, opus_int32, bandwidth)
OPUS_SHIM_ENCODER_CTL1(GET_MAX_BANDWIDTH, get_max_bandwidth, opus_int32*, bandwidth)
OPUS_SHIM_ENCODER_CTL1(SET_BANDWIDTH, set_bandwidth, opus_int32*, bandwidth)
OPUS_SHIM_ENCODER_CTL1(SET_SIGNAL, set_signal, opus_int32, signal)
OPUS_SHIM_ENCODER_CTL1(GET_SIGNAL, get_signal, opus_int32*, signal)
OPUS_SHIM_ENCODER_CTL1(SET_APPLICATION, set_application, opus_int32, application)
OPUS_SHIM_ENCODER_CTL1(GET_APPLICATION, get_application, opus_int32*, application)
OPUS_SHIM_ENCODER_CTL1(GET_LOOKAHEAD, get_lookahead, opus_int32*, lookahead)
OPUS_SHIM_ENCODER_CTL1(SET_INBAND_FEC, set_inband_fec, opus_int32, fec)
OPUS_SHIM_ENCODER_CTL1(GET_INBAND_FEC, get_inband_fec, opus_int32*, fec)
OPUS_SHIM_ENCODER_CTL1(SET_PACKET_LOSS_PERC, set_packet_loss_perc, opus_int32, loss)
OPUS_SHIM_ENCODER_CTL1(GET_PACKET_LOSS_PERC, get_packet_loss_perc, opus_int32*, loss)
OPUS_SHIM_ENCODER_CTL1(SET_DTX, set_dtx, opus_int32, dtx)
OPUS_SHIM_ENCODER_CTL1(GET_DTX, get_dtx, opus_int32*, dtx)
OPUS_SHIM_ENCODER_CTL1(SET_LSB_DEPTH, set_lsb_depth, opus_int32, depth)
OPUS_SHIM_ENCODER_CTL1(GET_LSB_DEPTH, get_lsb_depth, opus_int32*, depth)
OPUS_SHIM_ENCODER_CTL1(SET_EXPERT_FRAME_DURATION, set_expert_frame_duration, opus_int32, duration)
OPUS_SHIM_ENCODER_CTL1(GET_EXPERT_FRAME_DURATION, get_expert_frame_duration, opus_int32*, duration)
OPUS_SHIM_ENCODER_CTL1(SET_PREDICTION_DISABLED, set_prediction_disabled, opus_int32, predictionDisabled)
OPUS_SHIM_ENCODER_CTL1(GET_PREDICTION_DISABLED, get_prediction_disabled, opus_int32*, predictionDisabled)
OPUS_SHIM_DECODER_CTL1(SET_GAIN, set_gain, opus_int32, gain)
OPUS_SHIM_DECODER_CTL1(GET_GAIN, get_gain, opus_int32*, gain)
OPUS_SHIM_DECODER_CTL1(GET_LAST_PACKET_DURATION, get_last_packet_duration, opus_int32*, duration)
OPUS_SHIM_DECODER_CTL1(GET_PITCH, get_pitch, opus_int32*, pitch)

#undef OPUS_SHIM_GENERIC_CTL0
#undef OPUS_SHIM_GENERIC_CTL1
#undef OPUS_SHIM_ENCODER_CTL1
#undef OPUS_SHIM_DECODER_CTL1
