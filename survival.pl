:- module(survival, [
    step_rest/4, step_sleep/4, step_wake/4, step_drink/5, step_fill/4,
    step_fish/4, step_fly/5, step_climb/4, step_mount/5, step_dismount/4,
    step_stance/5, tick_srv/5
]).

:- use_module(entity).
:- use_module(world).

step_rest(W, Id, NW, [started_resting(Id)]) :- world:entity(W, Id, A), A1 = A.put(state, resting), world:update(W, A1, NW).
step_sleep(W, Id, NW, [fell_asleep(Id)]) :- world:entity(W, Id, A), A1 = A.put(state, sleeping), world:update(W, A1, NW).
step_wake(W, Id, NW, [woke_up(Id)]) :- world:entity(W, Id, A), A1 = A.put(state, normal), world:update(W, A1, NW).
step_drink(W, Id, _, NW, [drank(Id)]) :- world:entity(W, Id, A), A1 = A.put(thirst, 0), world:update(W, A1, NW).
step_fill(W, _, NW, []) :- NW = W.
step_fish(W, _, NW, []) :- NW = W.
step_fly(W, Id, Alt, NW, [flying(Id, Alt)]) :- world:entity(W, Id, A), A1 = A.put(altitude, Alt), world:update(W, A1, NW).
step_climb(W, Id, NW, [climbing(Id)]) :- world:entity(W, Id, A), A1 = A.put(climb_state, true), world:update(W, A1, NW).
step_mount(W, Id, Mount, NW, [mounted(Id, Mount)]) :- world:entity(W, Id, A), A1 = A.put(mount, Mount), world:update(W, A1, NW).
step_dismount(W, Id, NW, [dismounted(Id)]) :- world:entity(W, Id, A), A1 = A.put(mount, none), world:update(W, A1, NW).
step_stance(W, Id, Stance, NW, [stance_changed(Id, Stance)]) :- world:entity(W, Id, A), A1 = A.put(stance, Stance), world:update(W, A1, NW).
tick_srv(_, _, E, E, []).
