classdef electric_model
    %ELECTRIC_MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
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
        plot_electric_
        sim_input_data
        %parfor_mon
        debug
    end
    
    methods
        function obj = electric_model()
            %ELECTRIC_MODEL Construct an instance of this class
            %obj = obj.setup_electric_parameters();
            %obj = obj.setup_tps();
        end
        
        function obj = reset_model(obj)
            obj.tps = [];
            obj.global_model_mpc = [];
            obj = obj.setup_electric_parameters();
            obj = obj.setup_tps();
            %obj = obj.setup_trains();
        end
        
        function obj = test_case(obj, varargin) %% recebe parâmetros a pares: test_case('left', trains_left, 'right', trains_right)
            obj = obj.reset_model();
            %             switch nargin
            %                 case 1
            %                 trains_left_1.id = 1:3;
            %                 trains_left_1.position = random(makedist('Uniform','lower',0,'upper',1),3,1); trains_left_1.position = sortrows(trains_left_1.position, 1, 'asc')';
            %                 trains_left_1.apower = random(makedist('Uniform','lower',-0.2,'upper',2),3,1)';
            %                 trains_left_1.rpower = trains_left_1.apower.*tan(acos(random(makedist('Uniform','lower',0.9,'upper',1),3,1)'));
            %                 case 3
            %                     if strcmp(varargin(1), 'left')
            %                         trains_left_1 = varargin(2);
            %                     elseif strcmp(varargin(1), 'right')
            %                     end
            %                 case 5
            %                 otherwise
            %                     fprintf("\nwrong input\nplease use: electric_model.test_case('left', trains_left, 'right', trains_right)'\n");
            %             end
            trains_left_1.id = 1;
            trains_left_1.position = 0.01;
            trains_left_1.apower = 1;
            trains_left_1.rpower = 0;
            obj = obj.add_trains(1, 'left', 'asc', trains_left_1);
            obj.global_model_mpc.bus(3,3) = -0;
            obj.global_model_mpc.bus(7,3) = 0;
            obj = obj.run_powerflow();
            obj = obj.process_output();
        end
        function obj = test_statistics(obj)
            
            pos11 = []; pos12 = []; pos13 = []; pos14 = []; pos15 = [];
            pos21 = []; pos22 = []; pos23 = []; pos24 = []; pos25 = [];
            apower11 = []; apower12 = []; apower13 = []; apower14 = []; apower15 = [];
            apower21 = []; apower22 = []; apower23 = []; apower24 = []; apower25 = [];
            rpower11 = []; rpower12 = []; rpower13 = []; rpower14 = []; rpower15 = [];
            rpower21 = []; rpower22 = []; rpower23 = []; rpower24 = []; rpower25 = [];
            pf11 = []; pf12 = []; pf13 = []; pf14 = []; pf15 = [];
            pf21 = []; pf22 = []; pf23 = []; pf24 = []; pf25 = [];
            sum_apower1 = []; sum_apower2 = [];
            sum_rpower1 = []; sum_rpower2 = [];
            tic;
            for iter = 1:1e4
                %%% No comboios é rand
                train_no_left = 1;
                train_no_right = 1;
                
                %%% cria vector de identificadores
                trains_right_1.id = 1:train_no_right;
                trains_left_2.id = 1:train_no_left;
                trains_left_2.id = trains_left_2.id+train_no_left;%%% identificadores diferentes de anterior
                
                %%%posição dos comboios é random
                while 1
                    trains_right_1.position = random(makedist('Uniform','lower',0,'upper',1),train_no_right,1);
                    trains_right_1.position = sortrows(trains_right_1.position, 1, 'asc')';
                    trains_left_2.position = random(makedist('Uniform','lower',0,'upper',1),train_no_left,1);
                    trains_left_2.position = sortrows(trains_left_2.position, 1, 'asc')';
                    %%%posição: validação de distância mínima
                    if train_no_left > 1 && train_no_right > 1
                        min_distance = 0.75; %%750m
                        if (min(trains_right_1.position(2:end) - trains_right_1.position(1:end-1)))*obj.tps_lenghts(1,1) > min_distance && (min(trains_left_2.position(2:end) - trains_left_2.position(1:end-1)))*obj.tps_lenghts(1,1) > min_distance
                            break;
                        end
                    elseif train_no_left == 1 && train_no_right > 1
                        min_distance = 0.75; %%750m
                        if (min(trains_right_1.position(2:end) - trains_right_1.position(1:end-1)))*obj.tps_lenghts(1,1) > min_distance
                            break;
                        end
                    elseif train_no_right == 1 && train_no_left > 1
                        min_distance = 0.75; %%750m
                        if (min(trains_left_2.position(2:end) - trains_left_2.position(1:end-1)))*obj.tps_lenghts(1,1) > min_distance
                            break;
                        end
                    else
                        break;
                    end
                end
                
                %%%potências aparentes de comboios é random (max=10MVA @ 0.8ind)
                %%%RIGHT
%                 max_tps1_power = 15e6;
%                 tps_total_power1 = random(makedist('Lognormal', log(15e6), 1), 1, 1);
%                 while (tps_total_power1 > max_tps1_power) , tps_total_power1 = random(makedist('Lognormal', 14.5, 1), 1, 1); end
%                 delta_tps_total_power = max_tps1_power;
%                 %generate N active power values, where sum(P) = TPS_power which follows distribution
%                 for pwr_iter = 1:100
%                     loop_train_power = random(makedist('Uniform','lower',-0.2e6,'upper',8e6),train_no_right,1);
%                     if sum(loop_train_power) > tps_total_power1*0.9 && sum(loop_train_power) < tps_total_power1*1.1
%                         trains_right_1.apower = 1e-6.*loop_train_power.*(tps_total_power1/sum(loop_train_power));
%                         break;
%                     end
%                     if delta_tps_total_power > abs(sum(loop_train_power) - tps_total_power1)
%                         delta_tps_total_power = abs(sum(loop_train_power) - tps_total_power1);
%                         trains_right_1.apower = 1e-6.*loop_train_power.*(tps_total_power1/sum(loop_train_power));
%                     end
%                 end
%                 %generate reactive power values based on train active power
%                 trains_right_1.pf =  trains_right_1.id.*0+1;
%                 trains_right_1.rpower = trains_right_1.id.*0+1;
%                 for train_id = 1:size(trains_right_1.id,2)
%                     while 1
%                         lambda = (0.4/7)*trains_right_1.apower(train_id) + (0.35-0.4/7);
%                         trains_right_1.pf(train_id) = 1.1-random(makedist('Lognormal', 1, lambda),1,1).*0.05;
%                         if trains_right_1.pf(train_id) >0.5 && trains_right_1.pf(train_id) <= 1 && ...
%                                 sqrt(trains_right_1.apower(train_id)^2+(trains_right_1.apower(train_id)*tan(acos(trains_right_1.pf(train_id))))^2) < 10
%                             trains_right_1.rpower(train_id) = trains_right_1.apower(train_id).*tan(acos(trains_right_1.pf(train_id)));
%                             break;
%                         end
%                     end
%                 end
%                 %%%LEFT
%                 max_tps2_power = 15e6;
%                 tps_total_power2 = random(makedist('Lognormal', log(15e6), 1), 1, 1);
%                 while (tps_total_power2 > max_tps2_power) , tps_total_power2 = random(makedist('Lognormal', 14.5, 1), 1, 1); end
%                 delta_tps_total_power = max_tps2_power;
%                 %generate N active power values, where sum(P) = TPS_power which follows distribution
%                 for pwr_iter = 1:100
%                     loop_train_power = random(makedist('Uniform','lower',-0.2e6,'upper',8e6),train_no_left,1);
%                     if sum(loop_train_power) > tps_total_power2*0.9 && sum(loop_train_power) < tps_total_power2*1.1
%                         trains_left_2.apower = 1e-6.*loop_train_power.*(tps_total_power2/sum(loop_train_power));
%                         break;
%                     end
%                     if delta_tps_total_power > abs(sum(loop_train_power) - tps_total_power2)
%                         delta_tps_total_power = abs(sum(loop_train_power) - tps_total_power2);
%                         trains_left_2.apower = 1e-6.*loop_train_power.*(tps_total_power2/sum(loop_train_power));
%                     end
%                 end
%                 %generate reactive power values based on train active power
%                 trains_left_2.pf =  trains_left_2.id.*0+1;
%                 trains_left_2.rpower = trains_left_2.id.*0+1;
%                 for train_id = 1:size(trains_left_2.id,2)
%                     while 1
%                         lambda = (0.4/7)*trains_left_2.apower(train_id) + (0.35-0.4/7);
%                         trains_left_2.pf(train_id) = 1.1-random(makedist('Lognormal', 1, lambda),1,1).*0.05;
%                         if trains_left_2.pf(train_id) >0.5 && trains_left_2.pf(train_id) <= 1 && ...
%                                 sqrt(trains_left_2.apower(train_id)^2+(trains_left_2.apower(train_id)*tan(acos(trains_left_2.pf(train_id))))^2) < 10
%                             trains_left_2.rpower(train_id) = trains_left_2.apower(train_id).*tan(acos(trains_left_2.pf(train_id)));
%                             break;
%                         end
%                     end
%                 end
                
                %%%%%%%%%
                %var1 = [var1 trains_right_1.position(3)];
                
                pos11 = [pos11 trains_right_1.position(1)]; %pos12 = [pos12 trains_right_1.position(2)]; pos13 = [pos13 trains_right_1.position(3)]; pos14 = [pos14 trains_right_1.position(4)]; pos15 = [pos15 trains_right_1.position(5)];
                pos21 = [pos21 trains_left_2.position(1)]; %pos22 = [pos22 trains_left_2.position(2)]; pos23 = [pos23 trains_left_2.position(3)]; pos24 = [pos24 trains_left_2.position(4)]; pos25 = [pos25 trains_left_2.position(5)];
                
%                 apower11 = [apower11 trains_right_1.apower(1)]; %apower12 = [apower12 trains_right_1.apower(2)]; apower13 = [apower13 trains_right_1.apower(3)]; apower14 = [apower14 trains_right_1.apower(4)]; apower15 = [apower15 trains_right_1.apower(5)];
%                 apower21 = [apower21 trains_left_2.apower(1)]; %apower22 = [apower22 trains_left_2.apower(2)]; apower23 = [apower23 trains_left_2.apower(3)]; apower24 = [apower24 trains_left_2.apower(4)]; apower25 = [apower25 trains_left_2.apower(5)];
%                 
%                 rpower11 = [rpower11 trains_right_1.rpower(1)]; %rpower12 = [rpower12 trains_right_1.rpower(2)]; rpower13 = [rpower13 trains_right_1.rpower(3)]; rpower14 = [rpower14 trains_right_1.rpower(4)]; rpower15 = [rpower15 trains_right_1.rpower(5)];
%                 rpower21 = [rpower21 trains_left_2.rpower(1)]; %rpower22 = [rpower22 trains_left_2.rpower(2)]; rpower23 = [rpower23 trains_left_2.rpower(3)]; rpower24 = [rpower24 trains_left_2.rpower(4)]; rpower25 = [rpower25 trains_left_2.rpower(5)];
%                 
%                 pf11 = [pf11 trains_right_1.pf(5)]; %pf12 = [pf12 trains_right_1.pf(2)]; pf13 = [pf13 trains_right_1.pf(3)]; pf14 = [pf14 trains_right_1.pf(4)]; pf15 = [pf15 trains_right_1.pf(5)];
%                 pf21 = [pf21 trains_left_2.pf(1)]; %pf22 = [pf22 trains_left_2.pf(2)]; pf23 = [pf23 trains_left_2.pf(3)]; pf24 = [pf24 trains_left_2.pf(4)]; pf25 = [pf25 trains_left_2.pf(5)];
                
                %sum_apower1 = [sum_apower1 sum(trains_right_1.apower)]; sum_apower2 = [sum_apower2 sum(trains_left_2.apower)];
                %sum_rpower1 = [sum_rpower2 sum(trains_right_1.rpower)]; sum_rpower2 = [sum_rpower2 sum(trains_left_2.rpower)];
                %%%%%%%%%
            end
            toc;
            %%%%%%%histograms
            %position
            figure; subplot(5,1,1); histogram(pos11, 1e3); subplot(5,1,2); histogram(pos12, 1e3); subplot(5,1,3); histogram(pos13, 1e3); subplot(5,1,4); histogram(pos14, 1e3); subplot(5,1,5); histogram(pos15, 1e3);
            figure; subplot(5,1,1); histogram(pos21, 1e3); subplot(5,1,2); histogram(pos22, 1e3); subplot(5,1,3); histogram(pos23, 1e3); subplot(5,1,4); histogram(pos24, 1e3); subplot(5,1,5); histogram(pos25, 1e3);
            % scatter apparent power vs pf
            figure; scatter([sqrt(apower21.^2+rpower21.^2) sqrt(apower22.^2+rpower22.^2) sqrt(apower23.^2+rpower23.^2) sqrt(apower24.^2+rpower24.^2) sqrt(apower25.^2+rpower25.^2)], [pf21 pf22 pf23 pf24 pf25], [] );
            %histogram tps power
            figure; subplot(2,1,1); histogram(sum_apower1, 1e3); subplot(2,1,2); histogram(sum_apower2, 1e3);
            figure; subplot(2,1,1); histogram(sum_rpower1, 1e3); subplot(2,1,2); histogram(sum_rpower2, 1e3);
            %histogram train power
            figure; subplot(5,1,1); histogram(apower11, 1e3); subplot(5,1,2); histogram(apower12, 1e3); subplot(5,1,3); histogram(apower13, 1e3); subplot(5,1,4); histogram(apower14, 1e3); subplot(5,1,5); histogram(apower15, 1e3);
            figure; subplot(5,1,1); histogram(apower21, 1e3); subplot(5,1,2); histogram(apower22, 1e3); subplot(5,1,3); histogram(apower23, 1e3); subplot(5,1,4); histogram(apower24, 1e3); subplot(5,1,5); histogram(apower25, 1e3);
            figure; subplot(5,1,1); histogram(rpower11, 1e3); subplot(5,1,2); histogram(rpower12, 1e3); subplot(5,1,3); histogram(rpower13, 1e3); subplot(5,1,4); histogram(rpower14, 1e3); subplot(5,1,5); histogram(rpower15, 1e3);
            figure; subplot(5,1,1); histogram(rpower21, 1e3); subplot(5,1,2); histogram(rpower22, 1e3); subplot(5,1,3); histogram(rpower23, 1e3); subplot(5,1,4); histogram(rpower24, 1e3); subplot(5,1,5); histogram(rpower25, 1e3);
            figure; subplot(5,1,1); histogram(pf11, 1e3); subplot(5,1,2); histogram(pf12, 1e3); subplot(5,1,3); histogram(pf13, 1e3); subplot(5,1,4); histogram(pf14, 1e3); subplot(5,1,5); histogram(pf15, 1e3);
            figure; subplot(5,1,1); histogram(pf21, 1e3); subplot(5,1,2); histogram(pf22, 1e3); subplot(5,1,3); histogram(pf23, 1e3); subplot(5,1,4); histogram(pf24, 1e3); subplot(5,1,5); histogram(pf25, 1e3);
            %%%%%%%%%
        end
        
        function obj = generate_random_trains(obj, number_of_trains)
            %%%%%%%%%%%%% GERAÇÃO DADOS RAND input MONTE CARLO
            %%% No comboios pode ser rand e pertencente a [0 1 2 .. 6]
            train_no_left = number_of_trains(1);
            train_no_right = number_of_trains(2);

            %%% cria vector de identificadores
            trains_right_1.id = 1:train_no_right;
            trains_left_2.id = 1:train_no_left;
            trains_left_2.id = trains_left_2.id+train_no_left;%%% identificadores diferentes de anterior

            %%%posição dos comboios é random
            min_distance = 0.75; %%750m
            if train_no_right > 0
                while 1 
                    trains_right_1.position = random(makedist('Uniform','lower',0,'upper',1),train_no_right,1);
                    trains_right_1.position = sortrows(trains_right_1.position, 1, 'asc')';
                    if (min(trains_right_1.position(2:end) - trains_right_1.position(1:end-1)))*obj.tps_lenghts(1,1) > min_distance
                        break;
                    end
                end
            else
                trains_right_1.position = [];
            end
            if train_no_left > 0
                while 1 
                    trains_left_2.position = random(makedist('Uniform','lower',0,'upper',1),train_no_left,1);
                    trains_left_2.position = sortrows(trains_left_2.position, 1, 'asc')';
                    if (min(trains_left_2.position(2:end) - trains_left_2.position(1:end-1)))*obj.tps_lenghts(1,1) > min_distance
                        break;
                    end
                end
            else
                trains_left_2.position = [];
            end

%             %%%potências aparentes de comboios é random (max=10MVA @ 0.8ind)
%             %%%RIGHT
%             max_tps1_power = 15e6;
%             tps_total_power1 = random(makedist('Lognormal', log(15e6), 1), 1, 1);
%             while (tps_total_power1 > max_tps1_power) , tps_total_power1 = random(makedist('Lognormal', 14.5, 1), 1, 1); end
%             delta_tps_total_power = max_tps1_power;
%             %generate N active power values, where sum(P) = TPS_power which follows distribution
%             for pwr_iter = 1:100
%                 loop_train_power = random(makedist('Uniform','lower',-0.2e6,'upper',8e6),train_no_right,1);
%                 if sum(loop_train_power) > tps_total_power1*0.9 && sum(loop_train_power) < tps_total_power1*1.1
%                     trains_right_1.apower = 1e-6.*loop_train_power.*(tps_total_power1/sum(loop_train_power));
%                     break;
%                 end
%                 if delta_tps_total_power > abs(sum(loop_train_power) - tps_total_power1)
%                     delta_tps_total_power = abs(sum(loop_train_power) - tps_total_power1);
%                     trains_right_1.apower = 1e-6.*loop_train_power.*(tps_total_power1/sum(loop_train_power));
%                 end
%             end
%             %generate reactive power values based on train active power
%             trains_right_1.pf =  trains_right_1.id.*0+1;
%             trains_right_1.rpower = trains_right_1.id.*0+1;
%             for train_id = 1:size(trains_right_1.id,2)
%                 while 1
%                     lambda = (0.4/7)*trains_right_1.apower(train_id) + (0.35-0.4/7);
%                     lambda = max(0.01, lambda);
%                     trains_right_1.pf(train_id) = 1.1-random(makedist('Lognormal', 1, lambda),1,1).*0.05;
%                     if trains_right_1.pf(train_id) >0.5 && trains_right_1.pf(train_id) <= 1 && ...
%                             sqrt(trains_right_1.apower(train_id)^2+(trains_right_1.apower(train_id)*tan(acos(trains_right_1.pf(train_id))))^2) < 10
%                         trains_right_1.rpower(train_id) = trains_right_1.apower(train_id).*tan(acos(trains_right_1.pf(train_id)));
%                         break;
%                     end
%                 end
%             end
%             %%%LEFT
%             max_tps2_power = 15e6;
%             tps_total_power2 = random(makedist('Lognormal', log(15e6), 1), 1, 1);
%             while (tps_total_power2 > max_tps2_power) , tps_total_power2 = random(makedist('Lognormal', 14.5, 1), 1, 1); end
%             delta_tps_total_power = max_tps2_power;
%             %generate N active power values, where sum(P) = TPS_power which follows distribution
%             for pwr_iter = 1:100
%                 loop_train_power = random(makedist('Uniform','lower',-0.2e6,'upper',8e6),train_no_left,1);
%                 if sum(loop_train_power) > tps_total_power2*0.9 && sum(loop_train_power) < tps_total_power2*1.1
%                     trains_left_2.apower = 1e-6.*loop_train_power.*(tps_total_power2/sum(loop_train_power));
%                     break;
%                 end
%                 if delta_tps_total_power > abs(sum(loop_train_power) - tps_total_power2)
%                     delta_tps_total_power = abs(sum(loop_train_power) - tps_total_power2);
%                     trains_left_2.apower = 1e-6.*loop_train_power.*(tps_total_power2/sum(loop_train_power));
%                 end
%             end
%             %generate reactive power values based on train active power
%             trains_left_2.pf =  trains_left_2.id.*0+1;
%             trains_left_2.rpower = trains_left_2.id.*0+1;
%             for train_id = 1:size(trains_left_2.id,2)
%                 while 1
%                     lambda = (0.4/7)*trains_left_2.apower(train_id) + (0.35-0.4/7);
%                     lambda = max(0.01, lambda);
%                     trains_left_2.pf(train_id) = 1.1-random(makedist('Lognormal', 1, lambda),1,1).*0.05;
%                     if trains_left_2.pf(train_id) >0.5 && trains_left_2.pf(train_id) <= 1 && ...
%                             sqrt(trains_left_2.apower(train_id)^2+(trains_left_2.apower(train_id)*tan(acos(trains_left_2.pf(train_id))))^2) < 10
%                         trains_left_2.rpower(train_id) = trains_left_2.apower(train_id).*tan(acos(trains_left_2.pf(train_id)));
%                         break;
%                     end
%                 end
%             end
            %%%%%%%%%%%%% FIM GERAÇÃO DADOS RAND input MONTE CARLO
            obj.sim_input_data.trains_right_1 = trains_right_1;
            obj.sim_input_data.trains_left_2 = trains_left_2;
        end
        
        function obj = add_random_trains(obj)
            %%%este método apenas adiciona os comboios armazenados nos
            %%%atributos sim_input_data
            obj = obj.add_trains(1, 'right', 'asc', obj.sim_input_data.trains_right_1);
            obj = obj.add_trains(2, 'left', 'asc', obj.sim_input_data.trains_left_2);
        end
        function obj = test_random_trains(obj)
            figure;
            obj.debug = 0;
            numIterations = 1e3;
            parfor_progress(round(numIterations));
            parfor_mon = ParforProgressbar(numIterations, 'parpool', {'local', 4});
            tic;
            tps_lenghts_ = obj.tps_lenghts;
            input_data = repmat( struct('iter', [], 'trains_right_1', [], 'trains_left_2', []), numIterations, 1);
            output_data = repmat( struct('iter', [], 'trains_right_1', [], 'trains_left_2', [], 'matpower_output', [], 'results', []), numIterations, 1);
            for iter = 1:numIterations
                parfor_mon.increment();
                parfor_progress;
                obj = obj.reset_model();
                pause(0.1);
                [trains_right_1, trains_left_2] = G_generate_random_trains([5 5], tps_lenghts_);
                input_data(iter).trains_right_1 = trains_right_1;
                input_data(iter).trains_left_2 = trains_left_2;

%                 
%                 %%%Cria modelo de simulação
%                 obj = obj.add_trains(1, 'right', 'asc', input_data(iter).trains_right_1);
%                 obj = obj.add_trains(2, 'left', 'asc', input_data(iter).trains_left_2);
%                 
%                 %close all; obj = obj.plot_electric_diagram();
%                 
%                 %%%lança simulação::: while 1?
%                 obj = obj.run_powerflow();
%                 obj = obj.process_output();
%                 %%calcular perdas
%                 losses = sum(obj.powerflow_result.apower_losses);
%                 %definir compensação
%                 obj = obj.run_powerflow();
%                 obj = obj.process_output();
%                 %%calcular perdas
            end
            toc;
            delete(parfor_mon);
            
            %%%aux functions
%             function [trains_right_1 trains_left_2] = generate_rand_train_data (num_trains_TPS1_right, num_trains_TPS2_left)
%             
%             end
        end
        
        function obj = process_output(obj)
            obj.powerflow_result.tps_power = complex(obj.last_matpower_result.gen(:, 2), obj.last_matpower_result.gen(:, 3));
            obj.powerflow_result.min_voltage = [];
            obj.powerflow_result.apower_losses = [];
            obj.powerflow_result.rpower_losses = [];
            obj.powerflow_result.power_losses = [];
            areas = unique(obj.last_matpower_result.bus(:, 7));
            for area = 1:size(areas,1)
                obj.powerflow_result.min_voltage = [obj.powerflow_result.min_voltage;  min(obj.last_matpower_result.bus(obj.last_matpower_result.bus(:,7)==areas(area),8))];
                bus_area = obj.last_matpower_result.bus(obj.last_matpower_result.bus(:,7)==areas(area),1);
                branch_matrix_area = [];
                for elem = 1:size(bus_area)
                    branch_matrix_area = [branch_matrix_area;  obj.last_matpower_result.branch(obj.last_matpower_result.branch(:,1) == bus_area(elem),:)];
                end
                obj.powerflow_result.apower_losses = [obj.powerflow_result.apower_losses; sum((branch_matrix_area(:,14)+branch_matrix_area(:,16)))];
                obj.powerflow_result.rpower_losses = [obj.powerflow_result.rpower_losses; sum((branch_matrix_area(:,15)+branch_matrix_area(:,17)))];
                obj.powerflow_result.power_losses = [obj.powerflow_result.power_losses; complex(obj.powerflow_result.apower_losses, obj.powerflow_result.rpower_losses)];
            end
            
        end
        
        function obj = power_transfer_device_compensation(obj)
            tps1_power = real(obj.powerflow_result.tps_power(1));
            tps2_power = real(obj.powerflow_result.tps_power(2));
            compensation = (tps1_power - tps2_power)*0.5;
            obj.global_model_mpc.bus(4,3) = -compensation*1;
            obj.global_model_mpc.bus(7,3) = compensation*1;
        end
        function obj = setup_tps(obj)
            addpath('matpower7.0\');
            matpower_addpath;
            obj.mpopt = mpoption('model', 'AC', ... %[ 'AC' - use nonlinear AC model & corresponding algorithms/options  ]
                'pf.alg', 'NR', ...  %[ 'NR'    - Newton's method (formulation depends on values of pf.current_balance and pf.v_cartesian options)          ]
                'pf.tol', 1e-12, ... % termination tolerance on per unit P & Q mismatch
                'pf.nr.max_it', 1000, ... % maximum number of iterations for Newton's method
                'verbose', 0, 'out.all', 0);
            
            %%% setup MPC
            obj.global_model_mpc.version = '2';
            obj.global_model_mpc.baseMVA = 100; %%% em MVA
            obj.global_model_mpc.gen = [];
            obj.global_model_mpc.branch = [];
            obj.global_model_mpc.bus = [];
            
            obj.tps = [];
            for tps_no=1:obj.number_of_tps
                tps_to_add.number = tps_no;
                %%% generator data
                % bus  Pg  Qg  Qmax  Qmin Vg  mBase  status  Pmax  Pmin  Pc1  Pc2  Qc1min  Qc1max  Qc2min  Qc2max  ramp_agc  ramp_10  ramp_30  ramp_q  apf
                tps_to_add.gen = [(tps_no-1)*4+1  0.0000  0.0000  999  -999  1.0000  100  1   999  0  0  0  0  0  0  0  0  0  0  0  0];
                % % bus_i  type  Pd  Qd  Gs  Bs  area  Vm  Va  baseKV  zone  Vmax  Vmin
                tps_to_add.bus = [
                    (tps_no-1)*4+1  3  0.0000  0.0000  0.0000  0.0000  tps_no  1  0  25.0  1  1.35  0.35
                    (tps_no-1)*4+2  1  0.0000  0.0000  0.0000  0.0000  tps_no  1  0  25.0  1  1.35  0.35
                    (tps_no-1)*4+3  1  0.0000  0.0000  0.0000  0.0000  tps_no  1  0  25.0  1  1.35  0.35
                    (tps_no-1)*4+4  1  0.0000  0.0000  0.0000  0.0000  tps_no  1  0  25.0  1  1.35  0.35];
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
                tps_to_add_2.bus_index = size(obj.global_model_mpc.bus,1)-3:size(obj.global_model_mpc.bus,1);
                tps_to_add_2.branch_index = size(obj.global_model_mpc.branch,1)-2:size(obj.global_model_mpc.branch,1);
                tps_to_add_2.trains = [];%struct('id', [], 'dir', [], 'section', [],  'abs_position', [], 'apower', [], 'rpower', []);
                obj.tps = [obj.tps tps_to_add_2];
                
            end
            
        end
        
        function obj = setup_trains(obj)
            train_power = makedist('Uniform','lower',-0.2,'upper',4);
            train_power_factor = makedist('Uniform','lower',0.9,'upper',1);
            train_distance = makedist('Uniform','lower',0,'upper',1);
            trains.id = 1:6;
            trains.position = random(train_distance,6,1).';
            trains.position = sortrows(trains.position, 1, 'asc');
            trains.apower = random(train_power,6,1).';
            trains.rpower = random(train_power_factor,6,1).';
            trains.rpower = trains.apower.*tan(acos(trains.rpower));
            %             trains.id = 1;% 2 3];
            %             trains.position = 0.5;%1 0.5 0.6]; %%note: ensure order!
            %             trains.apower = 8;% 2 2];
            %             trains.rpower = 2;%.5 0.5 0.5].*0;
            obj = obj.add_trains(1, 'left', 'asc', trains);
            %             trains.id = [4 5 6];
            %             obj = obj.add_trains(1, 'right', 'asc', trains);
            %             trains.id = [7 8 9];
            %             obj = obj.add_trains(2, 'left', 'asc', trains);
            %             trains.id = [7 8 9];
            %             obj = obj.add_trains(2, 'right', 'asc', trains);
        end
        
        function obj = add_trains(obj, tps_no, side, direction, trains)
            
            switch direction
                case 'asc'
                    if obj.debug == 1, fprintf("adding trains in asc\n");end
                    switch side
                        case 'left'
                            
                            %%% add trains to the list of trains in
                            if ~isfield(obj.tps(tps_no), 'trains_left')
                                trains.abs_position = trains.position.*obj.tps_lenghts(tps_no,1);
                                obj.tps(tps_no).trains_left = trains;
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
                                catenary_length = max(catenary_length, 0.01);
                                %%% add new buses and branches
                                for train_it = 1: size(trains.id, 2)
                                    %%%fill the global electric model
                                    % % bus_i  type  Pd  Qd  Gs  Bs  area  Vm  Va  baseKV  zone  Vmax  Vmin
                                    bus_to_add= [prev_bus+train_it  1  trains.apower(train_it)  trains.rpower(train_it)  0.0000  0.0000  tps_no  1  0  25.0  1  1.35  0.35 ];
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
                            elseif isempty(obj.tps(tps_no).trains_left)
                                %%%%%%%%%%%% NOTA COPY PASTE DE ANTERIOR
                                trains.abs_position = trains.position.*obj.tps_lenghts(tps_no,1);
                                obj.tps(tps_no).trains_left = trains;
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
                                catenary_length = max(catenary_length, 0.01);
                                %%% add new buses and branches
                                for train_it = 1: size(trains.id, 2)
                                    %%%fill the global electric model
                                    % % bus_i  type  Pd  Qd  Gs  Bs  area  Vm  Va  baseKV  zone  Vmax  Vmin
                                    bus_to_add= [prev_bus+train_it  1  trains.apower(train_it)  trains.rpower(train_it)  0.0000  0.0000  tps_no  1  0  25.0  1  1.35  0.35 ];
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
                                %%%%%%%%%%%% NOTA END COPY PASTE DE ANTERIOR
                            else
                                %                         obj.tps(tps_no).trains_left = cat_trains(obj.tps(tps_no).trains_left, trains);
                                %                         %%% TODO: acrescentar novos comboios
                            end
                            
                        case 'right'
                            %%% add trains to the list of trains in
                            if ~isfield(obj.tps(tps_no), 'trains_right')
                                trains.abs_position = trains.position.*obj.tps_lenghts(tps_no,2);
                                obj.tps(tps_no).trains_right = trains;
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
                                catenary_length = max(catenary_length, 0.01);
                                %%% add new buses and branches
                                for train_it = 1: size(trains.id, 2)
                                    %%%fill the global electric model
                                    % % bus_i  type  Pd  Qd  Gs  Bs  area  Vm  Va  baseKV  zone  Vmax  Vmin
                                    bus_to_add= [prev_bus+train_it  1  trains.apower(train_it)  trains.rpower(train_it)  0.0000  0.0000  tps_no  1  0  25.0  1  1.35  0.35 ];
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
                                
                            elseif isempty(obj.tps(tps_no).trains_right)
                                %%%%%%%%%%%% NOTA COPY PASTE DE ANTERIOR
                                trains.abs_position = trains.position.*obj.tps_lenghts(tps_no,2);
                                obj.tps(tps_no).trains_right = trains;
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
                                catenary_length = max(catenary_length, 0.01);
                                %%% add new buses and branches
                                for train_it = 1: size(trains.id, 2)
                                    %%%fill the global electric model
                                    % % bus_i  type  Pd  Qd  Gs  Bs  area  Vm  Va  baseKV  zone  Vmax  Vmin
                                    bus_to_add= [prev_bus+train_it  1  trains.apower(train_it)  trains.rpower(train_it)  0.0000  0.0000  tps_no  1  0  25.0  1  1.35  0.35 ];
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
                                %%%%%%%%%%%% NOTA END COPY PASTE DE ANTERIOR
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
            %%%method aux functions
            function trains = cat_trains(trains_array, trains)
                trains_array.id = [trains_array.id trains.id];
                trains_array.position = [trains_array.position trains.position];
                trains_array.apower = [trains_array.apower trains.apower];
                trains_array.rpower = [trains_array.rpower trains.rpower];
            end
            %%%end method add_trains()
        end
        
        function obj = run_powerflow(obj)
            addpath('matpower7.0\');
            matpower_addpath;
            obj.last_matpower_result = runpf(obj.global_model_mpc, obj.mpopt);
        end
        
        function obj = setup_electric_parameters(obj)
            obj.number_of_tps = 2;
            obj.tps_lenghts =...
                [20 20
                15 15];
            %%%%%%%%%%%%%  PARAMETERS FROM AJM %%%%%%%%%%
            Rt = 0.055;      % 55 mohm/km
            Lt = 0.22e-3;    % 0.22mH
            Ct = 1e-6;        % 1uF ???????????????????
            dt = 0.5;        % distância 0.5 km
            %catenária
            Rc = 0.15;      % ohms/km
            Lc = 1.43e-3;   % 1,43 mH/km
            Cc = 12.4e-9;   % 12,4 nF/km
            %max secção A = 20km
            %max secção B = 15km
            
            %%%% SETUP PROBLEM DEFINITION
            Sbase = 100e6;
            Vbase = 25e3;
            Ibase = Sbase/Vbase;
            Zbase = Vbase/Ibase;
            
            %%%%%%%%%% SETUP Tranformer and Catenary parameters
            obj.tps_transformer_impedance = dt*(Rt+1i*2*50*pi*Lt)/Zbase;
            obj.tps_transformer_susceptance = dt*(1i*2*50*pi*Ct)/Zbase;
            obj.tps_catenary_impedance = (Rc + 1i*Lc*(2*pi*50))/Zbase; %ohm/km;
            obj.tps_catenary_susceptance = ((1i*2*pi*50)*Cc)/Zbase;  %"ohm"/km;
        end
        
        function obj = plot_electric_diagram(obj)
            obj.plot_electric_ = plot_electric;
            obj.plot_electric_ = obj.plot_electric_.attach_electric_model(obj.tps, obj.global_model_mpc, obj.tps_lenghts);
            obj.plot_electric_ = obj.plot_electric_.plot_electric_data();
        end
    end
end



