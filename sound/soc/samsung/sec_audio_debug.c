/*
 *  sec_audio_debug.c
 *
 *  Copyright (c) 2017 Samsung Electronics
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 *
 */

#include <linux/debugfs.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/time.h>
#include <linux/uaccess.h>

#include <sound/samsung/sec_audio_debug.h>

#define MAX_DEBUG_MSG_SIZE 100

struct audio_log_data {
	int count;
	int full;
	char **audio_log;
};

static struct dentry *audio_debugfs;
static int debug_enable;
static struct audio_log_data debug_log_data;

static ssize_t audio_log_read_file(struct file *file, char __user *user_buf,
					size_t count, loff_t *ppos)
{
	size_t buf_pos = 0;
	ssize_t ret, size;
	int i, num_msg;
	char *buf;
	unsigned long len = 0;

	if (*ppos < 0 || !count)
		return -EINVAL;

	if (debug_log_data.full)
		num_msg = debug_log_data.full;
	else
		num_msg = debug_log_data.count;

	size = (sizeof(char *) * MAX_DEBUG_MSG_SIZE) * num_msg;

	buf = kzalloc(size, GFP_KERNEL);
	if (!buf) {
		pr_err("%s: alloc failed\n", __func__);
		return -ENOMEM;
	}

	for (i = 0; i < num_msg; i++) {
		len += snprintf(buf + buf_pos, size - len, "%s",
				debug_log_data.audio_log[i]);
		buf_pos = len;
	}
	if (len > size)
		len = size;

	ret = simple_read_from_buffer(user_buf, count, ppos, buf, len);
	kfree(buf);

	return ret;
}

static const struct file_operations audio_log_fops = {
	.open = simple_open,
	.read = audio_log_read_file,
	.llseek = default_llseek,
};

void sec_audio_log(int level, const char *fmt, ...)
{
	return;
}
EXPORT_SYMBOL_GPL(sec_audio_log);

int alloc_sec_audio_log(int buffer_len)
{
	return 0;

alloc_err:
	for (--i; i >= 0; i--)
		kfree(debug_log_data.audio_log[i]);

	kfree(debug_log_data.audio_log);
	debug_log_data.audio_log = NULL;
	debug_enable = 0;

	return ret;
}
EXPORT_SYMBOL_GPL(alloc_sec_audio_log);

void free_sec_audio_log(void)
{
}

static ssize_t log_enable_read_file(struct file *file, char __user *user_buf,
					size_t count, loff_t *ppos)
{
	return 0;
}

static ssize_t log_enable_write_file(struct file *file,
				     const char __user *user_buf,
				     size_t count, loff_t *ppos)
{
	return 0;
}

static const struct file_operations log_enable_fops = {
	.open = simple_open,
	.read = log_enable_read_file,
	.write = log_enable_write_file,
	.llseek = default_llseek,
};

static int __init sec_audio_debug_init(void)
{
	return 0;
}
module_init(sec_audio_debug_init);

static void __exit sec_audio_debug_exit(void)
{
	if (debug_enable)
		free_sec_audio_log();

	debugfs_remove_recursive(audio_debugfs);
}
module_exit(sec_audio_debug_exit);

MODULE_DESCRIPTION("Samsung Electronics Audio Debug driver");
MODULE_LICENSE("GPL");
