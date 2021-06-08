classdef MONTE_CARLO
    %MONTE_CARLO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numIterations
        electric_model_objects
        clustered_electric_model_objects
        monte_carlo_type
        electric_diagram_fig_handler
        ptd_results_fig_handler
        results
        mcp_results
        figure_monitor_position %% 1980 para placement ser feito no segundo monitor
        random_status
        electric_parameters
    end
    
    methods
        function obj = MONTE_CARLO()
            %MONTE_CARLO class allows the analysis of N scenarios for a specific PTD compensation strategy
            %This class has the following highlights:
            %   1. each monte_carlo object is related to one specific PTD compensation strategy
            %   2. it uses/creates one array of simulation scenarios (objects of the type "electric_model")
            %   3. it allows the automatic generation of the input data statistics
            %   4. it allows the automatic generation of the results statistics/metrics
            obj.figure_monitor_position = 0;%1980;
            obj = obj.initiate_random_status();
            obj = obj.initiate_electric_parameters();
        end
        function obj = eval_compensation(obj, type, max_iter, parallelism_status)
            %method for the analysis of tps_power balancing compensation strategy
            electric_model_objects_ = repmat(electric_model, max_iter, 1);
            parfor_progress(round(max_iter/10));
            switch parallelism_status
                case 'enabled'
                    %if max_iter > 100  %%USE PARALELISM
                    parfor_mon = ParforProgressbar(round(max_iter/10), 'parpool', {'local', 4}, 'showWorkerProgress', true);
                    tic;
                    random_status_ = obj.random_status;
                    electric_parameters_ = obj.electric_parameters;
                    %%%%%%%%%%%%%  RUN PARFOR
                    parfor iter = 1:max_iter
                    %for iter = 1:max_iter
                        electric_model_objects_(iter) = electric_model_objects_(iter).set_random_status(random_status_);
                        electric_model_objects_(iter) = electric_model_objects_(iter).update_electric_model_parameters(electric_parameters_);
                        electric_model_objects_(iter) = electric_model_objects_(iter).reset_model();
                        electric_model_objects_(iter) = electric_model_objects_(iter).generate_random_trains();
                        %electric_model_objects_(iter) = electric_model_objects_(iter).add_random_trains();
                        electric_model_objects_(iter) = electric_model_objects_(iter).run_powerflow();
                        electric_model_objects_(iter) = electric_model_objects_(iter).process_output();
                        electric_model_objects_(iter) = electric_model_objects_(iter).attach_power_transfer_device();
                        switch type
                            case 'tps_power_optimization'
                                electric_model_objects_(iter) = electric_model_objects_(iter).tps_power_optimization();
                            case 'power_losses_optimization'
                                electric_model_objects_(iter) = electric_model_objects_(iter).tps_power_optimization();
                            case 'nz_voltage_optimization'
                                electric_model_objects_(iter) = electric_model_objects_(iter).tps_power_optimization();
                        end
                        %%%monitorizar execução MONTE CARLO
                        if mod(iter, 10) == 0 , pause(0.01); parfor_progress; parfor_mon.increment(); end
                    end
                    delete(parfor_mon); parfor_progress(0);
                case 'disabled'
                    tic;
                    random_status_ = obj.random_status;
                    electric_parameters_ = obj.electric_parameters;
                    %%%%%%%%%%%%%  RUN PARFOR
                    for iter = 1:max_iter
                    %for iter = 1:max_iter
                        electric_model_objects_(iter) = electric_model_objects_(iter).set_random_status(random_status_);
                        electric_model_objects_(iter) = electric_model_objects_(iter).update_electric_model_parameters(electric_parameters_);
                        electric_model_objects_(iter) = electric_model_objects_(iter).reset_model();
                        electric_model_objects_(iter) = electric_model_objects_(iter).generate_random_trains();
                        %electric_model_objects_(iter) = electric_model_objects_(iter).add_random_trains();
                        electric_model_objects_(iter) = electric_model_objects_(iter).run_powerflow();
                        electric_model_objects_(iter) = electric_model_objects_(iter).process_output();
                        electric_model_objects_(iter) = electric_model_objects_(iter).attach_power_transfer_device();
                        switch type
                            case 'tps_power_optimization'
                                electric_model_objects_(iter) = electric_model_objects_(iter).tps_power_optimization();
                            case 'power_losses_optimization'
                                electric_model_objects_(iter) = electric_model_objects_(iter).tps_power_optimization();
                            case 'nz_voltage_optimization'
                                electric_model_objects_(iter) = electric_model_objects_(iter).tps_power_optimization();
                        end
                        %%%monitorizar execução MONTE CARLO
                        if mod(iter, 10) == 0 , pause(0.01); parfor_progress; end
                    end
                    parfor_progress(0);
            end
            %%%print last electric diagram
%             electric_model_objects_(max_iter).plot_electric_diagram();
%             obj.electric_diagram_fig_handler = gcf;
            obj.electric_model_objects = electric_model_objects_;
            obj.monte_carlo_type = type;
            toc;
        end
        function obj = attach_results_array(obj, electric_model_objects_array)
            obj.electric_model_objects = electric_model_objects_array;
        end
        function obj = perform_statistical_analysis(obj, type)
            %%%percorre o vector de electric_model_objects e analiza cada
            %%%um dos parâmetros aleatórios
            %             type_of_analysis = {'train_position', 'train_power', 'train_pf'};
            %             type = type_of_analysis{1};
            if isempty(obj.clustered_electric_model_objects)
                obj.clustered_electric_model_objects = obj.electric_model_objects;
            end
            switch type
                
                case 'cluster'
                    statistic_analysis_num_trains(obj, obj.clustered_electric_model_objects);
                    statistic_analysis_tpspower_tpslength(obj, obj.clustered_electric_model_objects);
                    statistic_analysis_train_power(obj, obj.clustered_electric_model_objects)
                case 'all'
                    statistic_analysis_num_trains(obj, obj.electric_model_objects);
                    statistic_analysis_tpspower_tpslength(obj, obj.electric_model_objects);
                    statistic_analysis_train_power(obj, obj.electric_model_objects);
                    statistic_analysis_train_position(obj, obj.electric_model_objects);
                case 'train_position'
                    statistic_analysis_train_position(obj);
                case 'train_power'
                    %statistic_analysis_train_power3(obj);
                case 'train_pf'
                    %statistic_analysis_train_pf3(obj);
                otherwise
                    fprintf('\ntype of analysis -- %s -- not available', string(type));
            end
            function statistic_analysis_tpspower_tpslength(obj, objects_to_analyse)
                tps_power =  ones(size(objects_to_analyse,1),2).*NaN;
                tps_length = ones(size(objects_to_analyse,1),2).*NaN;
                for iter = 1:size(objects_to_analyse,1)
                    tps_power(iter,1) = objects_to_analyse(iter, 1).last_matpower_result.gen(1,2);
                    tps_power(iter,2) = objects_to_analyse(iter, 1).last_matpower_result.gen(2,2);
                    tps_length(iter,1) = objects_to_analyse(iter, 1).tps(1).length(2);
                    tps_length(iter,2) = objects_to_analyse(iter, 1).tps(2).length(1);
                end
                fig_handler = [];
                disc_hist = [5e1 5e1];
                %%% CRIA FIGURA 2x1 histograma para os potências de comboios de cada TPS CLUSTER
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                axes1 = subplot(2,2,1);
                hist3([tps_power(:,1) tps_length(:,1)], disc_hist, 'FaceAlpha', .95, 'FaceColor','interp','CDataMode','auto');
                view(axes1,[0 90]); c = colorbar; c.Title.String = 'frequency'; xlabel('tps1 power'); ylabel('tps1 length');
                axes2 = subplot(2,2,2);
                hist3([tps_power(:,1) tps_length(:,2)], disc_hist, 'FaceAlpha', .95, 'FaceColor','interp','CDataMode','auto');
                view(axes2,[0 90]); c = colorbar; c.Title.String = 'frequency'; xlabel('tps1 power'); ylabel('tps2 length');
                axes3 = subplot(2,2,3);
                hist3([tps_power(:,2) tps_length(:,1)], disc_hist, 'FaceAlpha', .95, 'FaceColor','interp','CDataMode','auto');
                view(axes3,[0 90]); c = colorbar; c.Title.String = 'frequency'; xlabel('tps2 power'); ylabel('tps1 length');
                axes4 = subplot(2,2,4);
                hist3([tps_power(:,2) tps_length(:,2)], disc_hist, 'FaceAlpha', .95, 'FaceColor','interp','CDataMode','auto');
                view(axes4,[0 90]); c = colorbar; c.Title.String = 'frequency'; xlabel('tps2 power'); ylabel('tps2 length');
            end
            function statistic_analysis_train_power_cluster(obj, objects_to_analyse)
                trains_power_tps1 = [];
                trains_power_tps2 = [];
                for iter = 1:size(objects_to_analyse,1)
                    trains_power_tps1 = [trains_power_tps1 [objects_to_analyse(iter, 1).tps(1).trains.apower]];
                    trains_power_tps2 = [trains_power_tps2 [objects_to_analyse(iter, 1).tps(2).trains.apower]];
                end
                
                fig_handler = [];
                %%% CRIA FIGURA 2x1 histograma para os potências de comboios de cada TPS CLUSTER
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                
                subplot(2,1,1); hold on; grid on; grid minor;
                histogram(trains_power_tps1, 1.5e2, 'DisplayName', strcat("Dense TPS: (total ", num2str(size(trains_power,2)), " trains)"));
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of trains power consumption in Dense TPS');
                subplot(2,1,2); hold on; grid on; grid minor;
                histogram(trains_cluster_sparse, 1.5e2, 'DisplayName', strcat("Sparse TPS: (total ", num2str(size(trains_cluster_sparse,2)), " trains)"));
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of trains power consumption in Sparse TPS');
                
                %%% CRIA FIGURA 2x1 histograma para os potências de tps de cada TPS CLUSTER
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                subplot(2,1,1); hold on; grid on; grid minor;
                histogram(tps_cluster_dense, 1.5e2,  'DisplayName', strcat("Dense TPS: (total ", num2str(size(tps_cluster_dense,2)), " tps)"));
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of TPS power consumption in Dense TPS');
                subplot(2,1,2); hold on; grid on; grid minor;
                histogram(tps_cluster_sparse, 1.5e2, 'DisplayName', strcat("Sparse TPS: (total ", num2str(size(tps_cluster_sparse,2)), " tps)"));
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of TPS power consumption in Sparse TPS');
            end
            function statistic_analysis_num_trains(obj, objects_to_analyse)
                tps1_num_trains_dense = [];
                tps2_num_trains_dense = [];
                tps1_num_trains_sparse = [];
                tps2_num_trains_sparse = [];
                %objects_to_analyse = obj.electric_model_objects;
                for iter = 1:size(objects_to_analyse,1)
                        switch objects_to_analyse(iter, 1).tps(1).tps_cluster
                            case 'dense'
                                tps1_num_trains_dense = [tps1_num_trains_dense   size(objects_to_analyse(iter, 1).tps(1).trains, 2)];
                            case 'sparse'
                                tps1_num_trains_sparse = [tps1_num_trains_sparse size(objects_to_analyse(iter, 1).tps(1).trains, 2)];
                        end
                        switch objects_to_analyse(iter, 1).tps(2).tps_cluster
                            case 'dense'
                                tps2_num_trains_dense = [tps2_num_trains_dense   size(objects_to_analyse(iter, 1).tps(2).trains, 2)];
                            case 'sparse'
                                tps2_num_trains_sparse = [tps2_num_trains_sparse size(objects_to_analyse(iter, 1).tps(2).trains, 2)];
                        end
                end
                fig_handler = [];
                %%% CRIA FIGURA 2x1 histograma para os potências de comboios de cada TPS CLUSTER
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                subplot(2,1,1); hold on; grid on; grid minor;
                if ~isempty(tps1_num_trains_dense), bar(0:1:6, histc(tps1_num_trains_dense, 0:1:6 ), 'BarWidth', 0.9, 'DisplayName', 'TPS1'); end
                if ~isempty(tps2_num_trains_dense), bar(0:1:6, histc(tps2_num_trains_dense, 0:1:6 ), 'BarWidth', 0.6, 'DisplayName', 'TPS2'); end
                grid on; grid minor; xlabel('Number of trains'); ylabel('frequency'); title({'Number of trains in', 'dense metropolitan area'});
%                 histogram(trains_cluster_dense, 1.5e2, 'DisplayName', strcat("Dense TPS: (total ", num2str(size(trains_cluster_dense,2)), " trains)"));
%                 legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of trains power consumption in Dense TPS');
                subplot(2,1,2); hold on; grid on; grid minor;
                if ~isempty(tps1_num_trains_sparse), bar(0:1:6, histc(tps1_num_trains_sparse, 0:1:6 ), 'BarWidth', 0.9, 'DisplayName', 'TPS1'); end
                if ~isempty(tps2_num_trains_sparse), bar(0:1:6, histc(tps2_num_trains_sparse, 0:1:6 ), 'BarWidth', 0.6, 'DisplayName', 'TPS2'); end
                grid on; grid minor; xlabel('Number of trains'); ylabel('frequency'); title({'Number of trains in', 'sparse metropolitan area'});
%                 histogram(trains_cluster_sparse, 1.5e2, 'DisplayName', strcat("Sparse TPS: (total ", num2str(size(trains_cluster_sparse,2)), " trains)"));
%                 legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of trains power consumption in Sparse TPS');
                
            end
            function statistic_analysis_train_position(obj, objects_to_analyse)
                
                %%%% TPS1
                for train_size = 1:6
                    trains_pos_tps1 = ones(size(objects_to_analyse,1), train_size).*NaN;
                    trains_pos_tps2 = ones(size(objects_to_analyse,1), train_size).*NaN;
%                     trains_pos_tps1 = ones(size(obj.electric_model_objects,1), ...
%                         size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
%                         );
%                     trains_pos_tps2 = ones(size(obj.electric_model_objects,1), ...
%                         size(obj.electric_model_objects(1, 1).tps(2).trains,2)...
%                         );
                    for iter = 1:size(obj.electric_model_objects,1)
                        if size(obj.electric_model_objects(iter, 1).tps(1).trains,2) == train_size
                            trains_pos_tps1(iter,:) = [obj.electric_model_objects(iter, 1).tps(1).trains.position];
                        end
                        if size(obj.electric_model_objects(iter, 1).tps(2).trains,2) == train_size
                            trains_pos_tps2(iter,:) = [obj.electric_model_objects(iter, 1).tps(2).trains.position];
                        end
                    end
                    fig_handler = [];
                    %%% CRIA FIGURA 2x1 histograma para os comboios de cada TPS
                    %   (NOTA: script só funciona para número de comboios sempre o mesmo)
                    fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                    subplot(2,1,1); hold on; grid on; grid minor;
                    for train = 1:size(trains_pos_tps1,2)
                        histogram(trains_pos_tps1(:,train), 1.5e2, 'DisplayName', strcat("Train ", num2str(train)));
                    end
                    legend(); xlabel('train absolute position (km)'); ylabel('frequency'); title('Histogram of train positions in TPS1');

                    subplot(2,1,2); hold on; grid on; grid minor;
                    for train = 1:size(trains_pos_tps2,2)
                        histogram(trains_pos_tps2(:,train), 1.5e2, 'DisplayName', strcat("Train ", num2str(train)));
                    end
                    legend(); xlabel('train absolute position (km)'); ylabel('frequency'); title('Histogram of train positions in TPS2');
                end
            end
            function statistic_analysis_train_power(obj, objects_to_analyse)
                trains_cluster_dense = [];
                trains_cluster_sparse = [];
                tps_cluster_dense = [];
                tps_cluster_sparse = [];
                
                for iter = 1:size(objects_to_analyse,1)
                    switch objects_to_analyse(iter, 1).tps(1).tps_cluster
                        case 'dense'
                            if ~isempty(objects_to_analyse(iter, 1).tps(1).trains)
                                tps_cluster_dense = [tps_cluster_dense sum([objects_to_analyse(iter, 1).tps(1).trains.apower])];
                                trains_cluster_dense = [trains_cluster_dense [objects_to_analyse(iter, 1).tps(1).trains.apower]];
                            else
                                 tps_cluster_dense = [tps_cluster_dense NaN];
                                 trains_cluster_dense = [trains_cluster_dense NaN];
                            end
                        case 'sparse'
                            if ~isempty(objects_to_analyse(iter, 1).tps(1).trains)
                                tps_cluster_sparse = [tps_cluster_sparse sum([objects_to_analyse(iter, 1).tps(1).trains.apower])];
                                trains_cluster_sparse = [trains_cluster_sparse [objects_to_analyse(iter, 1).tps(1).trains.apower]];
                            else
                                 tps_cluster_sparse = [tps_cluster_sparse NaN];
                                 trains_cluster_sparse = [trains_cluster_sparse NaN];
                            end
                    end
                    switch objects_to_analyse(iter, 1).tps(2).tps_cluster
                        case 'dense'
                            if ~isempty(objects_to_analyse(iter, 1).tps(2).trains)
                                tps_cluster_dense = [tps_cluster_dense sum([objects_to_analyse(iter, 1).tps(2).trains.apower])];
                                trains_cluster_dense = [trains_cluster_dense [objects_to_analyse(iter, 1).tps(2).trains.apower]];
                            else
                                 tps_cluster_dense = [tps_cluster_dense NaN];
                                 trains_cluster_dense = [trains_cluster_dense NaN];
                            end
                        case 'sparse'
                            if ~isempty(objects_to_analyse(iter, 1).tps(2).trains)
                                tps_cluster_sparse = [tps_cluster_sparse sum([objects_to_analyse(iter, 1).tps(2).trains.apower])];
                                trains_cluster_sparse = [trains_cluster_sparse [objects_to_analyse(iter, 1).tps(2).trains.apower]];
                            else
                                 tps_cluster_sparse = [tps_cluster_sparse NaN];
                                 trains_cluster_sparse = [trains_cluster_sparse NaN];
                            end
                    end
                end
                fig_handler = [];
                %%% CRIA FIGURA 2x1 histograma para os potências de comboios de cada TPS CLUSTER
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                subplot(2,1,1); hold on; grid on; grid minor;
                histogram(trains_cluster_dense, 1.5e2, 'DisplayName', strcat("Dense TPS: (total ", num2str(size(trains_cluster_dense,2)), " trains scenarios)"));
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of trains power consumption in Dense TPS');
                subplot(2,1,2); hold on; grid on; grid minor;
                histogram(trains_cluster_sparse, 1.5e2, 'DisplayName', strcat("Sparse TPS: (total ", num2str(size(trains_cluster_sparse,2)), " trains scenarios)"));
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of trains power consumption in Sparse TPS');
                
                %%% CRIA FIGURA 2x1 histograma para os potências de tps de cada TPS CLUSTER
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                subplot(2,1,1); hold on; grid on; grid minor;
                histogram(tps_cluster_dense, 1.5e2,  'DisplayName', strcat("Dense TPS: (total ", num2str(size(tps_cluster_dense,2)), " tps scenarios)"));
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of TPS power consumption in Dense TPS');
                subplot(2,1,2); hold on; grid on; grid minor;
                histogram(tps_cluster_sparse, 1.5e2, 'DisplayName', strcat("Sparse TPS: (total ", num2str(size(tps_cluster_sparse,2)), " tps scenarios)"));
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of TPS power consumption in Sparse TPS');
                
            end
            function statistic_analysis_train_power3(obj)
                trains_pwr1 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
                    );
                trains_pwr2 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(2).trains,2)...
                    );
                for iter = 1:size(obj.electric_model_objects,1)
                    trains_pwr1(iter,:) = [obj.electric_model_objects(iter, 1).tps(1).trains.apower];
                    trains_pwr2(iter,:) = [obj.electric_model_objects(iter, 1).tps(2).trains.apower];
                end
                fig_handler = [];
                %%% CRIA FIGURA 2x1 histograma para os potências de comboios de cada TPS
                %   (NOTA: script só funciona para número de comboios sempre o mesmo)
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                subplot(2,1,1); hold on; grid on; grid minor;
                for train = 1:size(trains_pwr1,2)
                    histogram(trains_pwr1(:,train), 1.5e2, 'DisplayName', strcat("Train ", num2str(train)));
                end
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of trains in TPS1');
                
                subplot(2,1,2); hold on; grid on; grid minor;
                for train = 1:size(trains_pwr2,2)
                    histogram(trains_pwr2(:,train), 1.5e2, 'DisplayName', strcat("Train ", num2str(train)));
                end
                legend(); xlabel('train power consumption (MW)'); ylabel('frequency'); title('Histogram of trains in TPS2');
                
                %%% CRIA FIGURA 2x1 histograma para os potências de comboios de cada TPS
                %   (NOTA: script só funciona para número de comboios sempre o mesmo)
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                subplot(2,3,1); histogram(trains_pwr1(:,1), 1.5e2); xlabel('train power consumption (MW)'); ylabel('frequency'); title('train\_id=1 (TPS1)'); grid on; grid minor;
                subplot(2,3,2); histogram(trains_pwr1(:,2), 1.5e2); xlabel('train power consumption (MW)'); ylabel('frequency'); title('train\_id=2 (TPS1)'); grid on; grid minor;
                subplot(2,3,3); histogram(trains_pwr1(:,3), 1.5e2); xlabel('train power consumption (MW)'); ylabel('frequency'); title('train\_id=3 (TPS1)'); grid on; grid minor;
                subplot(2,3,4); histogram(trains_pwr2(:,1), 1.5e2); xlabel('train power consumption (MW)'); ylabel('frequency'); title('train\_id=1 (TPS2)'); grid on; grid minor;
                subplot(2,3,5); histogram(trains_pwr2(:,2), 1.5e2); xlabel('train power consumption (MW)'); ylabel('frequency'); title('train\_id=2 (TPS2)'); grid on; grid minor;
                subplot(2,3,6); histogram(trains_pwr2(:,3), 1.5e2); xlabel('train power consumption (MW)'); ylabel('frequency'); title('train\_id=3 (TPS2)'); grid on; grid minor;
                
                %%% CRIA FIGURA histograma pwr TPS1 e pwr TPS2
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                subplot(2,1,1); histogram(sum(trains_pwr1(:,:).'), 2e2); xlabel('tps power consumption (MW)'); ylabel('frequency'); title('TPS1'); grid on; grid minor;
                subplot(2,1,2); histogram(sum(trains_pwr2(:,:).'), 2e2); xlabel('tps power consumption (MW)'); ylabel('frequency'); title('TPS2'); grid on; grid minor;
            end
            function statistic_analysis_train_pf3(obj)
                trains_apwr1 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
                    );
                trains_rpwr1 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
                    );
                trains_pwr1 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
                    );
                trains_pf1 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
                    );
                trains_apwr2 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
                    );
                trains_rpwr2 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
                    );
                trains_pwr2 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
                    );
                trains_pf2 = ones(size(obj.electric_model_objects,1), ...
                    size(obj.electric_model_objects(1, 1).tps(1).trains,2)...
                    );
                for iter = 1:size(obj.electric_model_objects,1)
                    trains_apwr1(iter,:) = [obj.electric_model_objects(iter, 1).tps(1).trains.apower];
                    trains_rpwr1(iter,:) = [obj.electric_model_objects(iter, 1).tps(1).trains.rpower];
                    trains_pwr1(iter,:) = sqrt(trains_apwr1(iter,:).^2+trains_rpwr1(iter,:).^2);
                    trains_pf1(iter,:) = cos(atan(trains_rpwr1(iter,:)./ trains_apwr1(iter,:)));
                    trains_apwr2(iter,:) = [obj.electric_model_objects(iter, 1).tps(2).trains.apower];
                    trains_rpwr2(iter,:) = [obj.electric_model_objects(iter, 1).tps(2).trains.rpower];
                    trains_pwr2(iter,:) = sqrt(trains_apwr2(iter,:).^2+trains_rpwr2(iter,:).^2);
                    trains_pf2(iter,:) = cos(atan(trains_rpwr2(iter,:)./ trains_apwr2(iter,:)));
                end
                fig_handler = [];
                %%% CRIA FIGURA histograma diferença pwr
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                subplot(2,3,1); plot(trains_pwr1(:,1), trains_pf1(:,1), '.'); xlabel('train power consumption (MVA)'); ylabel('train power factor'); title('train\_id=1 (TPS1)'); grid on; grid minor;
                subplot(2,3,2); plot(trains_pwr1(:,2), trains_pf1(:,2), '.'); xlabel('train power consumption (MVA)'); ylabel('train power factor'); title('train\_id=2 (TPS1)'); grid on; grid minor;
                subplot(2,3,3); plot(trains_pwr1(:,3), trains_pf1(:,3), '.'); xlabel('train power consumption (MVA)'); ylabel('train power factor'); title('train\_id=3 (TPS1)'); grid on; grid minor;
                subplot(2,3,4); plot(trains_pwr2(:,1), trains_pf2(:,1), '.'); xlabel('train power consumption (MVA)'); ylabel('train power factor'); title('train\_id=1 (TPS2)'); grid on; grid minor;
                subplot(2,3,5); plot(trains_pwr2(:,2), trains_pf2(:,2), '.'); xlabel('train power consumption (MVA)'); ylabel('train power factor'); title('train\_id=2 (TPS2)'); grid on; grid minor;
                subplot(2,3,6); plot(trains_pwr2(:,3), trains_pf2(:,3), '.'); xlabel('train power consumption (MVA)'); ylabel('train power factor'); title('train\_id=3 (TPS2)'); grid on; grid minor;
                
                %%% CRIA FIGURA histograma diferença pwr
                fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                subplot(2,1,1); plot(trains_pwr1(:,:), trains_pf1(:,:), '.'); xlabel('train power consumption (MVA)'); ylabel('train power factor'); title('TPS1'); grid on; grid minor;
                subplot(2,1,2); plot(trains_pwr2(:,:), trains_pf2(:,:), '.'); xlabel('train power consumption (MVA)'); ylabel('train power factor'); title('TPS1'); grid on; grid minor;
                %figure;
                %subplot(2,1,1); histogram(sum(trains_pwr(:,1:3).'), 2e2); xlabel('tps power consumption (MW)'); ylabel('frequency'); title('TPS1');
                %subplot(2,1,2); histogram(sum(trains_pwr(:,4:6).'), 2e2); xlabel('tps power consumption (MW)'); ylabel('frequency'); title('TPS2');
            end
        end
        function obj = perform_ptd_analysis(obj, type)
            %%%percorre o vector de electric_model_objects e analiza
            %%%resultados da compensação
            %             type_of_analysis = {'analysis_1', 'analysis_2', 'analysis_3'};
            %             type = type_of_analysis{1};
            switch type
                case 'metrics'
                    fprintf('\ngenerating metrics\n');
                    tps_clusters = {'dense-dense', 'dense-sparse2', 'sparse-dense2', 'sparse-sparse'};
                    length_clusters = {'short-short', 'short-long2', 'long-short2', 'long-long'};
                    obj.results.tps_cluster = [];
                    
                    for it=1:size(tps_clusters,2)
                        for it2=1:size(length_clusters,2)
                            result_to_add.tps_cluster = tps_clusters{it};
                            result_to_add.length_cluster = length_clusters{it2};
                            obj = prepare_cluster(obj, tps_clusters{it}, length_clusters{it2});
                            result_to_add.metric = metrics_analysis(obj, obj.clustered_electric_model_objects); 
                            result_to_add.delta_tps_power_mu = result_to_add.metric.delta_sum_losses.mu;
                            result_to_add.delta_tps_power_sigma = result_to_add.metric.delta_sum_losses.sigma;
                            obj.results.tps_cluster = [obj.results.tps_cluster result_to_add];
                            fprintf('\nTPS: %s | length: %s | delta_tps_power mu: %.5f | delta_tps_power sigma: %.5f', tps_clusters{it}, length_clusters{it2}, result_to_add.metric.delta_sum_losses.mu, result_to_add.metric.delta_sum_losses.sigma);
                        end
                    end
                    
                    fprintf('\n\nmetrics generation completed\n');
                    all_metrics = metrics_analysis(obj, obj.electric_model_objects);
                    obj.results.all_metrics = all_metrics;%.metric;
                    obj.results.all_metrics.mu = all_metrics.delta_sum_losses.mu;
                    obj.results.all_metrics.sigma = all_metrics.delta_sum_losses.sigma;
                    obj.mcp_results = [obj.mcp_results obj.results];
                    fprintf('\naverage: mu: %.5f; sigma: %.5f\n', all_metrics.delta_sum_losses.mu, all_metrics.delta_sum_losses.sigma);
                    
                    
                case 'cluster'
                    fprintf('\nplotting cluster');
                    ptd_analysis_analysis_1(obj, obj.clustered_electric_model_objects);
                case 'all'
                    ptd_analysis_analysis_1(obj, obj.electric_model_objects);
                case 'analysis_1'
                    ptd_analysis_analysis_1(obj, obj.electric_model_objects);
                case 'nz_voltage'
                    nz_voltage_analysis(obj);
                case 'tps_power_before_after'
                    ptd_analysis_tps_power_before_after(obj);
                otherwise
                    fprintf('\ntype of analysis -- %s -- not available', string(type));
            end
            
            function metric = metrics_analysis(obj, objects_to_analyse)
                %objects_to_analyse = obj.electric_model_objects;
                position_tps1 = ones(1,size(objects_to_analyse,1)).*NaN;
                position_tps2 = ones(1,size(objects_to_analyse,1)).*NaN;
                sum_losses_init = ones(1,size(objects_to_analyse,1)).*NaN;
                sum_losses_end = ones(1,size(objects_to_analyse,1)).*NaN;
                delta_sum_losses = ones(1,size(objects_to_analyse,1)).*NaN;
%                 percentage_reduction = ones(1,size(objects_to_analyse,1)).*NaN;
%                 transferred_power = ones(1,size(objects_to_analyse,1)).*NaN;
%                 tps_power_before = ones(2,size(objects_to_analyse,1)).*NaN;
%                 tps_power_after = ones(2,size(objects_to_analyse,1)).*NaN;
%                 tps_delta_power_before = ones(1,size(objects_to_analyse,1)).*NaN;
%                 tps_delta_power_after = ones(1,size(objects_to_analyse,1)).*NaN;
                for iter = 1:size(objects_to_analyse,1)
                    %trains_pos(iter,:) = [[objects_to_analyse(iter, 1).tps(1).trains.abs_position] [objects_to_analyse(iter, 1).tps(2).trains.abs_position]];
                    position_tps1(iter) = 1;%monte_carlo_data(iter).initial.avg_weighed_position(1);
                    position_tps2(iter) = 2;%monte_carlo_data(iter).initial.avg_weighed_position(2);
                    if objects_to_analyse(iter, 1).last_matpower_result.success == 1
                        sum_losses_init(iter) = sum(objects_to_analyse(iter, 1).init_powerflow_result.apower_losses);
                        sum_losses_end(iter) = sum(objects_to_analyse(iter, 1).powerflow_result.apower_losses);
                        delta_sum_losses(iter) = sum_losses_end(iter)-sum_losses_init(iter);
%                         percentage_reduction(iter) = (sum_losses_end(iter)*100)/sum_losses_init(iter);
%                         transferred_power(iter) = objects_to_analyse(iter, 1).powerflow_result.transferred_power(1);
%                         tps_power_before(:,iter) = real(objects_to_analyse(iter, 1).init_powerflow_result.tps_power);
%                         tps_power_after(:,iter) = real(objects_to_analyse(iter, 1).powerflow_result.tps_power);
%                         tps_delta_power_before(iter) = tps_power_before(1,iter) - tps_power_before(2,iter);
%                         tps_delta_power_after(iter) = tps_power_after(1,iter) - tps_power_after(2,iter);
                    end
                end
                metric.delta_sum_losses = fitdist(delta_sum_losses','normal');
            end
            function nz_voltage_analysis(obj)
                position_tps1 = ones(1,size(obj.electric_model_objects,1)).*NaN;
                position_tps2 = ones(1,size(obj.electric_model_objects,1)).*NaN;
                sum_losses_init = ones(1,size(obj.electric_model_objects,1)).*NaN;
                sum_losses_end = ones(1,size(obj.electric_model_objects,1)).*NaN;
                delta_sum_losses = ones(1,size(obj.electric_model_objects,1)).*NaN;
                percentage_reduction = ones(1,size(obj.electric_model_objects,1)).*NaN;
                transferred_power = ones(1,size(obj.electric_model_objects,1)).*NaN;
                tps_power_before = ones(2,size(obj.electric_model_objects,1)).*NaN;
                tps_power_after = ones(2,size(obj.electric_model_objects,1)).*NaN;
                tps_delta_power_before = ones(1,size(obj.electric_model_objects,1)).*NaN;
                tps_delta_power_after = ones(1,size(obj.electric_model_objects,1)).*NaN;
                %%% for voltage
                nz_voltage_mag_before = ones(2,size(obj.electric_model_objects,1)).*NaN;
                nz_voltage_mag_after = ones(2,size(obj.electric_model_objects,1)).*NaN;
                nz_voltage_pha_before = ones(2,size(obj.electric_model_objects,1)).*NaN;
                nz_voltage_pha_after = ones(2,size(obj.electric_model_objects,1)).*NaN;
                nz_voltage_mag_delta = ones(2,size(obj.electric_model_objects,1)).*NaN;
                nz_voltage_pha_delta = ones(2,size(obj.electric_model_objects,1)).*NaN;
                nz_voltage_mag_delta_tps = ones(2,size(obj.electric_model_objects,1)).*NaN;
                nz_voltage_pha_delta_tps = ones(2,size(obj.electric_model_objects,1)).*NaN;
                
                for iter = 1:size(obj.electric_model_objects,1)
                    %trains_pos(iter,:) = [[obj.electric_model_objects(iter, 1).tps(1).trains.abs_position] [obj.electric_model_objects(iter, 1).tps(2).trains.abs_position]];
                    position_tps1(iter) = 1;%monte_carlo_data(iter).initial.avg_weighed_position(1);
                    position_tps2(iter) = 2;%monte_carlo_data(iter).initial.avg_weighed_position(2);
                    if obj.electric_model_objects(iter, 1).last_matpower_result.success == 1
                        sum_losses_init(iter) = sum(obj.electric_model_objects(iter, 1).init_powerflow_result.apower_losses);
                        sum_losses_end(iter) = sum(obj.electric_model_objects(iter, 1).powerflow_result.apower_losses);
                        delta_sum_losses(iter) = sum_losses_end(iter)-sum_losses_init(iter);
                        percentage_reduction(iter) = (sum_losses_end(iter)*100)/sum_losses_init(iter);
                        transferred_power(iter) = obj.electric_model_objects(iter, 1).powerflow_result.transferred_power(1);
                        tps_power_before(:,iter) = real(obj.electric_model_objects(iter, 1).init_powerflow_result.tps_power);
                        tps_power_after(:,iter) = real(obj.electric_model_objects(iter, 1).powerflow_result.tps_power);
                        tps_delta_power_before(iter) = tps_power_before(1,iter) - tps_power_before(2,iter);
                        tps_delta_power_after(iter) = tps_power_after(1,iter) - tps_power_after(2,iter);
                        %%% for voltage
                        nz_voltage_mag_before(:, iter) = 25.*obj.electric_model_objects(iter, 1).init_matpower_result.bus([4 7],8);
                        nz_voltage_mag_after(:, iter)  = 25.*obj.electric_model_objects(iter, 1).last_matpower_result.bus([4 7],8);
                        nz_voltage_pha_before(:, iter) = obj.electric_model_objects(iter, 1).init_matpower_result.bus([4 7],9);
                        nz_voltage_pha_after(:, iter)  = obj.electric_model_objects(iter, 1).last_matpower_result.bus([4 7],9);
                        nz_voltage_mag_delta(:, iter)  = nz_voltage_mag_after(:, iter)-nz_voltage_mag_before(:, iter);
                        nz_voltage_pha_delta(:, iter)  = nz_voltage_pha_after(:, iter)-nz_voltage_pha_before(:, iter);
                        nz_voltage_mag_delta_tps(:, iter)  = nz_voltage_mag_after(2, iter)-nz_voltage_mag_after(1, iter);
                        nz_voltage_pha_delta_tps(:, iter)  = nz_voltage_pha_after(2, iter)-nz_voltage_pha_after(1, iter);
                        
                    end
                end
                obj.ptd_results_fig_handler = [];
                
                
                %%% CRIA FIGURA histograma diferença voltage magnitude
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                histogram(nz_voltage_mag_delta_tps, 5e2);
                grid on; grid minor;
                xlabel('Voltage magnitude difference (in kV)');
                ylabel('Frequency');
                title('Voltage magnitude difference ("after-before" PTD)');
                
                %%% CRIA FIGURA histograma diferença voltage phase
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                histogram(nz_voltage_pha_delta_tps, 5e2);
                grid on; grid minor;
                xlabel('Voltage phase difference (in deg.)');
                ylabel('Frequency');
                title('Voltage phase difference ("after-before" PTD)');
                
                %%% CRIA FIGURA 2x2 power TPS before->after; histogram power TPS before->after
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position+600;
                obj.ptd_results_fig_handler(end).Position([2 3 4]) = [200 1200 900];
                subplot(2,2,1); hold on; grid on; grid minor;
                plot(tps_power_before(1,:), tps_power_before(2,:), '.', 'Color', 'k');
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("TPS active power before PTD");
                subplot(2,2,2); hold on; grid on; grid minor;
                plot(tps_power_after(1,:), tps_power_after(2,:), '.', 'Color', 'k');
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("TPS active power after PTD");
                subplot(2,2,3); hold on; grid on; grid minor;
                histogram(tps_delta_power_before, 2e2);
                xlabel('Delta TPS power (MW)'); ylabel('frequency');
                title("TPS active power difference before PTD");
                subplot(2,2,4); hold on; grid on; grid minor;
                histogram(tps_delta_power_after, 2e2);
                xlabel('Delta TPS power (MW)'); ylabel('frequency');
                title("TPS active power difference after PTD");
                
                %%% GENERATE plot_scatter_contour_POSvsLOSS (tps_power_before(1,:), tps_power_before(2,:), delta_sum_losses);
                %%% CRIA FIGURA histograma diferença pwr
                %                     fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                %                     plot_scatter_contour_POSvsLOSS (tps_power_before(1,:), tps_power_before(2,:), delta_sum_losses);
                
                %%% CRIA FIGURA 1x2 system power losses before->after
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                obj.ptd_results_fig_handler(end).Position([2 3 4]) = [200 600 900];
                subplot(2,1,1); hold on; grid on; grid minor;
                scatter(tps_power_before(1,:), tps_power_before(2,:), [], sum_losses_init, '.');
                c1 = colorbar; c1.Title.String = 'Losses (MW)';
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("power losses before PTD");
                subplot(2,1,2); hold on; grid on; grid minor;
                scatter(tps_power_before(1,:), tps_power_before(2,:), [], sum_losses_end, '.');
                c2 = colorbar; c2.Title.String = 'Losses (MW)';
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("power losses after PTD");
                
                %%% CRIA FIGURA potência transferida PTD
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                obj.ptd_results_fig_handler(end).Position([2 3 4]) = [200 600 900];
                subplot(2,1,1); hold on; grid on; grid minor;
                scatter(tps_power_before(1,:), tps_power_before(2,:), [], transferred_power, '.');
                c3 = colorbar; c3.Title.String = 'Power (MW)';
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("Transferred power by PTD");
                %%% CRIA FIGURA diferença pwr vs perdas catenaria
                subplot(2,1,2); hold on; grid on; grid minor;
                plot(transferred_power, delta_sum_losses, '.', 'Color', 'k');
                xlabel('transferred power (MW) from TPS1 to TPS2');
                ylabel('System power losses difference (after-before, in MW)');
                title({"Evaluation of reduction of power, as function of the transferred power","(the lower, the better)"});
                grid on; grid minor;
            end
            function ptd_analysis_analysis_1(obj, objects_to_analyse)
                %objects_to_analyse = obj.electric_model_objects;
                position_tps1 = ones(1,size(objects_to_analyse,1)).*NaN;
                position_tps2 = ones(1,size(objects_to_analyse,1)).*NaN;
                train_power_tps1 = ones(1,size(objects_to_analyse,1)).*NaN;
                train_power_tps2 = ones(1,size(objects_to_analyse,1)).*NaN;
                
                sum_losses_init = ones(1,size(objects_to_analyse,1)).*NaN;
                sum_losses_end = ones(1,size(objects_to_analyse,1)).*NaN;
                delta_sum_losses = ones(1,size(objects_to_analyse,1)).*NaN;
                percentage_reduction = ones(1,size(objects_to_analyse,1)).*NaN;
                transferred_power = ones(1,size(objects_to_analyse,1)).*NaN;
                tps_power_before = ones(2,size(objects_to_analyse,1)).*NaN;
                tps_power_after = ones(2,size(objects_to_analyse,1)).*NaN;
                tps_delta_power_before = ones(1,size(objects_to_analyse,1)).*NaN;
                tps_delta_power_after = ones(1,size(objects_to_analyse,1)).*NaN;
                for iter = 1:size(objects_to_analyse,1)
                    %trains_pos(iter,:) = [[objects_to_analyse(iter, 1).tps(1).trains.abs_position] [objects_to_analyse(iter, 1).tps(2).trains.abs_position]];
                    if ~isempty(obj.electric_model_objects(iter,1).tps(1).trains)
                        position_tps1(iter) = mean([obj.electric_model_objects(iter,1).tps(1).trains.position]);%1;%monte_carlo_data(iter).initial.avg_weighed_position(1);
                        train_power_tps1(iter) = mean([obj.electric_model_objects(iter,1).tps(1).trains.apower]);
                    end
                    if ~isempty(obj.electric_model_objects(iter,1).tps(2).trains)
                        position_tps2(iter) = mean([obj.electric_model_objects(iter,1).tps(2).trains.position]);%monte_carlo_data(iter).initial.avg_weighed_position(2);
                        train_power_tps2(iter) = mean([obj.electric_model_objects(iter,1).tps(2).trains.apower]);
                    end
                    if objects_to_analyse(iter, 1).last_matpower_result.success == 1
                        sum_losses_init(iter) = sum(objects_to_analyse(iter, 1).init_powerflow_result.apower_losses);
                        sum_losses_end(iter) = sum(objects_to_analyse(iter, 1).powerflow_result.apower_losses);
                        delta_sum_losses(iter) = sum_losses_end(iter)-sum_losses_init(iter);
                        percentage_reduction(iter) = (sum_losses_end(iter)*100)/sum_losses_init(iter);
                        transferred_power(iter) = objects_to_analyse(iter, 1).powerflow_result.transferred_power(1);
                        tps_power_before(:,iter) = real(objects_to_analyse(iter, 1).init_powerflow_result.tps_power);
                        tps_power_after(:,iter) = real(objects_to_analyse(iter, 1).powerflow_result.tps_power);
                        tps_delta_power_before(iter) = tps_power_before(1,iter) - tps_power_before(2,iter);
                        tps_delta_power_after(iter) = tps_power_after(1,iter) - tps_power_after(2,iter);
                    end
                end
                obj.ptd_results_fig_handler = [];
                
                
                %%% CRIA FIGURA histograma diferença pwr
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                histogram(delta_sum_losses, 5e2);
                grid on; grid minor;
                xlabel('Power losses difference (in MW)');
                ylabel('Frequency');
                title('Power losses difference ("after-before" PTD)');
                
                %%% CRIA FIGURA losses train1_position pwr
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                obj.ptd_results_fig_handler(end).Position([2 3 4]) = [200 900 700];
                subplot(2,1,1); plot(position_tps1, delta_sum_losses, '.');
                grid on; grid minor;
                ylabel('Power losses difference ("after-before" PTD)');
                xlabel('Train 1 position (in percentage of branch length)');
                title('Power losses difference ("after-before" PTD) as function of train 1 position');
                subplot(2,1,2); plot(position_tps2, delta_sum_losses, '.');
                grid on; grid minor;
                ylabel('Power losses difference ("after-before" PTD)');
                xlabel('Train 2 position (in percentage of branch length)');
                title('Power losses difference ("after-before" PTD) as function of train 2 position');
                %%%fitting to curve: para análise atómica
%                 [xData, yData] = prepareCurveData( position_tps1, delta_sum_losses);
%                 [fitresult, ~] = fit( xData, yData, fittype( 'poly2' ) );
%                 coeff = coeffvalues(fitresult);
%                 x_crossing = (-coeff(2) - sqrt(coeff(2)^2-4*coeff(1)*coeff(3)))/(2*coeff(1));
%                 hold on; plot([x_crossing x_crossing], [min(delta_sum_losses), max(delta_sum_losses)]);
%                 text(x_crossing, sum([min(delta_sum_losses), max(delta_sum_losses)])*0.5, strcat('f(x)=0: x=', num2str(x_crossing)));
%                 text(sum([min(position_tps1), max(position_tps1)])*0.4, sum([min(delta_sum_losses), max(delta_sum_losses)])*0.6, ...
%                     strcat('f(x) = ', num2str(coeff(1), '%.2f'), 'x^2 + ',num2str(coeff(2), '%.2f'), 'x + ',num2str(coeff(3), '%.2f')), 'Rotation',-30);
                
                
                
                
                %%% CRIA FIGURA losses train1_position train2_position vs pwr
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                obj.ptd_results_fig_handler(end).Position([2 3 4]) = [200 900 700];
                %plot(position_tps1, delta_sum_losses, '.');
                hold on; grid on; grid minor;
                if sum(sum(isnan(position_tps1)))>0 ||  sum(sum(isnan(position_tps2)))>0 
                    text(0.5, 0.5, 'MISSING "random" TRAINS in TPS1 or TPS2');
                else
                scatter(position_tps1, position_tps2, [], delta_sum_losses, '.'); 
                gray_color = gray(255); colormap(gray_color(30:225,:)); c2 = colorbar; c2.Title.String = 'Losses (MW)';
                [X,Y] = meshgrid(linspace(min(position_tps1),max(position_tps1),100), linspace(min(position_tps2),max(position_tps2),100));
                [C,h] =  contour(X,Y,griddata(position_tps1,position_tps2,delta_sum_losses,X,Y), -1:0.001:1, 'LineWidth', 1.5);
                clabel(C,h);
                end
                %ylabel('after PTD power losses'); xlabel('before PTD power losses')
                ylabel('Train 2 position (in percentage of branch length)');
                xlabel('Train 1 position (in percentage of branch length)');
                title('Power losses difference ("after-before" PTD) as function of train 1 and train 2 position');
                
                  %%% CRIA FIGURA losses train1_position train1_power vs losses_pwr
                 obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                 obj.ptd_results_fig_handler(end).Position([2 3 4]) = [200 900 700];
                 hold on; grid on; grid minor;
                 ylabel('Train 1 power (in MW)');
                 xlabel('Train 1 position (in percentage of branch length)');
                 title('Power losses difference ("after-before" PTD) as function of train 1 position and power');
                 if (max(train_power_tps1) -min(train_power_tps1)) <= 1e-6
                     text(0.5, 0.5, 'TPS1 train power is fixed');
                 else
                     scatter(position_tps1, train_power_tps1, [], delta_sum_losses, '.');
                     gray_color = gray(255); colormap(gray_color(30:225,:)); c2 = colorbar; c2.Title.String = 'Losses (MW)';
                     [X,Y] = meshgrid(linspace(min(position_tps1),max(position_tps1),100), linspace(min(train_power_tps1),max(train_power_tps1),100));
                     [C,h] =  contour(X,Y,griddata(position_tps1,train_power_tps1,delta_sum_losses,X,Y), -1:0.05:1, 'LineWidth', 1.5);
                     clabel(C,h);
                 end



                
                %%% CRIA FIGURA 2x2 power TPS before->after; histogram power TPS before->after
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position+600;
                obj.ptd_results_fig_handler(end).Position([2 3 4]) = [200 1200 900];
                subplot(2,2,1); hold on; grid on; grid minor;
                plot(tps_power_before(1,:), tps_power_before(2,:), '.', 'Color', 'k');
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("TPS active power before PTD");
                subplot(2,2,2); hold on; grid on; grid minor;
                plot(tps_power_after(1,:), tps_power_after(2,:), '.', 'Color', 'k');
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("TPS active power after PTD");
                subplot(2,2,3); hold on; grid on; grid minor;
                histogram(tps_delta_power_before, 2e2);
                xlabel('Delta TPS power (MW)'); ylabel('frequency');
                title("TPS active power difference before PTD");
                subplot(2,2,4); hold on; grid on; grid minor;
                histogram(tps_delta_power_after, 2e2);
                xlabel('Delta TPS power (MW)'); ylabel('frequency');
                title("TPS active power difference after PTD");
                
                %%% GENERATE plot_scatter_contour_POSvsLOSS (tps_power_before(1,:), tps_power_before(2,:), delta_sum_losses);
                %%% CRIA FIGURA histograma diferença pwr
                %                     fig_handler = [fig_handler figure]; fig_handler(end).Position(1) = obj.figure_monitor_position;
                %                     plot_scatter_contour_POSvsLOSS (tps_power_before(1,:), tps_power_before(2,:), delta_sum_losses);
                
                %%% CRIA FIGURA 1x2 system power losses before->after
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                obj.ptd_results_fig_handler(end).Position([2 3 4]) = [200 600 900];
                subplot(2,1,1); hold on; grid on; grid minor;
                scatter(tps_power_before(1,:), tps_power_before(2,:), [], sum_losses_init, '.');
                c1 = colorbar; c1.Title.String = 'Losses (MW)';
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("power losses before PTD");
                subplot(2,1,2); hold on; grid on; grid minor;
                scatter(tps_power_before(1,:), tps_power_before(2,:), [], sum_losses_end, '.');
                c2 = colorbar; c2.Title.String = 'Losses (MW)';
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("power losses after PTD");
                
                %%% CRIA FIGURA potência transferida PTD
                obj.ptd_results_fig_handler = [obj.ptd_results_fig_handler figure]; obj.ptd_results_fig_handler(end).Position(1) = obj.figure_monitor_position;
                obj.ptd_results_fig_handler(end).Position([2 3 4]) = [200 600 900];
                subplot(2,1,1); hold on; grid on; grid minor;
                scatter(tps_power_before(1,:), tps_power_before(2,:), [], transferred_power, '.');
                c3 = colorbar; c3.Title.String = 'Power (MW)';
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("Transferred power by PTD");
                %%% CRIA FIGURA diferença pwr vs perdas catenaria
                subplot(2,1,2); hold on; grid on; grid minor;
                plot(transferred_power, delta_sum_losses, '.', 'Color', 'k');
                xlabel('transferred power (MW) from TPS1 to TPS2');
                ylabel('System power losses difference (after-before, in MW)');
                title({"Evaluation of reduction of power, as function of the transferred power","(the lower, the better)"});
                grid on; grid minor;
            end
            function ptd_analysis_tps_power_before_after(obj)
                position_tps1 = ones(1,size(obj.electric_model_objects,1)).*NaN;
                position_tps2 = ones(1,size(obj.electric_model_objects,1)).*NaN;
                sum_losses_init = ones(1,size(obj.electric_model_objects,1)).*NaN;
                sum_losses_end = ones(1,size(obj.electric_model_objects,1)).*NaN;
                delta_sum_losses = ones(1,size(obj.electric_model_objects,1)).*NaN;
                percentage_reduction = ones(1,size(obj.electric_model_objects,1)).*NaN;
                transferred_power = ones(1,size(obj.electric_model_objects,1)).*NaN;
                tps_power_before = ones(2,size(obj.electric_model_objects,1)).*NaN;
                tps_power_after = ones(2,size(obj.electric_model_objects,1)).*NaN;
                tps_delta_power_before = ones(1,size(obj.electric_model_objects,1)).*NaN;
                tps_delta_power_after = ones(1,size(obj.electric_model_objects,1)).*NaN;
                for iter = 1:size(obj.electric_model_objects,1)
                    %trains_pos(iter,:) = [[obj.electric_model_objects(iter, 1).tps(1).trains.abs_position] [obj.electric_model_objects(iter, 1).tps(2).trains.abs_position]];
                    position_tps1(iter) = 1;%monte_carlo_data(iter).initial.avg_weighed_position(1);
                    position_tps2(iter) = 2;%monte_carlo_data(iter).initial.avg_weighed_position(2);
                    if obj.electric_model_objects(iter, 1).last_matpower_result.success == 1
                        sum_losses_init(iter) = sum(obj.electric_model_objects(iter, 1).init_powerflow_result.apower_losses);
                        sum_losses_end(iter) = sum(obj.electric_model_objects(iter, 1).powerflow_result.apower_losses);
                        delta_sum_losses(iter) = sum_losses_end(iter)-sum_losses_init(iter);
                        percentage_reduction(iter) = (sum_losses_end(iter)*100)/sum_losses_init(iter);
                        transferred_power(iter) = obj.electric_model_objects(iter, 1).powerflow_result.transferred_power(1);
                        tps_power_before(:,iter) = real(obj.electric_model_objects(iter, 1).init_powerflow_result.tps_power);
                        tps_power_after(:,iter) = real(obj.electric_model_objects(iter, 1).powerflow_result.tps_power);
                        tps_delta_power_before(iter) = tps_power_before(1,iter) - tps_power_before(2,iter);
                        tps_delta_power_after(iter) = tps_power_after(1,iter) - tps_power_after(2,iter);
                    end
                end
                
                fig1 = figure;
                fig1.Position(1) = 1980;
                subplot(2,2,1); hold on; grid on; grid minor;
                plot(tps_power_before(1,:), tps_power_before(2,:), '.', 'Color', 'k');
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("TPS active power before PTD");
                subplot(2,2,2); hold on; grid on; grid minor;
                plot(tps_power_after(1,:), tps_power_after(2,:), '.', 'Color', 'k');
                xlabel('TPS 1 power (MW)'); ylabel('TPS 2 power (MW)');
                title("TPS active power after PTD");
                
                %                     fig2 = figure;
                %                     fig2.Position(1) = 1980;
                subplot(2,2,3); hold on; grid on; grid minor;
                histogram(tps_delta_power_before, 2e2);
                xlabel('Delta TPS power (MW)'); ylabel('frequency');
                title("TPS active power difference before PTD");
                subplot(2,2,4); hold on; grid on; grid minor;
                histogram(tps_delta_power_after, 2e2);
                xlabel('Delta TPS power (MW)'); ylabel('frequency');
                title("TPS active power difference after PTD");
            end
            function plot_scatter_contour_POSvsLOSS (position_tps1, position_tps2, losses)
                %%% produz um gráfico 2D color, em que X e Y é a posição média dos comboios
                %%% de cada lado; a cor corresponde ao valor das perdas
                
                scatter(position_tps1, position_tps2, 15, losses, 'filled');
                gray_color = gray(255);
                colormap(gray_color(30:225,:));
                colorbar;
                
                x = position_tps1;
                y = position_tps2;
                z = losses;
                max_Z = (max(max(z))-min(min(z)))/10;
                min_Z = min(min(z));
                [X,Y] = meshgrid(linspace(min(x),max(x),100), linspace(min(y),max(y),100));
                [C,h] =  contour(X,Y,griddata(x,y,z,X,Y), round((min_Z:max_Z:min_Z+max_Z*10)), 'LineWidth', 1.5);
                clabel(C,h);
            end
        end
        function obj = prepare_cluster(obj, tps_type, length_type)
            obj.clustered_electric_model_objects = obj.electric_model_objects;
            indexes = [];
            switch tps_type
                case 'all_tps_clusters'
                case 'dense-dense'
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).tps_cluster , 'dense') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).tps_cluster , 'dense')
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'dense-sparse'
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if (strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).tps_cluster , 'sparse') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).tps_cluster , 'dense')) ||...
                                (strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).tps_cluster , 'dense') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).tps_cluster , 'sparse'))
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'dense-sparse2'
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if (strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).tps_cluster , 'dense') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).tps_cluster , 'sparse'))
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'sparse-dense2'
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if (strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).tps_cluster , 'sparse') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).tps_cluster , 'dense'))
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'sparse-sparse'
                    indexes = [];
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).tps_cluster , 'sparse') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).tps_cluster , 'sparse')
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'otherwise'
                    fprintf("\nwrong tps cluster");
            end
            indexes = [];
            switch length_type
                case 'all_tps_lengths'
                case 'long-long'
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).length_cluster , 'long') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).length_cluster , 'long')
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'long-short'
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).length_cluster , 'long') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).length_cluster , 'short') ||...
                                strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).length_cluster , 'short') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).length_cluster , 'long')
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'long-short2'
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).length_cluster , 'long') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).length_cluster , 'short')
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'short-long2'
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).length_cluster , 'short') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).length_cluster , 'long')
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'short-short'
                    for iter = 1: size(obj.clustered_electric_model_objects,1)
                        if strcmp(obj.clustered_electric_model_objects(iter, 1).tps(1).length_cluster , 'short') && strcmp(obj.clustered_electric_model_objects(iter, 1).tps(2).length_cluster , 'short')
                            indexes = [indexes iter];
                        end
                    end
                    obj.clustered_electric_model_objects = obj.clustered_electric_model_objects(indexes, 1);
                case 'otherwise'
                    fprintf("\nwrong tps length");
            end
        end
        function obj = aux_test_statistics(obj, type, max_iter)
            %%% AUX: this method is only to test/evaluate the statistics generation
            electric_model_objects_ = repmat(electric_model, max_iter, 1);
            parfor_progress(round(max_iter/10));
            parfor_mon = ParforProgressbar(round(max_iter/10), 'parpool', {'local', 4}, 'showWorkerProgress', true);
            tic;
            %%%%%%%%%%%%%  RUN PARFOR
            parfor iter = 1:max_iter
                electric_model_objects_(iter) = electric_model_objects_(iter).reset_model();
                electric_model_objects_(iter) = electric_model_objects_(iter).generate_random_trains();
                %electric_model_objects_(iter) = electric_model_objects_(iter).add_random_trains();
                %%%monitorizar execução MONTE CARLO
                if mod(iter, 10) == 0 , pause(0.01); parfor_progress; parfor_mon.increment(); end
            end
            delete(parfor_mon); parfor_progress(0);
            
            obj.electric_model_objects = electric_model_objects_;
            toc;
            %obj = obj.perform_statistical_analysis(type);
        end
        function obj = load_monte_carlo(obj)
            fprintf("\n\n select path to .mat files\n");
            folder_path = uigetdir();
            
            fprintf("\n listing files...\n");
            mat_file_list = ls(fullfile(folder_path, '*.mat'));
            prompt = {'Information About simulation result file Selected:'; ...
                'Press Ok button to continue...'};
            dlg_title = 'Select file to process';
            database_information = mat_file_list;
            file_to_process = listdlg('PromptString', prompt,...
                'Name', dlg_title, 'ListSize', [560 200], ...
                'ListString', database_information, ...
                'SelectionMode', 'single', ...
                'CancelString','Cancel');
            
            file_to_load = strcat(folder_path, '\', strtrim(mat_file_list(file_to_process, :)));
            saved_object = load(file_to_load);
            saved_object = saved_object.obj;
            obj = saved_object; %%% WARNING: all data might be destroyed!
        end
        function obj = save_monte_carlo(obj)
            fprintf("\n\n select path to save .mat files\n");
            folder_path = uigetdir();
            filename = inputdlg({'filename'}, 'Enter filename', [1 75], {'monte_carlo_analysis'});
            file_to_save = strcat(folder_path, '\', filename{1});
            object_to_save = obj;
            save(file_to_save, 'obj', '-v7.3');
        end
        function split_results(obj)
            fprintf("\n\n select path to save .mat files\n");
            folder_path = uigetdir();
            filename = inputdlg({'filename'}, 'Enter filename', [1 75], {'monte_carlo_analysis'});
            file_to_save = strcat(folder_path, '\', filename{1});
            for iter=1:round(size(obj.electric_model_objects,1)/1e4)
                object_to_save = obj;
                object_to_save.clustered_electric_model_objects=[];
                object_to_save.electric_model_objects = object_to_save.electric_model_objects(((iter-1)*1e4)+1:1:(iter)*1e4);
                save(strcat(file_to_save,'_', num2str(iter)), 'object_to_save', '-v7.3');
            end
            
            
        end
        function obj = update_random_status(obj)
            
        end
        function obj = eval_mc_performance(obj, type, max_iter, parallelism_status, cluster_type_length)
            %method to evaluate the evolution of the metrics for a specific
            %cluster (?)
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
    end
end

