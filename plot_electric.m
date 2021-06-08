classdef plot_electric
    %PLOT_ELECTRIC Class for the plot of the electric diagram of the
    %railway electric model
    %
    %   This dinamic class can be attached to the electric model object,
    %   where is required the tps_data, mpc_data and tps_lenghts to plot
    %   all the electric diagram. 
    %   This class was tested to two TPS, having one PTD connected. Was
    %   also tested for two TPS for the two branches of the ascendent
    %   direction line. (not ready YET for double-track railway lines)
    %   USAGE:
    %   plot_electric_object = plot_electric;
    %   plot_electric_object = plot_electric_object.attach_electric_model(obj.tps, obj.global_model_mpc, obj.tps_lenghts);
    %   plot_electric_object = plot_electric_object.plot_electric_data();
    
    properties
        fig
        size_of_diagram
        row_start
        row_step
        pos_start
        sst_row_no
        trains2plot
        tps_data
        mpc_data
        tps_lenghts 
    end
    
    methods
        function obj = plot_electric()
            %PLOT_ELECTRIC Construct an instance of this class
            %   Detailed explanation goes here
        end
        
        function obj = attach_electric_model(obj,tps_data, mpc_data, tps_lenghts)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.tps_data = tps_data;
            obj.mpc_data = mpc_data;
            obj.tps_lenghts = tps_lenghts;
        end
        function obj = plot_electric_data(obj)
            obj.fig = figure; hold on;
            plot_side = 0;  %%% para plots no segundo ecrã
            obj.fig.Position = [plot_side+100 100 800+400*1 900];
            xlim([0 30+70*1]); ylim([0 200]);

            obj.row_start = 150;
            obj.row_step = 40;
            obj.pos_start = 20;
            obj.sst_row_no = 150;
            obj.trains2plot = 3;
            for tps_no=1:size(obj.tps_data, 2)
                obj.plot_tps(tps_no);
            end
        end
        function obj = plot_tps(obj, tps_no)
            
            lw = 0.75;%linewidth
            offset = (tps_no-1)*90+20;
            plot_oval(9.5, offset+10, 1.3, 3);
            text(8.75, offset+10, '~', 'FontSize', 15);
            plot([9.5 9.5], [offset+7 offset+0], 'LineWidth', lw, 'Color', [0 0 0]);
            plot([8 12], [offset offset], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus
            text(3, offset+3, strcat("TPS ", num2str(tps_no)), 'FontSize', 8, 'Color', [0.6 0.6 0.6]);
            text(9, offset-10, strcat("bus", num2str((tps_no-1)*4+1)), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
            
            obj = obj.plot_branch(10, offset); % plot branch
            plot([18 22], [offset offset], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus %plot busK+2
            text(19, offset-10, strcat("bus", num2str((tps_no-1)*4+2)), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
            %obj = obj.plot_branch_info (obj.tps_data(tps_no).trains(tps_trains), 12+10*train_id, offset+9);
            text(12, offset+9, strcat("br[", num2str((tps_no-1)*3+1),"]: ", num2str((tps_no-1)*4+1), "-", num2str((tps_no-1)*4+2)), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
            
            %plot([20.5 20.5], [offset offset+60], 'LineWidth', lw, 'Color', [0 0 0]); %% nota: para 4 ramos
            plot([20.5 20.5], [offset offset+40], 'LineWidth', lw, 'Color', [0 0 0]);
            obj = obj.plot_branch(20, offset); % plot branch
            obj = obj.plot_branch(20, offset+40); % plot branch
%             obj = obj.plot_branch(20, offset+40); % plot branch
%             obj = obj.plot_branch(20, offset+60); % plot branch
            section_asc_left = 1; section_asc_right = 1;
            %section_desc_right = 1; section_desc_left = 1;
            max_trains_asc_left = 0; max_trains_asc_right=0;
            for tps_trains=1:size(obj.tps_data(tps_no).trains,2) %%%%%%%%%%%%%%%% count trains in each section
                switch obj.tps_data(tps_no).trains(tps_trains).dir
                    case 'asc'
                        switch obj.tps_data(tps_no).trains(tps_trains).section
                            case 'left_section'
                                max_trains_asc_left = max_trains_asc_left+1;
                            case 'right_section'
                                max_trains_asc_right = max_trains_asc_right+1;
                        otherwise
                            fprintf('error: wrong section');
                        end
                    case 'desc'
                    otherwise
                        fprintf('error: wrong direction');
                end
            end
             if max_trains_asc_left == 0
                text(30, offset-15, strcat('no left trains asc'), 'FontSize', 8, 'Color', [0.8 0 0]);
                text(30, offset-18, strcat("TPS branch lenght: ", num2str(obj.tps_lenghts(tps_no,1)), " km"), 'FontSize', 8, 'Color', [0.6 0.6 0.6]);
                plot([28 32], [offset offset], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus %plot busK+2
                text(29, offset-10, strcat("bus", num2str(obj.tps_data(tps_no).bus_index(3))), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                text(22, offset+9, strcat("br[", num2str((tps_no-1)*3+2),"]: ", num2str((tps_no-1)*4+2), "-", num2str((tps_no-1)*4+3)), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
             end
             if max_trains_asc_right == 0
                text(30, offset+40-15, strcat('no right trains asc'), 'FontSize', 8, 'Color', [0.8 0 0]);
                text(30, offset+40-18, strcat("TPS branch right: ", num2str(obj.tps_lenghts(tps_no,2)), " km"), 'FontSize', 8, 'Color', [0.6 0.6 0.6]);
                plot([28 32], [offset+40 offset+40], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus %plot busK+2
                text(29, offset+40-10, strcat("bus", num2str(obj.tps_data(tps_no).bus_index(4))), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                text(22, offset+9+40, strcat("br[", num2str((tps_no-1)*3+3),"]: ", num2str((tps_no-1)*4+2), "-", num2str((tps_no-1)*4+4)), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
             end
            %%%%%%%%%%%%%%%%% plot trains of both sections
            if ~isempty(obj.tps_data(tps_no).trains)
                for tps_trains=1:size(obj.tps_data(tps_no).trains,2)
                    switch obj.tps_data(tps_no).trains(tps_trains).dir
                        case 'asc'
                            switch obj.tps_data(tps_no).trains(tps_trains).section
                                case 'left_section'
                                    train_id = section_asc_left;
                                    plot([20+10*train_id-2 20+10*train_id+2], [offset offset], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus %plot busK+2
                                    %text(19+10*train_id, offset-10, strcat("bus", num2str(obj.tps_data(tps_no).bus_index(4+train_id))), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                                    text(19+10*train_id, offset-10, strcat("bus", num2str(obj.tps_data(tps_no).trains(tps_trains).bus_no)), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                                    obj = obj.plot_branch(20+10*train_id, offset);
                                    obj = obj.plot_train_info(obj.tps_data(tps_no).trains(tps_trains), 21+10*train_id, offset);
                                    obj = obj.plot_branch_info (obj.tps_data(tps_no).trains(tps_trains), 12+10*train_id, offset+9);
                                    if section_asc_left == 1
                                        text(30, offset-15, strcat('left trains asc'), 'FontSize', 8, 'Color', [0.8 0 0]);
                                        text(30, offset-18, strcat("TPS branch lenght: ", num2str(obj.tps_lenghts(tps_no,1)), " km"), 'FontSize', 8, 'Color', [0.6 0.6 0.6]);
                                    end
                                    if section_asc_left == max_trains_asc_left
                                        plot([30+10*train_id-2 30+10*train_id+2], [offset offset], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus %plot busK+2
                                        text(29+10*train_id, offset-10, strcat("bus", num2str(obj.tps_data(tps_no).bus_index(3))), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                                        text(22+10*train_id, offset+9, strcat("br[", num2str(obj.tps_data(tps_no).trains(tps_trains).branch_right),"]: ", num2str(obj.mpc_data.branch(obj.tps_data(tps_no).trains(tps_trains).branch_right,1)), "-", num2str(obj.mpc_data.branch(obj.tps_data(tps_no).trains(tps_trains).branch_right,2))), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
                                    end
                                    section_asc_left  = section_asc_left +1;
                                case 'right_section'
                                    train_id = section_asc_right;
                                    plot([20+10*train_id-2 20+10*train_id+2], [offset+40 offset+40], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus %plot busK+2
                                    %text(19+10*train_id, offset+30-10, strcat("bus", num2str(obj.tps_data(tps_no).bus_index(4+train_id))), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                                    text(19+10*train_id, offset+40-10, strcat("bus", num2str(obj.tps_data(tps_no).trains(tps_trains).bus_no)), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                                    obj = obj.plot_branch(20+10*train_id, offset+40);
                                    obj = obj.plot_train_info(obj.tps_data(tps_no).trains(tps_trains), 21+10*train_id, offset+40);
                                    obj = obj.plot_branch_info (obj.tps_data(tps_no).trains(tps_trains), 12+10*train_id, offset+49);
                                    %obj = obj.plot_train_info(obj.tps_data(tps_no).trains_right, train_id, 21+10*train_id, offset+40);
                                    if section_asc_right == 1
                                        text(30, offset+40-15, strcat('right trains asc'), 'FontSize', 8, 'Color', [0.8 0 0]);
                                        text(30, offset+40-18, strcat("TPS branch lenght: ", num2str(obj.tps_lenghts(tps_no,2)), " km"), 'FontSize', 8, 'Color', [0.6 0.6 0.6]);
                                    end
                                    if section_asc_right == max_trains_asc_right
                                        plot([30+10*train_id-2 30+10*train_id+2], [offset+40 offset+40], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus %plot busK+2
                                        text(29+10*train_id, offset+40-10, strcat("bus", num2str(obj.tps_data(tps_no).bus_index(4))), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                                        text(22+10*train_id, offset+40+9, strcat("br[", num2str(obj.tps_data(tps_no).trains(tps_trains).branch_right),"]: ", num2str(obj.mpc_data.branch(obj.tps_data(tps_no).trains(tps_trains).branch_right,1)), "-", num2str(obj.mpc_data.branch(obj.tps_data(tps_no).trains(tps_trains).branch_right,2))), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
                                    end
                                    section_asc_right = section_asc_right+1;
                                otherwise
                                    fprintf('error: wrong section');
                            end
                        case 'desc'
                        otherwise
                            fprintf('error: wrong direction');
                    end
                end
            else
                fprintf('no trains to print');
            end
            %%%%%%%%%%%%%%%% plot ptd of the TPS
            switch obj.tps_data(tps_no).ptd.section
                case 'left'
                    if isfield(obj.tps_data(tps_no), 'trains_left') && ~isempty(obj.tps_data(tps_no).trains_left)
                        %%%plot na posição number of trains, 0 
                        %%%branch1
                        plot_ptd_asc(obj, tps_no, offset, lw, size(obj.tps_data(tps_no).trains_left.id, 2), 0);
                    else
                        %%%plot na posição 0, 0
                        plot_ptd_asc(obj, tps_no, offset, lw, 0, 0);
                    end
                case 'right'
                    if isfield(obj.tps_data(tps_no), 'trains_right') && ~isempty(obj.tps_data(tps_no).trains_right)
                        %%%plot na posição number of trains, 40 
                        %%%branch1
                        plot_ptd_asc(obj, tps_no, offset, lw, size(obj.tps_data(tps_no).trains_right.id, 2), 40);
                    else
                        %%%plot na posição 0, 40
                        plot_ptd_asc(obj, tps_no, offset, lw, 0, 40);
                    end
            end
            
            %%%%%%%%%%%%  METHOD AUX FUNCTIONS  %%%%%%%%%%%%%%%%%
            function plot_ptd_asc(obj, tps_no, offset, lw, branch_num_trains, y_offset)
                %y_offset = 40;
                plot_pos = 40+10*branch_num_trains;%size(obj.tps_data(tps_no).trains_right.id, 2);
                rectangle('Position',[plot_pos-10 offset+y_offset-12 25 24],'Curvature',0.1, 'LineStyle', '--');
                text(plot_pos, offset+y_offset+15, 'PTD');
                plot([plot_pos-2 plot_pos+2], [offset+y_offset offset+y_offset], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus %plot busK+2
                text(plot_pos-1, offset-10+y_offset, strcat("bus", num2str(obj.tps_data(tps_no).ptd.PTD_bus(1))), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                obj = obj.plot_branch(plot_pos-10, offset+y_offset);
                branch_pos = find(obj.mpc_data.branch(:,2)==obj.tps_data(tps_no).ptd.PTD_bus(1));
                text(plot_pos-8, offset+y_offset+9, strcat("br[", num2str(branch_pos),"]: ", num2str(obj.mpc_data.branch(branch_pos,1)), "-", num2str(obj.mpc_data.branch(branch_pos,2))), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
                %%%branch2
                plot_pos = 50+10*branch_num_trains;
                plot([plot_pos-2 plot_pos+2], [offset+y_offset offset+y_offset], 'LineWidth', lw*2, 'Color', [0 0 0]);   %%bus %plot busK+2
                text(plot_pos-1, offset-10+y_offset, strcat("bus", num2str(obj.tps_data(tps_no).ptd.PTD_bus(2))), 'FontSize', 8, 'Color', [0.6 0.6 0.6], 'Rotation',90);
                obj = obj.plot_branch(plot_pos-10, offset+y_offset);
                branch_pos = find(obj.mpc_data.branch(:,2)==obj.tps_data(tps_no).ptd.PTD_bus(2));
                text(plot_pos-8, offset+y_offset+9, strcat("br[", num2str(branch_pos),"]: ", num2str(obj.mpc_data.branch(branch_pos,1)), "-", num2str(obj.mpc_data.branch(branch_pos,2))), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
                 %%%plot arrow
                plot([plot_pos+0.75 plot_pos+0.75], [offset+y_offset offset+y_offset-4], 'LineWidth', 0.75, 'Color', [0 0 0]);
                plot(plot_pos+0.75, offset+y_offset-4, 'v', 'LineWidth', 0.75*0.5, 'Color', [0 0 0], 'MarkerFaceColor', 'k');
            end
        end
        
        function obj = plot_branch(obj, pos_x, pos_y)
            lw = 0.75;%linewidth
            %%% plot branch
            plot([pos_x+0.5 pos_x+1.5], [pos_y pos_y+5], 'LineWidth', lw, 'Color', [0 0 0]);
            plot([pos_x+1.5 pos_x+4], [pos_y+5 pos_y+5], 'LineWidth', lw, 'Color', [0 0 0]);
            %plot capacitor1
            pos_c = pos_x+2.75;
            plot([pos_c pos_c], [pos_y+5 pos_y+3.5], 'LineWidth', lw*0.5, 'Color', [0 0 0]);
            plot([pos_c-0.75 pos_c+0.75], [pos_y+3.5 pos_y+3.5], 'LineWidth', lw*0.5, 'Color', [0 0 0]);
            plot([pos_c-0.75 pos_c+0.75], [pos_y+2.5 pos_y+2.5], 'LineWidth', lw*0.5, 'Color', [0 0 0]);
            plot([pos_c pos_c], [pos_y+2.5 pos_y+1.5], 'LineWidth', lw*0.5, 'Color', [0 0 0]);
            %plot rectangle impedance
            rectangle('Position',[pos_x+4 pos_y+4 2 2], 'LineWidth', lw*1.5, 'EdgeColor', [0 0 0]); %%load
%           text(14, row+11, 'SST TRANSF', 'FontSize', 7);
%           text(14, row+8, 'Z_T = R_T + jX_T', 'FontSize', 7);
            %plot capacitor2
            pos_c = pos_x+7.25;
            plot([pos_c pos_c], [pos_y+5 pos_y+3.5], 'LineWidth', lw*0.5, 'Color', [0 0 0]);
            plot([pos_c-0.75 pos_c+0.75], [pos_y+3.5 pos_y+3.5], 'LineWidth', lw*0.5, 'Color', [0 0 0]);
            plot([pos_c-0.75 pos_c+0.75], [pos_y+2.5 pos_y+2.5], 'LineWidth', lw*0.5, 'Color', [0 0 0]);
            plot([pos_c pos_c], [pos_y+2.5 pos_y+1.5], 'LineWidth', lw*0.5, 'Color', [0 0 0]);
            %
            plot([pos_x+6 pos_x+8.5], [pos_y+5 pos_y+5], 'LineWidth', lw, 'Color', [0 0 0]);
            plot([pos_x+8.5 pos_x+9.5], [pos_y+5 pos_y], 'LineWidth', lw, 'Color', [0 0 0]);
            %%% end plot branch
        end
        function obj = plot_train_info (obj, train_data, pos_x, pos_y)
            
%             train_data.id = train.id(id);
%             train_data.abs_position = train.abs_position(id);
%             train_data.apower = train.apower(id);
%             train_data.rpower = train.rpower(id);
            text(pos_x, pos_y-3, strcat("ID:", num2str(train_data.id)), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
            text(pos_x, pos_y-6, strcat("pos:", num2str(train_data.abs_position, '%.1f')), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
            text(pos_x, pos_y-9, strcat("P:", num2str(train_data.apower, '%.2f')), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
            text(pos_x, pos_y-12, strcat("Q:", num2str(train_data.rpower, '%.2f')), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
            %%%plot arrow
            lw = 0.75;%linewidth
            plot([pos_x-0.75 pos_x-0.75], [pos_y pos_y-2], 'LineWidth', lw, 'Color', [0 0 0]);
            plot(pos_x-0.75, pos_y-2, 'v', 'LineWidth', lw*0.5, 'Color', [0 0 0], 'MarkerFaceColor', 'k');
        end
        function obj = plot_branch_info (obj, train, pos_x, pos_y)
            text(pos_x, pos_y, strcat("br[", num2str(train.branch_left),"]: ", num2str(obj.mpc_data.branch(train.branch_left,1)), "-", num2str(obj.mpc_data.branch(train.branch_left,2))), 'FontSize', 8, 'Color', [0.2 0.2 0.2]);
        end
    end
end


function plot_oval(xx, yy, h, v)
%PLOT_OVAL --- plots an oval
% 
%  @input 1: xx - is the horizontal centre, X0
%       
% 
%  @input 2: yy - is the vertical center, Y0
%       
% 
%  @input 3: h - is the height of the oval plot, the horizontal radius
%       
% 
%  @input 4: v - is the width of the oval plot, the vertical radius
%       
% 
%  @description: 
%       plots an oval
% 
%  @usage: 
%       plot_oval(1, 1, 0.5, 0.5);
% 
% $Author: VMORAIS $	$Date: 2020/04/04 10:10:45 $	$Revision: 0.1 $
% Copyright: FEUP - Vitor Morais 2020


a=h; % horizontal radius
b=v; % vertical radius
x0=xx; % x0,y0 ellipse centre coordinates
y0=yy;
t=-pi:pi/10:pi;
x=x0+a*cos(t);
y=y0+b*sin(t);
plot(x,y, 'LineWidth', 1, 'Color', [0 0 0])

end

