#ifndef _SEC_AUDIO_DEBUG_H
#define _SEC_AUDIO_DEBUG_H

#ifdef CONFIG_SND_SOC_SAMSUNG_AUDIO
void sec_audio_log(int level, const char *fmt, ...);
int alloc_sec_audio_log(int buffer_len);
void free_sec_audio_log(void);
#else
inline void sec_audio_log(int level, const char *fmt, ...)
{
}

inline int alloc_sec_audio_log(int buffer_len)
{
	return -EACCES;
}

inline void free_sec_audio_log(void)
{
}
#endif

#define adev_err(fmt, arg...)
#define adev_info(fmt, arg...)
#define adev_dbg(fmt, arg...)

#ifdef dev_err
#undef dev_err
#endif
#define dev_err(dev, fmt, arg...)

#ifdef dev_warn
#undef dev_warn
#endif
#define dev_warn(dev, fmt, arg...)

#ifdef dev_info
#undef dev_info
#endif
#define dev_info(dev, fmt, arg...)

#endif /* _SEC_AUDIO_DEBUG_H */
