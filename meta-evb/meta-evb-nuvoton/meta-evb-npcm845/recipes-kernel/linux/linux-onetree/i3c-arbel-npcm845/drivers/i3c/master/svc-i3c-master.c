// SPDX-License-Identifier: GPL-2.0
/*
 * Silvaco dual-role I3C master driver
 *
 * Copyright (C) 2020 Silvaco
 * Author: Miquel RAYNAL <miquel.raynal@bootlin.com>
 * Based on a work from: Conor Culhane <conor.culhane@silvaco.com>
 */

#include <linux/bitfield.h>
#include <linux/clk.h>
#include <linux/completion.h>
#include <linux/debugfs.h>
#include <linux/dmaengine.h>
#include <linux/dma-mapping.h>
#include <linux/dma/npcm_gdma.h>
#include <linux/errno.h>
#include <linux/i3c/master.h>
#include <linux/i3c/target.h>
#include <linux/interrupt.h>
#include <linux/iopoll.h>
#include <linux/list.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/of.h>
#include <linux/reset.h>
#include <linux/pinctrl/consumer.h>
#include <linux/platform_device.h>
#include <linux/pm_runtime.h>

/* Slave Mode Registers */
#define SVC_I3C_CONFIG      0x004
#define   SVC_I3C_CONFIG_SLVEN BIT(0)
#define   SVC_I3C_CONFIG_DDROK BIT(4)
#define SVC_I3C_STATUS      0x008
#define   SVC_I3C_STATUS_RXPEND(x) FIELD_GET(SVC_I3C_INT_RXPEND, (x))
#define   SVC_I3C_STATUS_STREQWR(x) (x & BIT(4))
#define   SVC_I3C_STATUS_DDRMATCH BIT(16)
#define   SVC_I3C_STATUS_STOP BIT(10)
#define SVC_I3C_CTRL        0x00C
#define   SVC_I3C_CTRL_EVENT(x) FIELD_PREP(GENMASK(1, 0), (x))
#define   SVC_I3C_CTRL_EVENT_HOT_JOIN 3
#define   SVC_I3C_CTRL_PENDINT(x) FIELD_PREP(GENMASK(19, 16), (x))
#define SVC_I3C_INTSET      0x010
#define   SVC_I3C_INT_STOP BIT(10)
#define   SVC_I3C_INT_RXPEND BIT(11)
#define   SVC_I3C_INT_TXNOTFULL BIT(12)
#define SVC_I3C_INTCLR      0x014
#define SVC_I3C_INTMASKED   0x018
#define SVC_I3C_ERRWARN     0x01C
#define SVC_I3C_DMACTRL     0x020
#define   SVC_I3C_DMACTRL_DMAFB(x) FIELD_PREP(GENMASK(1, 0), (x))
#define   SVC_I3C_DMACTRL_DMATB(x) FIELD_PREP(GENMASK(3, 2), (x))
#define   SVC_I3C_DMACTRL_DMAWIDTH(x) FIELD_PREP(GENMASK(5, 4), (x))
#define SVC_I3C_DATACTRL    0x02C
#define   SVC_I3C_DATACTRL_FLUSHTB BIT(0)
#define   SVC_I3C_DATACTRL_FLUSHRB BIT(1)
#define   SVC_I3C_DATACTRL_TXFULL BIT(30)
#define   SVC_I3C_DATACTRL_TXCOUNT(x) FIELD_GET(GENMASK(20, 16), (x))
#define   SVC_I3C_DATACTRL_RXCOUNT(x) FIELD_GET(GENMASK(28, 24), (x))
#define SVC_I3C_WDATAB      0x030
#define SVC_I3C_WDATABE     0x034
#define SVC_I3C_RDATAB      0x040
#define SVC_I3C_MAXLIMITS   0x068
#define   SVC_I3C_MAXLIMITS_MAXWR(x) FIELD_PREP(GENMASK(27, 16), (x))
#define   SVC_I3C_MAXLIMITS_MAXRD(x) FIELD_PREP(GENMASK(11, 0), (x))
#define SVC_I3C_PARTNO      0x06C
#define SVC_I3C_IDEXT       0x070
#define   SVC_I3C_IDEXT_BCR(x) FIELD_PREP(GENMASK(23 16), (x))
#define   SVC_I3C_IDEXT_DCR(x) FIELD_PREP(GENMASK(15, 8), (x))

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
#define   SVC_I3C_MCTRL_REQUEST_FORCE_EXIT 6
#define   SVC_I3C_MCTRL_REQUEST_AUTO_IBI 7
#define   SVC_I3C_MCTRL_TYPE_I3C 0
#define   SVC_I3C_MCTRL_TYPE_I2C BIT(4)
#define   SVC_I3C_MCTRL_TYPE_I3C_DDR BIT(5)
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
#define   SVC_I3C_MSTATUS_STATE(x) FIELD_GET(GENMASK(2, 0), (x))
#define   SVC_I3C_MSTATUS_STATE_DAA(x) (SVC_I3C_MSTATUS_STATE(x) == 5)
#define   SVC_I3C_MSTATUS_STATE_IDLE(x) (SVC_I3C_MSTATUS_STATE(x) == 0)
#define   SVC_I3C_MSTATUS_STATE_SLVREQ(x) (SVC_I3C_MSTATUS_STATE(x) == 1)
#define   SVC_I3C_MSTATUS_STATE_IBIACK(x) (SVC_I3C_MSTATUS_STATE(x) == 6)
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
#define   SVC_I3C_MERRWARN_NACK(x) FIELD_GET(BIT(2), (x))
#define   SVC_I3C_MERRWARN_TIMEOUT BIT(20)
#define   SVC_I3C_MERRWARN_HCRC(x) FIELD_GET(BIT(10), (x))
#define SVC_I3C_MDMACTRL     0x0A0
#define   SVC_I3C_MDMACTRL_DMAFB(x) FIELD_PREP(GENMASK(1, 0), (x))
#define   SVC_I3C_MDMACTRL_DMATB(x) FIELD_PREP(GENMASK(3, 2), (x))
#define   SVC_I3C_MDMACTRL_DMAWIDTH(x) FIELD_PREP(GENMASK(5, 4), (x))
#define SVC_I3C_MDATACTRL    0x0AC
#define   SVC_I3C_MDATACTRL_FLUSHTB BIT(0)
#define   SVC_I3C_MDATACTRL_FLUSHRB BIT(1)
#define   SVC_I3C_MDATACTRL_UNLOCK_TRIG BIT(3)
#define   SVC_I3C_MDATACTRL_TXTRIG_FIFO_NOT_FULL GENMASK(5, 4)
#define   SVC_I3C_MDATACTRL_RXTRIG_FIFO_NOT_EMPTY 0
#define   SVC_I3C_MDATACTRL_RXCOUNT(x) FIELD_GET(GENMASK(28, 24), (x))
#define   SVC_I3C_MDATACTRL_TXCOUNT(x) FIELD_GET(GENMASK(20, 16), (x))
#define   SVC_I3C_MDATACTRL_TXFULL BIT(30)
#define   SVC_I3C_MDATACTRL_RXEMPTY BIT(31)

#define SVC_I3C_MWDATAB      0x0B0
#define   SVC_I3C_MWDATAB_END BIT(8)

#define SVC_I3C_MWDATABE     0x0B4
#define SVC_I3C_MWDATAH      0x0B8
#define SVC_I3C_MWDATAHE     0x0BC
#define SVC_I3C_MRDATAB      0x0C0
#define SVC_I3C_MRDATAH      0x0C8
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

#define HDR_COMMAND	0x20
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

/* DMA definitions */
#define MAX_DMA_COUNT		1024
#define SVC_I3C_GDMA_MUX(n)	(((n & 0xFFFF) >> 12) * 2 + 6)

struct svc_i3c_cmd {
	u8 addr;
	bool rnw;
	u8 *in;
	const void *out;
	unsigned int len;
	unsigned int actual_len;
	struct i3c_priv_xfer *xfer;
	bool continued;
	bool use_dma;
};

struct svc_i3c_xfer {
	struct list_head node;
	struct completion comp;
	int ret;
	unsigned int type;
	unsigned int ncmds;
	struct svc_i3c_cmd cmds[];
};

struct svc_i3c_regs_save {
	u32 mconfig;
	u32 mdynaddr;
};

struct npcm_dma_xfer_desc {
	const u8 *out;
	u8 *in;
	u32 len;
	u32 actual_len;
	bool rnw;
	bool end;
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
 * @sclk: Slow clock (other events)
 * @xferqueue: Transfer queue structure
 * @xferqueue.list: List member
 * @xferqueue.cur: Current ongoing transfer
 * @xferqueue.lock: Queue lock
 * @ibi: IBI structure
 * @ibi.num_slots: Number of slots available in @ibi.slots
 * @ibi.slots: Available IBI slots
 * @ibi.tbq_slot: To be queued IBI slot
 * @ibi.lock: IBI lock
 * @lock: Transfer lock, prevent concurrent daa/priv_xfer/ccc
 * @req_lock: protect between IBI isr and bus operation request
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
	struct clk *sclk;
	struct {
		u32 i3c_pp_hi;
		u32 i3c_pp_lo;
		u32 i3c_od_hi;
		u32 i3c_od_lo;
	} scl_timing;
	struct {
		struct list_head list;
		struct svc_i3c_xfer *cur;
	} xferqueue;
	struct {
		unsigned int num_slots;
		struct i3c_dev_desc **slots;
		struct i3c_ibi_slot *tbq_slot;
		/* Prevent races within IBI handlers */
		spinlock_t lock;
	} ibi;
	spinlock_t req_lock;
	struct mutex lock;
	struct dentry *debugfs;

	struct {
		struct svc_i3c_xfer *cur;
		struct svc_i3c_xfer *pending_rd;
		spinlock_t lock;
	} slave;

	/* For DMA */
	struct dma_chan *chan_tx;
	struct dma_chan *chan_rx;
	dma_cookie_t cookie;
	bool use_dma;
	struct completion xfer_comp;
	char *dma_tx_buf;
	char *dma_rx_buf;
	dma_addr_t dma_tx_addr;
	dma_addr_t dma_rx_addr;
	struct npcm_dma_xfer_desc dma_xfer;

	bool en_hj;
	bool hdr_ddr;
	bool hdr_mode;
	bool dma_started;

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

static void svc_i3c_master_stop_dma(struct svc_i3c_master *master);

static void svc_i3c_master_err_stats(struct svc_i3c_master *master, u8 code)
{
	master->err_cnt++;
	master->err_code = code;
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

static void svc_i3c_master_set_sda_skew(struct svc_i3c_master *master, int skew)
{
	u32 val;

	val = readl(master->regs + SVC_I3C_MCONFIG) & ~SVC_I3C_MCONFIG_SKEW_MASK;
	val |= SVC_I3C_MCONFIG_SKEW(skew);
	writel(val, master->regs + SVC_I3C_MCONFIG);
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

static void svc_i3c_master_ack_ibi(struct svc_i3c_master *master,
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
	readl_poll_timeout(master->regs + SVC_I3C_MSTATUS, reg,
			   SVC_I3C_MSTATUS_MCTRLDONE(reg), 0, 1000);
}

static void svc_i3c_master_nack_ibi(struct svc_i3c_master *master)
{
	u32 reg;

	writel(SVC_I3C_MCTRL_REQUEST_IBI_ACKNACK |
	       SVC_I3C_MCTRL_IBIRESP_NACK,
	       master->regs + SVC_I3C_MCTRL);
	readl_poll_timeout(master->regs + SVC_I3C_MSTATUS, reg,
			   SVC_I3C_MSTATUS_MCTRLDONE(reg), 0, 1000);
}

static void svc_i3c_master_emit_stop(struct svc_i3c_master *master)
{
	u32 reg = readl(master->regs + SVC_I3C_MSTATUS);

	/* Do not emit stop in the IDLE or SLVREQ state */
	if (SVC_I3C_MSTATUS_STATE_IDLE(reg) || SVC_I3C_MSTATUS_STATE_SLVREQ(reg))
		return;

	/*
	 * The spurious IBI event may change controller state to IBIACK, switch state
	 * to NORMACT before emitSTOP request.
	 */
	if (SVC_I3C_MSTATUS_STATE_IBIACK(reg)) {
		svc_i3c_master_nack_ibi(master);
		writel(SVC_I3C_MINT_IBIWON, master->regs + SVC_I3C_MSTATUS);
	}

	if (master->hdr_mode) {
		writel(SVC_I3C_MCTRL_REQUEST_FORCE_EXIT, master->regs + SVC_I3C_MCTRL);
		master->hdr_mode = false;
	} else {
		writel(SVC_I3C_MCTRL_REQUEST_STOP, master->regs + SVC_I3C_MCTRL);
		/*
		 * Wait for STOP condition to complete, in case the subsequent
		 * EmitStartAddr request is issued too early.
		 */
		readl_poll_timeout(master->regs + SVC_I3C_MSTATUS, reg,
				   SVC_I3C_MSTATUS_MCTRLDONE(reg), 0, 1000);
	}

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
	u32 mdatactrl, val;
	int ret;
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

static int svc_i3c_master_handle_ibiwon(struct svc_i3c_master *master, bool autoibi)
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
	/* Handle the critical responses to IBI's */
	switch (ibitype) {
	case SVC_I3C_MSTATUS_IBITYPE_IBI:
		dev = svc_i3c_master_dev_from_addr(master, ibiaddr);
		/* Bypass the invalid ibi with address 0 */
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
		if (!autoibi) {
			if (dev->info.bcr & I3C_BCR_IBI_PAYLOAD)
				svc_i3c_master_ack_ibi(master, true);
			else
				svc_i3c_master_ack_ibi(master, false);
		}
		svc_i3c_master_handle_ibi(master, dev);
		break;
	case SVC_I3C_MSTATUS_IBITYPE_HOT_JOIN:
		svc_i3c_master_ack_ibi(master, false);
		break;
	case SVC_I3C_MSTATUS_IBITYPE_MASTER_REQUEST:
		svc_i3c_master_nack_ibi(master);
		status = readl(master->regs + SVC_I3C_MSTATUS);
		/* Invalid event may be reported as MR request
		 * and sometimes produce dummy bytes. Flush the garbage data.
		 */
		if (SVC_I3C_MSTATUS_RXPEND(status))
			svc_i3c_master_flush_rx_fifo(master);
		break;
	default:
		break;
	}

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
		/*
		 * No need to emit stop here because the caller should do it
		 * if return error
		 */
		ret = -EIO;
		svc_i3c_master_err_stats(master, EIO);
		goto clear_ibiwon;
	}

	/* Handle the non critical tasks */
	switch (ibitype) {
	case SVC_I3C_MSTATUS_IBITYPE_IBI:
		/*
		 * Sometimes I3C HW returns to IDLE state after IBIRCV completed,
		 * do not emit STOP in the idle state.
		 */
		svc_i3c_master_emit_stop(master);
		if (dev && master->ibi.tbq_slot) {
			i3c_master_queue_ibi(dev, master->ibi.tbq_slot);
			master->ibi.tbq_slot = NULL;
		}
		break;
	case SVC_I3C_MSTATUS_IBITYPE_HOT_JOIN:
		/* Emit stop to avoid the INVREQ error after DAA process */
		svc_i3c_master_emit_stop(master);
		queue_work(master->base.wq, &master->hj_work);
		break;
	case SVC_I3C_MSTATUS_IBITYPE_MASTER_REQUEST:
		ret = -EOPNOTSUPP;
		svc_i3c_master_err_stats(master, EOPNOTSUPP);
	default:
		break;
	}

clear_ibiwon:
	/* clear IBIWON status */
	writel(SVC_I3C_MINT_IBIWON, master->regs + SVC_I3C_MSTATUS);
	return ret;
}

static void svc_i3c_master_ibi_isr(struct svc_i3c_master *master)
{
	u32 val, mstatus;
	int ret;

	spin_lock(&master->req_lock);

	/* Check slave ibi handled not yet */
	mstatus = readl(master->regs + SVC_I3C_MSTATUS);
	if (!SVC_I3C_MSTATUS_STATE_SLVREQ(mstatus))
		goto ibi_out;

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
					 SVC_I3C_MSTATUS_IBIWON(val), 0, 1000);
	if (ret) {
		/* Cancle AUTOIBI if not started */
		val = readl(master->regs + SVC_I3C_MCTRL);
		if (SVC_I3C_MCTRL_REQUEST(val) == SVC_I3C_MCTRL_REQUEST_AUTO_IBI)
			writel(0, master->regs + SVC_I3C_MCTRL);

		dev_err(master->dev, "Timeout when polling for IBIWON\n");
		svc_i3c_master_clear_merrwarn(master);
		svc_i3c_master_emit_stop(master);
		svc_i3c_master_err_stats(master, ETIMEDOUT);
		goto ibi_out;
	}

	if (svc_i3c_master_handle_ibiwon(master, true))
		svc_i3c_master_emit_stop(master);
ibi_out:
	spin_unlock(&master->req_lock);
}

static irqreturn_t svc_i3c_master_irq_handler(int irq, void *dev_id)
{
	struct svc_i3c_master *master = (struct svc_i3c_master *)dev_id;
	u32 active = readl(master->regs + SVC_I3C_MINTMASKED), mstatus;
	struct npcm_dma_xfer_desc *xfer = &master->dma_xfer;
	u32 count;
	struct dma_chan *dma_chan;
	struct dma_tx_state state;

	if (SVC_I3C_MSTATUS_COMPLETE(active)) {
		/* Clear COMPLETE status before emit STOP */
		writel(SVC_I3C_MINT_COMPLETE, master->regs + SVC_I3C_MSTATUS);
		/* Disable COMPLETE interrupt */
		writel(SVC_I3C_MINT_COMPLETE, master->regs + SVC_I3C_MINTCLR);

		svc_i3c_master_stop_dma(master);
		if (master->dma_xfer.end)
			svc_i3c_master_emit_stop(master);

		/* Get the DMA transfer count */
		dma_chan = xfer->rnw ? master->chan_rx : master->chan_tx;
		dmaengine_tx_status(dma_chan, master->cookie, &state);
		count = state.residue;
		count = (count > xfer->len) ? 0 :
			(xfer->len - count);
		dev_dbg(master->dev, "dma xfer count %u\n", count);
		if (xfer->rnw)
			memcpy(xfer->in, master->dma_rx_buf, count);
		if (count != xfer->len)
			dev_dbg(master->dev, "short dma xfer(%s), want %d transfer %d\n",
				xfer->rnw ? "R" : "W", xfer->len, count);
		xfer->actual_len = count;


		complete(&master->xfer_comp);

		return IRQ_HANDLED;
	}

	if (SVC_I3C_MSTATUS_SLVSTART(active)) {
		/* Clear the interrupt status */
		writel(SVC_I3C_MINT_SLVSTART, master->regs + SVC_I3C_MSTATUS);

		/* Read I3C state */
		mstatus = readl(master->regs + SVC_I3C_MSTATUS);

		if (SVC_I3C_MSTATUS_STATE_SLVREQ(mstatus)) {
			svc_i3c_master_ibi_isr(master);
		} else {
			/*
			 * Workaround:
			 * SlaveStart event under bad signals condition. SLVSTART bit in
			 * MSTATUS may set even slave device doesn't holding I3C_SDA low,
			 * but actual SlaveStart event may happened concurently in this
			 * bad signals condition handler. Give a chance to check current
			 * work state and intmask to avoid actual SlaveStart cannot be
			 * trigger after we clear SlaveStart interrupt status.
			 */

			/* Check if state change after we clear interrupt status */
			active = readl(master->regs + SVC_I3C_MINTMASKED);
			mstatus = readl(master->regs + SVC_I3C_MSTATUS);

			if (SVC_I3C_MSTATUS_STATE_SLVREQ(mstatus)) {
				if (!SVC_I3C_MSTATUS_SLVSTART(active)) {
					svc_i3c_master_ibi_isr(master);
				} else {
					/* handle interrupt in next time */
				}
			}
		}
	}

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

	ret = pm_runtime_resume_and_get(master->dev);
	if (ret < 0) {
		dev_err(master->dev,
			"<%s> cannot resume i3c bus master, err: %d\n",
			__func__, ret);
		return ret;
	}

	/* Timings derivation */
	fclk_rate = clk_get_rate(master->fclk);
	if (!fclk_rate) {
		ret = -EINVAL;
		goto rpm_out;
	}

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
	dev_info(master->dev, "mconfig=0x%x\n", readl(master->regs + SVC_I3C_MCONFIG));
	/* Master core's registration */
	ret = i3c_master_get_free_addr(m, 0);
	if (ret < 0)
		goto rpm_out;

	info.dyn_addr = ret;
	reg = readl(master->regs + SVC_I3C_VENDORID);
	info.pid = (SVC_I3C_VENDORID_VID(reg) << 33 ) | readl(master->regs + SVC_I3C_PARTNO);

	writel(SVC_MDYNADDR_VALID | SVC_MDYNADDR_ADDR(info.dyn_addr),
	       master->regs + SVC_I3C_MDYNADDR);

	ret = i3c_master_set_info(&master->base, &info);
	if (ret)
		goto rpm_out;

rpm_out:
	pm_runtime_mark_last_busy(master->dev);
	pm_runtime_put_autosuspend(master->dev);

	return ret;
}

static void svc_i3c_master_bus_cleanup(struct i3c_master_controller *m)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	int ret;

	ret = pm_runtime_resume_and_get(master->dev);
	if (ret < 0) {
		dev_err(master->dev, "<%s> Cannot get runtime PM.\n", __func__);
		return;
	}

	svc_i3c_master_disable_interrupts(master);

	/* Disable master */
	writel(0, master->regs + SVC_I3C_MCONFIG);

	pm_runtime_mark_last_busy(master->dev);
	pm_runtime_put_autosuspend(master->dev);
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
	unsigned int dev_nb = 0, last_addr = 0;
	unsigned long start = jiffies;
	u32 reg;
	int ret, i;
	int dyn_addr;

	svc_i3c_master_flush_fifo(master);

	while (true) {
		/* Enter/proceed with DAA */
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
			return ret;

		if (time_after(jiffies, start + msecs_to_jiffies(3000))) {
			svc_i3c_master_emit_stop(master);
			dev_info(master->dev, "do_daa expired\n");
			break;
		}
		/* runtime do_daa may ibiwon by others slave devices */
		if (SVC_I3C_MSTATUS_IBIWON(reg)) {
			ret = svc_i3c_master_handle_ibiwon(master, false);
			if (ret) {
				dev_err(master->dev, "daa: handle ibi event fail, ret=%d\n", ret);
				return ret;
			}
			writel(SVC_I3C_MINT_MCTRLDONE, master->regs + SVC_I3C_MSTATUS);
			continue;
		}

		if (dev_nb == SVC_I3C_MAX_DEVS) {
			svc_i3c_master_emit_stop(master);
			dev_info(master->dev, "Reach max devs\n");
			break;
		}
		if (SVC_I3C_MSTATUS_RXPEND(reg)) {
			u8 data[6];

			/* Give the slave device a suitable dynamic address */
			dyn_addr = i3c_master_get_free_addr(&master->base, last_addr + 1);
			if (dyn_addr < 0)
				return dyn_addr;
			writel(dyn_addr, master->regs + SVC_I3C_MWDATAB);

			/*
			 * We only care about the 48-bit provisional ID yet to
			 * be sure a device does not nack an address twice.
			 * Otherwise, we would just need to flush the RX FIFO.
			 */
			ret = svc_i3c_master_readb(master, data, 6);
			if (ret)
				return ret;

			for (i = 0; i < 6; i++)
				prov_id[dev_nb] |= (u64)(data[i]) << (8 * (5 - i));

			/* We do not care about the BCR and DCR yet */
			ret = svc_i3c_master_readb(master, data, 2);
			if (ret)
				return ret;
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
				 */
				break;
			} else if (SVC_I3C_MSTATUS_NACKED(reg)) {
				/* No I3C devices attached */
				if (dev_nb == 0) {
					svc_i3c_master_emit_stop(master);
					break;
				}

				/*
				 * A slave device nacked the address, this is
				 * allowed only once, DAA will be stopped and
				 * then resumed. The same device is supposed to
				 * answer again immediately and shall ack the
				 * address this time.
				 */
				if (prov_id[dev_nb] == nacking_prov_id)
					return -EIO;

				dev_nb--;
				nacking_prov_id = prov_id[dev_nb];
				svc_i3c_master_emit_stop(master);

				continue;
			} else {
				return -EIO;
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
			return ret;

		addrs[dev_nb] = dyn_addr;
		dev_dbg(master->dev, "DAA: device %d assigned to 0x%02x\n",
			dev_nb, addrs[dev_nb]);
		last_addr = addrs[dev_nb++];
	}

	*count = dev_nb;

	return 0;
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
		if (I3C_BCR_DEVICE_ROLE(dev->info.bcr) == I3C_BCR_I3C_MASTER) {
			if (!(dev->info.bcr & I3C_BCR_IBI_REQ_CAP))
				continue;
		}

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
	unsigned int dev_nb;
	unsigned long flags;
	int ret, i;

	ret = pm_runtime_resume_and_get(master->dev);
	if (ret < 0) {
		dev_err(master->dev, "<%s> Cannot get runtime PM.\n", __func__);
		return ret;
	}

	mutex_lock(&master->lock);
	spin_lock_irqsave(&master->req_lock, flags);
	/*
	 * Fix SCL/SDA timing issue during DAA.
	 * Set SKEW bit to 1 before initiating a DAA, set SKEW bit to 0
	 * after DAA is completed.
	 */
	svc_i3c_master_set_sda_skew(master, 1);
	ret = svc_i3c_master_do_daa_locked(master, addrs, &dev_nb);
	svc_i3c_master_set_sda_skew(master, 0);
	spin_unlock_irqrestore(&master->req_lock, flags);
	mutex_unlock(&master->lock);
	if (ret) {
		svc_i3c_master_emit_stop(master);
		svc_i3c_master_clear_merrwarn(master);
		goto rpm_out;
	}

	/* Register all devices who participated to the core */
	for (i = 0; i < dev_nb; i++) {
		ret = i3c_master_add_i3c_dev_locked(m, addrs[i]);
		if (ret)
			dev_err(master->dev, "Unable to add i3c dev@0x%x, err %d\n",
				addrs[i], ret);
	}

	/* Configure IBI auto-rules */
	ret = svc_i3c_update_ibirules(master);
	if (ret)
		dev_err(master->dev, "Cannot handle such a list of devices");

rpm_out:
	pm_runtime_mark_last_busy(master->dev);
	pm_runtime_put_autosuspend(master->dev);

	/* No Slave ACK */
	if (ret == -EIO)
		return 0;

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

static void svc_i3c_master_stop_dma(struct svc_i3c_master *master)
{
	dmaengine_terminate_all(master->chan_tx);
	dmaengine_terminate_all(master->chan_rx);
	writel(0, master->regs + SVC_I3C_MDMACTRL);

	/* Disable COMPLETE interrupt */
	writel(SVC_I3C_MINT_COMPLETE, master->regs + SVC_I3C_MINTCLR);
	master->dma_started = false;
}

static void svc_i3c_master_write_dma_table(const u8 *src, u32 *dst, int len)
{
	int i;

	if (len > MAX_DMA_COUNT)
		return;

	for (i = 0; i < len; i++)
		dst[i] = (u32)src[i] & 0xFF;

	/* Set end bit for last byte */
	dst[len - 1] |= 0x100;
}

static bool svc_i3c_master_start_dma(struct svc_i3c_master *master)
{
	struct npcm_dma_xfer_desc *xfer = &master->dma_xfer;
	struct dma_async_tx_descriptor *dma_desc;
	struct dma_chan *dma_chan;
	struct scatterlist sg;
	enum dma_transfer_direction dir;
	u32 val;

	if (!xfer->len)
		return false;

	dev_dbg(master->dev, "start dma for %s, count %d\n",
		xfer->rnw ? "R" : "W", xfer->len);

	xfer->actual_len = 0;

	/* Write data to DMA TX table */
	if (!xfer->rnw)
		svc_i3c_master_write_dma_table(xfer->out,
					       (u32 *)master->dma_tx_buf,
					       xfer->len);

	/*
	 * Setup I3C DMA control
	 * 1 byte DMA width
	 * Enable DMA util disabled
	 */
	val = SVC_I3C_MDMACTRL_DMAWIDTH(1);
	val |= xfer->rnw ? SVC_I3C_MDMACTRL_DMAFB(2) : SVC_I3C_MDMACTRL_DMATB(2);
	writel(val, master->regs + SVC_I3C_MDMACTRL);

	sg_init_table(&sg, 1);
	sg_dma_len(&sg) = xfer->len;

	if (xfer->rnw) {
		dma_chan = master->chan_rx;
		sg_dma_address(&sg) = master->dma_rx_addr;
		dir = DMA_DEV_TO_MEM;
	} else {
		dma_chan = master->chan_tx;
		sg_dma_address(&sg) = master->dma_tx_addr;
		dir = DMA_MEM_TO_DEV;
	}

	dma_desc = dmaengine_prep_slave_sg(dma_chan, &sg, 1, dir, DMA_CTRL_ACK);
	if (!dma_desc)
		return false;

	master->cookie = dmaengine_submit(dma_desc);
	dma_async_issue_pending(dma_chan);
	master->dma_started = true;

	return true;
}

static int svc_i3c_master_xfer(struct svc_i3c_master *master,
			       bool rnw, unsigned int xfer_type, u8 addr,
			       u8 *in, const u8 *out, unsigned int xfer_len,
			       unsigned int *actual_len, bool continued,
			       bool use_dma)
{
	bool no_data = xfer_len ? false : true;
	u32 reg, rdterm = *actual_len, mstatus;
	int ret, i, count, space;
	unsigned long flags;
	bool restarted = false;
	u32 ibitype;

	if (rdterm > SVC_I3C_MAX_RDTERM)
		rdterm = SVC_I3C_MAX_RDTERM;

	/* Use SDR mode if transfer size is odd */
	if (xfer_type == SVC_I3C_MCTRL_TYPE_I3C_DDR && (xfer_len % 2))
		xfer_type = SVC_I3C_MCTRL_TYPE_I3C;

	if (xfer_type == SVC_I3C_MCTRL_TYPE_I3C_DDR) {
		/* Write the HDR-DDR cmd to the MWDATAB register to send out to slave */
		writel(HDR_COMMAND, master->regs + SVC_I3C_MWDATAB);
		/* Read count: add 1 for HDR-DDR command word and 1 for CRC word */
		if (rnw)
			rdterm = 2 + rdterm / 2;
		master->hdr_mode = true;
	}

	/*
	 * Acquire the spinlock to:
	 * 1. Prevent concurrent execution of MCTRL request and IBI isr.
	 * 2. Prevent schedule(local irq is disabled) to avoid TX FIFO
	 *    empty during the transmission.
	 */
	spin_lock_irqsave(&master->req_lock, flags);

restart:
	writel(SVC_I3C_MCTRL_REQUEST_START_ADDR |
	       xfer_type |
	       SVC_I3C_MCTRL_IBIRESP_NACK |
	       SVC_I3C_MCTRL_DIR(rnw) |
	       SVC_I3C_MCTRL_ADDR(addr) |
	       SVC_I3C_MCTRL_RDTERM(rdterm),
	       master->regs + SVC_I3C_MCTRL);

	/*
	 * HW issue:
	 * I3C HW stalls the write transfer if the transmit FIFO becomes empty,
	 * when new data is written to FIFO, I3C HW resumes the transfer but
	 * the first transmitted data bit may have the wrong value.
	 * Workaround:
	 * Fill the FIFO in advance to prevent FIFO from becoming empty.
	 */
	if (!rnw && xfer_len && !restarted) {
		reg = readl(master->regs + SVC_I3C_MDATACTRL);
		space = SVC_I3C_FIFO_SIZE - SVC_I3C_MDATACTRL_TXCOUNT(reg);
		count = xfer_len > space ? space : xfer_len;
		for (i = 0; i < count; i++) {
			if (i == xfer_len - 1)
				writel(out[0], master->regs + SVC_I3C_MWDATABE);
			else
				writel(out[0], master->regs + SVC_I3C_MWDATAB);
			out++;
		}
		xfer_len -= count;
		if (!xfer_len)
			use_dma = false;
	}
	if (use_dma && !restarted) {
		master->dma_xfer.out = out;
		master->dma_xfer.in = in;
		master->dma_xfer.len = xfer_len;
		master->dma_xfer.rnw = rnw;
		master->dma_xfer.end = !continued;
		ret = svc_i3c_master_start_dma(master);
		if (!ret) {
			ret = -EIO;
			goto emit_stop;
		}
	}

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

	if (use_dma) {
		init_completion(&master->xfer_comp);
		/* Use COMPLETE interrupt as notification of transfer completion */
		svc_i3c_master_enable_interrupts(master, SVC_I3C_MINT_COMPLETE);
		spin_unlock_irqrestore(&master->req_lock, flags);
		ret = wait_for_completion_timeout(&master->xfer_comp, msecs_to_jiffies(100));
		if (ret < 0) {
			svc_i3c_master_stop_dma(master);
			svc_i3c_master_flush_fifo(master);
			svc_i3c_master_emit_stop(master);
			svc_i3c_master_clear_merrwarn(master);
			dev_err(master->dev, "DMA transfer timeout (%s)\n",
				rnw ? "Read" : "write");
			dev_err(master->dev, "mstatus = 0x%02x\n",
				readl(master->regs + SVC_I3C_MSTATUS));
			svc_i3c_master_err_stats(master, ETIMEDOUT);
			return ret;
		}

		if (rnw)
			*actual_len = master->dma_xfer.actual_len;
		return 0;
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

		/* If use_dma, COMPLETE bit is cleared in the isr */
		writel(SVC_I3C_MINT_COMPLETE, master->regs + SVC_I3C_MSTATUS);
	}


	if (master->hdr_mode) {
		reg = readl(master->regs + SVC_I3C_MERRWARN);
		if (SVC_I3C_MERRWARN_HCRC(reg)) {
			dev_err(master->dev, "HDR CRC error\n");
			ret = -EIO;
			goto emit_stop;
		}
	}

	if (!continued)
		svc_i3c_master_emit_stop(master);

	spin_unlock_irqrestore(&master->req_lock, flags);

	return 0;

emit_stop:
	if (master->dma_started)
		svc_i3c_master_stop_dma(master);
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
	spin_unlock_irqrestore(&master->req_lock, flags);

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
	svc_i3c_master_dequeue_xfer_locked(master, xfer);
}

static void svc_i3c_master_start_xfer_locked(struct svc_i3c_master *master)
{
	struct svc_i3c_xfer *xfer = master->xferqueue.cur;
	unsigned long flags;
	int retry = 2;
	int ret, i;

	if (!xfer)
		return;

	/* Prevent fifo flush while IBI isr is running */
	spin_lock_irqsave(&master->req_lock, flags);
	svc_i3c_master_clear_merrwarn(master);
	svc_i3c_master_flush_fifo(master);
	spin_unlock_irqrestore(&master->req_lock, flags);

	for (i = 0; i < xfer->ncmds; i++) {
		struct svc_i3c_cmd *cmd = &xfer->cmds[i];
again:
		ret = svc_i3c_master_xfer(master, cmd->rnw, xfer->type,
					  cmd->addr, cmd->in, cmd->out,
					  cmd->len, &cmd->actual_len,
					  cmd->continued, cmd->use_dma);
		if (ret == -EAGAIN && --retry)
			goto again;
		/* cmd->xfer is NULL if I2C or CCC transfer */
		if (cmd->xfer)
			cmd->xfer->actual_len = cmd->actual_len;
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
	int ret;

	ret = pm_runtime_resume_and_get(master->dev);
	if (ret < 0) {
		dev_err(master->dev, "<%s> Cannot get runtime PM.\n", __func__);
		return;
	}

	init_completion(&xfer->comp);

	if (master->xferqueue.cur) {
		list_add_tail(&xfer->node, &master->xferqueue.list);
	} else {
		master->xferqueue.cur = xfer;
		svc_i3c_master_start_xfer_locked(master);
	}

	pm_runtime_mark_last_busy(master->dev);
	pm_runtime_put_autosuspend(master->dev);
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
	cmd->out = ccc->rnw ? NULL : ccc->dests[0].payload.data,
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

	if (master->hdr_ddr && dev->info.hdr_cap & BIT(I3C_HDR_DDR))
		xfer->type = SVC_I3C_MCTRL_TYPE_I3C_DDR;
	else
		xfer->type = SVC_I3C_MCTRL_TYPE_I3C;

	for (i = 0; i < nxfers; i++) {
		struct svc_i3c_cmd *cmd = &xfer->cmds[i];

		cmd->xfer = &xfers[i];
		cmd->addr = master->addrs[data->index];
		cmd->rnw = xfers[i].rnw;
		cmd->in = xfers[i].rnw ? xfers[i].data.in : NULL;
		cmd->out = xfers[i].rnw ? NULL : xfers[i].data.out;
		cmd->len = xfers[i].len;
		cmd->actual_len = xfers[i].rnw ? xfers[i].len : 0;
		cmd->continued = (i + 1) < nxfers;
		if (master->use_dma && (xfers[i].len > SVC_I3C_FIFO_SIZE)
		    && (xfers[i].len <= MAX_DMA_COUNT))
			cmd->use_dma = true;
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
	int ret;

	ret = pm_runtime_resume_and_get(master->dev);
	if (ret < 0) {
		dev_err(master->dev, "<%s> Cannot get runtime PM.\n", __func__);
		return ret;
	}

	/* Clear the interrupt status */
	writel(SVC_I3C_MINT_SLVSTART, master->regs + SVC_I3C_MSTATUS);
	svc_i3c_master_enable_interrupts(master, SVC_I3C_MINT_SLVSTART);

	return i3c_master_enec_locked(m, dev->info.dyn_addr, I3C_CCC_EVENT_SIR);
}

static int svc_i3c_master_disable_ibi(struct i3c_dev_desc *dev)
{
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	int ret;

	writel(SVC_I3C_MINT_SLVSTART, master->regs + SVC_I3C_MINTCLR);

	ret = i3c_master_disec_locked(m, dev->info.dyn_addr, I3C_CCC_EVENT_SIR);

	pm_runtime_mark_last_busy(master->dev);
	pm_runtime_put_autosuspend(master->dev);

	return ret;
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

static void svc_i3c_slave_enable_interrupts(struct svc_i3c_master *master,
					    bool enable)
{
	/* Use STOP condition to check the end of transaction */
	if (enable)
		writel(SVC_I3C_INT_STOP, master->regs + SVC_I3C_INTSET);
	else
		writel(SVC_I3C_INT_STOP, master->regs + SVC_I3C_INTCLR);
}

static void svc_i3c_slave_stop_dma(struct svc_i3c_master *master)
{
	dmaengine_terminate_all(master->chan_tx);
	dmaengine_terminate_all(master->chan_rx);
	writel(0, master->regs + SVC_I3C_MDMACTRL);
}

static bool svc_i3c_slave_start_dma(struct svc_i3c_master *master,
				   struct svc_i3c_xfer *xfer)
{
	struct svc_i3c_cmd *cmd = &xfer->cmds[0];
	struct dma_async_tx_descriptor *dma_desc;
	struct dma_chan *dma_chan;
	struct scatterlist sg;
	enum dma_transfer_direction dir;
	u32 val;

	if (!cmd->len)
		return false;

	dev_dbg(master->dev, "slave start dma for %s, count %d\n",
		cmd->rnw ? "R" : "W", cmd->len);

	/* Write data to DMA TX table */
	if (!cmd->rnw)
		svc_i3c_master_write_dma_table(cmd->out,
					       (u32 *)master->dma_tx_buf,
					       cmd->len);

	/*
	 * Setup I3C DMA control
	 * 1 byte DMA width
	 * Enable DMA util dsiabled
	 */
	val = SVC_I3C_DMACTRL_DMAWIDTH(1);
	val |= cmd->rnw ? SVC_I3C_DMACTRL_DMAFB(2) : SVC_I3C_DMACTRL_DMATB(2);
	writel(val, master->regs + SVC_I3C_DMACTRL);

	/* Clear STOP status because this will be used as check point of transaction end */
	writel(SVC_I3C_STATUS_STOP, master->regs + SVC_I3C_STATUS);

	sg_init_table(&sg, 1);
	sg_dma_len(&sg) = cmd->len;

	if (cmd->rnw) {
		dma_chan = master->chan_rx;
		sg_dma_address(&sg) = master->dma_rx_addr;
		dir = DMA_DEV_TO_MEM;
	} else {
		dma_chan = master->chan_tx;
		sg_dma_address(&sg) = master->dma_tx_addr;
		dir = DMA_MEM_TO_DEV;
	}

	dma_desc = dmaengine_prep_slave_sg(dma_chan, &sg, 1, dir, DMA_CTRL_ACK);
	if (!dma_desc)
		return false;

	master->cookie = dmaengine_submit(dma_desc);
	dma_async_issue_pending(dma_chan);

	return true;
}

static void svc_i3c_slave_check_complete(struct svc_i3c_master *master)
{
	struct svc_i3c_xfer *xfer = master->slave.cur;
	struct svc_i3c_cmd *cmd = &xfer->cmds[0];
	u32 count, reg;
	bool hdr_mode = false;
	struct dma_chan *dma_chan;
	struct dma_tx_state state;

	dma_chan = cmd->rnw ? master->chan_rx : master->chan_tx;
	dmaengine_tx_status(dma_chan, master->cookie, &state);
	count = state.residue;

	/* No rx data transferred */
	if (cmd->rnw && cmd->len == count)
		return;

	/* No tx data transferred */
	if (!cmd->rnw) {
		reg = readl(master->regs + SVC_I3C_DATACTRL);
		if (cmd->len == count + SVC_I3C_DATACTRL_TXCOUNT(reg))
			return;
	}
	svc_i3c_slave_stop_dma(master);

	if (cmd->len < count)
		goto quit;
	count = cmd->len - count;

	reg = readl(master->regs + SVC_I3C_STATUS);
	if (reg & SVC_I3C_STATUS_DDRMATCH) {
		writel(SVC_I3C_STATUS_DDRMATCH, master->regs);
		hdr_mode = true;
	}
	if (cmd->rnw) {
		struct i3c_dev_desc *desc = master->base.this;

		if (hdr_mode) {
			/* Drop the hdr command */
			dev_dbg(master->dev, "drop hdr cmd: 0x%x\n", master->dma_rx_buf[0]);
			count--;
			memcpy(cmd->in, master->dma_rx_buf + 1, count);
		} else {
			memcpy(cmd->in, master->dma_rx_buf, count);
		}
		dev_dbg(master->dev, "slave rx count %u\n", count);
		if (desc->target_info.read_handler)
			desc->target_info.read_handler(desc->dev, cmd->in, count);
	} else {
		cmd->len = count - SVC_I3C_DATACTRL_TXCOUNT(reg);
		if (hdr_mode) {
			reg = readl(master->regs + SVC_I3C_RDATAB);
			dev_dbg(master->dev, "recv: hdr cmd=0x%x\n", reg);
		}

		/* Clear Pending Intr */
		writel(0, master->regs + SVC_I3C_CTRL);
		dev_dbg(master->dev, "slave tx count %u\n", cmd->len);
		complete(&xfer->comp);
	}
quit:
	if (master->slave.pending_rd) {
		master->slave.cur = master->slave.pending_rd;
		svc_i3c_slave_start_dma(master, master->slave.cur);
	} else {
		master->slave.cur = NULL;
		svc_i3c_slave_enable_interrupts(master, false);
	}
}

static irqreturn_t svc_i3c_slave_irq_handler(int irq, void *dev_id)
{
	struct svc_i3c_master *master = (struct svc_i3c_master *)dev_id;
	u32 active = readl(master->regs + SVC_I3C_INTMASKED);
	u32 status = readl(master->regs + SVC_I3C_STATUS);

	if ((active & SVC_I3C_INT_STOP) && (status & SVC_I3C_INT_STOP)) {
		writel(SVC_I3C_STATUS_STOP, master->regs + SVC_I3C_STATUS);
		if (master->slave.cur)
			svc_i3c_slave_check_complete(master);
	}

	return IRQ_HANDLED;
}

static int svc_i3c_slave_write(struct i3c_master_controller *m,
			       struct svc_i3c_xfer *xfer)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	int ret;
	unsigned long flags;

	spin_lock_irqsave(&master->slave.lock, flags);
	if (master->slave.cur)
		svc_i3c_slave_stop_dma(master);
	writel(SVC_I3C_DATACTRL_FLUSHTB, master->regs + SVC_I3C_DATACTRL);
	master->slave.cur = xfer;

	init_completion(&xfer->comp);
	svc_i3c_slave_start_dma(master, xfer);
	svc_i3c_slave_enable_interrupts(master, true);

	/*
	 * Set Pending Intr in GetStatus response to inform that
	 * slave has data to send.
	 */
	writel(SVC_I3C_CTRL_PENDINT(1), master->regs + SVC_I3C_CTRL);
	spin_unlock_irqrestore(&master->slave.lock, flags);

	ret = wait_for_completion_timeout(&xfer->comp,
					  msecs_to_jiffies(3000));
	if (!ret) {
		/* Clear Pending Intr */
		writel(0, master->regs + SVC_I3C_CTRL);

		spin_lock_irqsave(&master->slave.lock, flags);
		svc_i3c_slave_stop_dma(master);
		if (master->slave.pending_rd) {
			master->slave.cur = master->slave.pending_rd;
			svc_i3c_slave_start_dma(master, master->slave.cur);
		} else {
			master->slave.cur = NULL;
			svc_i3c_slave_enable_interrupts(master, false);
		}
		spin_unlock_irqrestore(&master->slave.lock, flags);
		dev_info(master->dev, "slave write timeout\n");
		xfer->ret = -ETIMEDOUT;
		return -ETIMEDOUT;
	}

	xfer->ret = 0;
	return 0;
}

static int svc_i3c_slave_priv_xfers(struct i3c_dev_desc *dev,
				    struct i3c_priv_xfer *xfers,
				    int nxfers)
{
	struct i3c_master_controller *m = i3c_dev_get_master(dev);
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct svc_i3c_xfer *xfer;
	struct svc_i3c_cmd *cmd;
	int ret;

	/* Only support one write transfer */
	if (nxfers != 1 || xfers[0].rnw)
		return -EOPNOTSUPP;

	if (master->slave.cur && master->slave.cur != master->slave.pending_rd)
		return -EBUSY;

	xfer = svc_i3c_master_alloc_xfer(master, nxfers);
	if (!xfer)
		return -ENOMEM;

	cmd = &xfer->cmds[0];
	cmd->rnw = false;
	cmd->out = xfers[0].data.out;
	cmd->len = xfers[0].len;
	svc_i3c_slave_write(m, xfer);

	ret = xfer->ret;
	svc_i3c_master_free_xfer(xfer);

	return ret;
}

static int svc_i3c_slave_bus_init(struct i3c_master_controller *m)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	struct i3c_dev_desc *desc = m->this;
	u32 partno = (u32)desc->info.pid;
	struct svc_i3c_xfer *xfer;
	struct svc_i3c_cmd *cmd;
	u32 reg;

	if (!master->use_dma)
		return -ENOTSUPP;

	/* Set dcr/partno */
	writel(SVC_I3C_IDEXT_DCR(desc->info.dcr), master->regs + SVC_I3C_IDEXT);
	writel(partno, master->regs + SVC_I3C_PARTNO);

	/* Set max rd/wr length */
	reg = SVC_I3C_MAXLIMITS_MAXRD(MAX_DMA_COUNT) |
		SVC_I3C_MAXLIMITS_MAXWR(MAX_DMA_COUNT);
	writel(reg, master->regs + SVC_I3C_MAXLIMITS);

	/* Enable slave mode */
	reg = readl(master->regs + SVC_I3C_CONFIG);
	reg |= SVC_I3C_CONFIG_SLVEN;
	if (master->hdr_ddr)
		reg |= SVC_I3C_CONFIG_DDROK;
	writel(reg, master->regs + SVC_I3C_CONFIG);

	/* Prepare one RX transfer */
	xfer = svc_i3c_master_alloc_xfer(master, 1);
	if (!xfer)
		return -ENOMEM;

	cmd = &xfer->cmds[0];
	cmd->rnw = true;
	cmd->len = MAX_DMA_COUNT;
	cmd->in = kzalloc(MAX_DMA_COUNT, GFP_KERNEL);
	if (!cmd->in) {
		svc_i3c_master_free_xfer(xfer);
		return -ENOMEM;
	}
	master->slave.pending_rd = xfer;
	master->slave.cur = xfer;
	svc_i3c_slave_start_dma(master, xfer);
	svc_i3c_slave_enable_interrupts(master, true);

	return 0;
}

static void svc_i3c_slave_bus_cleanup(struct i3c_master_controller *m)
{
	struct svc_i3c_master *master = to_svc_i3c_master(m);
	u32 reg;

	svc_i3c_slave_enable_interrupts(master, false);

	reg = readl(master->regs + SVC_I3C_CONFIG);
	reg &= ~SVC_I3C_CONFIG_SLVEN;
	writel(reg, master->regs + SVC_I3C_CONFIG);
}

static const struct i3c_target_ops svc_i3c_slave_ops = {
	.bus_init = svc_i3c_slave_bus_init,
	.bus_cleanup = svc_i3c_slave_bus_cleanup,
	.priv_xfers = svc_i3c_slave_priv_xfers,
};

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
		svc_i3c_debugfs_dir = debugfs_create_dir("svc_i3c", NULL);
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

static void svc_i3c_release_dma_chan(struct svc_i3c_master *master)
{
	if (master->chan_tx)
		dma_release_channel(master->chan_tx);

	if (master->chan_rx)
		dma_release_channel(master->chan_rx);
}

static int svc_i3c_setup_dma(struct platform_device *pdev, struct svc_i3c_master *master)
{
	struct device *dev = &pdev->dev;
	struct dma_slave_config tx_slave_cfg = {}, rx_slave_cfg = {};
	struct npcm_gdma_peripheral_config tx_pcfg = {}, rx_pcfg = {};
	u32 reg_base;
	int ret;

	if (!of_property_read_bool(dev->of_node, "dmas") ||
	    !of_property_read_bool(dev->of_node, "dma-names"))
		return 0;

	master->chan_tx = dma_request_chan(dev, "tx");
	if (IS_ERR(master->chan_tx)) {
		dev_err(dev, "Failed to request DMA tx channel\n");
		return PTR_ERR(master->chan_tx);
	}

	master->chan_rx = dma_request_chan(dev, "rx");
	if (IS_ERR(master->chan_rx)) {
		dev_err(dev, "Failed to request DMA rx channel\n");
		ret = PTR_ERR(master->chan_rx);
		goto release_chan;
	}

	of_property_read_u32_index(dev->of_node, "reg", 0, &reg_base);

	tx_slave_cfg.dst_addr = reg_base + SVC_I3C_MWDATAB;
	tx_pcfg.connectivity = SVC_I3C_GDMA_MUX(reg_base);
	tx_slave_cfg.peripheral_config = &tx_pcfg;
	tx_slave_cfg.peripheral_size = sizeof(tx_pcfg);

	ret = dmaengine_slave_config(master->chan_tx, &tx_slave_cfg);
	if (ret) {
		dev_err(dev, "Failed to configure DMA tx channel\n");
		goto release_chan;
	}

	rx_slave_cfg.src_addr = reg_base + SVC_I3C_MRDATAB;
	rx_pcfg.connectivity = SVC_I3C_GDMA_MUX(reg_base) + 1;
	rx_slave_cfg.peripheral_config = &rx_pcfg;
	rx_slave_cfg.peripheral_size = sizeof(rx_pcfg);

	ret = dmaengine_slave_config(master->chan_rx, &rx_slave_cfg);
	if (ret) {
		dev_err(dev, "Failed to configure DMA rx channel\n");
		goto release_chan;
	}

	/* DMA TX transfer width is 32 bits(MWDATAB width) for each byte sent to I3C bus */
	master->dma_tx_buf = dma_alloc_coherent(dev, MAX_DMA_COUNT * 4,
						&master->dma_tx_addr, GFP_KERNEL);
	if (!master->dma_tx_buf) {
		ret = -ENOMEM;
		goto release_chan;
	}

	master->dma_rx_buf = dma_alloc_coherent(dev, MAX_DMA_COUNT,
						&master->dma_rx_addr, GFP_KERNEL);
	if (!master->dma_rx_buf) {
		dma_free_coherent(master->dev, MAX_DMA_COUNT * 4, master->dma_tx_buf,
				  master->dma_tx_addr);
		ret = -ENOMEM;
		goto release_chan;
	}

	master->use_dma = true;
	dev_info(dev, "Using GDMA\n");

	return 0;

release_chan:
	svc_i3c_release_dma_chan(master);
	return ret;
}

static int svc_i3c_master_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct svc_i3c_master *master;
	struct reset_control *reset;
	const char *role;
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
	ret = of_property_read_string(pdev->dev.of_node, "initial-role", &role);
	if (!ret && !strcmp("target", role))
		ret = devm_request_irq(dev, master->irq, svc_i3c_slave_irq_handler,
				       IRQF_NO_SUSPEND, "svc-i3c-irq", master);
	else
		ret = devm_request_irq(dev, master->irq, svc_i3c_master_irq_handler,
				       IRQF_NO_SUSPEND, "svc-i3c-irq", master);
	if (ret)
		goto err_disable_clks;

	master->free_slots = GENMASK(SVC_I3C_MAX_DEVS - 1, 0);

	mutex_init(&master->lock);
	INIT_LIST_HEAD(&master->xferqueue.list);

	spin_lock_init(&master->req_lock);
	spin_lock_init(&master->ibi.lock);
	spin_lock_init(&master->slave.lock);
	master->ibi.num_slots = SVC_I3C_MAX_DEVS;
	master->ibi.slots = devm_kcalloc(&pdev->dev, master->ibi.num_slots,
					 sizeof(*master->ibi.slots),
					 GFP_KERNEL);
	if (!master->ibi.slots) {
		ret = -ENOMEM;
		goto err_disable_clks;
	}

	platform_set_drvdata(pdev, master);

	pm_runtime_set_autosuspend_delay(&pdev->dev, SVC_I3C_PM_TIMEOUT_MS);
	pm_runtime_use_autosuspend(&pdev->dev);
	pm_runtime_get_noresume(&pdev->dev);
	pm_runtime_set_active(&pdev->dev);
	pm_runtime_enable(&pdev->dev);

	svc_i3c_master_reset(master);

	if (of_property_read_bool(dev->of_node, "hdr-ddr")) {
		dev_info(master->dev, "support hdr-ddr\n");
		master->hdr_ddr = true;
	}
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

	svc_i3c_master_clear_merrwarn(master);
	svc_i3c_master_flush_fifo(master);

	ret = svc_i3c_setup_dma(pdev, master);
	if (ret)
		goto rpm_disable;

	svc_i3c_init_debugfs(pdev, master);

	/* Register the master */
	ret = i3c_register(&master->base, &pdev->dev,
			   &svc_i3c_master_ops, &svc_i3c_slave_ops, false);
	if (ret)
		goto rpm_disable;

	pm_runtime_mark_last_busy(&pdev->dev);
	pm_runtime_put_autosuspend(&pdev->dev);

	if (master->en_hj) {
		dev_info(master->dev, "enable hot-join\n");
		svc_i3c_master_enable_interrupts(master, SVC_I3C_MINT_SLVSTART);
	}
	return 0;

rpm_disable:
	pm_runtime_dont_use_autosuspend(&pdev->dev);
	pm_runtime_put_noidle(&pdev->dev);
	pm_runtime_set_suspended(&pdev->dev);
	pm_runtime_disable(&pdev->dev);
	debugfs_remove_recursive(master->debugfs);

err_disable_clks:
	svc_i3c_master_unprepare_clks(master);

	return ret;
}

static int svc_i3c_master_remove(struct platform_device *pdev)
{
	struct svc_i3c_master *master = platform_get_drvdata(pdev);
	int ret;

	/* Avoid ibi events during driver unbinding */
	writel(SVC_I3C_MINT_SLVSTART, master->regs + SVC_I3C_MINTCLR);

	debugfs_remove_recursive(master->debugfs);

	cancel_work_sync(&master->hj_work);
	ret = i3c_unregister(&master->base);
	if (ret)
		return ret;

	pm_runtime_dont_use_autosuspend(&pdev->dev);
	pm_runtime_disable(&pdev->dev);

	if (master->use_dma) {
		dma_free_coherent(master->dev, MAX_DMA_COUNT * 4, master->dma_tx_buf,
				  master->dma_tx_addr);
		dma_free_coherent(master->dev, MAX_DMA_COUNT, master->dma_rx_buf,
				  master->dma_rx_addr);
	}
	return 0;
}

static void svc_i3c_save_regs(struct svc_i3c_master *master)
{
	master->saved_regs.mconfig = readl(master->regs + SVC_I3C_MCONFIG);
	master->saved_regs.mdynaddr = readl(master->regs + SVC_I3C_MDYNADDR);
}

static void svc_i3c_restore_regs(struct svc_i3c_master *master)
{
	if (readl(master->regs + SVC_I3C_MDYNADDR) !=
	    master->saved_regs.mdynaddr) {
		writel(master->saved_regs.mconfig,
		       master->regs + SVC_I3C_MCONFIG);
		writel(master->saved_regs.mdynaddr,
		       master->regs + SVC_I3C_MDYNADDR);
	}
}

static int __maybe_unused svc_i3c_runtime_suspend(struct device *dev)
{
	struct svc_i3c_master *master = dev_get_drvdata(dev);

	svc_i3c_save_regs(master);
	svc_i3c_master_unprepare_clks(master);
	pinctrl_pm_select_sleep_state(dev);

	return 0;
}

static int __maybe_unused svc_i3c_runtime_resume(struct device *dev)
{
	struct svc_i3c_master *master = dev_get_drvdata(dev);

	pinctrl_pm_select_default_state(dev);
	svc_i3c_master_prepare_clks(master);

	svc_i3c_restore_regs(master);

	return 0;
}

static const struct dev_pm_ops svc_i3c_pm_ops = {
	SET_NOIRQ_SYSTEM_SLEEP_PM_OPS(pm_runtime_force_suspend,
				      pm_runtime_force_resume)
	SET_RUNTIME_PM_OPS(svc_i3c_runtime_suspend,
			   svc_i3c_runtime_resume, NULL)
};

static const struct of_device_id svc_i3c_master_of_match_tbl[] = {
	{ .compatible = "silvaco,i3c-master" },
	{ /* sentinel */ },
};
MODULE_DEVICE_TABLE(of, svc_i3c_master_of_match_tbl);

static struct platform_driver svc_i3c_master = {
	.probe = svc_i3c_master_probe,
	.remove = svc_i3c_master_remove,
	.driver = {
		.name = "silvaco-i3c-master",
		.of_match_table = svc_i3c_master_of_match_tbl,
		.pm = &svc_i3c_pm_ops,
	},
};
module_platform_driver(svc_i3c_master);

MODULE_AUTHOR("Conor Culhane <conor.culhane@silvaco.com>");
MODULE_AUTHOR("Miquel Raynal <miquel.raynal@bootlin.com>");
MODULE_DESCRIPTION("Silvaco dual-role I3C master driver");
MODULE_LICENSE("GPL v2");
