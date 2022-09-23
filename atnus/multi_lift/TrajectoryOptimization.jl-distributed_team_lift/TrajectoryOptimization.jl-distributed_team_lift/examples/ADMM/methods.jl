function solve_admm_1slack(prob_lift, prob_load, n_slack, admm_type, opts, infeasible=false)
    N = prob_load.N; dt = prob_load.dt

    # Problem dimensions
    num_lift = length(prob_lift)
    n_lift = prob_lift[1].model.n
    m_lift = prob_lift[1].model.m
    n_load = prob_load.model.n
    m_load = prob_load.model.m

    # Calculate cable lengths based on initial configuration
    d = [norm(prob_lift[i].x0[1:n_slack] - prob_load.x0[1:n_slack]) for i = 1:num_lift]

    for i = 1:num_lift
        solve!(prob_lift[i],opts)

    end
    solve!(prob_load,opts)
    # return prob_lift,prob_load,1,1

    # Generate cable constraints
    X_lift = [deepcopy(prob_lift[i].X) for i = 1:num_lift]
    U_lift = [deepcopy(prob_lift[i].U) for i = 1:num_lift]

    X_load = deepcopy(prob_load.X)
    U_load = deepcopy(prob_load.U)

    cable_lift = [gen_lift_cable_constraints_1slack(X_load,
                    U_load,
                    i,
                    n_lift,
                    m_lift,
                    d[i],
                    n_slack) for i = 1:num_lift]

    cable_load = gen_load_cable_constraints_1slack(X_lift,U_lift,n_load,m_load,d,n_slack)

    r_lift = .275
    self_col = [gen_self_collision_constraints(X_lift,i,n_lift,m_lift,r_lift,n_slack) for i = 1:num_lift]


    # Add system constraints to problems
    for i = 1:num_lift
        for k = 1:N
            prob_lift[i].constraints[k] += cable_lift[i][k]
            prob_lift[i].constraints[k] += self_col[i][k]
        end
    end

    for k = 1:N
        prob_load.constraints[k] += cable_load[k]
    end

    # Create augmented Lagrangian problems, solvers
    solver_lift_al = []
    prob_lift_al = []
    for i = 1:num_lift

        solver = TO.AbstractSolver(prob_lift[i],opts)
        prob = AugmentedLagrangianProblem(prob_lift[i],solver)
        prob.model = gen_lift_model(X_load,N,dt)

        push!(solver_lift_al,solver)
        push!(prob_lift_al,prob)
    end


    solver_load_al = TO.AbstractSolver(prob_load,opts)
    prob_load_al = AugmentedLagrangianProblem(prob_load,solver_load_al)
    prob_load_al.model = gen_load_model(X_lift,N,dt)

    for ii = 1:opts.iterations
        # Solve lift agents
        for i = 1:num_lift

            TO.solve_aula!(prob_lift_al[i],solver_lift_al[i])

            # Update constraints (sequentially)
            if admm_type == :sequential
                X_lift[i] .= prob_lift_al[i].X
                U_lift[i] .= prob_lift_al[i].U
            end
        end

        # Update constraints (parallel)
        if admm_type == :parallel
            for i = 1:num_lift
                X_lift[i] .= prob_lift_al[i].X
                U_lift[i] .= prob_lift_al[i].U
            end
        end

        # Solve load
        # return prob_lift,prob_load,1,1

        prob_load_al.model = gen_load_model(X_lift,N,dt)
        TO.solve_aula!(prob_load_al,solver_load_al)

        # Update constraints
        X_load .= prob_load_al.X
        U_load .= prob_load_al.U

        for i = 1:num_lift
            prob_lift_al[i].model = gen_lift_model(X_load,N,dt)
        end

        # Update lift constraints prior to evaluating convergence
        for i = 1:num_lift
            TO.update_constraints!(prob_lift_al[i].obj.C,prob_lift_al[i].obj.constraints, prob_lift_al[i].X, prob_lift_al[i].U)
            TO.update_active_set!(prob_lift_al[i].obj)
        end
        # TO.update_constraints!(prob_load_al.obj.C,prob_load_al.obj.constraints, prob_load_al.X, prob_load_al.U)
        # TO.update_active_set!(prob_load_al.obj)

        max_c = max([max_violation(solver_lift_al[i]) for i = 1:num_lift]...,max_violation(solver_load_al))
        println(max_c)

        if max_c < opts.constraint_tolerance
            @info "ADMM problem solved"
            break
        end
    end

    return prob_lift_al, prob_load_al, solver_lift_al, solver_load_al
end


function solve_admm(prob_lift, prob_load, n_slack, admm_type, opts, infeasible=false)
    N = prob_load.N

    # Problem dimensions
    num_lift = length(prob_lift)
    n_lift = prob_lift[1].model.n
    m_lift = prob_lift[1].model.m
    n_load = prob_load.model.n
    m_load = prob_load.model.m

    # Calculate cable lengths based on initial configuration
    d = [norm(prob_lift[i].x0[1:n_slack] - prob_load.x0[1:n_slack]) for i = 1:num_lift]

    opts.constraint_tolerance = 1.0e-4
    for i = 1:num_lift
        solve!(prob_lift[i],opts)

        # rollout!(prob_lift[i])
    end
    solve!(prob_load,opts)
    # rollout!(prob_load)
    opts.constraint_tolerance = 0.001
    # return prob_lift,prob_load,1,1

    # Generate cable constraints
    X_lift = [deepcopy(prob_lift[i].X) for i = 1:num_lift]
    U_lift = [deepcopy(prob_lift[i].U) for i = 1:num_lift]

    X_load = deepcopy(prob_load.X)
    U_load = deepcopy(prob_load.U)

    cable_lift = [gen_lift_cable_constraints(X_load,
                    U_load,
                    i,
                    n_lift,
                    m_lift,
                    d[i],
                    n_slack) for i = 1:num_lift]

    cable_load = gen_load_cable_constraints(X_lift,U_lift,n_load,m_load,d,n_slack)

    r_lift = prob_lift[1].model.info[:radius]::Float64
    self_col = [gen_self_collision_constraints(X_lift,i,n_lift,m_lift,r_lift,n_slack) for i = 1:num_lift]

    dir_lift = [gen_lift_direction_constraints(prob_lift[i].model, X_load,U_load,i) for i = 1:num_lift]
    dir_load = gen_load_direction_constraints(prob_load.model, X_lift, U_lift)

    # Add system constraints to problems
    for i = 1:num_lift
        for k = 1:N
            prob_lift[i].constraints[k] += cable_lift[i][k]
            prob_lift[i].constraints[k] += self_col[i][k]
            if k < N
                prob_lift[i].constraints[k] += dir_lift[i][k]
            end
        end
    end

    for k = 1:N
        prob_load.constraints[k] += cable_load[k]
        if k < N
            prob_load.constraints[k] += dir_load[k]
        end
    end

    # Create augmented Lagrangian problems, solvers
    solver_lift_al = []
    prob_lift_al = []
    for i = 1:num_lift

        solver = TO.AbstractSolver(prob_lift[i],opts)
        prob = AugmentedLagrangianProblem(prob_lift[i],solver)


        push!(solver_lift_al,solver)
        push!(prob_lift_al,prob)
    end


    solver_load_al = TO.AbstractSolver(prob_load,opts)
    prob_load_al = AugmentedLagrangianProblem(prob_load,solver_load_al)

    for ii = 1:opts.iterations
        # Solve lift agents
        for i = 1:num_lift


            TO.solve_aula!(prob_lift_al[i],solver_lift_al[i])

            # Update constraints (sequentially)
            if admm_type == :sequential
                X_lift[i] .= prob_lift_al[i].X
                U_lift[i] .= prob_lift_al[i].U
            end
        end

        # Update constraints (parallel)
        if admm_type == :parallel
            for i = 1:num_lift
                X_lift[i] .= prob_lift_al[i].X
                U_lift[i] .= prob_lift_al[i].U
            end
        end

        # Solve load
        TO.solve_aula!(prob_load_al,solver_load_al)

        # Update constraints
        X_load .= prob_load_al.X
        U_load .= prob_load_al.U

        # Update lift constraints prior to evaluating convergence
        for i = 1:num_lift
            TO.update_constraints!(prob_lift_al[i].obj.C,prob_lift_al[i].obj.constraints, prob_lift_al[i].X, prob_lift_al[i].U)
            TO.update_active_set!(prob_lift_al[i].obj)
        end
        # TO.update_constraints!(prob_load_al.obj.C,prob_load_al.obj.constraints, prob_load_al.X, prob_load_al.U)
        # TO.update_active_set!(prob_load_al.obj)

        max_c = max([max_violation(solver_lift_al[i]) for i = 1:num_lift]...,max_violation(solver_load_al))
        println(max_c)

        if max_c < opts.constraint_tolerance
            @info "ADMM problem solved"
            break
        end
    end

    return prob_lift_al, prob_load_al, solver_lift_al, solver_load_al
end

function gen_lift_cable_constraints(X_load,U_load,agent,n,m,d,n_slack=3)
    N = length(X_load)
    con_cable_lift = []
    Is = Diagonal(I,n_slack)

    for k = 1:N
        function con(c,x,u=zeros())
            if k == 1
                c[1:n_slack] = u[(end-(n_slack-1)):end] + U_load[k][(agent-1)*n_slack .+ (1:n_slack)]
            else
                c[1] = norm(x[1:n_slack] - X_load[k][1:n_slack])^2 - d^2
                if k < N
                    c[1 .+ (1:n_slack)] = u[(end-(n_slack-1)):end] + U_load[k][(agent-1)*n_slack .+ (1:n_slack)]
                end
            end
        end

        function ∇con(C,x,u=zeros())
            x_pos = x[1:n_slack]
            x_load_pos = X_load[k][1:n_slack]
            dif = x_pos - x_load_pos
            if k == 1
                C[1:n_slack,(end-(n_slack-1)):end] = Is
            else
                C[1,1:n_slack] = 2*dif
                if k < N
                    C[1 .+ (1:n_slack),(end-(n_slack-1)):end] = Is
                end
            end
        end
        if k == 1
            p_con = n_slack
        else
            k < N ? p_con = 1+n_slack : p_con = 1
        end
        cc = Constraint{Equality}(con,∇con,n,m,p_con,:cable_lift)
        push!(con_cable_lift,cc)
    end

    return con_cable_lift
end

function gen_lift_cable_constraints_1slack(X_load,U_load,agent,n,m,d,n_slack=3)
    N = length(X_load)
    con_cable_lift = []
    Is = Diagonal(I,n_slack)

    for k = 1:N
        function con(c,x,u=zeros())
            if k == 1
                c[1] = u[end] - U_load[k][(agent-1) + 1]
            else
                c[1] = norm(x[1:n_slack] - X_load[k][1:n_slack])^2 - d^2
                if k < N
                    c[2] = u[end] - U_load[k][(agent-1) + 1]
                end
            end
        end

        function ∇con(C,x,u=zeros())
            x_pos = x[1:n_slack]
            x_load_pos = X_load[k][1:n_slack]
            dif = x_pos - x_load_pos
            if k == 1
                C[1,end] = 1.0
            else
                C[1,1:n_slack] = 2*dif
                if k < N
                    C[2,end] = 1.0
                end
            end
        end
        if k == 1
            p_con = 1
        else
            k < N ? p_con = 1+1 : p_con = 1
        end
        cc = Constraint{Equality}(con,∇con,n,m,p_con,:cable_lift)
        push!(con_cable_lift,cc)
    end

    return con_cable_lift
end

function gen_load_cable_constraints(X_lift,U_lift,n,m,d,n_slack=3)
    num_lift = length(X_lift)
    N = length(X_lift[1])
    con_cable_load = []

    Is = Diagonal(I,n_slack)

    for k = 1:N
        function con(c,x,u=zeros())
            if k == 1
                _shift = 0
                for i = 1:num_lift
                    c[_shift .+ (1:n_slack)] = U_lift[i][k][(end-(n_slack-1)):end] + u[(i-1)*n_slack .+ (1:n_slack)]
                    _shift += n_slack
                end
            else
                for i = 1:num_lift
                    c[i] = norm(X_lift[i][k][1:n_slack] - x[1:n_slack])^2 - d[i]^2
                end

                if k < N
                    _shift = num_lift
                    for i = 1:num_lift
                        c[_shift .+ (1:n_slack)] = U_lift[i][k][(end-(n_slack-1)):end] + u[(i-1)*n_slack .+ (1:n_slack)]
                        _shift += n_slack
                    end
                end
            end
        end

        function ∇con(C,x,u=zeros())
            if k == 1
                _shift = 0
                for i = 1:num_lift
                    u_idx = ((i-1)*n_slack .+ (1:n_slack))
                    C[_shift .+ (1:n_slack),n .+ u_idx] = Is
                    _shift += n_slack
                end
            else
                for i = 1:num_lift
                    x_pos = X_lift[i][k][1:n_slack]
                    x_load_pos = x[1:n_slack]
                    dif = x_pos - x_load_pos
                    C[i,1:n_slack] = -2*dif
                end
                if k < N
                    _shift = num_lift
                    for i = 1:num_lift
                        u_idx = ((i-1)*n_slack .+ (1:n_slack))
                        C[_shift .+ (1:n_slack),n .+ u_idx] = Is
                        _shift += n_slack
                    end
                end
            end
        end
        if k == 1
            p_con = num_lift*n_slack
        else
            k < N ? p_con = num_lift*(1 + n_slack) : p_con = num_lift
        end
        cc = Constraint{Equality}(con,∇con,n,m,p_con,:cable_load)
        push!(con_cable_load,cc)
    end

    return con_cable_load
end

function gen_load_cable_constraints_1slack(X_lift,U_lift,n,m,d,n_slack=3)
    num_lift = length(X_lift)
    N = length(X_lift[1])
    con_cable_load = []

    Is = Diagonal(I,n_slack)

    for k = 1:N
        function con(c,x,u=zeros())
            if k == 1
                _shift = 0
                for i = 1:num_lift
                    c[_shift + 1] = U_lift[i][k][end] - u[(i-1) + 1]
                    _shift += 1
                end
            else
                for i = 1:num_lift
                    c[i] = norm(X_lift[i][k][1:n_slack] - x[1:n_slack])^2 - d[i]^2
                end

                if k < N
                    _shift = num_lift
                    for i = 1:num_lift
                        c[_shift + 1] = U_lift[i][k][end] - u[(i-1) + 1]
                        _shift += 1
                    end
                end
            end
        end

        function ∇con(C,x,u=zeros())
            if k == 1
                _shift = 0
                for i = 1:num_lift
                    u_idx = ((i-1) + 1)
                    C[_shift + 1,n + u_idx] = -1.0
                    _shift += 1
                end
            else
                for i = 1:num_lift
                    x_pos = X_lift[i][k][1:n_slack]
                    x_load_pos = x[1:n_slack]
                    dif = x_pos - x_load_pos
                    C[i,1:n_slack] = -2*dif
                end
                if k < N
                    _shift = num_lift
                    for i = 1:num_lift
                        u_idx = ((i-1) + 1)
                        C[_shift + 1,n + u_idx] = -1.0
                        _shift += 1
                    end
                end
            end
        end
        if k == 1
            p_con = num_lift
        else
            k < N ? p_con = num_lift*(1 + 1) : p_con = num_lift
        end
        cc = Constraint{Equality}(con,∇con,n,m,p_con,:cable_load)
        push!(con_cable_load,cc)
    end

    return con_cable_load
end

function gen_self_collision_constraints(X_lift,agent,n,m,r_lift,n_slack=3)
    num_lift = length(X_lift)
    N = length(X_lift[1])
    p_con = num_lift - 1

    self_col_con = []

    for k = 1:N
        function col_con(c,x,u=zeros())
            p_shift = 1
            for i = 1:num_lift
                if i != agent
                    x_pos = x[1:n_slack]
                    x_pos2 = X_lift[i][k][1:n_slack]
                    c[p_shift] = (r_lift + r_lift)^2 - norm(x_pos - x_pos2)^2
                    p_shift += 1
                end
            end
        end

        function ∇col_con(C,x,u=zeros())
            p_shift = 1
            for i = 1:num_lift
                if i != agent
                    x_pos = x[1:n_slack]
                    x_pos2 = X_lift[i][k][1:n_slack]
                    dif = x_pos - x_pos2
                    C[p_shift,1:n_slack] = -2*dif
                    p_shift += 1
                end
            end
        end

        push!(self_col_con,Constraint{Inequality}(col_con,∇col_con,n,m,p_con,:self_col))
    end

    return self_col_con
end

function update_lift_problem(prob, X_cache, U_cache, agent::Int, d::Float64, r_lift)
    n_lift = prob.model.n
    m_lift = prob.model.m
    n_slack = 3
    N = prob.N

    X_load = X_cache[1]
    U_load = U_cache[1]
    cable_lift = gen_lift_cable_constraints(X_load,
                    U_load,
                    agent,
                    n_lift,
                    m_lift,
                    d,
                    n_slack)


    X_lift = X_cache[2:4]
    U_lift = U_cache[2:4]
    self_col = gen_self_collision_constraints(X_lift, agent, n_lift, m_lift, r_lift, n_slack)

    # Add constraints to problems
    for k = 1:N
        prob.constraints[k] += cable_lift[k]
        (k != 1 && k != N) ? prob.constraints[k] += self_col[k] : nothing
    end
end

function update_load_problem(prob, X_lift, U_lift, d::Vector)
    n_load = prob.model.n
    m_load = prob.model.m
    n_slack = 3

    cable_load = gen_load_cable_constraints(X_lift, U_lift, n_load, m_load, d, n_slack)

    for k = 1:prob.N
        prob.constraints[k] += cable_load[k]
    end
end

function output_traj(prob,idx=collect(1:6),filename=joinpath(pwd(),"examples/ADMM/traj_output.txt"))
    f = open(filename,"w")
    x0 = prob.x0
    for k = 1:prob.N
        x, y, z, vx, vy, vz = prob.X[k][idx]
        str = "$(x-x0[1]) $(y-x0[2]) $(z) $vx $vy $vz"
        if k != prob.N
            str *= " "
        end
        write(f,str)
    end

    close(f)
end

function gen_lift_direction_constraints(model::Model, X_load,U_load,agent,n_slack=3)
    n,m = model.n, model.m
    N = length(X_load)
    con_direction_lift = []
    Is = Diagonal(I,n_slack)

    for k = 1:N-1
        function con(c,x,u=zeros())
            ū = u[(end-(n_slack-1)):end]
            xpos = x[1:n_slack]
            xpos_load = X_load[k][1:n_slack]
            Δx = xpos_load - xpos
            c[1:n_slack] = (Δx'*Δx*Is - Δx*Δx')*ū
        end

        function ∇con(C,x,u=zeros())
            ū = u[(end-(n_slack-1)):end]
            x_pos = x[1:n_slack]
            x_load_pos = X_load[k][1:n_slack]
            Δx =  x_load_pos - x_pos

            function tmp(x)
                Δx = X_load[k][1:n_slack] - x
                (Δx'*Δx*I - Δx*Δx')*ū
            end
            ∇tmp(x) = ForwardDiff.jacobian(tmp,x)
            # println(size(∇tmp(x_pos)))
            C[(1:n_slack),1:n_slack] = reshape(∇tmp(x_pos),n_slack,n_slack)
            C[(1:n_slack),(end-(n_slack-1)):end] = (Δx'*Δx*Is - Δx*Δx')
        end

        p_con = n_slack

        cc = Constraint{Equality}(con,n,m,p_con,:dir_lift)

        push!(con_direction_lift,cc)
    end

    return con_direction_lift
end

function gen_load_direction_constraints(model, X_lift, U_lift, n_slack=3)
    n, m = model.n, model.m

    num_lift = length(X_lift)
    N = length(X_lift[1])
    con_cable_load = Constraint{Equality}[]

    Is = Diagonal(I,n_slack)

    for k = 1:N-1

        function con(c,x,u=zeros())
            _shift = 0
            for i = 1:num_lift
                x_pos = X_lift[i][k][1:n_slack]
                x_load_pos = x[1:n_slack]
                Δx = x_pos - x_load_pos
                ū = u[(i-1)*n_slack .+ (1:n_slack)]
                c[_shift .+ (1:n_slack)] = (Δx'*Δx*Is - Δx*Δx')*ū
                _shift += n_slack
            end
        end

        function ∇con(C,x,u=zeros())
            _shift = 0
            for i = 1:num_lift
                x_pos = X_lift[i][k][1:n_slack]
                x_load_pos = x[1:n_slack]
                Δx = x_pos - x_load_pos
                u_idx = collect((i-1)*n_slack .+ (1:n_slack))
                ū = u[u_idx]
                C[_shift .+ (1:n_slack),n .+ u_idx] = Δx'*Δx*Is - Δx*Δx'

                function tmp(x)
                    Δx = X_lift[i][k][1:n_slack] - x
                    (Δx'*Δx*I - Δx*Δx')*ū
                end
                ∇tmp(x) = ForwardDiff.jacobian(tmp,x)

                C[_shift .+ (1:n_slack),1:n_slack] = reshape(∇tmp(x_load_pos),n_slack,n_slack)
                _shift += n_slack
            end
        end

        p_con = num_lift*n_slack
        cc = Constraint{Equality}(con,∇con,n,m,p_con,:dir_load)
        push!(con_cable_load,cc)
    end

    return con_cable_load
end

function gen_self_collision_constraints(X_lift,agent,n,m,r_lift,n_slack=3)
    num_lift = length(X_lift)
    N = length(X_lift[1])
    p_con = num_lift - 1

    self_col_con = []

    for k = 1:N
        function col_con(c,x,u=zeros())
            p_shift = 1
            for i = 1:num_lift
                if i != agent
                    x_pos = x[1:n_slack]
                    x_pos2 = X_lift[i][k][1:n_slack]
                    # c[p_shift] = (r_lift + r_lift)^2 - norm(x_pos - x_pos2)^2
                    c[p_shift] = circle_constraint(x_pos,x_pos2[1],x_pos2[2],2*r_lift)
                    p_shift += 1
                end
            end
        end

        function ∇col_con(C,x,u=zeros())
            p_shift = 1
            for i = 1:num_lift
                if i != agent
                    x_pos = x[1:n_slack]
                    x_pos2 = X_lift[i][k][1:n_slack]
                    # dif = x_pos - x_pos2
                    # C[p_shift,1:n_slack] = -2*dif
                    C[p_shift,1] = -2*(x_pos[1] - x_pos2[1])
                    C[p_shift,2] = -2*(x_pos[2] - x_pos2[2])
                    p_shift += 1
                end
            end
        end

        push!(self_col_con,Constraint{Inequality}(col_con,∇col_con,n,m,p_con,:self_col))
    end

    return self_col_con
end
