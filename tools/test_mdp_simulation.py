"""
Verification test script for MDP & Bayesian Belief Formulation
Matches scripts/core/MDPSolver.gd logic in Python.
"""
def update_bayesian_belief(warning_detected: bool) -> float:
    prior_hazard = 0.10
    prior_safe = 0.90
    sensor_p_w_given_hazard = 0.90
    sensor_p_w_given_safe = 0.10

    if not warning_detected:
        p_no_w_given_haz = 1.0 - sensor_p_w_given_hazard
        p_no_w_given_safe = 1.0 - sensor_p_w_given_safe
        p_no_w = (p_no_w_given_haz * prior_hazard) + (p_no_w_given_safe * prior_safe)
        return (p_no_w_given_haz * prior_hazard) / p_no_w
    else:
        p_w = (sensor_p_w_given_hazard * prior_hazard) + (sensor_p_w_given_safe * prior_safe)
        posterior = (sensor_p_w_given_hazard * prior_hazard) / p_w
        return posterior

def solve_value_iteration(f: float, max_iter: int = 15):
    gamma = 0.8
    R_goal = 10.0
    R_fail = -20.0
    R_step = -2.0

    # States: 0=Altar, 1=Simpang, 2=Pintas, 3=Raya, 4=Goal, 5=Fail
    V = {s: 0.0 for s in range(6)}

    history = []
    history.append((0, dict(V), {}))

    for k in range(1, max_iter + 1):
        next_V = dict(V)
        step_Q = {}

        # Simpang decisions:
        # a_Pintas -> Goal with (1-f), Fail with f
        q_pintas = (1.0 - f) * (R_goal + gamma * 0.0) + f * (R_fail + gamma * 0.0)
        
        # a_Raya -> Raya with 1.0, R = R_step
        q_raya = 1.0 * (R_step + gamma * V[3])
        
        # a_Balik -> Altar with 1.0, R = R_step
        q_balik = 1.0 * (R_step + gamma * V[0])

        step_Q[1] = {"PINTAS": q_pintas, "RAYA": q_raya, "BALIK": q_balik}
        next_V[1] = max(q_pintas, q_raya, q_balik)

        # Jalur Utama -> Goal with 1.0, R = R_goal
        q_raya_to_goal = 1.0 * (R_goal + gamma * 0.0)
        next_V[3] = q_raya_to_goal

        # Altar -> Simpang with 1.0, R = R_step
        next_V[0] = 1.0 * (R_step + gamma * V[1])

        # Terminal
        next_V[4] = 0.0
        next_V[5] = 0.0

        V = next_V
        history.append((k, dict(V), dict(step_Q)))

    return history

if __name__ == "__main__":
    # Test Bayes
    b_normal = update_bayesian_belief(False)
    b_warning = update_bayesian_belief(True)
    print(f"Bayesian Belief Clear:   P(H|no W) = {b_normal:.4f}")
    print(f"Bayesian Belief Warning: P(H|W)    = {b_warning:.4f}")
    assert abs(b_warning - 0.50) < 1e-4, "Posterior must be 0.50!"

    # Test Value Iteration Normal
    hist_normal = solve_value_iteration(0.10)
    print("\n--- Value Iteration Normal (f = 0.10) ---")
    for k, v, q in hist_normal[:4]:
        q1 = q.get(1, {})
        print(f"k={k}: V(Altar)={v[0]:.2f}, Q(Simpang,Pintas)={q1.get('PINTAS',0):.2f}, Q(Simpang,Raya)={q1.get('RAYA',0):.2f}, V(Simpang)={v[1]:.2f}, V(Raya)={v[3]:.2f}")

    assert hist_normal[2][2][1]["PINTAS"] == 7.0
    assert hist_normal[2][2][1]["RAYA"] == 6.0
    print("Normal test PASSED: Pintas chosen (7.0 > 6.0)!")

    # Test Value Iteration Warning
    hist_warn = solve_value_iteration(0.50)
    print("\n--- Value Iteration Warning (f = 0.50) ---")
    for k, v, q in hist_warn[:4]:
        q1 = q.get(1, {})
        print(f"k={k}: V(Altar)={v[0]:.2f}, Q(Simpang,Pintas)={q1.get('PINTAS',0):.2f}, Q(Simpang,Raya)={q1.get('RAYA',0):.2f}, V(Simpang)={v[1]:.2f}, V(Raya)={v[3]:.2f}")

    assert hist_warn[2][2][1]["PINTAS"] == -5.0
    assert hist_warn[2][2][1]["RAYA"] == 6.0
    print("Warning test PASSED: Policy Shifted to Raya (-5.0 < 6.0)!")

