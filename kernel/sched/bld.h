#ifdef CONFIG_BLD

static DEFINE_RWLOCK(rt_list_lock);
static LIST_HEAD(rt_rq_head);
static LIST_HEAD(cfs_rq_head);
static DEFINE_RWLOCK(cfs_list_lock);

#ifdef CONFIG_FAIR_GROUP_SCHED
static inline struct rq *rq_of_cfs(struct cfs_rq *cfs_rq)
{
	return cfs_rq->rq;
}
#else
static inline struct rq *rq_of_cfs(struct cfs_rq *cfs_rq)
{
	return container_of(cfs_rq, struct rq, cfs);
}
#endif

#ifdef CONFIG_RT_GROUP_SCHED
static inline struct rq *rq_of_rt(struct rt_rq *rt_rq)
{
	return rt_rq->rq;
}
#else
static inline struct rq *rq_of_rt(struct rt_rq *rt_rq)
{
	return container_of(rt_rq, struct rq, rt);
}
#endif

static int select_cpu_for_wakeup(int task_type, struct cpumask *mask)
{
	int cpu = smp_processor_id(), i;
	unsigned long load, varload;
	struct rq *rq;

	if (task_type) {
		varload = ULONG_MAX;
		for_each_cpu(i, mask) {
			rq = cpu_rq(i);
			load = rq->cfs.load.weight;
			if (load < varload) {
				varload = load;
				cpu = i;
			}
		}
	} else {
		/* Here's an attempt to get a CPU within the mask where
		 * we can preempt easily. To achieve this we tried to
		 * maintain a lowbit, which indicate the lowest bit set on
		 * array bitmap. Since all CPUs contains high priority
		 * kernel threads therefore we eliminate 0, so it might not
		 * be right every time, but it's just an indicator.
		 */
		varload = 1;

		for_each_cpu(i, mask) {
			rq = cpu_rq(i);
			load = rq->rt.lowbit;
			if (load >= varload) {
				varload = load;
				cpu = i;
			}
		}
	}

	return cpu;
}

static int bld_pick_cpu_cfs(struct task_struct *p, int sd_flags, int wake_flags)
{
	struct cfs_rq *cfs;
	unsigned long flags;
	unsigned int cpu = smp_processor_id();

	read_lock_irqsave(&cfs_list_lock, flags);
	list_for_each_entry(cfs, &cfs_rq_head, bld_cfs_list) {
		cpu = cpu_of(rq_of_cfs(cfs));
		if (cpu_online(cpu))
			break;
	}
	read_unlock_irqrestore(&cfs_list_lock, flags);
	return cpu;
}

static int bld_pick_cpu_rt(struct task_struct *p, int sd_flags, int wake_flags)
{
	struct rt_rq *rt;
	unsigned long flags;
	unsigned int cpu = smp_processor_id();

	read_lock_irqsave(&rt_list_lock, flags);
	list_for_each_entry(rt, &rt_rq_head, bld_rt_list) {
		cpu = cpu_of(rq_of_rt(rt));
		if (cpu_online(cpu))
			break;
	}
	read_unlock_irqrestore(&rt_list_lock, flags);
	return cpu;
}

static int bld_pick_cpu_domain(struct task_struct *p, int sd_flags, int wake_flags)
{
	unsigned int cpu = smp_processor_id(), want_affine = 0;
	struct cpumask *tmpmask;

	if (p->nr_cpus_allowed == 1)
		return task_cpu(p);

	if (sd_flags & SD_BALANCE_WAKE) {
		if (cpumask_test_cpu(cpu, tsk_cpus_allowed(p))) {
			want_affine = 1;
		}
	}

	if (want_affine)
		tmpmask = tsk_cpus_allowed(p);
	else
		tmpmask = sched_domain_span(cpu_rq(task_cpu(p))->sd);

	if (rt_task(p))
		cpu = select_cpu_for_wakeup(0, tmpmask);
	else
		cpu = select_cpu_for_wakeup(1, tmpmask);

	return cpu;
}

static void track_load_rt(struct rq *rq, struct task_struct *p)
{
	unsigned long flag;
	int firstbit;
	struct rt_rq *first;
	struct rt_prio_array *array = &rq->rt.active;

	first = list_entry(rt_rq_head.next, struct rt_rq, bld_rt_list);
	firstbit = sched_find_first_bit(array->bitmap);

	/* Maintaining rt.lowbit */
	if (firstbit > 0 && firstbit <= rq->rt.lowbit)
		rq->rt.lowbit = firstbit;

	if (rq->rt.lowbit < first->lowbit) {
		write_lock_irqsave(&rt_list_lock, flag);
		list_del(&rq->rt.bld_rt_list);
		list_add_tail(&rq->rt.bld_rt_list, &rt_rq_head);
		write_unlock_irqrestore(&rt_list_lock, flag);
	}
}

static int bld_get_cpu(struct task_struct *p, int sd_flags, int wake_flags)
{
	unsigned int cpu;

	if (sd_flags == SD_BALANCE_WAKE || (sd_flags == SD_BALANCE_EXEC && (get_nr_threads(p) > 1)))
		cpu = bld_pick_cpu_domain(p, sd_flags, wake_flags);
	else {
		if (rt_task(p))
			cpu = bld_pick_cpu_rt(p, sd_flags, wake_flags);
		else
			cpu = bld_pick_cpu_cfs(p, sd_flags, wake_flags);
	}

	return cpu;
}

static void bld_track_load_activate(struct rq *rq, struct task_struct *p)
{
	unsigned long flag;
	if (rt_task(p)) {
		track_load_rt(rq, p);
	} else {
		if (rq->cfs.pos != 2) {
			struct cfs_rq *last;
			last = list_entry(cfs_rq_head.prev, struct cfs_rq, bld_cfs_list);
			if (rq->cfs.load.weight >= last->load.weight) {
				write_lock_irqsave(&cfs_list_lock, flag);
				list_del(&rq->cfs.bld_cfs_list);
				list_add_tail(&rq->cfs.bld_cfs_list, &cfs_rq_head);
				rq->cfs.pos = 2; last->pos = 1;
				write_unlock_irqrestore(&cfs_list_lock, flag);
			}
		}
	}
}

static void bld_track_load_deactivate(struct rq *rq, struct task_struct *p)
{
	unsigned long flag;
	if (rt_task(p)) {
		track_load_rt(rq, p);
	} else {
		if (rq->cfs.pos != 0) {
			struct cfs_rq *first;
			first = list_entry(cfs_rq_head.next, struct cfs_rq, bld_cfs_list);
			if (rq->cfs.load.weight <= first->load.weight) {
				write_lock_irqsave(&cfs_list_lock, flag);
				list_del(&rq->cfs.bld_cfs_list);
				list_add(&rq->cfs.bld_cfs_list, &cfs_rq_head);
				rq->cfs.pos = 0; first->pos = 1;
				write_unlock_irqrestore(&cfs_list_lock, flag);
			}
		}
	}
}
#else
static inline void bld_track_load_activate(struct rq *rq, struct task_struct *p)
{
}

static inline void bld_track_load_deactivate(struct rq *rq, struct task_struct *p)
{
}
#endif /* CONFIG_BLD */
