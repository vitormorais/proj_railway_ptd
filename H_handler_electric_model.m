%clear;
%close all;

numIterations = 1e5;

electric_model_objects = repmat(electric_model, numIterations, 1);
monte_carlo_data = repmat(struct('iter', [], 'input', [], 'initial', [], 'final', []), numIterations, 1);


parfor_progress(round(numIterations/10));
parfor_mon = ParforProgressbar(round(numIterations/10), 'parpool', {'local', 4}, 'showWorkerProgress', true);
tic;

parfor iter = 1:numIterations
    electric_model_objects(iter) = electric_model_objects(iter).reset_model(); %% cleans the object properties
    electric_model_objects(iter) = electric_model_objects(iter).generate_random_trains([3 3]);
%     electric_model_objects(iter) = electric_model_objects(iter).add_random_trains();
%    
%     %%%lança simulação::: while 1?
%     electric_model_objects(iter) = electric_model_objects(iter).run_powerflow();
%     electric_model_objects(iter) = electric_model_objects(iter).process_output();
%     monte_carlo_data(iter).iter = iter;
%     monte_carlo_data(iter).input = electric_model_objects(iter).sim_input_data;
%     monte_carlo_data(iter).initial = electric_model_objects(iter).powerflow_result();
%     %%performs compensation
%     electric_model_objects(iter) = electric_model_objects(iter).power_transfer_device_compensation();  
%     electric_model_objects(iter) = electric_model_objects(iter).run_powerflow();
%     electric_model_objects(iter) = electric_model_objects(iter).process_output();
%     monte_carlo_data(iter).final = electric_model_objects(iter).powerflow_result();
    
    %%%monitorizar execução MONTE CARLO
    if mod(iter, 10) == 0 , pause(0.01); parfor_progress; parfor_mon.increment(); end
end

toc;
delete(parfor_mon);

sum_losses_init = [];
sum_losses_end = [];
delta_sum_losses = [];
percentage_reduction = [];
%%%process losses result
for iter = 1:numIterations
    sum_losses_init = [sum_losses_init sum(monte_carlo_data(iter).initial.apower_losses)];
    sum_losses_end = [sum_losses_end sum(monte_carlo_data(iter).final.apower_losses)];
    delta_sum_losses = [delta_sum_losses sum_losses_end(iter)-sum_losses_init(iter)];
    percentage_reduction = [percentage_reduction (sum_losses_end(iter)*100)/sum_losses_init(iter)];
end
figure; hold on; plot(sum_losses_init);plot(sum_losses_end); 
figure; plot(delta_sum_losses);
figure; histogram(delta_sum_losses, 2e2);


