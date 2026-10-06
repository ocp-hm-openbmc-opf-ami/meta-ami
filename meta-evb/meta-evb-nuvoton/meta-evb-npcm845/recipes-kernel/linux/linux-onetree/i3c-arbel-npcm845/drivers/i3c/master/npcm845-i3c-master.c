// SPDX-License-Identifier: GPL-2.0
/*
 * Nuvoton NPCM845 I3C controller driver
 *
 * Copyright (C) 2025 Nuvoton Technology Corp.
 * Based on svc-i3c-master.c
 */

#include <linux/bitfield.h>
#include <linux/clk.h>
#include <linux/completion.h>
#include <linux/debugfs.h>
#include <linux/errno.h>
#include <linux/i3c/master.h>
#include <linux/interrupt.h>
#include <linux/iopoll.h>
#include <linux/list.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/reset.h>
#include <linux/pinctrl/consumer.h>
#include <linux/platform_device.h>

/* Master Mode Registers */
#define SVC_I3C_MCONFIG      0x000
#define   SVC_I3C_MCONFIG_MASTER_EN BIT(0)
#define   SVC_I3C_MCONFIG_DISTO(x) FIELD_PREP(BIT(3), (x))
#define   SVC_I3C_MCONFIG_HKEEP(x) FIELD_PREP(GENMASK(5, 4), (x))
#define   SVC_I3C_MCONFIG_ODSTOP(x) FIELD_PREP(BIT(6), (x))
#define   SVC_I3C_MCONFIG_PPBAUD(x) FIELD_PREP(GENMASK(11, 8), (x))
#define   SVC_I3C_MCONFIG_PPLOW(x) FIELD_PREP(GENMASK(15, 12), (x))
#define   SVC_I3C_MCONFIG_ODBAUD(x) FIELD_PREP(GENMASK(23, 16), (x))
#define   SVC_I3C_MCONFIG_ODHPP(x) FIELD_PREP(BIT(24), (x))
#define   SVC_I3C_MCONFIG_SKEW(x) FIELD_PREP(GENMASK(27, 25), (x))
#define   SVC_I3C_MCONFIG_SKEW_MASK GENMASK(27, 25)
#define   SVC_I3C_MCONFIG_I2CBAUD(x) FIELD_PREP(GENMASK(31, 28), (x))

#define SVC_I3C_MCTRL        0x084
#define   SVC_I3C_MCTRL_REQUEST_MASK GENMASK(2, 0)
#define   SVC_I3C_MCTRL_REQUEST(x) FIELD_GET(GENMASK(2, 0), (x))
#define   SVC_I3C_MCTRL_REQUEST_NONE 0
#define   SVC_I3C_MCTRL_REQUEST_START_ADDR 1
#define   SVC_I3C_MCTRL_REQUEST_STOP 2
#define   SVC_I3C_MCTRL_REQUEST_IBI_ACKNACK 3
#define   SVC_I3C_MCTRL_REQUEST_PROC_DAA 4
#define   SVC_I3C_MCTRL_REQUEST_AUTO_IBI 7
#define   SVC_I3C_MCTRL_TYPE_I3C 0
#define   SVC_I3C_MCTRL_TYPE_I2C BIT(4)
#define   SVC_I3C_MCTRL_IBIRESP_AUTO 0
#define   SVC_I3C_MCTRL_IBIRESP_ACK_WITHOUT_BYTE 0
#define   SVC_I3C_MCTRL_IBIRESP_ACK_WITH_BYTE BIT(7)
#define   SVC_I3C_MCTRL_IBIRESP_NACK BIT(6)
#define   SVC_I3C_MCTRL_IBIRESP_MANUAL GENMASK(7, 6)
#define   SVC_I3C_MCTRL_DIR(x) FIELD_PREP(BIT(8), (x))
#define   SVC_I3C_MCTRL_DIR_WRITE 0
#define   SVC_I3C_MCTRL_DIR_READ 1
#define   SVC_I3C_MCTRL_ADDR(x) FIELD_PREP(GENMASK(15, 9), (x))
#define   SVC_I3C_MCTRL_RDTERM(x) FIELD_PREP(GENMASK(23, 16), (x))

#define SVC_I3C_MSTATUS      0x088
#define   SVC_I3C_MSTATUS_STATE_IBIACK(x) (SVC_I3C_MSTATUS_STATE(x) == 6)
#define   SVC_I3C_MSTATUS_STATE(x) FIELD_GET(GENMASK(2, 0), (x))
#define   SVC_I3C_MSTATUS_STATE_DAA(x) (SVC_I3C_MSTATUS_STATE(x) == 5)
#define   SVC_I3C_MSTATUS_STATE_SLVREQ(x) (SVC_I3C_MSTATUS_STATE(x) == 1)
#define   SVC_I3C_MSTATUS_STATE_IDLE(x) (SVC_I3C_MSTATUS_STATE(x) == 0)
#define   SVC_I3C_MSTATUS_BETWEEN(x) FIELD_GET(BIT(4), (x))
#define   SVC_I3C_MSTATUS_NACKED(x) FIELD_GET(BIT(5), (x))
#define   SVC_I3C_MSTATUS_IBITYPE(x) FIELD_GET(GENMASK(7, 6), (x))
#define   SVC_I3C_MSTATUS_IBITYPE_IBI 1
#define   SVC_I3C_MSTATUS_IBITYPE_MASTER_REQUEST 2
#define   SVC_I3C_MSTATUS_IBITYPE_HOT_JOIN 3
#define   SVC_I3C_MINT_SLVSTART BIT(8)
#define   SVC_I3C_MINT_MCTRLDONE BIT(9)
#define   SVC_I3C_MINT_COMPLETE BIT(10)
#define   SVC_I3C_MINT_RXPEND BIT(11)
#define   SVC_I3C_MINT_TXNOTFULL BIT(12)
#define   SVC_I3C_MINT_IBIWON BIT(13)
#define   SVC_I3C_MINT_ERRWARN BIT(15)
#define   SVC_I3C_MSTATUS_SLVSTART(x) FIELD_GET(SVC_I3C_MINT_SLVSTART, (x))
#define   SVC_I3C_MSTATUS_MCTRLDONE(x) FIELD_GET(SVC_I3C_MINT_MCTRLDONE, (x))
#define   SVC_I3C_MSTATUS_COMPLETE(x) FIELD_GET(SVC_I3C_MINT_COMPLETE, (x))
#define   SVC_I3C_MSTATUS_RXPEND(x) FIELD_GET(SVC_I3C_MINT_RXPEND, (x))
#define   SVC_I3C_MSTATUS_TXNOTFULL(x) FIELD_GET(SVC_I3C_MINT_TXNOTFULL, (x))
#define   SVC_I3C_MSTATUS_IBIWON(x) FIELD_GET(SVC_I3C_MINT_IBIWON, (x))
#define   SVC_I3C_MSTATUS_ERRWARN(x) FIELD_GET(SVC_I3C_MINT_ERRWARN, (x))
#define   SVC_I3C_MSTATUS_IBIADDR(x) FIELD_GET(GENMASK(30, 24), (x))

#define SVC_I3C_IBIRULES     0x08C
#define   SVC_I3C_IBIRULES_ADDR(slot, addr) FIELD_PREP(GENMASK(29, 0), \
						       ((addr) & 0x3F) << ((slot) * 6))
#define   SVC_I3C_IBIRULES_ADDRS 5
#define   SVC_I3C_IBIRULES_MSB0 BIT(30)
#define   SVC_I3C_IBIRULES_NOBYTE BIT(31)
#define   SVC_I3C_IBIRULES_MANDBYTE 0
#define SVC_I3C_MINTSET      0x090
#define SVC_I3C_MINTCLR      0x094
#define SVC_I3C_MINTMASKED   0x098
#define SVC_I3C_MERRWARN     0x09C
#define   SVC_I3C_MERRWARN_NACK BIT(2)
#define   SVC_I3C_MERRWARN_TIMEOUT BIT(20)
#define SVC_I3C_MDMACTRL     0x0A0
#define SVC_I3C_MDATACTRL    0x0AC
#define   SVC_I3C_MDATACTRL_FLUSHTB BIT(0)
#define   SVC_I3C_MDATACTRL_FLUSHRB BIT(1)
#define   SVC_I3C_MDATACTRL_UNLOCK_TRIG BIT(3)
#define   SVC_I3C_MDATACTRL_TXTRIG_FIFO_NOT_FULL GENMASK(5, 4)
#define   SVC_I3C_MDATACTRL_RXTRIG_FIFO_NOT_EMPTY 0
#define   SVC_I3C_MDATACTRL_RXCOUNT(x) FIELD_GET(GENMASK(28, 24), (x))
#define   SVC_I3C_MDATACTRL_TXFULL BIT(30)
#define   SVC_I3C_MDATACTRL_RXEMPTY BIT(31)

#define SVC_I3C_MWDATAB      0x0B0
#define   SVC_I3C_MWDATAB_END BIT(8)

#define SVC_I3C_MWDATABE     0x0B4
#define SVC_I3C_MWDATAH      0x0B8
#define SVC_I3C_MWDATAHE     0x0BC
#define SVC_I3C_MRDATAB      0x0C0
#define SVC_I3C_MRDATAH      0x0C8
#define SVC_I3C_MWDATAB1     0x0CC
#define SVC_I3C_MWMSG_SDR    0x0D0
#define SVC_I3C_MRMSG_SDR    0x0D4
#define SVC_I3C_MWMSG_DDR    0x0D8
#define SVC_I3C_MRMSG_DDR    0x0DC

#define SVC_I3C_MDYNADDR     0x0E4
#define   SVC_MDYNADDR_VALID BIT(0)
#define   SVC_MDYNADDR_ADDR(x) FIELD_PREP(GENMASK(7, 1), (x))

#define SVC_I3C_PARTNO       0x06C
#define SVC_I3C_VENDORID     0x074
#define   SVC_I3C_VENDORID_VID(x) FIELD_GET(GENMASK(14, 0), (x))

#define SVC_I3C_MAX_DEVS 32
#define SVC_I3C_PM_TIMEOUT_MS 1000

/* This parameter depends on the implementation and may be tuned */
#define SVC_I3C_FIFO_SIZE 16
#define SVC_I3C_MAX_IBI_PAYLOAD_SIZE 8
#define SVC_I3C_MAX_RDTERM 255
#define SVC_I3C_MAX_PPBAUD 15
#define SVC_I3C_MAX_PPLOW 15
#define SVC_I3C_MAX_ODBAUD 255
#define SVC_I3C_MAX_I2CBAUD 15
#define I3C_SCL_PP_PERIOD_NS_MIN 40
#define I3C_SCL_OD_LOW_PERIOD_NS_MIN 200

#define SVC_I3C_EVENT_IBI	GENMASK(31, 0)
#define SVC_I3C_EVENT_HOTJOIN	0x100000000ULL

struct svc_i3c_cmd {
	u8 addr;
	bool rnw;
	u8 *in;
	const void *out;
	unsigned int len;
	unsigned int actual_len;
	bool continued;
};

struct svc_i3c_xfer {
	struct list_head node;
	struct completion comp;
	int ret;
	unsigned int type;
	unsigned int ncmds;
	struct svc_i3c_cmd cmds[] __counted_by(ncmds);
};

struct svc_i3c_regs_save {
	u32 mconfig;
	u32 mdynaddr;
};

/**
 * struct svc_i3c_master - Silvaco I3C Master structure
 * @base: I3C master controller
 * @dev: Corresponding device
 * @regs: Memory mapping
 * @saved_regs: Volatile values for PM operations
 * @free_slots: Bit array of available slots
 * @addrs: Array containing the dynamic addresses of each attached device
 * @descs: Array of descriptors, one per attached device
 * @hj_work: Hot-join work
 * @irq: Main interrupt
 * @pclk: System clock
 * @fclk: Fast clock (bus)
 * @xferqueue: Transfer queue structure
 * @xferqueue.list: List member
 * @xferqueue.cur: Current ongoing transfer
 * @xferqueue.lock: Queue lock
 * @ibi: IBI structure
 * @ibi.num_slots: Number of slots available in @ibi.slots
 * @ibi.slots: Available IBI slots
 * @ibi.tbq_slot: To be queued IBI slot
 * @ibi.lock: IBI lock
 * @lock: Transfer lock, protect between IBI work thread and callbacks from master
 * @enabled_events: Bit masks for enable events (IBI, HotJoin).
 * @mctrl_config: Configuration value in SVC_I3C_MCTRL for setting speed back.
 */
struct svc_i3c_master {
	struct i3c_master_controller base;
	struct device *dev;
	void __iomem *regs;
	struct svc_i3c_regs_save saved_regs;
	u32 free_slots;
	u8 addrs[SVC_I3C_MAX_DEVS];
	struct i3c_dev_desc *descs[SVC_I3C_MAX_DEVS];
	struct work_struct hj_work;
	int irq;
	struct clk *pclk;
	struct clk *fclk;
	struct {
		u32 i3c_pp_hi;
		u32 i3c_pp_lo;
		u32 i3c_od_hi;
		u32 i3c_od_lo;
	} scl_timing;
	struct {
		struct list_head list;
		struct svc_i3c_xfer *cur;
		/* Prevent races between transfers */
		spinlock_t lock;
	} xferqueue;
	struct {
		unsigned int num_slots;
		struct i3c_dev_desc **slots;
		struct i3c_ibi_slot *tbq_slot;
		/* Prevent races within IBI handlers */
		spinlock_t lock;
	} ibi;
	struct mutex lock;
	u64 enabled_events;
	u32 mctrl_config;
	struct dentry *debugfs;

	bool en_hj;

	/* Statistic report */
	u8 err_code;
	u64 err_cnt;
	u64 rd_ibiwon_cnt;
	u64 wr_ibiwon_cnt;
};

/**
 * struct svc_i3c_i2c_dev_data - Device specific data
 * @index: Index in the master tables corresponding to this device
 * @ibi: IBI slot index in the master structure
 * @ibi_pool: IBI pool associated to this device
 */
struct svc_i3c_i2c_dev_data {
	u8 index;
	int ibi;
	struct i3c_generic_ibi_pool *ibi_pool;
};

static void svc_i3c_master_err_stats(struct svc_i3c_master *master, u8 code)
{
	master->err_cnt++;
	master->err_code = code;
}

static inline bool is_events_enabled(struct svc_i3c_master *master, u64 mask)
{
	return !!(master->enabled_events & mask);
}

static bool svc_i3c_master_error(struct svc_i3c_master *master)
{
	u32 mstatus, merrwarn;

	mstatus = readl(master->regs + SVC_I3C_MSTATUS);
	if (SVC_I3C_MSTATUS_ERRWARN(mstatus)) {
		merrwarn = readl(master->regs + SVC_I3C_MERRWARN);
		writel(merrwarn, master->regs + SVC_I3C_MERRWARN);

		/* Ignore timeout error */
		if (merrwarn & SVC_I3C_MERRWARN_TIMEOUT) {
			dev_dbg(master->dev, "Warning condition: MSTATUS 0x%08x, MERRWARN 0x%08x\n",
				mstatus, merrwarn);
			return false;
		}

		dev_err(master->dev,
			"Error condition: MSTATUS 0x%08x, MERRWARN 0x%08x\n",
			mstatus, merrwarn);

		return true;
	}

	return false;
}

static void svc_i3c_master_enable_interrupts(struct svc_i3c_master *master, u32 mask)
{
	writel(mask, master->regs + SVC_I3C_MINTSET);
}

static void svc_i3c_master_disable_interrupts(struct svc_i3c_master *master)
{
	u32 mask = readl(master->regs + SVC_I3C_MINTSET);

	writel(mask, master->regs + SVC_I3C_MINTCLR);
}

static void svc_i3c_master_clear_merrwarn(struct svc_i3c_master *master)
{
	/* Clear pending warnings */
	writel(readl(master->regs + SVC_I3C_MERRWARN),
	       master->regs + SVC_I3C_MERRWARN);
}

static void svc_i3c_master_flush_fifo(struct svc_i3c_master *master)
{
	/* Flush FIFOs */
	writel(SVC_I3C_MDATACTRL_FLUSHTB | SVC_I3C_MDATACTRL_FLUSHRB,
	       master->regs + SVC_I3C_MDATACTRL);
}

static void svc_i3c_master_flush_rx_fifo(struct svc_i3c_master *master)
{
	writel(SVC_I3C_MDATACTRL_FLUSHRB, master->regs + SVC_I3C_MDATACTRL);
}

static void svc_i3c_master_reset_fifo_trigger(struct svc_i3c_master *master)
{
	u32 reg;

	/* Set RX and TX tigger levels, flush FIFOs */
	reg = SVC_I3C_MDATACTRL_FLUSHTB |
	      SVC_I3C_MDATACTRL_FLUSHRB |
	      SVC_I3C_MDATACTRL_UNLOCK_TRIG |
	      SVC_I3C_MDATACTRL_TXTRIG_FIFO_NOT_FULL |
	      SVC_I3C_MDATACTRL_RXTRIG_FIFO_NOT_EMPTY;
	writel(reg, master->regs + SVC_I3C_MDATACTRL);
}

static void svc_i3c_master_reset(struct svc_i3c_master *master)
{
	svc_i3c_master_clear_merrwarn(master);
	svc_i3c_master_reset_fifo_trigger(master);
	svc_i3c_master_disable_interrupts(master);
}

static inline struct svc_i3c_master *
to_svc_i3c_master(struct i3c_master_controller *master)
{
	return container_of(master, struct svc_i3c_master, base);
}

static void svc_i3c_master_hj_work(struct work_struct *work)
{
	struct svc_i3c_master *master;

	master = container_of(work, struct svc_i3c_master, hj_work);
	i3c_master_do_daa(&master->base);
}

static struct i3c_dev_desc *
svc_i3c_master_dev_from_addr(struct svc_i3c_master *master,
			     unsigned int ibiaddr)
{
	int i;

	for (i = 0; i < SVC_I3C_MAX_DEVS; i++)
		if (master->addrs[i] == ibiaddr)
			break;

	if (i == SVC_I3C_MAX_DEVS)
		return NULL;

	return master->descs[i];
}

static void svc_i3c_master_emit_stop(struct svc_i3c_master *master)
{
	u32 reg = readl(master->regs + SVC_I3C_MSTATUS);

	/* Do not emit stop in the IDLE or SLVREQ state */
	if (SVC_I3C_MSTATUS_STATE_IDLE(reg) || SVC_I3C_MSTATUS_STATE_SLVREQ(reg))
		return;

	writel(SVC_I3C_MCTRL_REQUEST_STOP, master->regs + SVC_I3C_MCTRL);
	/*
	 * Wait for STOP condition to complete, otherwise the subsequent
	 * request may be omitted if it is started too early.
	 */
	readl_poll_timeout(master->regs + SVC_I3C_MSTATUS, reg,
			   SVC_I3C_MSTATUS_MCTRLDONE(reg), 0, 1000);

	/*
	 * This delay is necessary after the emission of a stop, otherwise eg.
	 * repeating IBIs do not get detected. There is a note in the manual
	 * about it, stating that the stop condition might not be settled
	 * correctly if a start condition follows too rapidly.
	 */
	udelay(1);
}

static int svc_i3c_master_handle_ibi(struct svc_i3c_master *master,
				     struct i3c_dev_desc *dev)
{
	struct svc_i3c_i2c_dev_data *data = i3c_dev_get_master_data(dev);
	struct i3c_ibi_slot *slot;
	unsigned int count;
	u32 mdatactrl;
	int ret, val;
	u8 *buf;

	if (!data) {
		dev_err_ratelimited(master->dev, "No data for addr 0x%x\n",
			dev->info.dyn_addr);
		goto no_ibi_pool;
	}
	if (!data->ibi_pool) {
		dev_err_ratelimited(master->dev, "No ibi pool for addr 0x%x\n",
			master->addrs[data->index]);
		goto no_ibi_pool;
	}
	slot = i3c_generic_ibi_get_free_slot(data->ibi_pool);
	if (!slot) {
		dev_err_ratelimited(master->dev, "No free ibi slot\n");
		goto no_ibi_pool;
	}

	slot->len = 0;
	buf = slot->data;

	/*
	 * Sometimes I3C HW returns to IDLE state after IBIRCV completed,
	 * continue when state becomes IDLE.
	 */
	ret = readl_relaxed_poll_timeout(master->regs + SVC_I3C_MSTATUS, val,
						SVC_I3C_MSTATUS_COMPLETE(val) |
						SVC_I3C_MSTATUS_STATE_IDLE(val),
						0, 1000);
	if (ret) {
		dev_err(master->dev, "Timeout when polling for COMPLETE\n");
		/* The event is wrong, do not deliver it to upper layer. */
		if (SVC_I3C_MSTATUS_RXPEND(val))
			svc_i3c_master_flush_rx_fifo(master);
		i3c_generic_ibi_recycle_slot(data->ibi_pool, slot);
		slot = NULL;
		svc_i3c_master_err_stats(master, ETIMEDOUT);
		goto handle_done;
	}

	while (SVC_I3C_MSTATUS_RXPEND(readl(master->regs + SVC_I3C_MSTATUS))  &&
	       slot->len < SVC_I3C_MAX_IBI_PAYLOAD_SIZE) {
		mdatactrl = readl(master->regs + SVC_I3C_MDATACTRL);
		count = SVC_I3C_MDATACTRL_RXCOUNT(mdatactrl);
		readsb(master->regs + SVC_I3C_MRDATAB, buf, count);
		slot->len += count;
		buf += count;
	}

handle_done:
	master->ibi.tbq_slot = slot;

	return ret;

no_ibi_pool:
	/* No ibi pool, drop the payload if received  */
	readl_relaxed_poll_timeout(master->regs + SVC_I3C_MSTATUS, val,
				   SVC_I3C_MSTATUS_COMPLETE(val) |
				   SVC_I3C_MSTATUS_STATE_IDLE(val),
				   0, 1000);
	svc_i3c_master_flush_rx_fifo(master);
	return -ENOSPC;
}

static int svc_i3c_master_ack_ibi(struct svc_i3c_master *master,
				   bool mandatory_byte)
{
	unsigned int ibi_ack_nack;
	u32 reg;

	ibi_ack_nack = SVC_I3C_MCTRL_REQUEST_IBI_ACKNACK;
	if (mandatory_byte)
		ibi_ack_nack |= SVC_I3C_MCTRL_IBIRESP_ACK_WITH_BYTE |
			SVC_I3C_MCTRL_RDTERM(SVC_I3C_MAX_IBI_PAYLOAD_SIZE);
	else
		ibi_ack_nack |= SVC_I3C_MCTRL_IBIRESP_ACK_WITHOUT_BYTE;

	writel(ibi_ack_nack, master->regs + SVC_I3C_MCTRL);

	return readl_poll_timeout_atomic(master->regs + SVC_I3C_MSTATUS, reg,
					 SVC_I3C_MSTATUS_MCTRLDONE(reg), 1, 1000);

}

static int svc_i3c_master_nack_ibi(struct svc_i3c_master *master)
{
	int ret;
	u32 reg;

	writel(SVC_I3C_MCTRL_REQUEST_IBI_ACKNACK |
	       SVC_I3C_MCTRL_IBIRESP_NACK,
	       master->regs + SVC_I3C_MCTRL);

	ret = readl_poll_timeout_atomic(master->regs + SVC_I3C_MSTATUS, reg,
					SVC_I3C_MSTATUS_MCTRLDONE(reg), 1, 1000);
	return ret;
}

static int svc_i3c_master_handle_ibi_won(struct svc_i3c_master *master, bool autoibi)
{
	struct svc_i3c_i2c_dev_data *data;
	unsigned int ibitype, ibiaddr;
	struct i3c_dev_desc *dev;
	u32 status;
	int ret = 0;

	status = readl(master->regs + SVC_I3C_MSTATUS);
	ibitype = SVC_I3C_MSTATUS_IBITYPE(status);
	ibiaddr = SVC_I3C_MSTATUS_IBIADDR(status);

	dev_dbg(master->dev, "ibitype=%d ibiaddr=%d\n", ibitype, ibiaddr);
	dev_dbg(master->dev, "ibiwon: mctrl=0x%x mstatus=0x%x\n",
		readl(master->regs + SVC_I3C_MCTRL), status);

	writel(SVC_I3C_MINT_IBIWON, master->regs + SVC_I3C_MSTATUS);

	/* Handle the critical responses to IBI's */
	switch (ibitype) {
	case SVC_I3C_MSTATUS_IBITYPE_IBI:
		dev = svc_i3c_master_dev_from_addr(master, ibiaddr);
		if (!dev || ibiaddr == 0) {
			if (!autoibi) {
				svc_i3c_master_nack_ibi(master);
				break;
			}
			/*
			 * Wait for complete to make sure the subsequent emitSTOP
			 * request will be performed in the correct state(NORMACT).
			 */
			readl_relaxed_poll_timeout(master->regs + SVC_I3C_MSTATUS, status,
						   SVC_I3C_MSTATUS_COMPLETE(status),
						   0, 1000);
			/* Flush the garbage data */
			if (SVC_I3C_MSTATUS_RXPEND(status))
				svc_i3c_master_flush_rx_fifo(master);
			break;
		}
		if (!autoibi)
			svc_i3c_master_ack_ibi(master, !!(dev->info.bcr & I3C_BCR_IBI_PAYLOAD));
		svc_i3c_master_handle_ibi(master, dev);
		break;
	case SVC_I3C_MSTATUS_IBITYPE_HOT_JOIN:
		svc_i3c_master_ack_ibi(master, false);
		break;
	case SVC_I3C_MSTATUS_IBITYPE_MASTER_REQUEST:
		svc_i3c_master_nack_ibi(master);
		status = readl(master->regs + SVC_I3C_MSTATUS);
		if (SVC_I3C_MSTATUS_RXPEND(status))
			svc_i3c_master_flush_rx_fifo(master);
		break;
	default:
		break;
	}

	/*
	 * The spurious IBI event may change controller state to IBIACK, switch state
	 * to NORMACT before emitSTOP request.
	 */
	if (SVC_I3C_MSTATUS_STATE_IBIACK(status))
		svc_i3c_master_nack_ibi(master);

	svc_i3c_master_emit_stop(master);

	/*
	 * If an error happened, we probably got interrupted and the exchange
	 * timedout. In this case we just drop everything, emit a stop and wait
	 * for the slave to interrupt again.
	 */
	if (svc_i3c_master_error(master)) {
		if (master->ibi.tbq_slot) {
			data = i3c_dev_get_master_data(dev);
			i3c_generic_ibi_recycle_slot(data->ibi_pool,
						     master->ibi.tbq_slot);
			master->ibi.tbq_slot = NULL;
		}

		dev_err(master->dev, "svc_i3c_master_error in ibiwon\n");
		svc_i3c_master_err_stats(master, EIO);
		return -EIO;
	}

	/* Handle the non critical tasks */
	switch (ibitype) {
	case SVC_I3C_MSTATUS_IBITYPE_IBI:
		if (dev && master->ibi.tbq_slot) {
			i3c_master_queue_ibi(dev, master->ibi.tbq_slot);
			master->ibi.tbq_slot = NULL;
		}
		break;
	case SVC_I3C_MSTATUS_IBITYPE_HOT_JOIN:
		if (is_events_enabled(master, SVC_I3C_EVENT_HOTJOIN))
			queue_work(master->base.wq, &master->hj_work);
		break;
	case SVC_I3C_MSTATUS_IBITYPE_MASTER_REQUEST:
		ret = -EOPNOTSUPP;
		svc_i3c_master_err_stats(master, EOPNOTSUPP);
		break;
	default:
		break;
	}

	return ret;
}

static int svc_i3c_master_start_autoibi(struct svc_i3c_master *master)
{
	u32 val;
	int ret;

	/*
	 * According to I3C spec ver 1.1, 09-Jun-2021, section 5.1.2.5:
	 *
	 * The I3C Controller shall hold SCL low while the Bus is in ACK/NACK Phase of I3C/I2C
	 * transfer. But maximum stall time is 100us. The IRQs have to be disabled to prevent
	 * schedule during the whole I3C transaction, otherwise, the I3C bus timeout may happen if
	 * any irq or schedule happen during transaction.
	 */
	guard(spinlock)(&master->xferqueue.lock);

	/* Make sure this is a true slave event */
	val = readl(master->regs + SVC_I3C_MSTATUS);
	if (!SVC_I3C_MSTATUS_STATE_SLVREQ(val))
		return 0;

	/*
	 * IBIWON may be set before SVC_I3C_MCTRL_REQUEST_AUTO_IBI, causing
	 * readl_relaxed_poll_timeout() to return immediately. Consequently,
	 * ibitype will be 0 since it was last updated only after the 8th SCL
	 * cycle, leading to missed client IBI handlers.
	 *
	 * A typical scenario is when IBIWON occurs and bus arbitration is lost
	 * at svc_i3c_master_priv_xfers().
	 *
	 * Clear SVC_I3C_MINT_IBIWON before sending SVC_I3C_MCTRL_REQUEST_AUTO_IBI.
	 */
	writel(SVC_I3C_MINT_IBIWON, master->regs + SVC_I3C_MSTATUS);

	/* Acknowledge the incoming interrupt with the AUTOIBI mechanism */
	writel(SVC_I3C_MCTRL_REQUEST_AUTO_IBI |
	       SVC_I3C_MCTRL_IBIRESP_AUTO |
	       SVC_I3C_MCTRL_RDTERM(SVC_I3C_MAX_IBI_PAYLOAD_SIZE),
	       master->regs + SVC_I3C_MCTRL);

	/* Wait for IBIWON, should take approximately 100us */
	ret = readl_relaxed_poll_timeout_atomic(master->regs + SVC_I3C_MSTATUS, val,
					 SVC_I3C_MSTATUS_IBIWON(val), 0, 100);
	if (ret) {
		/* Cancle AUTOIBI if not started */
		val = readl(master->regs + SVC_I3C_MCTRL);
		if (SVC_I3C_MCTRL_REQUEST(val) == SVC_I3C_MCTRL_REQUEST_AUTO_IBI)
			writel(0, master->regs + SVC_I3C_MCTRL);

		dev_err(master->dev, "Timeout when polling for IBIWON\n");
		svc_i3c_master_clear_merrwarn(master);
		svc_i3c_master_emit_stop(master);
		svc_i3c_master_err_stats(master, ETIMEDOUT);
		return -ETIMEDOUT;
	}

	return svc_i3c_master_handle_ibi_won(master, true);
}

static irqreturn_t svc_i3c_master_irq_handler(int irq, void *dev_id)
{
	struct svc_i3c_master *master = (struct svc_i3c_master *)dev_id;
	u32 active = readl(master->regs + SVC_I3C_MSTATUS);

	if (!SVC_I3C_MSTATUS_SLVSTART(active))
		return IRQ_NONE;

	/* Clear the interrupt status */
	writel(SVC_I3C_MINT_SLVSTART, master->regs + SVC_I3C_MSTATUS);

	/*
	 * A valid event may be missed if it occurs between the status read and clear.
	 * Re-read the status register to retrieve the latest state.
	 */
	active = readl(master->regs + SVC_I3C_MSTATUS);
	/* Ignore the false event */
	if (!SVC_I3C_MSTATUS_STATE_SLVREQ(active))
		return IRQ_HANDLED;

	svc_i3c_master_start_autoibi(master);

	return IRQ_HANDLED;
}

static int svc_i3c_master_bus_init(struct i3c_master_controller *m)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct i3c_bus *bus = i3c_master_get_bus(m);
	struct i3c_device_info info = {};
	unsigned long fclk_rate, fclk_period_ns;
	unsigned long i3c_scl_rate, i2c_scl_rate;
	unsigned int pp_high_period_ns, od_low_period_ns, i2c_period_ns;
	unsigned int scl_period_ns;
	u32 ppbaud, pplow, odhpp, odbaud, i2cbaud, reg;
	int ret;

	/* Timings derivation */
	fclk_rate = clk_get_rate(master->fclk);
	if (!fclk_rate)
		return -EINVAL;

	fclk_period_ns = DIV_ROUND_UP(1000000000, fclk_rate);

	/*
	 * Configure for Push-Pull mode.
	 */
	if (master->scl_timing.i3c_pp_hi >= I3C_SCL_PP_PERIOD_NS_MIN &&
	    master->scl_timing.i3c_pp_lo >= master->scl_timing.i3c_pp_hi) {
		ppbaud = DIV_ROUND_UP(master->scl_timing.i3c_pp_hi, fclk_period_ns) - 1;
		if (ppbaud > SVC_I3C_MAX_PPBAUD)
			ppbaud = SVC_I3C_MAX_PPBAUD;
		pplow = DIV_ROUND_UP(master->scl_timing.i3c_pp_lo, fclk_period_ns)
			- (ppbaud + 1);
		if (pplow > SVC_I3C_MAX_PPLOW)
			pplow = SVC_I3C_MAX_PPLOW;
		bus->scl_rate.i3c = 1000000000 / (((ppbaud + 1) * 2 + pplow) * fclk_period_ns);
	} else {
		scl_period_ns = DIV_ROUND_UP(1000000000, bus->scl_rate.i3c);
		if (bus->scl_rate.i3c == 10000000) {
			/* Workaround for npcm8xx: 40/60 ns */
			ppbaud = DIV_ROUND_UP(40, fclk_period_ns) - 1;
			pplow = DIV_ROUND_UP(20, fclk_period_ns);
		} else {
			/* 50% duty-cycle */
			ppbaud = DIV_ROUND_UP((scl_period_ns / 2), fclk_period_ns) - 1;
			pplow = 0;
		}
		if (ppbaud > SVC_I3C_MAX_PPBAUD)
			ppbaud = SVC_I3C_MAX_PPBAUD;
	}
	pp_high_period_ns = (ppbaud + 1) * fclk_period_ns;

	/*
	 * Configure for Open-Drain mode.
	 */
	if (master->scl_timing.i3c_od_hi >= pp_high_period_ns &&
	    master->scl_timing.i3c_od_lo >= I3C_SCL_OD_LOW_PERIOD_NS_MIN) {
		if (master->scl_timing.i3c_od_hi == pp_high_period_ns)
			odhpp = 1;
		else
			odhpp = 0;
		odbaud = DIV_ROUND_UP(master->scl_timing.i3c_od_lo, pp_high_period_ns) - 1;
	} else {
		/* Set default OD timing: 1MHz/1000ns with 50% duty cycle */
		odhpp = 0;
		odbaud = DIV_ROUND_UP(500, pp_high_period_ns) - 1;
	}
	if (odbaud > SVC_I3C_MAX_ODBAUD)
		odbaud = SVC_I3C_MAX_ODBAUD;
	od_low_period_ns = (odbaud + 1) * pp_high_period_ns;

	/* Configure for I2C mode */
	i2c_period_ns = DIV_ROUND_UP(1000000000, bus->scl_rate.i2c);
	if (i2c_period_ns < od_low_period_ns * 2)
		i2c_period_ns = od_low_period_ns * 2;
	i2cbaud = DIV_ROUND_UP(i2c_period_ns, od_low_period_ns) - 2;
	if (i2cbaud > SVC_I3C_MAX_I2CBAUD)
		i2cbaud = SVC_I3C_MAX_I2CBAUD;

	i3c_scl_rate = 1000000000 / (((ppbaud + 1) * 2 + pplow) * fclk_period_ns);
	i2c_scl_rate = 1000000000 / ((i2cbaud + 2) * od_low_period_ns);

	reg = SVC_I3C_MCONFIG_MASTER_EN |
	      SVC_I3C_MCONFIG_DISTO(0) |
	      SVC_I3C_MCONFIG_HKEEP(3) |
	      SVC_I3C_MCONFIG_ODSTOP(1) |
	      SVC_I3C_MCONFIG_PPBAUD(ppbaud) |
	      SVC_I3C_MCONFIG_PPLOW(pplow) |
	      SVC_I3C_MCONFIG_ODBAUD(odbaud) |
	      SVC_I3C_MCONFIG_ODHPP(odhpp) |
	      SVC_I3C_MCONFIG_SKEW(0) |
	      SVC_I3C_MCONFIG_I2CBAUD(i2cbaud);
	writel(reg, master->regs + SVC_I3C_MCONFIG);

	master->mctrl_config = reg;
	dev_dbg(master->dev, "dts: i3c rate=%lu, i2c rate=%lu\n",
		bus->scl_rate.i3c, bus->scl_rate.i2c);
	dev_info(master->dev, "fclk=%lu, period_ns=%lu\n", fclk_rate, fclk_period_ns);
	dev_info(master->dev, "i3c scl_rate=%lu\n", i3c_scl_rate);
	dev_info(master->dev, "i2c scl_rate=%lu\n", i2c_scl_rate);
	dev_info(master->dev, "pp_high=%u, pp_low=%lu\n", pp_high_period_ns,
			(ppbaud + 1 + pplow) * fclk_period_ns);
	dev_info(master->dev, "od_high=%d, od_low=%d\n", odhpp ? pp_high_period_ns : od_low_period_ns,
		 od_low_period_ns);
	dev_dbg(master->dev, "i2c_high=%u, i2c_low=%u\n", ((i2cbaud >> 1) + 1) * od_low_period_ns,
			((i2cbaud >> 1) + 1 + (i2cbaud % 2)) * od_low_period_ns);
	dev_dbg(master->dev, "ppbaud=%d, pplow=%d, odbaud=%d, i2cbaud=%d\n",
		ppbaud, pplow, odbaud, i2cbaud);
	dev_info(master->dev, "mconfig=0x%x\n", master->mctrl_config);
	/* Master core's registration */
	ret = i3c_master_get_free_addr(m, 0);
	if (ret < 0)
		return ret;

	info.dyn_addr = ret;
	reg = readl(master->regs + SVC_I3C_VENDORID);
	info.pid = (SVC_I3C_VENDORID_VID(reg) << 33) | readl(master->regs + SVC_I3C_PARTNO);

	writel(SVC_MDYNADDR_VALID | SVC_MDYNADDR_ADDR(info.dyn_addr),
	       master->regs + SVC_I3C_MDYNADDR);

	ret = i3c_master_set_info(&master->base, &info);

	return ret;
}

static void svc_i3c_master_bus_cleanup(struct i3c_master_controller *m)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);

	svc_i3c_master_disable_interrupts(master);

	/* Disable master */
	writel(0, master->regs + SVC_I3C_MCONFIG);
}

static int svc_i3c_master_reserve_slot(struct svc_i3c_master *master)
{
	unsigned int slot;

	if (!(master->free_slots & GENMASK(SVC_I3C_MAX_DEVS - 1, 0)))
		return -ENOSPC;

	slot = ffs(master->free_slots) - 1;

	master->free_slots &= ~BIT(slot);

	return slot;
}

static void svc_i3c_master_release_slot(struct svc_i3c_master *master,
					unsigned int slot)
{
	master->free_slots |= BIT(slot);
}

static int svc_i3c_master_attach_i3c_dev(struct i3c_dev_desc *dev)
{
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_i2c_dev_data *data;
	int slot;

	slot = svc_i3c_master_reserve_slot(master);
	if (slot < 0)
		return slot;

	data = kzalloc(sizeof(*data), GFP_KERNEL);
	if (!data) {
		svc_i3c_master_release_slot(master, slot);
		return -ENOMEM;
	}

	data->ibi = -1;
	data->index = slot;
	master->addrs[slot] = dev->info.dyn_addr ? dev->info.dyn_addr :
						   dev->info.static_addr;
	master->descs[slot] = dev;

	i3c_dev_set_master_data(dev, data);

	return 0;
}

static int svc_i3c_master_reattach_i3c_dev(struct i3c_dev_desc *dev,
					   u8 old_dyn_addr)
{
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_i2c_dev_data *data = i3c_dev_get_master_data(dev);

	master->addrs[data->index] = dev->info.dyn_addr ? dev->info.dyn_addr :
							  dev->info.static_addr;

	return 0;
}

static void svc_i3c_master_detach_i3c_dev(struct i3c_dev_desc *dev)
{
	struct svc_i3c_i2c_dev_data *data = i3c_dev_get_master_data(dev);
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);

	master->addrs[data->index] = 0;
	svc_i3c_master_release_slot(master, data->index);

	kfree(data);
}

static int svc_i3c_master_attach_i2c_dev(struct i2c_dev_desc *dev)
{
	struct i3c_master_controller *m = i2c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_i2c_dev_data *data;
	int slot;

	slot = svc_i3c_master_reserve_slot(master);
	if (slot < 0)
		return slot;

	data = kzalloc(sizeof(*data), GFP_KERNEL);
	if (!data) {
		svc_i3c_master_release_slot(master, slot);
		return -ENOMEM;
	}

	data->index = slot;
	master->addrs[slot] = dev->addr;

	i2c_dev_set_master_data(dev, data);

	return 0;
}

static void svc_i3c_master_detach_i2c_dev(struct i2c_dev_desc *dev)
{
	struct svc_i3c_i2c_dev_data *data = i2c_dev_get_master_data(dev);
	struct i3c_master_controller *m = i2c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);

	svc_i3c_master_release_slot(master, data->index);

	kfree(data);
}

static int svc_i3c_master_readb(struct svc_i3c_master *master, u8 *dst,
				unsigned int len)
{
	int ret, i;
	u32 reg;

	for (i = 0; i < len; i++) {
		ret = readl_poll_timeout_atomic(master->regs + SVC_I3C_MSTATUS,
						reg,
						SVC_I3C_MSTATUS_RXPEND(reg),
						0, 1000);
		if (ret)
			return ret;

		dst[i] = readl(master->regs + SVC_I3C_MRDATAB);
	}

	return 0;
}

static int svc_i3c_master_do_daa_locked(struct svc_i3c_master *master,
					u8 *addrs, unsigned int *count)
{
	u64 prov_id[SVC_I3C_MAX_DEVS] = {}, nacking_prov_id = 0;
	unsigned int dev_nb = 0, last_addr = 0, dyn_addr = 0;
	ktime_t timeout;
	u32 reg;
	int ret, i;

	svc_i3c_master_flush_fifo(master);

	timeout = ktime_add_ms(ktime_get(), 3000);
	while (true) {
		/* clean SVC_I3C_MINT_IBIWON w1c bits */
		writel(SVC_I3C_MINT_IBIWON, master->regs + SVC_I3C_MSTATUS);

		if (ktime_compare(ktime_get(), timeout) > 0) {
			dev_info(master->dev, "do_daa expired\n");
			ret = -ETIMEDOUT;
			break;
		}
		/* SVC_I3C_MCTRL_REQUEST_PROC_DAA have two mode, ENTER DAA or PROCESS DAA.
		 *
		 * ENTER DAA:
		 *   1 will issue START, 7E, ENTDAA, and then emits 7E/R to process first target.
		 *   2 Stops just before the new Dynamic Address (DA) is to be emitted.
		 *
		 * PROCESS DAA:
		 *   1 The DA is written using MWDATAB or ADDR bits 6:0.
		 *   2 ProcessDAA is requested again to write the new address, and then starts the
		 *     next (START, 7E, ENTDAA)  unless marked to STOP; an MSTATUS indicating NACK
		 *     means DA was not accepted (e.g. parity error). If PROCESSDAA is NACKed on the
		 *     7E/R, which means no more Slaves need a DA, then a COMPLETE will be signaled
		 *     (along with DONE), and a STOP issued automatically.
		 */
		writel(SVC_I3C_MCTRL_REQUEST_PROC_DAA |
		       SVC_I3C_MCTRL_TYPE_I3C |
		       SVC_I3C_MCTRL_IBIRESP_MANUAL |
		       SVC_I3C_MCTRL_DIR(SVC_I3C_MCTRL_DIR_WRITE),
		       master->regs + SVC_I3C_MCTRL);

		/*
		 * Either one slave will send its ID, or the assignment process
		 * is done.
		 */
		ret = readl_relaxed_poll_timeout_atomic(master->regs + SVC_I3C_MSTATUS,
						reg,
						SVC_I3C_MSTATUS_RXPEND(reg) |
						SVC_I3C_MSTATUS_MCTRLDONE(reg),
						0, 1000);
		if (ret)
			break;

		/* runtime do_daa may ibiwon by others slave devices */
		if (SVC_I3C_MSTATUS_IBIWON(reg)) {
			ret = svc_i3c_master_handle_ibi_won(master, false);
			if (ret) {
				dev_err(master->dev, "daa: handle ibiwon fail (err %d)\n", ret);
				break;
			}
			continue;
		}

		if (SVC_I3C_MSTATUS_RXPEND(reg)) {
			u8 data[6];

			/*
			 * One slave sends its ID to request for address assignment,
			 * prefilling the dynamic address can reduce SCL clock stalls
			 * and also fix the SVC_I3C_QUIRK_FIFO_EMPTY quirk.
			 *
			 * Ideally, prefilling before the processDAA command is better.
			 * However, it requires an additional check to write the dyn_addr
			 * at the right time because the driver needs to write the processDAA
			 * command twice for one assignment.
			 * Prefilling here is safe and efficient because the FIFO starts
			 * filling within a few hundred nanoseconds, which is significantly
			 * faster compared to the 64 SCL clock cycles.
			 */
			ret = i3c_master_get_free_addr(&master->base, last_addr + 1);
			if (ret < 0)
				break;

			dyn_addr = ret;
			writel(dyn_addr, master->regs + SVC_I3C_MWDATAB);

			/*
			 * We only care about the 48-bit provisioned ID yet to
			 * be sure a device does not nack an address twice.
			 * Otherwise, we would just need to flush the RX FIFO.
			 */
			ret = svc_i3c_master_readb(master, data, 6);
			if (ret)
				break;

			for (i = 0; i < 6; i++)
				prov_id[dev_nb] |= (u64)(data[i]) << (8 * (5 - i));

			/* We do not care about the BCR and DCR yet */
			ret = svc_i3c_master_readb(master, data, 2);
			if (ret)
				break;
		} else if (SVC_I3C_MSTATUS_MCTRLDONE(reg)) {
			if ((SVC_I3C_MSTATUS_STATE_IDLE(reg) |
			     SVC_I3C_MSTATUS_STATE_SLVREQ(reg)) &&
			    SVC_I3C_MSTATUS_COMPLETE(reg)) {
				/*
				 * Sometimes the controller state is SLVREQ after
				 * DAA request completed, treat it as normal end.
				 */
				/*
				 * All devices received and acked they dynamic
				 * address, this is the natural end of the DAA
				 * procedure.
				 *
				 * Hardware will auto emit STOP at this case.
				 */
				*count = dev_nb;
				return 0;

			} else if (SVC_I3C_MSTATUS_NACKED(reg)) {
				/* No I3C devices attached */
				if (dev_nb == 0) {
					/*
					 * Hardware can't treat first NACK for ENTAA as normal
					 * COMPLETE. So need manual emit STOP.
					 */
					ret = 0;
					*count = 0;
					break;
				}

				/*
				 * A slave device nacked the address, this is
				 * allowed only once, DAA will be stopped and
				 * then resumed. The same device is supposed to
				 * answer again immediately and shall ack the
				 * address this time.
				 */
				if (prov_id[dev_nb] == nacking_prov_id) {
					ret = -EIO;
					break;
				}

				dev_nb--;
				nacking_prov_id = prov_id[dev_nb];
				svc_i3c_master_emit_stop(master);

				continue;
			} else {
				break;
			}
		}

		/* Wait for the slave to be ready to receive its address */
		ret = readl_poll_timeout_atomic(master->regs + SVC_I3C_MSTATUS,
						reg,
						SVC_I3C_MSTATUS_MCTRLDONE(reg) &&
						SVC_I3C_MSTATUS_STATE_DAA(reg) &&
						SVC_I3C_MSTATUS_BETWEEN(reg),
						0, 1000);
		if (ret)
			break;

		addrs[dev_nb] = dyn_addr;
		dev_dbg(master->dev, "DAA: device %d assigned to 0x%02x\n",
			dev_nb, addrs[dev_nb]);
		last_addr = addrs[dev_nb++];

		if (dev_nb == SVC_I3C_MAX_DEVS) {
			dev_info(master->dev, "Reach max devs\n");
			break;
		}
	}

	/* Need manual issue STOP except for Complete condition */
	svc_i3c_master_emit_stop(master);
	svc_i3c_master_flush_fifo(master);

	return ret;
}

static int svc_i3c_update_ibirules(struct svc_i3c_master *master)
{
	struct i3c_dev_desc *dev;
	u32 reg_mbyte = 0, reg_nobyte = SVC_I3C_IBIRULES_NOBYTE;
	unsigned int mbyte_addr_ok = 0, mbyte_addr_ko = 0, nobyte_addr_ok = 0,
		nobyte_addr_ko = 0;
	bool list_mbyte = false, list_nobyte = false;

	/* Create the IBIRULES register for both cases */
	i3c_bus_for_each_i3cdev(&master->base.bus, dev) {
		if (!(dev->info.bcr & I3C_BCR_IBI_REQ_CAP))
			continue;

		if (dev->info.bcr & I3C_BCR_IBI_PAYLOAD) {
			reg_mbyte |= SVC_I3C_IBIRULES_ADDR(mbyte_addr_ok,
							   dev->info.dyn_addr);

			/* IBI rules cannot be applied to devices with MSb=1 */
			if (dev->info.dyn_addr & BIT(7))
				mbyte_addr_ko++;
			else
				mbyte_addr_ok++;
		} else {
			reg_nobyte |= SVC_I3C_IBIRULES_ADDR(nobyte_addr_ok,
							    dev->info.dyn_addr);

			/* IBI rules cannot be applied to devices with MSb=1 */
			if (dev->info.dyn_addr & BIT(7))
				nobyte_addr_ko++;
			else
				nobyte_addr_ok++;
		}
	}

	/* Device list cannot be handled by hardware */
	if (!mbyte_addr_ko && mbyte_addr_ok <= SVC_I3C_IBIRULES_ADDRS)
		list_mbyte = true;

	if (!nobyte_addr_ko && nobyte_addr_ok <= SVC_I3C_IBIRULES_ADDRS)
		list_nobyte = true;

	/* No list can be properly handled, return an error */
	if (!list_mbyte && !list_nobyte)
		return -ERANGE;

	/* Pick the first list that can be handled by hardware, randomly */
	if (list_mbyte)
		writel(reg_mbyte, master->regs + SVC_I3C_IBIRULES);
	else
		writel(reg_nobyte, master->regs + SVC_I3C_IBIRULES);

	return 0;
}

static int svc_i3c_master_do_daa(struct i3c_master_controller *m)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	u8 addrs[SVC_I3C_MAX_DEVS];
	unsigned long flags;
	unsigned int dev_nb;
	int ret, i;

	spin_lock_irqsave(&master->xferqueue.lock, flags);
	/* Fix npcm845 DAA corrupt issue */
	writel(master->mctrl_config | SVC_I3C_MCONFIG_SKEW(1),
	       master->regs + SVC_I3C_MCONFIG);
	ret = svc_i3c_master_do_daa_locked(master, addrs, &dev_nb);
	writel(master->mctrl_config, master->regs + SVC_I3C_MCONFIG);
	spin_unlock_irqrestore(&master->xferqueue.lock, flags);

	svc_i3c_master_clear_merrwarn(master);
	if (ret)
		return ret;

	/*
	 * Register all devices who participated to the core
	 *
	 * If two devices (A and B) are detected in DAA and address 0xa is assigned to
	 * device A and 0xb to device B, a failure in i3c_master_add_i3c_dev_locked()
	 * for device A (addr: 0xa) could prevent device B (addr: 0xb) from being
	 * registered on the bus. The I3C stack might still consider 0xb a free
	 * address. If a subsequent Hotjoin occurs, 0xb might be assigned to Device A,
	 * causing both devices A and B to use the same address 0xb, violating the I3C
	 * specification.
	 *
	 * The return value for i3c_master_add_i3c_dev_locked() should not be checked
	 * because subsequent steps will scan the entire I3C bus, independent of
	 * whether i3c_master_add_i3c_dev_locked() returns success.
	 *
	 * If device A registration fails, there is still a chance to register device
	 * B. i3c_master_add_i3c_dev_locked() can reset DAA if a failure occurs while
	 * retrieving device information.
	 */
	for (i = 0; i < dev_nb; i++)
		i3c_master_add_i3c_dev_locked(m, addrs[i]);

	/* Configure IBI auto-rules */
	ret = svc_i3c_update_ibirules(master);
	if (ret)
		dev_err(master->dev, "Cannot handle such a list of devices");

	return ret;
}

static int svc_i3c_master_read(struct svc_i3c_master *master,
			       u8 *in, unsigned int len)
{
	int offset = 0, i;
	u32 mdctrl, mstatus;
	bool completed = false;
	unsigned int count;
	ktime_t timeout;

	timeout = ktime_add_ms(ktime_get(), 1000);
	while (!completed) {
		mstatus = readl(master->regs + SVC_I3C_MSTATUS);
		if (SVC_I3C_MSTATUS_COMPLETE(mstatus) != 0)
			completed = true;

		if (ktime_compare(ktime_get(), timeout) > 0) {
			dev_err(master->dev, "I3C read timeout, count=%d/%d\n", offset, len);
			return -ETIMEDOUT;
		}

		mdctrl = readl(master->regs + SVC_I3C_MDATACTRL);
		count = SVC_I3C_MDATACTRL_RXCOUNT(mdctrl);
		if (offset + count > len) {
			dev_err(master->dev, "I3C receive length too long!\n");
			return -EINVAL;
		}
		for (i = 0; i < count; i++)
			in[offset + i] = readl(master->regs + SVC_I3C_MRDATAB);

		offset += count;
	}

	return offset;
}

static int svc_i3c_master_write(struct svc_i3c_master *master,
				const u8 *out, unsigned int len)
{
	int offset = 0, ret;
	u32 mdctrl;

	while (offset < len) {
		ret = readl_poll_timeout(master->regs + SVC_I3C_MDATACTRL,
					 mdctrl,
					 !(mdctrl & SVC_I3C_MDATACTRL_TXFULL),
					 0, 1000);
		if (ret)
			return ret;

		/*
		 * The last byte to be sent over the bus must either have the
		 * "end" bit set or be written in MWDATABE.
		 */
		if (likely(offset < (len - 1)))
			writel(out[offset++], master->regs + SVC_I3C_MWDATAB);
		else
			writel(out[offset++], master->regs + SVC_I3C_MWDATABE);
	}

	return 0;
}

static int svc_i3c_master_xfer(struct svc_i3c_master *master,
			       bool rnw, unsigned int xfer_type, u8 addr,
			       u8 *in, const u8 *out, unsigned int xfer_len,
			       unsigned int *actual_len, bool continued)
{
	bool no_data = xfer_len ? false : true;
	u32 reg, rdterm = *actual_len, mstatus;
	bool restarted = false;
	u32 ibitype;
	int ret;

	/* clean SVC_I3C_MINT_IBIWON w1c bits */
	writel(SVC_I3C_MINT_IBIWON, master->regs + SVC_I3C_MSTATUS);

	if (rdterm > SVC_I3C_MAX_RDTERM)
		rdterm = 0;

	/*
	 * HW issue:
	 * I3C HW stalls the write transfer if the transmit FIFO becomes empty,
	 * when new data is written to FIFO, I3C HW resumes the transfer but
	 * the first transmitted data bit may have the wrong value.
	 * Workaround:
	 * Fill the FIFO in advance to prevent FIFO from becoming empty.
	 */
	if (!rnw && xfer_len && !restarted) {
		u32 end = xfer_len > SVC_I3C_FIFO_SIZE ? 0 : SVC_I3C_MWDATAB_END;
		u32 len = min_t(u32, xfer_len, SVC_I3C_FIFO_SIZE);

		writesb(master->regs + SVC_I3C_MWDATAB1, out, len - 1);
		/* Mark END bit if this is the last byte */
		writel(out[len - 1] | end, master->regs + SVC_I3C_MWDATAB);
		xfer_len -= len;
		out += len;
	}

restart:
	writel(SVC_I3C_MCTRL_REQUEST_START_ADDR |
	       xfer_type |
	       SVC_I3C_MCTRL_IBIRESP_NACK |
	       SVC_I3C_MCTRL_DIR(rnw) |
	       SVC_I3C_MCTRL_ADDR(addr) |
	       SVC_I3C_MCTRL_RDTERM(rdterm),
	       master->regs + SVC_I3C_MCTRL);

	ret = readl_poll_timeout(master->regs + SVC_I3C_MSTATUS, reg,
				 SVC_I3C_MSTATUS_MCTRLDONE(reg), 0, 1000);
	if (ret)
		goto emit_stop;

	mstatus = readl(master->regs + SVC_I3C_MSTATUS);

	/* NACK the slave event, restart the original transfer */
	if (SVC_I3C_MSTATUS_IBIWON(mstatus) && !restarted) {
		ibitype = SVC_I3C_MSTATUS_IBITYPE(mstatus);
		writel(SVC_I3C_MINT_IBIWON, master->regs + SVC_I3C_MSTATUS);

		/* Hardware can't auto emit NACK for hot join and master request */
		switch (ibitype) {
			case SVC_I3C_MSTATUS_IBITYPE_HOT_JOIN:
			case SVC_I3C_MSTATUS_IBITYPE_MASTER_REQUEST:
			svc_i3c_master_nack_ibi(master);
		}
		if (rnw)
			master->rd_ibiwon_cnt++;
		else
			master->wr_ibiwon_cnt++;

		restarted = true;
		goto restart;
	}

	if (SVC_I3C_MSTATUS_NACKED(mstatus)) {
		dev_dbg(master->dev, "addr 0x%x NACK\n", addr);
		ret = -EIO;
		goto emit_stop;
	}

	if (rnw)
		ret = svc_i3c_master_read(master, in, xfer_len);
	else
		ret = svc_i3c_master_write(master, out, xfer_len);
	if (ret < 0)
		goto emit_stop;

	if (rnw)
		*actual_len = ret;

	if (!no_data) {
		ret = readl_poll_timeout(master->regs + SVC_I3C_MSTATUS, reg,
					 SVC_I3C_MSTATUS_COMPLETE(reg), 0, 1000);
		if (ret)
			goto emit_stop;

		writel(SVC_I3C_MINT_COMPLETE, master->regs + SVC_I3C_MSTATUS);
	}

	if (!continued)
		svc_i3c_master_emit_stop(master);

	return 0;

emit_stop:
	/*
	 * If the read transfer is not completed, update RDTERM value to
	 * terminate the transfer and let emitting STOP work normally.
	 */
	if (rnw && ret == -ETIMEDOUT) {
		writel(SVC_I3C_MCTRL_RDTERM(1), master->regs + SVC_I3C_MCTRL);
		svc_i3c_master_flush_fifo(master);
		readl_poll_timeout(master->regs + SVC_I3C_MSTATUS, reg,
				   SVC_I3C_MSTATUS_COMPLETE(reg), 0, 1000);
	}
	svc_i3c_master_flush_fifo(master);
	svc_i3c_master_emit_stop(master);
	svc_i3c_master_clear_merrwarn(master);

	return ret;
}

static struct svc_i3c_xfer *
svc_i3c_master_alloc_xfer(struct svc_i3c_master *master, unsigned int ncmds)
{
	struct svc_i3c_xfer *xfer;

	xfer = kzalloc(struct_size(xfer, cmds, ncmds), GFP_KERNEL);
	if (!xfer)
		return NULL;

	INIT_LIST_HEAD(&xfer->node);
	xfer->ncmds = ncmds;
	xfer->ret = -ETIMEDOUT;

	return xfer;
}

static void svc_i3c_master_free_xfer(struct svc_i3c_xfer *xfer)
{
	kfree(xfer);
}

static void svc_i3c_master_dequeue_xfer_locked(struct svc_i3c_master *master,
					       struct svc_i3c_xfer *xfer)
{
	if (master->xferqueue.cur == xfer)
		master->xferqueue.cur = NULL;
	else
		list_del_init(&xfer->node);
}

static void svc_i3c_master_dequeue_xfer(struct svc_i3c_master *master,
					struct svc_i3c_xfer *xfer)
{
	unsigned long flags;

	spin_lock_irqsave(&master->xferqueue.lock, flags);
	svc_i3c_master_dequeue_xfer_locked(master, xfer);
	spin_unlock_irqrestore(&master->xferqueue.lock, flags);
}

static void svc_i3c_master_start_xfer_locked(struct svc_i3c_master *master)
{
	struct svc_i3c_xfer *xfer = master->xferqueue.cur;
	int retry = 2;
	int ret, i;

	if (!xfer)
		return;

	svc_i3c_master_clear_merrwarn(master);
	svc_i3c_master_flush_fifo(master);

	for (i = 0; i < xfer->ncmds; i++) {
		struct svc_i3c_cmd *cmd = &xfer->cmds[i];
again:
		ret = svc_i3c_master_xfer(master, cmd->rnw, xfer->type,
					  cmd->addr, cmd->in, cmd->out,
					  cmd->len, &cmd->actual_len,
					  cmd->continued);
		if (ret == -EAGAIN && --retry)
			goto again;
		if (ret)
			break;
	}

	xfer->ret = ret;
	complete(&xfer->comp);

	if (ret < 0)
		svc_i3c_master_dequeue_xfer_locked(master, xfer);

	xfer = list_first_entry_or_null(&master->xferqueue.list,
					struct svc_i3c_xfer,
					node);
	if (xfer)
		list_del_init(&xfer->node);

	master->xferqueue.cur = xfer;
	svc_i3c_master_start_xfer_locked(master);
}

static void svc_i3c_master_enqueue_xfer(struct svc_i3c_master *master,
					struct svc_i3c_xfer *xfer)
{
	unsigned long flags;

	init_completion(&xfer->comp);
	spin_lock_irqsave(&master->xferqueue.lock, flags);
	if (master->xferqueue.cur) {
		list_add_tail(&xfer->node, &master->xferqueue.list);
	} else {
		master->xferqueue.cur = xfer;
		svc_i3c_master_start_xfer_locked(master);
	}
	spin_unlock_irqrestore(&master->xferqueue.lock, flags);
}

static bool
svc_i3c_master_supports_ccc_cmd(struct i3c_master_controller *master,
				const struct i3c_ccc_cmd *cmd)
{
	/* No software support for CCC commands targeting more than one slave */
	return (cmd->ndests == 1);
}

static int svc_i3c_master_send_bdcast_ccc_cmd(struct svc_i3c_master *master,
					      struct i3c_ccc_cmd *ccc)
{
	unsigned int xfer_len = ccc->dests[0].payload.len + 1;
	struct svc_i3c_xfer *xfer;
	struct svc_i3c_cmd *cmd;
	u8 *buf;
	int ret;

	xfer = svc_i3c_master_alloc_xfer(master, 1);
	if (!xfer)
		return -ENOMEM;

	buf = kmalloc(xfer_len, GFP_KERNEL);
	if (!buf) {
		svc_i3c_master_free_xfer(xfer);
		return -ENOMEM;
	}

	buf[0] = ccc->id;
	memcpy(&buf[1], ccc->dests[0].payload.data, ccc->dests[0].payload.len);

	xfer->type = SVC_I3C_MCTRL_TYPE_I3C;

	cmd = &xfer->cmds[0];
	cmd->addr = ccc->dests[0].addr;
	cmd->rnw = ccc->rnw;
	cmd->in = NULL;
	cmd->out = buf;
	cmd->len = xfer_len;
	cmd->actual_len = 0;
	cmd->continued = false;

	mutex_lock(&master->lock);
	svc_i3c_master_enqueue_xfer(master, xfer);
	if (!wait_for_completion_timeout(&xfer->comp, msecs_to_jiffies(1000)))
		svc_i3c_master_dequeue_xfer(master, xfer);
	mutex_unlock(&master->lock);

	ret = xfer->ret;
	kfree(buf);
	svc_i3c_master_free_xfer(xfer);

	return ret;
}

static int svc_i3c_master_send_direct_ccc_cmd(struct svc_i3c_master *master,
					      struct i3c_ccc_cmd *ccc)
{
	unsigned int xfer_len = ccc->dests[0].payload.len;
	unsigned int actual_len = ccc->rnw ? xfer_len : 0;
	struct svc_i3c_xfer *xfer;
	struct svc_i3c_cmd *cmd;
	int ret;

	xfer = svc_i3c_master_alloc_xfer(master, 2);
	if (!xfer)
		return -ENOMEM;

	xfer->type = SVC_I3C_MCTRL_TYPE_I3C;

	/* Broadcasted message */
	cmd = &xfer->cmds[0];
	cmd->addr = I3C_BROADCAST_ADDR;
	cmd->rnw = 0;
	cmd->in = NULL;
	cmd->out = &ccc->id;
	cmd->len = 1;
	cmd->actual_len = 0;
	cmd->continued = true;

	/* Directed message */
	cmd = &xfer->cmds[1];
	cmd->addr = ccc->dests[0].addr;
	cmd->rnw = ccc->rnw;
	cmd->in = ccc->rnw ? ccc->dests[0].payload.data : NULL;
	cmd->out = ccc->rnw ? NULL : ccc->dests[0].payload.data;
	cmd->len = xfer_len;
	cmd->actual_len = actual_len;
	cmd->continued = false;

	mutex_lock(&master->lock);
	svc_i3c_master_enqueue_xfer(master, xfer);
	if (!wait_for_completion_timeout(&xfer->comp, msecs_to_jiffies(1000)))
		svc_i3c_master_dequeue_xfer(master, xfer);
	mutex_unlock(&master->lock);

	if (cmd->actual_len != xfer_len)
		ccc->dests[0].payload.len = cmd->actual_len;

	ret = xfer->ret;
	svc_i3c_master_free_xfer(xfer);

	return ret;
}

static int svc_i3c_master_send_ccc_cmd(struct i3c_master_controller *m,
				       struct i3c_ccc_cmd *cmd)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	bool broadcast = cmd->id < 0x80;
	int ret;

	if (broadcast)
		ret = svc_i3c_master_send_bdcast_ccc_cmd(master, cmd);
	else
		ret = svc_i3c_master_send_direct_ccc_cmd(master, cmd);

	if (ret) {
		dev_dbg(master->dev, "send ccc 0x%02x %s, ret = %d\n",
				cmd->id, broadcast ? "(broadcast)" : "", ret);
		cmd->err = I3C_ERROR_M2;
	}

	return ret;
}

static int svc_i3c_master_priv_xfers(struct i3c_dev_desc *dev,
				     struct i3c_priv_xfer *xfers,
				     int nxfers)
{
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_i2c_dev_data *data = i3c_dev_get_master_data(dev);
	struct svc_i3c_xfer *xfer;
	int ret, i;

	xfer = svc_i3c_master_alloc_xfer(master, nxfers);
	if (!xfer)
		return -ENOMEM;

	xfer->type = SVC_I3C_MCTRL_TYPE_I3C;

	for (i = 0; i < nxfers; i++) {
		struct svc_i3c_cmd *cmd = &xfer->cmds[i];

		cmd->addr = master->addrs[data->index];
		cmd->rnw = xfers[i].rnw;
		cmd->in = xfers[i].rnw ? xfers[i].data.in : NULL;
		cmd->out = xfers[i].rnw ? NULL : xfers[i].data.out;
		cmd->len = xfers[i].len;
		cmd->actual_len = xfers[i].rnw ? xfers[i].len : 0;
		cmd->continued = (i + 1) < nxfers;
	}

	mutex_lock(&master->lock);
	svc_i3c_master_enqueue_xfer(master, xfer);
	if (!wait_for_completion_timeout(&xfer->comp, msecs_to_jiffies(1000)))
		svc_i3c_master_dequeue_xfer(master, xfer);
	mutex_unlock(&master->lock);

	for (i = 0; i < nxfers; i++) {
		struct svc_i3c_cmd *cmd = &xfer->cmds[i];

		if (xfers[i].rnw)
			xfers[i].len = cmd->actual_len;
	}

	ret = xfer->ret;
	svc_i3c_master_free_xfer(xfer);

	return ret;
}

static int svc_i3c_master_i2c_xfers(struct i2c_dev_desc *dev,
				    const struct i2c_msg *xfers,
				    int nxfers)
{
	struct i3c_master_controller *m = i2c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_i2c_dev_data *data = i2c_dev_get_master_data(dev);
	struct svc_i3c_xfer *xfer;
	int ret, i;

	xfer = svc_i3c_master_alloc_xfer(master, nxfers);
	if (!xfer)
		return -ENOMEM;

	xfer->type = SVC_I3C_MCTRL_TYPE_I2C;

	for (i = 0; i < nxfers; i++) {
		struct svc_i3c_cmd *cmd = &xfer->cmds[i];

		cmd->addr = master->addrs[data->index];
		cmd->rnw = xfers[i].flags & I2C_M_RD;
		cmd->in = cmd->rnw ? xfers[i].buf : NULL;
		cmd->out = cmd->rnw ? NULL : xfers[i].buf;
		cmd->len = xfers[i].len;
		cmd->actual_len = cmd->rnw ? xfers[i].len : 0;
		cmd->continued = (i + 1 < nxfers);
	}

	mutex_lock(&master->lock);
	svc_i3c_master_enqueue_xfer(master, xfer);
	if (!wait_for_completion_timeout(&xfer->comp, msecs_to_jiffies(1000)))
		svc_i3c_master_dequeue_xfer(master, xfer);
	mutex_unlock(&master->lock);

	ret = xfer->ret;
	svc_i3c_master_free_xfer(xfer);

	return ret;
}

static int svc_i3c_master_request_ibi(struct i3c_dev_desc *dev,
				      const struct i3c_ibi_setup *req)
{
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_i2c_dev_data *data = i3c_dev_get_master_data(dev);
	unsigned long flags;
	unsigned int i;

	if (dev->ibi->max_payload_len > SVC_I3C_MAX_IBI_PAYLOAD_SIZE) {
		dev_err(master->dev, "IBI max payload %d should be < %d\n",
			dev->ibi->max_payload_len, SVC_I3C_MAX_IBI_PAYLOAD_SIZE + 1);
		return -ERANGE;
	}

	data->ibi_pool = i3c_generic_ibi_alloc_pool(dev, req);
	if (IS_ERR(data->ibi_pool))
		return PTR_ERR(data->ibi_pool);

	spin_lock_irqsave(&master->ibi.lock, flags);
	for (i = 0; i < master->ibi.num_slots; i++) {
		if (!master->ibi.slots[i]) {
			data->ibi = i;
			master->ibi.slots[i] = dev;
			break;
		}
	}
	spin_unlock_irqrestore(&master->ibi.lock, flags);

	if (i < master->ibi.num_slots)
		return 0;

	i3c_generic_ibi_free_pool(data->ibi_pool);
	data->ibi_pool = NULL;

	return -ENOSPC;
}

static void svc_i3c_master_free_ibi(struct i3c_dev_desc *dev)
{
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_i2c_dev_data *data = i3c_dev_get_master_data(dev);
	unsigned long flags;

	spin_lock_irqsave(&master->ibi.lock, flags);
	master->ibi.slots[data->ibi] = NULL;
	data->ibi = -1;
	spin_unlock_irqrestore(&master->ibi.lock, flags);

	i3c_generic_ibi_free_pool(data->ibi_pool);
}

static int svc_i3c_master_enable_ibi(struct i3c_dev_desc *dev)
{
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_i2c_dev_data *data = i3c_dev_get_master_data(dev);
	int ret;

	ret = i3c_master_enec_locked(m, dev->info.dyn_addr, I3C_CCC_EVENT_SIR);
	if (ret)
		return ret;

	if (data->ibi >= 0)
		master->enabled_events |= (1 << data->ibi);
	svc_i3c_master_enable_interrupts(master, SVC_I3C_MINT_SLVSTART);

	return 0;
}

static int svc_i3c_master_disable_ibi(struct i3c_dev_desc *dev)
{
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_i2c_dev_data *data = i3c_dev_get_master_data(dev);
	int ret;

	if (data->ibi >= 0)
		master->enabled_events &= ~(1 << data->ibi);
	if (!master->enabled_events)
		svc_i3c_master_disable_interrupts(master);

	ret = i3c_master_disec_locked(m, dev->info.dyn_addr, I3C_CCC_EVENT_SIR);

	return ret;
}

static int svc_i3c_master_enable_hotjoin(struct i3c_master_controller *m)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);

	master->enabled_events |= SVC_I3C_EVENT_HOTJOIN;

	svc_i3c_master_enable_interrupts(master, SVC_I3C_MINT_SLVSTART);

	return 0;
}

static int svc_i3c_master_disable_hotjoin(struct i3c_master_controller *m)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);

	master->enabled_events &= ~SVC_I3C_EVENT_HOTJOIN;

	if (!master->enabled_events)
		svc_i3c_master_disable_interrupts(master);

	return 0;
}

static void svc_i3c_master_recycle_ibi_slot(struct i3c_dev_desc *dev,
					    struct i3c_ibi_slot *slot)
{
	struct svc_i3c_i2c_dev_data *data = i3c_dev_get_master_data(dev);

	i3c_generic_ibi_recycle_slot(data->ibi_pool, slot);
}

static const struct i3c_master_controller_ops svc_i3c_master_ops = {
	.bus_init = svc_i3c_master_bus_init,
	.bus_cleanup = svc_i3c_master_bus_cleanup,
	.attach_i3c_dev = svc_i3c_master_attach_i3c_dev,
	.detach_i3c_dev = svc_i3c_master_detach_i3c_dev,
	.reattach_i3c_dev = svc_i3c_master_reattach_i3c_dev,
	.attach_i2c_dev = svc_i3c_master_attach_i2c_dev,
	.detach_i2c_dev = svc_i3c_master_detach_i2c_dev,
	.do_daa = svc_i3c_master_do_daa,
	.supports_ccc_cmd = svc_i3c_master_supports_ccc_cmd,
	.send_ccc_cmd = svc_i3c_master_send_ccc_cmd,
	.priv_xfers = svc_i3c_master_priv_xfers,
	.i2c_xfers = svc_i3c_master_i2c_xfers,
	.request_ibi = svc_i3c_master_request_ibi,
	.free_ibi = svc_i3c_master_free_ibi,
	.recycle_ibi_slot = svc_i3c_master_recycle_ibi_slot,
	.enable_ibi = svc_i3c_master_enable_ibi,
	.disable_ibi = svc_i3c_master_disable_ibi,
	.enable_hotjoin = svc_i3c_master_enable_hotjoin,
	.disable_hotjoin = svc_i3c_master_disable_hotjoin,
};

static int svc_i3c_master_prepare_clks(struct svc_i3c_master *master)
{
	int ret = 0;

	ret = clk_prepare_enable(master->pclk);
	if (ret)
		return ret;

	ret = clk_prepare_enable(master->fclk);
	if (ret) {
		clk_disable_unprepare(master->pclk);
		return ret;
	}

	return 0;
}

static void svc_i3c_master_unprepare_clks(struct svc_i3c_master *master)
{
	clk_disable_unprepare(master->pclk);
	clk_disable_unprepare(master->fclk);
}

static struct dentry *svc_i3c_debugfs_dir;
static int debug_show(struct seq_file *seq, void *v)
{
	struct svc_i3c_master *master = seq->private;

	seq_printf(seq, "MSTATUS=0x%x\n", readl(master->regs + SVC_I3C_MSTATUS));
	seq_printf(seq, "MERRWARN=0x%x\n", readl(master->regs + SVC_I3C_MERRWARN));
	seq_printf(seq, "MCTRL=0x%x\n", readl(master->regs + SVC_I3C_MCTRL));
	seq_printf(seq, "MDATACTRL=0x%x\n", readl(master->regs + SVC_I3C_MDATACTRL));
	seq_printf(seq, "MCONFIG=0x%x\n", readl(master->regs + SVC_I3C_MCONFIG));

	return 0;
}

DEFINE_SHOW_ATTRIBUTE(debug);

static void svc_i3c_init_debugfs(struct platform_device *pdev,
				 struct svc_i3c_master *master)
{
	if (!svc_i3c_debugfs_dir) {
		svc_i3c_debugfs_dir = debugfs_create_dir("npcm_i3c", NULL);
		if (!svc_i3c_debugfs_dir)
			return;
	}

	master->debugfs = debugfs_create_dir(dev_name(&pdev->dev),
					     svc_i3c_debugfs_dir);
	if (!master->debugfs)
		return;

	debugfs_create_file("debug", 0444, master->debugfs, master, &debug_fops);
	debugfs_create_u64("err_cnt", 0444, master->debugfs, &master->err_cnt);
	debugfs_create_u8("err_code", 0444, master->debugfs, &master->err_code);
	debugfs_create_u64("rd_ibiwon_cnt", 0444, master->debugfs, &master->rd_ibiwon_cnt);
	debugfs_create_u64("wr_ibiwon_cnt", 0444, master->debugfs, &master->wr_ibiwon_cnt);
}

static int svc_i3c_master_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct svc_i3c_master *master;
	struct reset_control *reset;
	u32 val;
	int ret;

	master = devm_kzalloc(dev, sizeof(*master), GFP_KERNEL);
	if (!master)
		return -ENOMEM;

	master->regs = devm_platform_ioremap_resource(pdev, 0);
	if (IS_ERR(master->regs))
		return PTR_ERR(master->regs);

	master->pclk = devm_clk_get(dev, "pclk");
	if (IS_ERR(master->pclk))
		return PTR_ERR(master->pclk);

	master->fclk = devm_clk_get(dev, "fast_clk");
	if (IS_ERR(master->fclk))
		return PTR_ERR(master->fclk);

	master->irq = platform_get_irq(pdev, 0);
	if (master->irq < 0)
		return master->irq;

	master->dev = dev;

	ret = svc_i3c_master_prepare_clks(master);
	if (ret)
		return ret;

	reset = devm_reset_control_get(&pdev->dev, NULL);
	if (!IS_ERR(reset)) {
		reset_control_assert(reset);
		udelay(5);
		reset_control_deassert(reset);
	}
	INIT_WORK(&master->hj_work, svc_i3c_master_hj_work);
	mutex_init(&master->lock);

	ret = devm_request_irq(dev, master->irq, svc_i3c_master_irq_handler,
			       IRQF_NO_SUSPEND, "npcm-i3c-irq", master);
	if (ret)
		goto err_disable_clks;

	master->free_slots = GENMASK(SVC_I3C_MAX_DEVS - 1, 0);

	spin_lock_init(&master->xferqueue.lock);
	INIT_LIST_HEAD(&master->xferqueue.list);

	spin_lock_init(&master->ibi.lock);
	master->ibi.num_slots = SVC_I3C_MAX_DEVS;
	master->ibi.slots = devm_kcalloc(&pdev->dev, master->ibi.num_slots,
					 sizeof(*master->ibi.slots),
					 GFP_KERNEL);
	if (!master->ibi.slots) {
		ret = -ENOMEM;
		goto err_disable_clks;
	}

	platform_set_drvdata(pdev, master);

	if (of_property_read_bool(dev->of_node, "enable-hj"))
		master->en_hj = true;
	if (!of_property_read_u32(dev->of_node, "i3c-pp-scl-hi-period-ns", &val))
		master->scl_timing.i3c_pp_hi = val;

	if (!of_property_read_u32(dev->of_node, "i3c-pp-scl-lo-period-ns", &val))
		master->scl_timing.i3c_pp_lo = val;

	if (!of_property_read_u32(dev->of_node, "i3c-od-scl-hi-period-ns", &val))
		master->scl_timing.i3c_od_hi = val;

	if (!of_property_read_u32(dev->of_node, "i3c-od-scl-lo-period-ns", &val))
		master->scl_timing.i3c_od_lo = val;

	svc_i3c_init_debugfs(pdev, master);
	svc_i3c_master_reset(master);

	/* Register the master */
	ret = i3c_master_register(&master->base, &pdev->dev,
				  &svc_i3c_master_ops, false);
	if (ret)
		goto err_disable_clks;

	if (master->en_hj) {
		dev_info(master->dev, "enable hot-join\n");
		master->enabled_events |= SVC_I3C_EVENT_HOTJOIN;
		svc_i3c_master_enable_interrupts(master, SVC_I3C_MINT_SLVSTART);
	}
	return 0;

err_disable_clks:
	debugfs_remove_recursive(master->debugfs);
	svc_i3c_master_unprepare_clks(master);

	return ret;
}

static void svc_i3c_master_remove(struct platform_device *pdev)
{
	struct svc_i3c_master *master = platform_get_drvdata(pdev);

	/* Avoid ibi events during driver unbinding */
	writel(SVC_I3C_MINT_SLVSTART, master->regs + SVC_I3C_MINTCLR);

	debugfs_remove_recursive(master->debugfs);

	i3c_master_unregister(&master->base);
}

static const struct of_device_id svc_i3c_master_of_match_tbl[] = {
	{ .compatible = "nuvoton,npcm845-i3c-v1" },
	{ /* sentinel */ },
};
MODULE_DEVICE_TABLE(of, svc_i3c_master_of_match_tbl);

static struct platform_driver svc_i3c_master = {
	.probe = svc_i3c_master_probe,
	.remove = svc_i3c_master_remove,
	.driver = {
		.name = "npcm845-i3c-master",
		.of_match_table = svc_i3c_master_of_match_tbl,
	},
};
module_platform_driver(svc_i3c_master);

MODULE_AUTHOR("Stanley Chu <yschu@nuvoton.com>");
MODULE_AUTHOR("James Chiang <cpchiang1@nuvoton.com>");
MODULE_DESCRIPTION("Nuvoton NPCM845 I3C controller driver");
MODULE_LICENSE("GPL v2");
