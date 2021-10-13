

A Railway Power System Scenario Simulation tool based on Monte Carlo Analysis
-----------------------------------------------------------------------------

This repository comprises two MATLAB classes: **MONTE_CARLO.m** and **electric_model.m** capable of snapshot simulation of a railway line.
The implemented framework depends on MATPOWER for power flow solver.


### Current Development Version
There are two options:
1. Clone the repository from GitHub.
2. Download a ZIP file of the repository from GitHub.


### System Requirements
*   MATLAB version 9.4 (R2018a) or later
*   (older versions might not be compatible with the GUI)
*   Statistics toolbox
*   Parallelism toolbox

------------
### Instalation
Installation and use of this framework requires familiarity with the basic
operation of MATLAB or Octave.
1. The instalation only requires download of the repository.


### Usage
The simplest way to run the framework is to use the GUI. 
1. Open the matlab with the workspace in the cloned repository;
2. Open the file **GUI_montecarlo.mlapp**
3. This GUI is the main handler for the **MONTE_CARLO.m** and **electric_model.m** classes.

Alternativelly, the **electric_model.m** class can be used as following:

    electric_model = electric_model;  %%% creates a new object
    electric_model = electric_model.set_random_status('default');
    electric_model = electric_model.update_electric_model_parameters('default');
    electric_model = electric_model.reset_model();
    electric_model = electric_model.generate_random_trains();
    electric_model = electric_model.run_powerflow();
    electric_model = electric_model.process_output();
    electric_model = electric_model.attach_power_transfer_device();
    electric_model = electric_model.tps_power_optimization();

------------
### Documentation and Manuals
Under construction

### Dependencies
This toolbox depends on the following third-party tools
*   **MATPOWER**: Free, open-source tools for electric power system simulation and optimization 
https://matpower.org/
*   **ParforProgressbar**: PARFOR progress monitor (progress bar) v4 
https://www.mathworks.com/matlabcentral/fileexchange/71436-parfor-progress-monitor-progress-bar-v4
*   **PARFOR_PROGRESS**: Progress monitor (progress bar) that works with parfor
https://www.mathworks.com/matlabcentral/fileexchange/32101-progress-monitor-progress-bar-that-works-with-parfor

### Citing framework
All publications derived from the use of this framework, or the included data
files, should cite:
>   Morais, V. A.; and Martins, A. P. (2021) "Traction Power Substation Balance and Losses Estimation in AC Railways
    using a Power Transfer Device through Monte Carlo Analysis". In Railway Engineering Science (261) 
    doi: [10.1007/s40534-021-00261-y][1]
    
    
[1]: https://doi.org/10.1007/s40534-021-00261-y]

