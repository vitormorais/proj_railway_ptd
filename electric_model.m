classdef electric_model
    %ELECTRIC_MODEL: class for railway power system analysis
    %   This simulation framework enables a dynamic configuration of a
    %   railway power system, having multiple traction power substations
    
    properties
        number_of_tps
        tps_lenghts
        tps_transformer_impedance
        tps_transformer_susceptance
        tps_catenary_impedance
        tps_catenary_susceptance
        tps
        global_model_mpc
        mpopt
        last_matpower_result
        powerflow_result
        init_matpower_result
        init_powerflow_result
        plot_electric_
        sim_input_data
        debug
        random_status
        electric_parameters
    end
    
    methods
        function obj = electric_model()
            %ELECTRIC_MODEL Construct a simulation scenario for power system analysis
            obj = obj.initiate_random_status();
            obj = obj.initiate_electric_parameters();
        end
        function obj = initiate_random_status(obj)
            obj.random_status.tps_length = {'long','long'}; % {'random', 'random'}; %
            obj.random_status.tps_length_value = {25 25};
            obj.random_status.tps_cluster = {'dense', 'dense'}; % {'random', 'random'}; %
            obj.random_status.num_trains_tps = {'fixed', 'fixed'}; % {'random', 'random'}; %
            obj.random_status.num_trains_tps_value = {1 1};  %% NOTA: zero!
            obj.random_status.trains_power_tps = {'fixed', 'fixed'}; %{'random', 'random'}; % 
            obj.random_status.trains_power_tps_value = {[5] [0]};  %% em MW 
            obj.random_status.trains_pf_tps = {'fixed', 'fixed'}; % {'random', 'random'}; % 
            obj.random_status.trains_pf_tps_value = {[0.98] [0.98]};
            obj.random_status.trains_pos_tps = {'random', 'random'}; %% {'random', 'random'}; %
            obj.random_status.trains_pos_tps_value = {[0.5] [0.5]};  %% entre 0 e 1
        end
        function obj = initiate_electric_parameters(obj)
            %%% set "cable" parameters
            cable.resistance = 0.055;
            cable.reactance = 0.22e-3;
            cable.capacitance = 1e-6;
            cable.distance = 0.5;
            obj.electric_parameters.cable = cable;
            %%% set catenary parameters
            catenary.resistance = 0.15;
            catenary.reactance  = 1.43e-3;
            catenary.capacitance = 12.4e-9;
            obj.electric_parameters.catenary = catenary;
            obj.electric_parameters.nominal_voltage = 27.5;
            %%% set ptd parameters
            ptd.nominal_power = 12.5;
            ptd.transformer_impedance = 1.089 + 1i*2.178;
            ptd.inverter_impedance = 0.423;
            ptd.permanent_losses = 0.0375;
            obj.electric_parameters.ptd = ptd;
            %%% set pu
            pu.sbase = 100;
            pu.vbase = 27.5;
            pu.ibase = 3636.4;
            pu.zbase = 7.5625;
            obj.electric_parameters.pu = pu;
        end
        function obj = set_random_status(obj, random_status_)
            %%%Method to be updated by the MC top class
             obj.random_status = random_status_;
        end
        function obj = update_electric_model_parameters(obj, electric_parameters_)
            %%%Method to be updated by the MC top class
             obj.electric_parameters = electric_parameters_;
        end
        function obj = reset_model(obj)
            %%% This method clears the matrices and TPS structure array, and resets the parameters of each TPS and the electrical parameters
            obj.tps = [];
            obj.global_model_mpc = [];
            obj = obj.setup_electric_parameters();
            obj = obj.setup_tps();
        end
        function obj = generate_random_trains(obj)
            %%% This method is used to generate two structures of random trains (for asc_right in tps1 and asc_left in tps2). 
            % All the random number generation follows a distribution PDF: 
            % 1. (TBD) type/cluster of TPS is random [1 2];
            % 2. (TBD) number of trains random, according to type;
            % 3. Position of each train is random, according to number of
            %    trains (is ensured minimum X meters between trains)
            % 4. TPS power is defined following a lognormal PDF
            % 5. Train powers are defined based on the desired TPS power
            %    (is ensured train power limits)
            % 6. Train power factors are defined following a 2D PDF,
            %    based on train power
            
            
%             trains_left_2.tps_cluster = gen_rand_tps_cluster();
%             trains_right_1.tps_cluster = gen_rand_tps_cluster();            
            switch obj.random_status.tps_cluster{1} 
                case 'random'
                    trains_right_1.tps_cluster = gen_rand_tps_cluster();
                otherwise
                    trains_right_1.tps_cluster = obj.random_status.tps_cluster{1} ;
            end
            switch obj.random_status.tps_cluster{2} 
                case 'random'
                    trains_left_2.tps_cluster = gen_rand_tps_cluster();
                otherwise
                    trains_left_2.tps_cluster = obj.random_status.tps_cluster{2};
            end

            
            %%%%%%%%%%%%% GERAÇÃO DADOS RAND input MONTE CARLO
            %%% Number of trains is rand and in [0 1 2 .. 6]
%             train_no_left = gen_num_trains(trains_left_2.tps_cluster);%number_of_trains(1);
%             train_no_right = gen_num_trains(trains_right_1.tps_cluster);%number_of_trains(2);
            switch  obj.random_status.num_trains_tps{1}
                case 'random'
                    train_no_right = gen_num_trains(trains_right_1.tps_cluster);%number_of_trains(1);
                otherwise
                    train_no_right = obj.random_status.num_trains_tps_value{1};
            end
            switch  obj.random_status.num_trains_tps{2}
                case 'random'
                    train_no_left = gen_num_trains(trains_left_2.tps_cluster);%number_of_trains(2);
                otherwise
                    train_no_left = obj.random_status.num_trains_tps_value{2};
            end
            
            
            %%% cria vector de identificadores
            trains_right_1.id = 1:train_no_right;
            trains_left_2.id = 1:train_no_left;
            trains_left_2.id = trains_left_2.id+train_no_right;%%% identificadores diferentes de anterior
            
            %%%posição dos comboios é random
%              trains_right_1.position = gen_rand_positions(train_no_right, obj.tps_lenghts(1,2));
%              trains_left_2.position  = gen_rand_positions(train_no_left, obj.tps_lenghts(2,1));
            switch  obj.random_status.trains_pos_tps{1}
                case 'random'
                    trains_right_1.position = gen_rand_positions(train_no_right, obj.tps_lenghts(1,2));
                otherwise
                    trains_right_1.position =  obj.random_status.trains_pos_tps_value{1};
            end
            switch  obj.random_status.trains_pos_tps{2}
                case 'random'
                    trains_left_2.position  = gen_rand_positions(train_no_left, obj.tps_lenghts(2,1));
                otherwise
                    trains_left_2.position  =  obj.random_status.trains_pos_tps_value{2};
            end

            %%%potência dos comboios é random
            %%%potências aparentes de comboios é random (max=8MVA @ pf1.0)
            if train_no_right > 0
                %%%RIGHT generate N active power values, where sum(P) = TPS_power which follows distribution
%                 trains_right_1.apower = gen_rand_power(train_no_right, [-1e6 20e6], [-0.2e6 8e6], trains_right_1.tps_cluster);
                switch  obj.random_status.trains_power_tps{1}
                    case 'random'
                        trains_right_1.apower = gen_rand_power(train_no_right, [-1e6 20e6], [-0.2e6 8e6], trains_right_1.tps_cluster);
                    otherwise
                        trains_right_1.apower = obj.random_status.trains_power_tps_value{1};
                end
                
                %generate reactive power values based on train active power
%                 [trains_right_1.rpower, trains_right_1.pf] = gen_rand_reactive_power(trains_right_1.apower, [0.5 1], [-0.2 8]);
                switch  obj.random_status.trains_pf_tps{1}
                    case 'random'
                        [trains_right_1.rpower, trains_right_1.pf] = gen_rand_reactive_power(trains_right_1.apower, [0.5 1], [-0.2 8]);
                    otherwise
                        trains_right_1.pf = obj.random_status.trains_pf_tps_value{1};
                        trains_right_1.rpower = trains_right_1.apower.*tan(acos(trains_right_1.pf));
                end
            else
                trains_right_1.apower = [];
                trains_right_1.pf = [];
                trains_right_1.rpower = [];
            end
            
            if train_no_left > 0
                %%%LEFT generate N active power values, where sum(P) = TPS_power which follows distribution
                %trains_left_2.apower = gen_rand_power(train_no_left, [-1e6 20e6], [-0.2e6 8e6], trains_left_2.tps_cluster);
                switch  obj.random_status.trains_power_tps{2}
                    case 'random'
                        trains_left_2.apower = gen_rand_power(train_no_left, [-1e6 20e6], [-0.2e6 8e6], trains_left_2.tps_cluster);
                    otherwise
                        trains_left_2.apower = obj.random_status.trains_power_tps_value{2};
                end
                %generate reactive power values based on train active power
                %[trains_left_2.rpower, trains_left_2.pf] = gen_rand_reactive_power(trains_left_2.apower, [0.5 1], [-0.2 8]);
                 switch  obj.random_status.trains_pf_tps{2}
                    case 'random'
                        [trains_left_2.rpower, trains_left_2.pf] = gen_rand_reactive_power(trains_left_2.apower, [0.5 1], [-0.2 8]);
                    otherwise
                        trains_left_2.pf = obj.random_status.trains_pf_tps_value{2};
                        trains_left_2.rpower = trains_left_2.apower.*tan(acos(trains_left_2.pf));
                end
            else
                trains_left_2.apower = [];
                trains_left_2.pf = [];
                trains_left_2.rpower = [];
            end
            
            % FIM GERAÇÃO DADOS RAND input MONTE CARLO
            obj.sim_input_data.trains_right_1 = trains_right_1;
            obj.sim_input_data.trains_left_2 = trains_left_2;
            
            % ADD TRAINS
            obj = obj.add_trains(1, 'right', 'asc', obj.sim_input_data.trains_right_1);
            obj = obj.add_trains(2, 'left', 'asc', obj.sim_input_data.trains_left_2);
            
            %%% method "generate_random_trains" aux functions
            function tps_type = gen_rand_tps_cluster()
                tps_type_val = round(random(makedist('Uniform','lower',0,'upper',1),1,1));
                switch tps_type_val
                    case 0
                        tps_type = 'dense';
                    case 1
                        tps_type = 'sparse';
                end
            end
            function array_num_trains = gen_num_trains(type_of_tps)
                switch type_of_tps
                    case 'dense'
                        array_num_trains = poissrnd(1.4, 1, 1);
                    case 'sparse'
                        array_num_trains = poissrnd(0.3, 1, 1);
                end
            end
            function pos_array = gen_rand_positions(num_trains, tps_length)
                min_dist = 0.75; %%750m
                if num_trains > 0
                    for iter = 1:1000  %%%while 1
                         pos_array = random(makedist('Uniform','lower',0,'upper',1),num_trains,1);
                         pos_array = sortrows(pos_array, 1, 'asc')';
                         if (min(pos_array(2:end) - pos_array(1:end-1)))*tps_length > min_dist
                             break;
                         end
                    end
                else
                    pos_array = [];
                end
            end
            function power_array = gen_rand_power(num_trains, lim_tps_power, lim_train_power, type_of_tps)
                %%% generates an array of power values (in MW), based on
                %%% the desired distribution functions
                switch type_of_tps
                    case 'dense'
                        mu = log(5); sigma = 0.75;
                    case 'sparse'
                        mu = log(1); sigma = 1;
                end
                for iter_1 = 1:10
                    for iter_2 = 1:100
                        tps_total_power = 1e6.* random(makedist('Lognormal', mu, sigma), 1, 1);
                        if (tps_total_power < min(lim_tps_power(2),num_trains*lim_train_power(2))  && tps_total_power > lim_tps_power(1))
                            break; %gera TPS_power
                        end
                    end
                    for iter_3 = 1:100
                        %%% creates a 100xN power matrix; then finds/selects the value where sum(P1..Pn)-desiredP is lower 
                        loop_train_pwr = random(makedist('Uniform','lower',lim_train_power(1),'upper',lim_train_power(2)),num_trains,100);
                        loop_train_pwr_index = sum(loop_train_pwr)-tps_total_power;
                        loop_train_pwr_index = find(loop_train_pwr_index == min(loop_train_pwr_index));
                        power_array = 1e-6.*loop_train_pwr(:,loop_train_pwr_index).*(tps_total_power/sum(loop_train_pwr(:,loop_train_pwr_index)));
                        if min(power_array) > lim_train_power(1)*1e-6 && max(power_array) < lim_train_power(2)*1e-6
                           break; %gera array train power
                        end
                    end
                    if min(power_array) > lim_train_power(1)*1e-6 && max(power_array) < lim_train_power(2)*1e-6 &&...
                            sum(power_array) > lim_tps_power(1)*1e-6 && sum(power_array) < lim_tps_power(2)*1e-6
                        break;
                    end
                end
            end
            function [rpower_array, pf_array] = gen_rand_reactive_power(apower_array, pf_lim, pwr_lim)
                %%% generates an array of N random PF values and reactive
                %%% power values
                pf_array =  apower_array.*0+1;
                rpower_array = apower_array.*0;
                for train = 1:size(apower_array,1)
                    for iter = 1:1000   %%%while 1
                        pf_array(train) = gen_rand_pf(apower_array(train));
                        if pf_array(train) > pf_lim(1) && pf_array(train) <= pf_lim(2) && ...
                                sqrt(apower_array(train)^2+(apower_array(train)*tan(acos(pf_array(train))))^2) < pwr_lim(2)
                            rpower_array(train) = apower_array(train).*tan(acos(pf_array(train)));
                            break;
                        end
                    end
                end
            end
            function value = gen_rand_pf(power)
                sigma_value = 0.125 - 0.125*(1/8 .* power);
                sigma_value = max(sigma_value,0);
                mu_value = 0.8 + (0.2/16 .* power.^2); %mu_value = 0.8 + 0.2*sigmf(power, [1 4]);
                mu_value = max(0.5, min(1, mu_value));
                value = random(makedist('Normal','mu', mu_value ,'sigma', sigma_value),1,1);
                iter = 0;
                while value > 1 || value < 0.5
                    value = random(makedist('Normal','mu', mu_value ,'sigma', sigma_value),1,1);
                    if iter > 1000, break; else, iter = iter+1; end  %%%avoid while(1) loops!!!
                end
            end
        end
        function obj = losses_optimization(obj, max_iter, tol)
            %%% This method performs the compensation NUMBER2: the TPS power is balanced and then, the compensation power is ITERATIVELLY adapted while the global power losses are evaluated. Objective function is to reduce power losses.
            prev_losses = sum(obj.powerflow_result.apower_losses);
            tps1_power = real(obj.powerflow_result.tps_power(1));
            tps2_power = real(obj.powerflow_result.tps_power(2));
            compensation = (tps1_power - tps2_power)*0.5;
            compensation = max(min(compensation, 12.5), -12.5); %% saturação entre -1.5 e 1.5 MVA
            reactive = @(apower) apower^4*2.368457120606040e-04 + apower^3*0.003644081427839 + apower^2*0.069676709709654 + apower^1*0.001647622855671 + 0.003024538598544;
            get_bus_no = @(global_model_mpc, bus_id) find(global_model_mpc.bus(:,1)==bus_id);
            %polyn = [2.368457120606040e-04 0.003644081427839 0.069676709709654 0.001647622855671 0.003024538598544]; %%dupla compensação transf + polinómio de grau 4
            
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),3) = -compensation;
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),4) = 0;%-(reactive(-compensation));% (-compensation)^4*polyn(1) + (-compensation)^3*polyn(2) + (-compensation)^2*polyn(3) + (-compensation)*polyn(4) + polyn(5));
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),3) = compensation;
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),4) = 0;%-(reactive(compensation));%(compensation)^4*polyn(1) + (compensation)^3*polyn(2) + (compensation)^2*polyn(3) + (compensation)*polyn(4) + polyn(5));
%             function bus = get_bus_no(global_model_mpc, bus_id)
%                 bus = find(global_model_mpc.bus(:,1)==bus_id);
%             end
            obj = obj.run_powerflow();
            obj = obj.process_output();
            direction = sign(compensation);
            losses = [prev_losses sum(obj.powerflow_result.apower_losses)];
            for iter = 1:max_iter
                %%%%este método procura o valor de trânsito de potência com
                %%%%base no valor das perdas nos dois ramos
                losses_branch1 = obj.powerflow_result.apower_losses(1);
                losses_branch2 = obj.powerflow_result.apower_losses(2);
                delta_losses = obj.powerflow_result.apower_losses(1)-obj.powerflow_result.apower_losses(2);
                if prev_losses > sum(obj.powerflow_result.apower_losses) %%se perdas antes comp > perdas depois de comp 
                    compensation = compensation + direction*0.1*compensation;
                else
                    direction = -direction;
                    compensation = compensation + direction*0.1*compensation;
                end
                prev_losses = sum(obj.powerflow_result.apower_losses);
                compensation = max(min(compensation, 12.5), -12.5); %% saturação entre -1.5 e 1.5 MVA
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),3) = -compensation;
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),4) = 0;%-(reactive(-compensation));% (-compensation)^4*polyn(1) + (-compensation)^3*polyn(2) + (-compensation)^2*polyn(3) + (-compensation)*polyn(4) + polyn(5));
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),3) = compensation;
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),4) = 0;%-(reactive(compensation));%(compensation)^4*polyn(1) + (compensation)^3*polyn(2) + (compensation)^2*polyn(3) + (compensation)*polyn(4) + polyn(5));
    %             function bus = get_bus_no(global_model_mpc, bus_id)
    %                 bus = find(global_model_mpc.bus(:,1)==bus_id);
    %             end
                obj = obj.run_powerflow();
                obj = obj.process_output();
                losses = [losses sum(obj.powerflow_result.apower_losses)];
                
                %%% BREAK if reduction is lower than tol
            end
        end
        function obj = tps_power_optimization(obj)
            %%% This method performs the compensation NUMBER1: the TPS power is balanced.
            % The diference of power between TPS is calculated, and then,
            % the compensation power in the PTD is set to half the value.
            
            %FXN declaration
            reactive = @(apower) apower^4*2.368457120606040e-04 + apower^3*0.003644081427839 + apower^2*0.069676709709654 + apower^1*0.001647622855671 + 0.003024538598544;
            get_bus_no = @(global_model_mpc, bus_id) find(global_model_mpc.bus(:,1)==bus_id);
            
            % só "reinicia" modelo se potência diferente de 0
            if obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),3) == 0
            else
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),3) = 0;
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),4) = 0;
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),3) = 0;
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),4) = 0;
                obj = obj.run_powerflow();
                obj = obj.process_output();
            end
            % calcula diferença de potências
            tps1_power = real(obj.powerflow_result.tps_power(1));
            tps2_power = real(obj.powerflow_result.tps_power(2));
            compensation = (tps1_power - tps2_power)*0.5;
            compensation = max(min(compensation, 12.5), -12.5); %% saturação entre -1.5 e 1.5 MVA
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),3) = -compensation;
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),4) = 0;%-(reactive(-compensation));
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),3) = compensation;
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),4) = 0;%-(reactive(-compensation));
            obj = obj.run_powerflow();
            obj = obj.process_output();
        end
        function obj = nz_voltage_optimization(obj)
            %%% This method performs the compensation NUMBER3: the NZ voltage is balanced.
            % The phase angle difference between NZ is calculated, and then,
            % the compensation power in the PTD is set to half the value.
            
            %FXN declaration
            reactive = @(apower) apower^4*2.368457120606040e-04 + apower^3*0.003644081427839 + apower^2*0.069676709709654 + apower^1*0.001647622855671 + 0.003024538598544;
            get_bus_no = @(global_model_mpc, bus_id) find(global_model_mpc.bus(:,1)==bus_id);
            
            compensation_droop = @(delta_phase) delta_phase/(1.71536955859211);
            
            % só "reinicia" modelo se potência diferente de 0
            if obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),3) == 0
            else
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),3) = 0;
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),4) = 0;
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),3) = 0;
                obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),4) = 0;
                obj = obj.run_powerflow();
                obj = obj.process_output();
            end
            % calcula diferença de potências
%             tps1_power = real(obj.powerflow_result.tps_power(1));
%             tps2_power = real(obj.powerflow_result.tps_power(2));
%             compensation = (tps1_power - tps2_power)*0.5;
            nz_phase_diff = obj.last_matpower_result.bus(obj.tps(1).ptd.NZ_bus, 9)-obj.last_matpower_result.bus(obj.tps(2).ptd.NZ_bus, 9);
            compensation = -compensation_droop(nz_phase_diff);
            compensation = max(min(compensation, 12.5), -12.5); %% saturação entre -1.5 e 1.5 MVA
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),3) = -compensation;
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(1).ptd.PTD_bus(2)),4) = 0;%-(reactive(-compensation));
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),3) = compensation;
            obj.global_model_mpc.bus(get_bus_no(obj.global_model_mpc, obj.tps(2).ptd.PTD_bus(2)),4) = 0;%-(reactive(-compensation));
            obj = obj.run_powerflow();
            obj = obj.process_output();
        end
        function obj = setup_tps(obj)
            %%% This method configures all TPS. It configures the bus and branch matrices for matpower power flow solver. Then, it is created the tps stucture array.
            
            addpath('matpower7.0\');
            matpower_addpath;
            obj.mpopt = mpoption('model', 'AC', ... %[ 'AC' - use nonlinear AC model & corresponding algorithms/options  ]
                'pf.alg', 'NR', ...  %[ 'NR'    - Newton's method (formulation depends on values of pf.current_balance and pf.v_cartesian options)          ]
                'pf.tol', 1e-13, ... % termination tolerance on per unit P & Q mismatch
                'pf.nr.max_it', 1000, ... % maximum number of iterations for Newton's method
                'verbose', 0, 'out.all', 0);
            
            %%% setup MPC
            obj.global_model_mpc.version = '2';
            obj.global_model_mpc.baseMVA = obj.electric_parameters.pu.sbase; %%% em MVA
            obj.global_model_mpc.gen = [];
            obj.global_model_mpc.branch = [];
            obj.global_model_mpc.bus = [];
            
            obj.tps = [];
            for tps_no=1:obj.number_of_tps
                tps_to_add.number = tps_no;
                
                %%%generate random TPS branch lengths
                switch obj.random_status.tps_length{tps_no} 
                    case 'random'
                        length_cluster = gen_rand_tps_distance_cluster();
                        length = gen_rand_tps_length(length_cluster);
                        obj.tps_lenghts(tps_no,:) = length;
                    otherwise
                        length_cluster = obj.random_status.tps_length{tps_no};
                        length = [obj.random_status.tps_length_value{tps_no} obj.random_status.tps_length_value{tps_no}];
                        obj.tps_lenghts(tps_no,:) = length;
                end
                
                %%% generator data
                % bus  Pg  Qg  Qmax  Qmin Vg  mBase  status  Pmax  Pmin  Pc1  Pc2  Qc1min  Qc1max  Qc2min  Qc2max  ramp_agc  ramp_10  ramp_30  ramp_q  apf
                tps_to_add.gen = [(tps_no-1)*4+1  0.0000  0.0000  999  -999  1.0000  100  1   999  0  0  0  0  0  0  0  0  0  0  0  0];
                % % bus_i  type  Pd  Qd  Gs  Bs  area  Vm  Va  baseKV  zone  Vmax  Vmin
                tps_to_add.bus = [
                    (tps_no-1)*4+1  3  0.0000  0.0000  0.0000  0.0000  tps_no  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35
                    (tps_no-1)*4+2  1  0.0000  0.0000  0.0000  0.0000  tps_no  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35
                    (tps_no-1)*4+3  1  0.0000  0.0000  0.0000  0.0000  tps_no  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35
                    (tps_no-1)*4+4  1  0.0000  0.0000  0.0000  0.0000  tps_no  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35];
                % fbus  tbus  r  x  b  rateA  rateB  rateC  ratio  angle  status  angmin  angmax
                lenght_of_tps = obj.tps_lenghts(tps_no,:);
                tps_to_add.branch = [
                    (tps_no-1)*4+1   (tps_no-1)*4+2  real(obj.tps_transformer_impedance)  imag(obj.tps_transformer_impedance)  imag(obj.tps_transformer_susceptance)  999  999  999  0     0  1  -360*2  360*2
                    (tps_no-1)*4+2   (tps_no-1)*4+3  lenght_of_tps(1).* ([real(obj.tps_catenary_impedance)  imag(obj.tps_catenary_impedance)  imag(obj.tps_catenary_susceptance)])  999  999  999  0     0  1  -360*2  360*2
                    (tps_no-1)*4+2   (tps_no-1)*4+4  lenght_of_tps(2).* ([real(obj.tps_catenary_impedance)  imag(obj.tps_catenary_impedance)  imag(obj.tps_catenary_susceptance)])  999  999  999  0     0  1  -360*2  360*2 ];
                
                %%%fill the global electric model
                obj.global_model_mpc.gen = [obj.global_model_mpc.gen; tps_to_add.gen];
                obj.global_model_mpc.branch = [obj.global_model_mpc.branch; tps_to_add.branch];
                obj.global_model_mpc.bus = [obj.global_model_mpc.bus; tps_to_add.bus];
                
                %%%%%
                tps_to_add_2.number = tps_no;
                tps_to_add_2.gen_index = tps_no;%size(obj.global_model_mpc.gen,1)-2:size(obj.global_model_mpc.gen,1);
                tps_to_add_2.length_cluster = length_cluster;
                tps_to_add_2.length = length;
                tps_to_add_2.bus_index = size(obj.global_model_mpc.bus,1)-3:size(obj.global_model_mpc.bus,1);
                tps_to_add_2.branch_index = size(obj.global_model_mpc.branch,1)-2:size(obj.global_model_mpc.branch,1);
                tps_to_add_2.trains = [];%struct('id', [], 'dir', [], 'section', [],  'abs_position', [], 'apower', [], 'rpower', []);
                obj.tps = [obj.tps tps_to_add_2]; 
            end
            function tps_type = gen_rand_tps_distance_cluster()
                tps_type_val = round(random(makedist('Uniform','lower',0,'upper',1),1,1));
                switch tps_type_val
                    case 0
                        tps_type = 'short';
                    case 1
                        tps_type = 'long';
                end
            end
            function length = gen_rand_tps_length(type_of_tps_length)
                %small_distances = random(makedist('Normal', 'mu', 15, 'sigma', 2), 1e4, 1);
                %large_distances = random(makedist('Normal', 'mu', 21, 'sigma', 2), 1e4, 1);
                switch type_of_tps_length
                    case 'short'
                        length = random(makedist('Normal', 'mu', 15, 'sigma', 2), 2, 1);
                        while length < 0 , length = random(makedist('Normal', 'mu', 15, 'sigma', 2), 2, 1); end
                    case 'long'
                        length = random(makedist('Normal', 'mu', 21, 'sigma', 2), 2, 1);
                        while length < 0 , random(makedist('Normal', 'mu', 21, 'sigma', 2), 2, 1); end
                end
            end
        end  
        function obj = add_trains(obj, tps_no, side, direction, trains)
            %%% This method uses the list of trains to be added to a branch, and adds them to the matrices. 
            % The received train relative positions (between 0 and 1) are
            % converted to absolute positions (with the multiplication by
            % the tps lenght). It is ensured that the branch between the
            % last train and the neutral zone is propperly modelled.
            % Furthermore, is created an array of trains in the
            % respective TPS property of this simulation framework. The
            % code in this method is repeated for all the 4 scenarios
            % (asc and desc, left and right). 
            
            obj.tps(tps_no).tps_cluster = trains.tps_cluster;
            if isempty(trains.id) %%% se vector vazio, não há nada para adicionar
            else
                switch direction
                    case 'asc'
                        if obj.debug == 1, fprintf("adding trains in asc\n"); end
                        switch side
                            case 'left'
                                %%% add trains to the list of trains in
                                if ~isfield(obj.tps(tps_no), 'trains_left')
                                    obj = add_trains_asc_left(obj, tps_no, trains);
                                elseif isempty(obj.tps(tps_no).trains_left)
                                    obj = add_trains_asc_left(obj, tps_no, trains);
                                else
                                    %                         obj.tps(tps_no).trains_left = cat_trains(obj.tps(tps_no).trains_left, trains);
                                    %                         %%% TODO: acrescentar novos comboios
                                end

                            case 'right'
                                %%% add trains to the list of trains in
                                if ~isfield(obj.tps(tps_no), 'trains_right')
                                    obj = add_trains_asc_right(obj, tps_no, trains);
                                elseif isempty(obj.tps(tps_no).trains_right)
                                    obj = add_trains_asc_right(obj, tps_no, trains);
                                else
                                    %                         obj.tps(tps_no).trains_right = cat_trains(obj.tps(tps_no).trains_right, trains);
                                    %                         %%% TODO: acrescentar novos comboios
                                end

                            otherwise
                                fprintf("shit hit the fan!\n");
                        end
                    case 'desc'
                        fprintf("descendent trains: to be defined\n");
                    otherwise
                        fprintf("shit hit the fan!\n");
                end
            end
            
            %%%method "add_trains" aux functions
            function obj = add_trains_asc_left(obj, tps_no, trains)
                trains.abs_position = trains.position.*obj.tps_lenghts(tps_no,1);
                obj.tps(tps_no).trains_left = trains;
%               obj.tps(tps_no).tps_cluster = trains.tps_cluster;
                %%% get distances vector
                prev_bus = size(obj.global_model_mpc.bus,1);
                prev_branch = size(obj.global_model_mpc.branch,1);
                prev_length = obj.tps_lenghts(tps_no,1);
                distances = [trains.abs_position prev_length];
                distances = fliplr(distances);
                catenary_length = distances;
                for branch=1:size(catenary_length,2)-1
                    catenary_length(branch) = distances(branch)-distances(branch+1);
                end
                catenary_length = fliplr(catenary_length);
                
                catenary_length = max(catenary_length, 0.01);
                %%% add new buses and branches
                for train_it = 1: size(trains.id, 2)
                    %%%fill the global electric model
                    % % bus_i  type  Pd  Qd  Gs  Bs  area  Vm  Va  baseKV  zone  Vmax  Vmin
                    bus_to_add= [prev_bus+train_it  1  trains.apower(train_it)  trains.rpower(train_it)  0.0000  0.0000  tps_no  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35 ];
                    % fbus  tbus  r  x  b  rateA  rateB  rateC  ratio  angle  status  angmin  angmax
                    branch_to_add = [prev_bus+train_it-1    prev_bus+train_it  catenary_length(train_it).* ([real(obj.tps_catenary_impedance)  imag(obj.tps_catenary_impedance)  imag(obj.tps_catenary_susceptance)])  999  999  999  0     0  1  -360*2  360*2 ];
                    obj.global_model_mpc.branch = [obj.global_model_mpc.branch; branch_to_add];
                    obj.global_model_mpc.bus = [obj.global_model_mpc.bus; bus_to_add];
                    %%%update tps_data structure
                    obj.tps(tps_no).bus_index = [obj.tps(tps_no).bus_index size(obj.global_model_mpc.bus,1)];
                    obj.tps(tps_no).branch_index = [obj.tps(tps_no).branch_index size(obj.global_model_mpc.branch,1)];
                    trains_to_add = struct('id', trains.id(train_it), ...
                        'dir', 'asc', ...
                        'section', 'left_section', ...
                        'position', trains.position(train_it), ...
                        'abs_position', trains.abs_position(train_it), ...
                        'apower', trains.apower(train_it), ...
                        'rpower', trains.rpower(train_it),...
                        'bus_no', size(obj.global_model_mpc.bus,1),...
                        'branch_left', size(obj.global_model_mpc.branch,1),...
                        'branch_right', size(obj.global_model_mpc.branch,1)+1);
                    obj.tps(tps_no).trains = [obj.tps(tps_no).trains trains_to_add];
                end
                %%% fix first branch
                obj.global_model_mpc.branch(prev_branch+1,1) = (tps_no-1)*4+2;
                %%% fix old branch %2-3 --> 11-3%
                obj.global_model_mpc.branch((tps_no-1)*3+2,1) = prev_bus+train_it;
                obj.global_model_mpc.branch((tps_no-1)*3+2,3:5) = catenary_length(end).* ([real(obj.tps_catenary_impedance)  imag(obj.tps_catenary_impedance)  imag(obj.tps_catenary_susceptance)]);
                obj.tps(tps_no).trains(end).branch_right = (tps_no-1)*3+2;
            end
            function obj = add_trains_asc_right(obj, tps_no, trains)
                trains.abs_position = trains.position.*obj.tps_lenghts(tps_no,2);
                obj.tps(tps_no).trains_right = trains;
                %obj.tps(tps_no).tps_cluster = trains.tps_cluster;
                %%% fix old branch
                prev_bus = size(obj.global_model_mpc.bus,1);
                prev_branch = size(obj.global_model_mpc.branch,1);
                prev_length = obj.tps_lenghts(tps_no,2);
                distances = [trains.abs_position prev_length];
                distances = fliplr(distances);
                catenary_length = distances;
                for branch=1:size(catenary_length,2)-1
                    catenary_length(branch) = distances(branch)-distances(branch+1);
                end
                catenary_length = fliplr(catenary_length);
                
                catenary_length = max(catenary_length, 0.01);
                %%% add new buses and branches
                for train_it = 1: size(trains.id, 2)
                    %%%fill the global electric model
                    % % bus_i  type  Pd  Qd  Gs  Bs  area  Vm  Va  baseKV  zone  Vmax  Vmin
                    bus_to_add= [prev_bus+train_it  1  trains.apower(train_it)  trains.rpower(train_it)  0.0000  0.0000  tps_no  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35 ];
                    % fbus  tbus  r  x  b  rateA  rateB  rateC  ratio  angle  status  angmin  angmax
                    branch_to_add = [prev_bus+train_it-1    prev_bus+train_it  catenary_length(train_it).* ([real(obj.tps_catenary_impedance)  imag(obj.tps_catenary_impedance)  imag(obj.tps_catenary_susceptance)])  999  999  999  0     0  1  -360*2  360*2 ];
                    obj.global_model_mpc.branch = [obj.global_model_mpc.branch; branch_to_add];
                    obj.global_model_mpc.bus = [obj.global_model_mpc.bus; bus_to_add];
                    %%%update tps_data structure
                    obj.tps(tps_no).bus_index = [obj.tps(tps_no).bus_index size(obj.global_model_mpc.bus,1)];
                    obj.tps(tps_no).branch_index = [obj.tps(tps_no).branch_index size(obj.global_model_mpc.branch,1)];
                    trains_to_add = struct('id', trains.id(train_it), ...
                        'dir', 'asc', ...
                        'section', 'right_section', ...
                        'position', trains.position(train_it), ...
                        'abs_position', trains.abs_position(train_it), ...
                        'apower', trains.apower(train_it), ...
                        'rpower', trains.rpower(train_it),...
                        'bus_no', size(obj.global_model_mpc.bus,1),...
                        'branch_left', size(obj.global_model_mpc.branch,1),...
                        'branch_right', size(obj.global_model_mpc.branch,1)+1);
                    obj.tps(tps_no).trains = [obj.tps(tps_no).trains trains_to_add];
                end
                %%% fix first branch
                obj.global_model_mpc.branch(prev_branch+1,1) = (tps_no-1)*4+2;
                %%% fix old branch %2-3 --> 11-3%
                obj.global_model_mpc.branch((tps_no-1)*3+3,1) = prev_bus+train_it;
                obj.global_model_mpc.branch((tps_no-1)*3+3,3:5) = catenary_length(end).* ([real(obj.tps_catenary_impedance)  imag(obj.tps_catenary_impedance)  imag(obj.tps_catenary_susceptance)]);
                obj.tps(tps_no).trains(end).branch_right = (tps_no-1)*3+3;
            end
            function trains = cat_trains(trains_array, trains)
                %%%to be defined: if branch already populated, then intest
                %%%new array of trains... this strategy was abandoned
                trains_array.id = [trains_array.id trains.id];
                trains_array.position = [trains_array.position trains.position];
                trains_array.apower = [trains_array.apower trains.apower];
                trains_array.rpower = [trains_array.rpower trains.rpower];
            end
        end
        function obj = attach_power_transfer_device(obj)%, tps_info1, tps_info2)
            %%% This method attaches a power transfer device between two sections of the neutral zone.
            %%% tps1_info and tps2_info follows:
            %%% info.tps_number: which tps is this device attached
            %%% info.dir: which sub-line --> asc or desc
            %%% info.section: which side of TPS --> left or right
            %%% info.NZ_bus: what bus will this device be connected
            %%%%% the first new created bus of PTD is 100
            tps_info1.tps_number = 1;
            tps_info1.dir = 'asc';
            tps_info1.section = 'right';
            tps_info1.NZ_bus = 4;
            tps_info1.PTD_bus = [100 101];
            tps_info1.PTD_branch = [size(obj.global_model_mpc.branch, 1) size(obj.global_model_mpc.branch, 1)+1];
            tps_info1.transf_impedance = obj.electric_parameters.ptd.transformer_impedance; %(12.5e6*0.004)/((12.5e6/25e3)^2) + 1i*2*(12.5e6*0.004)/((12.5e6/25e3)^2);
            tps_info1.transf_iron_loss =  obj.electric_parameters.ptd.permanent_losses;%(12.5e6*0.001);
            tps_info1.converter_impedance =  obj.electric_parameters.ptd.inverter_impedance;%(0.7*12.5e6*0.01)/((12.5e6/25e3)^2) + 1i*0;
            tps_info1.converter_constant_loss = 0; %TODO %obj.electric_parameters.ptd.permanent_losses; %0.3*12.5e6*0.01;
            tps_info2.tps_number = 2;
            tps_info2.dir = 'asc';
            tps_info2.section = 'left';
            tps_info2.NZ_bus = 7;
            tps_info2.PTD_bus = [102 103];
            tps_info2.PTD_branch = [size(obj.global_model_mpc.branch, 1)+2 size(obj.global_model_mpc.branch, 1)+3];
            tps_info2.transf_impedance = obj.electric_parameters.ptd.transformer_impedance; %(12.5e6*0.004)/((12.5e6/25e3)^2) + 1i*2*(12.5e6*0.004)/((12.5e6/25e3)^2);
            tps_info2.transf_iron_loss =  obj.electric_parameters.ptd.permanent_losses;%(12.5e6*0.001);
            tps_info2.converter_impedance =  obj.electric_parameters.ptd.inverter_impedance;%(0.7*12.5e6*0.01)/((12.5e6/25e3)^2) + 1i*0;
            tps_info2.converter_constant_loss = 0; %TODO %obj.electric_parameters.ptd.permanent_losses; %0.3*12.5e6*0.01;
            %%%%TODO cada tps pode ter mais de um PTD a ser injectado numa
            %%%%determinada zona neutra?
            if ~isfield(obj.tps(1), 'ptd')
                obj.tps(1).ptd = tps_info1;
            else
                obj.tps(1).ptd = [obj.tps(1).ptd tps_info1];
            end
            if ~isfield(obj.tps(2), 'ptd')
                obj.tps(2).ptd = tps_info2;
            else
                obj.tps(2).ptd = [obj.tps(2).ptd tps_info2];
            end
            %%%adiciona BUS
            % % bus_i  type  Pd  Qd  Gs  Bs  area  Vm  Va  baseKV  zone  Vmax  Vmin
            obj.global_model_mpc.bus = [obj.global_model_mpc.bus
                tps_info1.PTD_bus(1) 1 (tps_info1.transf_iron_loss+tps_info1.converter_constant_loss)  0  0.0000  0.0000  1  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35
                tps_info1.PTD_bus(2) 1 0  0  0.0000  0.0000  1  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35
                tps_info2.PTD_bus(1) 1 (tps_info2.transf_iron_loss+tps_info2.converter_constant_loss)  0  0.0000  0.0000  2  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35
                tps_info2.PTD_bus(2) 1 0  0  0.0000  0.0000  2  1  0  obj.electric_parameters.nominal_voltage  1  1.35  0.35];
            
            Sbase = obj.electric_parameters.pu.sbase; 
            Vbase = obj.electric_parameters.pu.vbase; 
            Ibase = obj.electric_parameters.pu.ibase; 
            Zbase = obj.electric_parameters.pu.zbase;
            %%%adiciona BRANCH
            % fbus  tbus  r  x  b  rateA  rateB  rateC  ratio  angle  status  angmin  angmax
            obj.global_model_mpc.branch = [obj.global_model_mpc.branch
                tps_info1.NZ_bus        tps_info1.PTD_bus(1) real(tps_info1.transf_impedance)/Zbase    imag(tps_info1.transf_impedance)/Zbase  0  999  999  999  0     0  1  -360*2  360*2
                tps_info1.PTD_bus(1)    tps_info1.PTD_bus(2) real(tps_info1.converter_impedance)/Zbase imag(tps_info1.converter_impedance)/Zbase 0  999  999  999  0     0  1  -360*2  360*2
                tps_info2.NZ_bus        tps_info2.PTD_bus(1) real(tps_info2.transf_impedance)/Zbase    imag(tps_info2.transf_impedance)/Zbase  0  999  999  999  0     0  1  -360*2  360*2
                tps_info2.PTD_bus(1)    tps_info2.PTD_bus(2) real(tps_info2.converter_impedance)/Zbase imag(tps_info2.converter_impedance)/Zbase 0  999  999  999  0     0  1  -360*2  360*2];
        end
        function obj = run_powerflow(obj)
            %%% This method executes the matpower power flow solver
            addpath('matpower7.0\');
            matpower_addpath;
            obj.last_matpower_result = runpf(obj.global_model_mpc, obj.mpopt);
            if isempty(obj.init_matpower_result)
                obj.init_matpower_result = obj.last_matpower_result;
            end
        end
        function obj = process_output(obj)
            %%% This method generate knowledge from the power flow result, regarding the tps power, catenary voltage and other relevant metrics. 
            % All the data are saved in the "powerflow_result" property of
            % this simulation framework.
            obj.powerflow_result.tps_power = complex(obj.last_matpower_result.gen(:, 2), obj.last_matpower_result.gen(:, 3));
            obj.powerflow_result.min_voltage = [];
            obj.powerflow_result.apower_losses = [];
            obj.powerflow_result.rpower_losses = [];
            obj.powerflow_result.power_losses = [];
            obj.powerflow_result.transferred_power = [];
            %%% extras
%             obj.powerflow_result.avg_position = [ ... %%%[mean(pos_tps1) mean(pos_tps2)] %%warning: abs_position vector has all trains of tps
%                 mean([obj.tps(1).trains.abs_position])  mean([obj.tps(2).trains.abs_position])];    
%             
%             a_t = [obj.tps(1).trains.apower] - min([obj.tps(1).trains.apower]);
%             b_t = [obj.tps(2).trains.apower] - min([obj.tps(2).trains.apower]);
%             
%             lambda1 = a_t / sum(a_t);
%             lambda2 = b_t / sum(b_t);
%             
%             obj.powerflow_result.avg_weighed_position = [ ... %%%[mean(pos_tps1) mean(pos_tps2)] %%warning: abs_position vector has all trains of tps
%                 sum([obj.tps(1).trains.abs_position].*lambda1)  ...
%                 sum([obj.tps(2).trains.abs_position].*lambda2)]; 
            obj.powerflow_result.delta_power = [ ... %%%[(pwr_tps1-pwr_tps2) (pwr_tps2 - pwr_tps1)]
                obj.powerflow_result.tps_power(1)-obj.powerflow_result.tps_power(2) ...
                obj.powerflow_result.tps_power(2)-obj.powerflow_result.tps_power(1)];
            areas = unique(obj.last_matpower_result.bus(:, 7));
            for area = 1:size(areas,1)
                obj.powerflow_result.min_voltage = [obj.powerflow_result.min_voltage;  min(obj.last_matpower_result.bus(obj.last_matpower_result.bus(:,7)==areas(area),8))];
                bus_area = obj.last_matpower_result.bus(obj.last_matpower_result.bus(:,7)==areas(area),1);
                branch_matrix_area = [];
                for elem = 1:size(bus_area)
                    branch_matrix_area = [branch_matrix_area;  obj.last_matpower_result.branch(obj.last_matpower_result.branch(:,1) == bus_area(elem),:)];
                end
                if ~isfield(obj.tps(area), 'ptd')
                    constant_alosses = 0;
                else
                    constant_alosses = (obj.tps(area).ptd.transf_iron_loss + obj.tps(area).ptd.converter_constant_loss);
                    obj.powerflow_result.transferred_power = [obj.powerflow_result.transferred_power;   obj.last_matpower_result.bus(find(obj.last_matpower_result.bus(:,1)==obj.tps(area).ptd.PTD_bus(2)),3)];
                end
                obj.powerflow_result.apower_losses = [obj.powerflow_result.apower_losses; sum((branch_matrix_area(:,14)+branch_matrix_area(:,16)))+constant_alosses];
                obj.powerflow_result.rpower_losses = [obj.powerflow_result.rpower_losses; sum((branch_matrix_area(:,15)+branch_matrix_area(:,17)))];
                obj.powerflow_result.power_losses = [obj.powerflow_result.power_losses; complex(obj.powerflow_result.apower_losses, obj.powerflow_result.rpower_losses)];
            end
            if isempty(obj.init_powerflow_result)
                obj.init_powerflow_result = obj.powerflow_result;
            end
        end
        function obj = setup_electric_parameters(obj)
            %%% This method is the first method called in this simulation framework. Is responsible to define the number of TPS, the characteristics of the catenary. 
            % The relevant information is placed in the properties of the class
            
            obj.number_of_tps = 2;
            obj.tps_lenghts =...
                [20 20
                20 20];
            %%%%%%%%%%%%%  PARAMETERS FROM AJM %%%%%%%%%%
%             Rt = 0.055;      % 55 mohm/km
%             Lt = 0.22e-3;    % 0.22mH
%             Ct = 1e-6;        % 1uF ???????????????????
%             dt = 0.5;        % distância 0.5 km
            Rt = obj.electric_parameters.cable.resistance;      % 55 mohm/km
            Lt = obj.electric_parameters.cable.reactance;    % 0.22mH
            Ct = obj.electric_parameters.cable.capacitance;        % 1uF ???????????????????
            dt = obj.electric_parameters.cable.distance;        % distância 0.5 km
%             %catenária
%             Rc = 0.15;      % ohms/km
%             Lc = 1.43e-3;   % 1,43 mH/km
%             Cc = 12.4e-9;   % 12,4 nF/km
            Rc = obj.electric_parameters.catenary.resistance;
            Lc = obj.electric_parameters.catenary.reactance;
            Cc = obj.electric_parameters.catenary.capacitance;
            %max secção A = 20km
            %max secção B = 15km
            
            %%%% SETUP PROBLEM DEFINITION
%             Sbase = 1e9;%500e6;
%             Vbase = 25e3;
%             Ibase = Sbase/Vbase;
%             Zbase = Vbase/Ibase;
            Sbase = obj.electric_parameters.pu.sbase;
            Vbase = obj.electric_parameters.pu.vbase;
            Ibase = obj.electric_parameters.pu.ibase;
            Zbase = obj.electric_parameters.pu.zbase;
            
            %%%%%%%%%% SETUP Tranformer and Catenary parameters
            obj.tps_transformer_impedance = dt*(Rt+1i*2*50*pi*Lt)/Zbase;
            obj.tps_transformer_susceptance = dt*(1i*2*50*pi*Ct)/Zbase;
            obj.tps_catenary_impedance = (Rc + 1i*Lc*(2*pi*50))/Zbase; %ohm/km;
            obj.tps_catenary_susceptance = ((1i*2*pi*50)*Cc)/Zbase;  %"ohm"/km;
        end
        function obj = plot_electric_diagram(obj)
            %%% This method uses the plot_electric class to automatically generate an graphical electric diagram.
            % 1. It starts to generate the information of the buses of
            %     each TPS. (now is plotted for single-track line)
            % 2. It places the information of each train ID, power
            %     and position in the respective bus. 
            % 3. It places the details of the power transfer device
            obj.plot_electric_ = plot_electric;
            obj.plot_electric_ = obj.plot_electric_.attach_electric_model(obj.tps, obj.global_model_mpc, obj.tps_lenghts);
            obj.plot_electric_ = obj.plot_electric_.plot_electric_data();
        end
    end
end