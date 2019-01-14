#include <rte_log.h>
#include "pipeline_common_be.h"
#include "pipeline_firewall_be.h"
#include "Enclave_t.h"
#include "Enclave.h"

#include "app.h"

int running = 1;

int ecall_firewall_thread(struct app_thread_data *t) {
	uint32_t i;
	for (i = 0; running; i++) {
		/* uint32_t n_regular = RTE_MIN(t->n_regular, RTE_DIM(t->regular)); */
		/* uint32_t n_custom = RTE_MIN(t->n_custom, RTE_DIM(t->custom)); */

		/* Run regular pipelines */
		/* for (j = 0; j < n_regular; j++) { */
			/* struct app_thread_pipeline_data *data = &t->regular[j]; */
			/* struct pipeline *p = data->be; */

			/* PIPELINE_RUN_REGULAR(t, p); */
		/* } */

		/* Run custom pipelines */
		/* for (j = 0; j < n_custom; j++) { */
			/* struct app_thread_pipeline_data *data = &t->custom[j]; */

			/* PIPELINE_RUN_CUSTOM(t, data); */
		/* } */

		struct app_thread_pipeline_data *data = &t->trusted[0];
		struct pipeline *p = data->be;
		rte_pipeline_run(p->p);

		/* Timer */
		if ((i & 0xF) == 0) {
			pipeline_firewall_timer(p);
			/* uint64_t time = rte_get_tsc_cycles(); */
			/* uint64_t t_deadline = UINT64_MAX; */

			/* if (time < t->deadline) */
				/* continue; */

			/* Timer for regular pipelines */
			/* for (j = 0; j < n_regular; j++) { */
				/* struct app_thread_pipeline_data *data = */
					/* &t->regular[j]; */
				/* uint64_t p_deadline = data->deadline; */

				/* if (p_deadline <= time) { */
					/* data->f_timer(data->be); */
					/* p_deadline = time + data->timer_period; */
					/* data->deadline = p_deadline; */
				/* } */

				/* if (p_deadline < t_deadline) */
					/* t_deadline = p_deadline; */
			/* } */

			/* Timer for custom pipelines */
			/* for (j = 0; j < n_custom; j++) { */
				/* struct app_thread_pipeline_data *data = */
					/* &t->custom[j]; */
				/* uint64_t p_deadline = data->deadline; */

				/* if (p_deadline <= time) { */
					/* data->f_timer(data->be); */
					/* p_deadline = time + data->timer_period; */
					/* data->deadline = p_deadline; */
				/* } */

				/* if (p_deadline < t_deadline) */
					/* t_deadline = p_deadline; */
			/* } */

			/* Timer for thread message request */
			/* { */
				/* uint64_t deadline = t->thread_req_deadline; */

				/* if (deadline <= time) { */
					/* thread_msg_req_handle(t); */
					/* thread_headroom_update(t, time); */
					/* deadline = time + t->timer_period; */
					/* t->thread_req_deadline = deadline; */
				/* } */

				/* if (deadline < t_deadline) */
					/* t_deadline = deadline; */
			/* } */


			/* t->deadline = t_deadline; */
		}
	}
	return 0;
}
