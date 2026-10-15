// SPDX-License-Identifier: GPL-2.0-only
/*
 * Driver for NPCM Bridge IC.
 *
 * Copyright (C) 2023 Nuvoton Technologies
 */

#include <linux/delay.h>
#include <linux/i3c/device.h>
#include <linux/i3c/master.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/sysfs.h>
#include "internals.h"

#define MQ_BUF_SIZE	8 /* HW limitation that only 8 bytes IBI data can be received */
#define MQ_BUF_COUNT	64
#define MQ_BUF_NEXT(x)	(((x) + 1) % MQ_BUF_COUNT)

/* If want to use I3C hub to emulate BIC for IBI generation, set HUB_TEST as 1 */
#define HUB_TEST	0

struct mq_buf {
	int len;
	u8 *buf;
};

struct npcm_bic {
	struct bin_attribute bin;
	struct kernfs_node *kn;
	struct i3c_device *i3cdev;
	spinlock_t lock;
	struct mutex mq_lock;
	int head;
	int tail;
	struct mq_buf queue[MQ_BUF_COUNT];
};

static void i3c_ibi_mqueue_callback(struct i3c_device *dev,
				    const struct i3c_ibi_payload *payload)
{
	struct npcm_bic *bic = dev_get_drvdata(&dev->dev);
	struct mq_buf *mq_buf;
	u8 *data = (u8 *)payload->data;
	struct i3c_device_info info;

	dev_dbg(&dev->dev, "%s: payload len %d, queue to mq[%d]\n", __func__,
		payload->len, bic->tail);

	mutex_lock(&bic->mq_lock);
	i3c_device_get_info(dev, &info);

	mq_buf = &bic->queue[bic->tail];
	memset(mq_buf->buf, 0, MQ_BUF_SIZE);
	mq_buf->len = 0;

	memcpy(mq_buf->buf, data, payload->len);
	mq_buf->len += payload->len;
	bic->tail = MQ_BUF_NEXT(bic->tail);

	kernfs_notify(bic->kn);
	mutex_unlock(&bic->mq_lock);
}

static ssize_t i3c_npcm_bic_bin_read(struct file *filp, struct kobject *kobj,
				     struct bin_attribute *attr, char *buf,
				     loff_t pos, size_t count)
{
	struct npcm_bic *bic;
	struct mq_buf *mq_buf;
	unsigned long flags;
	bool more = false;
	int i;

	bic = dev_get_drvdata(container_of(kobj, struct device, kobj));
	spin_lock_irqsave(&bic->lock, flags);
	if (bic->head != bic->tail) {
		mq_buf = &bic->queue[bic->head];
		memcpy(buf, mq_buf->buf, mq_buf->len);

		dev_dbg(&bic->i3cdev->dev, "mq[%d] =\n", bic->head);
		for(i = 0; i < mq_buf->len; i++)
			dev_dbg(&bic->i3cdev->dev, "%02x ", buf[i]);
		dev_dbg(&bic->i3cdev->dev, "\n\n");

		bic->head = MQ_BUF_NEXT(bic->head);
		if (bic->head != bic->tail)
			more = true;
	}
	spin_unlock_irqrestore(&bic->lock, flags);

	if (more)
		kernfs_notify(bic->kn);

	return 0;
}

static ssize_t i3c_npcm_bic_bin_write(struct file *filp, struct kobject *kobj,
				      struct bin_attribute *attr, char *buf,
				      loff_t pos, size_t count)
{
	struct npcm_bic *bic;
	struct i3c_priv_xfer xfers = {
		.rnw = false,
		.len = count,
	};
	int ret;

	bic = dev_get_drvdata(container_of(kobj, struct device, kobj));

	dev_dbg(&bic->i3cdev->dev, "%s: count = %zu\n", __func__, count);
	xfers.data.out = buf;
	ret = i3c_device_do_priv_xfers(bic->i3cdev, &xfers, 1);

	return (!ret) ? count : ret;
}

static void i3c_npcm_bic_remove(struct i3c_device *i3cdev)
{
	struct device *dev = &i3cdev->dev;
	struct npcm_bic *bic;

	i3c_device_disable_ibi(i3cdev);
	i3c_device_free_ibi(i3cdev);

	bic = dev_get_drvdata(dev);
	kernfs_put(bic->kn);
	sysfs_remove_bin_file(&dev->kobj, &bic->bin);
	devm_kfree(dev, bic);
}

static int i3c_npcm_bic_probe(struct i3c_device *i3cdev)
{
	struct device *dev = &i3cdev->dev;
	struct npcm_bic *bic;
	struct i3c_ibi_setup ibireq = {};
	int ret, i;
	struct i3c_device_info info;
	void *buf;

	if (dev->type == &i3c_masterdev_type)
		return -ENOTSUPP;

	bic = devm_kzalloc(dev, sizeof(*bic), GFP_KERNEL);
	if (!bic)
		return -ENOMEM;

	buf = devm_kmalloc_array(dev, MQ_BUF_COUNT, MQ_BUF_SIZE, GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	for (i = 0; i < MQ_BUF_COUNT; i++) {
		bic->queue[i].buf = (u8 *)buf + i * MQ_BUF_SIZE;
		bic->queue[i].len = 0;
	}

	bic->head = 0;
	bic->tail = 0;
	bic->i3cdev = i3cdev;
	bic->bin.attr.name = "mqueue";
	bic->bin.attr.mode = 0600;
	bic->bin.read = i3c_npcm_bic_bin_read;
	bic->bin.write = i3c_npcm_bic_bin_write;
	bic->bin.size = MQ_BUF_SIZE * MQ_BUF_COUNT;

	spin_lock_init(&bic->lock);
	mutex_init(&bic->mq_lock);

	sysfs_bin_attr_init(&bic->bin);
	ret = sysfs_create_bin_file(&dev->kobj, &bic->bin);
	if (ret) {
		dev_err(dev, "Failed to create bin file\n");
		return ret;
	}

	bic->kn = kernfs_find_and_get(dev->kobj.sd, bic->bin.attr.name);
	if (!bic->kn) {
		ret = -EFAULT;
		goto rel_bin_file;
	}

	i3c_device_get_info(i3cdev, &info);
	ret = i3c_device_setmrl_ccc(i3cdev, &info, MQ_BUF_SIZE,
				    min(MQ_BUF_SIZE, __UINT8_MAX__));
	if (ret) {
		dev_err(dev, "Failed to SETMRL\n");
#if !HUB_TEST
		goto rel_kn;
#endif
	}

	dev_set_drvdata(dev, bic);

	ibireq.handler = i3c_ibi_mqueue_callback;
	ibireq.max_payload_len = MQ_BUF_SIZE;
	ibireq.num_slots = MQ_BUF_COUNT;

	ret = i3c_device_request_ibi(bic->i3cdev, &ibireq);
	ret |= i3c_device_enable_ibi(bic->i3cdev);
	if (ret) {
		dev_err(dev, "Failed to request and enable IBI\n");
		goto rel_kn;
	}

	return 0;

rel_kn:
	kernfs_put(bic->kn);
rel_bin_file:
	sysfs_remove_bin_file(&dev->kobj, &bic->bin);

	return ret;
}

static const struct i3c_device_id i3c_npcm_bic_ids[] = {
	/* TODO: add ids for matching BIC here */
#if HUB_TEST
	I3C_CLASS(0xc2, NULL),
#endif
	{ /* sentinel */ },
};
MODULE_DEVICE_TABLE(i3c, i3c_npcm_bic_ids);

static struct i3c_driver npcm_bic_driver = {
	.driver = {
		.name = "i3c-npcm-bic",
	},
	.probe = i3c_npcm_bic_probe,
	.remove = i3c_npcm_bic_remove,
	.id_table = i3c_npcm_bic_ids,
};
module_i3c_driver(npcm_bic_driver);

MODULE_AUTHOR("Marvin Lin <kflin@nuvoton.com>");
MODULE_DESCRIPTION("Driver for NPCM Bridge IC");
MODULE_LICENSE("GPL v2");
