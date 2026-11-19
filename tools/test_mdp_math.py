# Python verification of MDPSolver math
def solve(f):
    gamma = 0.8
    R_goal = 10.0
    R_fail = -20.0
    R_step = -2.0
    
    # Q(Simpang, Pintas) = (1 - f) * R_goal + f * R_fail
    q_pintas = (1.0 - f) * R_goal + f * R_fail
    
    # Jalur utama leads to goal with prob 1.0, R = R_goal = 10
    # Living cost from simpang to jalur utama is R_step = -2
    # Q(Simpang, Raya) = R_step + gamma * 10 = -2 + 8.0 = 6.0
    q_raya = R_step + gamma * R_goal
    
    return q_pintas, q_raya

print("Normal (f=0.10):", solve(0.10))
print("Warning (f=0.50):", solve(0.50))

