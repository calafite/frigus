:- module(cfg_npc, [
    job_sched/3,
    job_tgt/2,
    base_job/2,
    mem_mod/2
]).

job_sched(citizen, H, sleep) :- (H >= 22 ; H < 6), !.
job_sched(citizen, H, eat) :- (H >= 6, H < 8 ; H >= 18, H < 20), !.
job_sched(citizen, H, work) :- H >= 8, H < 18, !.
job_sched(citizen, _, leisure).

job_sched(merchant, H, sleep) :- (H >= 23 ; H < 6), !.
job_sched(merchant, H, eat) :- (H >= 6, H < 7 ; H >= 20, H < 21), !.
job_sched(merchant, H, work) :- H >= 7, H < 20, !.
job_sched(merchant, _, leisure).

job_sched(guard, H, work) :- H >= 6, H < 18, !.
job_sched(guard, H, eat) :- H >= 18, H < 19, !.
job_sched(guard, H, sleep) :- H >= 20 ; H < 6, !.
job_sched(guard, _, leisure).

job_sched(night_guard, H, work) :- (H >= 18 ; H < 6), !.
job_sched(night_guard, H, eat) :- H >= 6, H < 7, !.
job_sched(night_guard, H, sleep) :- H >= 8, H < 16, !.
job_sched(night_guard, _, leisure).

job_sched(_, _, wander).

job_tgt(sleep, home).
job_tgt(work, work).
job_tgt(eat, tavern).
job_tgt(leisure, square).

base_job(citizen, citizen).
base_job(peasant, citizen).
base_job(merchant, merchant).
base_job(guard, guard).
base_job(scholar, citizen).
base_job(priest, citizen).

mem_mod(trade, 2).
mem_mod(talk, 1).
mem_mod(help, 10).
mem_mod(attack, -50).
mem_mod(steal, -20).
