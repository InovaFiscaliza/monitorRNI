classdef dockManualMeasurement_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        GridLayout8                    matlab.ui.container.GridLayout
        StationPin                     matlab.ui.control.Image
        StationNumber                  matlab.ui.control.Label
        GridLayout7                    matlab.ui.container.GridLayout
        EstEditionCancel               matlab.ui.control.Image
        EstEditionConfirm              matlab.ui.control.Image
        LocationRefresh                matlab.ui.control.Image
        ImageEdit                      matlab.ui.control.Image
        Title_3                        matlab.ui.control.Label
        exportar                       matlab.ui.control.Image
        importar                       matlab.ui.control.Image
        Add                            matlab.ui.control.Image
        Title_2                        matlab.ui.control.Label
        NextSelection                  matlab.ui.control.Image
        Panel_4                        matlab.ui.container.Panel
        LocationPanelGrid_3            matlab.ui.container.GridLayout
        Longitude_3                    matlab.ui.control.NumericEditField
        LongitudeLabel_6               matlab.ui.control.Label
        Latitude_3                     matlab.ui.control.NumericEditField
        LatitudeLabel_4                matlab.ui.control.Label
        Panel_3                        matlab.ui.container.Panel
        EditableFieldsGrid_2           matlab.ui.container.GridLayout
        UGatualDropDown                matlab.ui.control.DropDown
        UGatualDropDownLabel           matlab.ui.control.Label
        PatrimnioSIADSNdeSrieDropDown  matlab.ui.control.DropDown
        PatrimnioSIADSNdeSrieDropDownLabel  matlab.ui.control.Label
        MarcaModeloDropDown            matlab.ui.control.DropDown
        MarcaModeloDropDownLabel       matlab.ui.control.Label
        Panel_2                        matlab.ui.container.Panel
        GridLayout6                    matlab.ui.container.GridLayout
        Altitude                       matlab.ui.control.NumericEditField
        Medida                         matlab.ui.control.NumericEditField
        LongitudeLabel_3               matlab.ui.control.Label
        LongitudeLabel_4               matlab.ui.control.Label
        Longitude                      matlab.ui.control.NumericEditField
        Latitude                       matlab.ui.control.NumericEditField
        LongitudeLabel_2               matlab.ui.control.Label
        LatitudeLabel_2                matlab.ui.control.Label
        Hora                           matlab.ui.control.EditField
        Datadamedicao                  matlab.ui.control.DatePicker
        HoraEditFieldLabel_2           matlab.ui.control.Label
        DatadamedioDatePickerLabel     matlab.ui.control.Label
        Panel                          matlab.ui.container.Panel
        TreeMedidas                    matlab.ui.container.Tree
        EditableFieldsLabel            matlab.ui.control.Label
        SummaryLabel                   matlab.ui.control.Label
        PreviousSelection              matlab.ui.control.Image
    end

    
    properties (Access = private)
        %-----------------------------------------------------------------%
        Role = 'secondaryDockApp'

        TreeContextMenu             matlab.ui.container.ContextMenu
        EditNodeMenu                matlab.ui.container.Menu
        DeleteNodeMenu              matlab.ui.container.Menu
        EditingNode                 = []
        PreviousKeyPressFcn         = []
        EquipmentTable              = table()
        UIAxes                      = []
        StationInfo                 = struct('Service', '', 'Entity', '', 'UD', '', 'Municipality', '', 'UF', '')

        % Nº da estação não é exibido, mas é registrado junto às medidas.
        StationId                   = NaN
        StationIdx                  = []
        StationCoordinates          = struct('Latitude', NaN, 'Longitude', NaN)
        IsStationEditing            = false
    end


    properties (Access = public)
        %-----------------------------------------------------------------%
        Container
        isDocked = true
        mainApp
        callingApp

    end
    
    methods (Access = private)
        %-----------------------------------------------------------------%
        function configureComponents(app)
            % Propriedades e callbacks ajustados em tempo de execução, pois a 
            % seção "Component initialization" é gerada pelo App Designer.
            set([app.Latitude, app.Longitude, app.Altitude, app.Medida], 'Editable', true)
            set([app.Latitude, app.Longitude, app.Medida], 'AllowEmpty', true)
            set(app.Altitude, 'Limits', [-Inf Inf])
            set(app.Medida,   'Limits', [0 Inf])
                   
            set(app.Add,   'Tooltip', 'Adiciona (ou atualiza) a medida, registrando-a no projeto', 'ImageSource', 'Add_16.png')
            set(app.PreviousSelection,  'Tooltip', 'Estação anterior')
            set(app.NextSelection, 'Tooltip', 'Próxima estação')

            % Ícones de edição das coordenadas da estação (idênticos aos de
            % auxApp.dockStationInfo).
            set(app.LocationRefresh,   'Tooltip', 'Retorna aos valores constantes em base')
            set(app.ImageEdit,         'Tooltip', 'Habilita ou desabilita edição das coordenadas da estação')
            set(app.EstEditionConfirm, 'Tooltip', 'Confirma edição')
            set(app.EstEditionCancel,  'Tooltip', 'Cancela edição')

            set(app.importar, 'Tooltip', 'Abre planilha contendo medidas')
            set(app.exportar, 'Tooltip', 'Salva as medidas em planilha')

            % Árvore de medições: seleção múltipla, menu de contexto (editar/excluir)
            % e exclusão pela tecla DELETE (tratada no KeyPressFcn da figura, pois
            % o uitree não possui esse callback).
            app.TreeMedidas.Multiselect = 'on';

            app.TreeContextMenu = uicontextmenu(app.UIFigure);

            app.EditNodeMenu = uimenu(app.TreeContextMenu);
            app.EditNodeMenu.Text = '✏️ Editar';
            app.EditNodeMenu.MenuSelectedFcn = createCallbackFcn(app, @onTreeMenuSelected, true);

            app.DeleteNodeMenu = uimenu(app.TreeContextMenu);
            app.DeleteNodeMenu.Text = '🗑️ Excluir';
            app.DeleteNodeMenu.MenuSelectedFcn = createCallbackFcn(app, @onTreeMenuSelected, true);

            app.TreeMedidas.ContextMenu = app.TreeContextMenu;

            app.PreviousKeyPressFcn = app.UIFigure.WindowKeyPressFcn;
            app.UIFigure.WindowKeyPressFcn = createCallbackFcn(app, @onKeyPressed, true);
            app.TreeMedidas.DeleteFcn = createCallbackFcn(app, @onTreeDeleted, true);
        end

        %-----------------------------------------------------------------%
        % ## MAPA ##
        %-----------------------------------------------------------------%
        function createMap(app)
            app.Panel.AutoResizeChildren = 'off';
            app.Panel.BorderType         = 'none';

            app.UIAxes = plot.axesCreationController(app.Panel, app.mainApp.General);
        end

        %-----------------------------------------------------------------%
        function plotStation(app, resetView)
            arguments
                app
                resetView logical = true
            end

            delete(findobj(app.UIAxes.Children, 'Tag', 'Station'))

            General   = app.mainApp.General;
            latitude  = app.Latitude_3.Value;
            longitude = app.Longitude_3.Value;
            DIST_km   = General.context.MONITORINGPLAN.maxMeasurementDistanceKm;

            % Círculo entorno da estação, igual ao exibido em auxApp.winMonitoringPlan.
            drawcircle(app.UIAxes,                                  ...
                'Position',       [latitude, longitude],            ...
                'Radius',         km2deg(DIST_km),                  ...
                'Color',          General.plot.circleRegion.color,     ...
                'FaceAlpha',      General.plot.circleRegion.faceAlpha, ...
                'EdgeAlpha',      General.plot.circleRegion.edgeAlpha, ...
                'FaceSelectable', 0, 'InteractionsAllowed', 'none', ...
                'Tag',            'Station');

            hPlot = geoscatter(app.UIAxes, latitude, longitude, 300, ...
                'Marker',          'pentagram',                       ...
                'MarkerFaceColor', General.plot.selectedStation.color, ...
                'MarkerEdgeColor', 'white',                           ...
                'LineWidth',       1.5,                               ...
                'DisplayName',     sprintf('Estação nº %d', app.StationId), ...
                'Tag',             'Station');
            plot.datatip.Template(hPlot, 'Coordinates')

            if resetView
                % A estação fica no centro do mapa. 
                plot.zoom(app.UIAxes, latitude, longitude, General.plot.selectedStation.automaticZoomFactor * DIST_km)
            end

           plot.axes.StackingOrder.execute(app.UIAxes, 'ManualMeasurement') 
        end

        %-----------------------------------------------------------------%
        function updateStationROI(app)
            % No modo de edição, o marcador da estação pode ser arrastado no mapa.
            delete(findobj(app.UIAxes.Children, 'Tag', 'StationROI'))

            if ~app.IsStationEditing
                return
            end

            hROI = images.roi.Point(app.UIAxes, ...
                'Position',   [app.Latitude_3.Value, app.Longitude_3.Value], ...
                'Color',      app.mainApp.General.plot.selectedStation.color, ...
                'MarkerSize', 12,                                             ...
                'Deletable',  false,                                          ...
                'Tag',        'StationROI');

            addlistener(hROI, 'MovingROI', @(src, evt)onStationROIEvent(app, src, evt));
            addlistener(hROI, 'ROIMoved',  @(src, evt)onStationROIEvent(app, src, evt));
            addlistener(hROI, 'ObjectBeingDestroyed', @(src, ~)plot.axes.Interactivity.DeleteROIListeners(src));

            plot.axes.StackingOrder.execute(app.UIAxes, 'ManualMeasurement')
        end

        %-----------------------------------------------------------------%
        function onStationROIEvent(app, hROI, event)
            switch event.EventName
                case 'MovingROI'
                    plot.axes.Interactivity.DefaultDisable(app.UIAxes)

                case 'ROIMoved'
                    plot.axes.Interactivity.DefaultEnable(app.UIAxes)

                    app.Latitude_3.Value  = round(min(max(hROI.Position(1), -90),  90),  6);
                    app.Longitude_3.Value = round(min(max(hROI.Position(2), -180), 180), 6);
                    plotStation(app, false)
            end
        end

        %-----------------------------------------------------------------%
        function updateLocationPanelLayout(app, editionStatus)
            arguments
                app
                editionStatus char {mustBeMember(editionStatus, {'on', 'off'})}
            end

            hEditFields = [app.Latitude_3, app.Longitude_3];

            switch editionStatus
                case 'on'
                    app.IsStationEditing = true;
                    app.ImageEdit.ImageSource = 'Edit_32Filled.png';
                    set(hEditFields, 'Editable', true)

                    app.GridLayout7.ColumnWidth(end-1:end) = {18, 18};
                    app.EstEditionConfirm.Enable = 1;
                    app.EstEditionCancel.Enable  = 1;

                case 'off'
                    app.IsStationEditing = false;
                    app.ImageEdit.ImageSource = 'Edit_32.png';
                    set(hEditFields, 'Editable', false)

                    app.GridLayout7.ColumnWidth(end-1:end) = {0, 0};
                    app.EstEditionConfirm.Enable = 0;
                    app.EstEditionCancel.Enable  = 0;
            end

            if ~isempty(app.UIAxes) && isvalid(app.UIAxes)
                updateStationROI(app)
            end
        end

        %-----------------------------------------------------------------%
        function refreshMeasurementPlot(app)
            if isempty(app.UIAxes) || ~isvalid(app.UIAxes)
                return
            end

            plotMeasures(app)
            updateMeasurementSelection(app)
        end

        %-----------------------------------------------------------------%
        function plotMeasures(app)
            delete(findobj(app.UIAxes.Children, 'Tag', 'Measures'))
            delete(findobj(app.UIAxes.Children, 'Tag', 'RiskMeasures'))

            nodes = app.TreeMedidas.Children;
            if ~isempty(nodes)
                measurements = [nodes.NodeData];
                measTable    = table([measurements.Latitude]', [measurements.Longitude]', [measurements.FieldValue]', ...
                                     'VariableNames', {'Latitude', 'Longitude', 'FieldValue'});

                % Os círculos são coloridos pelo valor da medida, como em auxApp.winMonitoringPlan.
                plot.draw.Measures(app.UIAxes, measTable, app.mainApp.General.context.MONITORINGPLAN.electricFieldStrengthThreshold, app.mainApp.General);
            end

            plot.axes.StackingOrder.execute(app.UIAxes, 'ManualMeasurement')
        end

        %-----------------------------------------------------------------%
        function updateMeasurementSelection(app)
            % Os nós selecionados na árvore ganham no mapa um ponto destacado 
            % (ROI) que pode ser arrastado.
            delete(findobj(app.UIAxes.Children, 'Tag', 'MeasurementPoint'))

            selectedNodes = app.TreeMedidas.SelectedNodes;
            for ii = 1:numel(selectedNodes)
                measurement = selectedNodes(ii).NodeData;

                hROI = images.roi.Point(app.UIAxes, ...
                    'Position',  [measurement.Latitude, measurement.Longitude], ...
                    'Color',     measurementColor(app, measurement.FieldValue), ...
                    'MarkerSize', 10,                                           ...
                    'Deletable', false,                                         ...
                    'Tag',       'MeasurementPoint',                            ...
                    'UserData',  selectedNodes(ii));

                addlistener(hROI, 'MovingROI', @(src, evt)onMeasurementROIEvent(app, src, evt));
                addlistener(hROI, 'ROIMoved',  @(src, evt)onMeasurementROIEvent(app, src, evt));
                addlistener(hROI, 'ObjectBeingDestroyed', @(src, ~)plot.axes.Interactivity.DeleteROIListeners(src));
            end

            plot.axes.StackingOrder.execute(app.UIAxes, 'ManualMeasurement')
        end

        %-----------------------------------------------------------------%
        function rgb = measurementColor(app, fieldValue)
            nodes     = app.TreeMedidas.Children;
            allValues = [nodes.NodeData];
            allValues = [allValues.FieldValue];

            try
                cLim = double(app.UIAxes.CLim);
            catch
                cLim = [min(allValues), max(allValues)];
            end

            colorMap = app.UIAxes.Colormap;
            if diff(cLim) <= 0
                normalizedValue = 0.5;
            else
                normalizedValue = min(max((fieldValue - cLim(1)) / diff(cLim), 0), 1);
            end

            rgb = colorMap(1 + round(normalizedValue * (size(colorMap, 1) - 1)), :);
        end

        %-----------------------------------------------------------------%
        function ensureMeasuresVisible(app)
            nodes = app.TreeMedidas.Children;
            if isempty(nodes)
                return
            end

            measurements = [nodes.NodeData];
            latitudes    = [measurements.Latitude,  app.Latitude_3.Value];
            longitudes   = [measurements.Longitude, app.Longitude_3.Value];

            if all(latitudes  >= app.UIAxes.LatitudeLimits(1)  & latitudes  <= app.UIAxes.LatitudeLimits(2) & ...
                   longitudes >= app.UIAxes.LongitudeLimits(1) & longitudes <= app.UIAxes.LongitudeLimits(2))
                return
            end

            latPad = max(0.1 * (max(latitudes)  - min(latitudes)),  km2deg(0.05));
            lonPad = max(0.1 * (max(longitudes) - min(longitudes)), km2deg(0.05));
            geolimits(app.UIAxes, [max(min(latitudes)  - latPad, -90),  min(max(latitudes)  + latPad, 90)], ...
                                  [max(min(longitudes) - lonPad, -180), min(max(longitudes) + lonPad, 180)])
        end

        %-----------------------------------------------------------------%
        function onMeasurementROIEvent(app, hROI, event)
            switch event.EventName
                case 'MovingROI'
                    plot.axes.Interactivity.DefaultDisable(app.UIAxes)

                case 'ROIMoved'
                    plot.axes.Interactivity.DefaultEnable(app.UIAxes)

                    node = hROI.UserData;
                    if ~isvalid(node)
                        return
                    end

                    measurement = node.NodeData;
                    measurement.Latitude  = round(min(max(hROI.Position(1), -90),  90),  6);
                    measurement.Longitude = round(min(max(hROI.Position(2), -180), 180), 6);

                    node.NodeData = measurement;
                    node.Text     = measurementNodeText(app, measurement);

                    % Mantém coerente o formulário, caso a medida esteja em edição.
                    if isscalar(app.EditingNode) && isvalid(app.EditingNode) && (app.EditingNode == node)
                        app.Latitude.Value  = measurement.Latitude;
                        app.Longitude.Value = measurement.Longitude;
                    end

                    plotMeasures(app)
                    syncManualMeasurements(app, measurement)
            end
        end

        %-----------------------------------------------------------------%
        function loadStationData(app, stationIdx)
            % Os dados da estação são provenientes da linha selecionada em 
            % auxApp.winMonitoringPlan. O nº da estação é exibido em "StationNumber" 
            % e mantido para registro das medidas.
            stationTable = app.mainApp.projectData.modules.MONITORINGPLAN.stationTable;

            app.StationIdx              = stationIdx;
            app.StationId               = double(stationTable.("Estação")(stationIdx));
            app.Latitude_3.Value        = stationTable.("Latitude")(stationIdx);
            app.Longitude_3.Value       = stationTable.("Longitude")(stationIdx);

            app.StationInfo = struct( ...
                'Service',      char(string(stationTable.("Serviço")(stationIdx))),   ...
                'Entity',       char(string(stationTable.("Entidade")(stationIdx))),  ...
                'UD',           char(string(stationTable.("UD")(stationIdx))),        ...
                'Municipality', char(string(stationTable.("Município")(stationIdx))), ...
                'UF',           char(string(stationTable.("UF")(stationIdx))));

            app.StationCoordinates = struct('Latitude', app.Latitude_3.Value, 'Longitude', app.Longitude_3.Value);
            updateStationNumber(app)
            updateLocationRefresh(app)
            updateLocationPanelLayout(app, 'off')
        end

        %-----------------------------------------------------------------%
        function updateStationNumber(app)
            app.StationNumber.Text = sprintf(' Estação Nº: %d  |  Latitude: %.6f  |  Longitude: %.6f', ...
                app.StationId, app.StationCoordinates.Latitude, app.StationCoordinates.Longitude);
        end

        %-----------------------------------------------------------------%
        function updateLocationRefresh(app)
            % O ícone é exibido apenas quando as coordenadas da estação diferem 
            % das constantes em base ("Lat" e "Long"). Estações importadas de 
            % planilha e ausentes da tabela de referência não possuem registro.
            isEdited = false;

            if ~isempty(app.StationIdx)
                stationTable = app.mainApp.projectData.modules.MONITORINGPLAN.stationTable;
                isEdited = (stationTable.("Lat")(app.StationIdx)  ~= stationTable.("Latitude")(app.StationIdx)) || ...
                           (stationTable.("Long")(app.StationIdx) ~= stationTable.("Longitude")(app.StationIdx));
            end

            app.LocationRefresh.Visible = isEdited;
        end

        %-----------------------------------------------------------------%
        function loadStationMeasurements(app)
            % A árvore reflete as medidas da estação registradas no projeto 
            % (app.mainApp.projectData.modules.MONITORINGPLAN.manualMeasurement).
            delete(app.TreeMedidas.Children)
            app.EditingNode = [];

            manualTable = app.mainApp.projectData.modules.MONITORINGPLAN.manualMeasurement;
            manualTable = manualTable(manualTable.Station == app.StationId, :);

            for ii = 1:height(manualTable)
                measurement = struct( ...
                    'Timestamp',    manualTable.Timestamp(ii),       ...
                    'Latitude',     manualTable.Latitude(ii),        ...
                    'Longitude',    manualTable.Longitude(ii),       ...
                    'Altitude',     manualTable.Altitude(ii),        ...
                    'FieldValue',   manualTable.FieldValue(ii),      ...
                    'Sensor',       char(manualTable.Sensor{ii}),       ...
                    'SIADS',        char(manualTable.SIADS{ii}),        ...
                    'SerialNumber', char(manualTable.SerialNumber{ii}));

                uitreenode(app.TreeMedidas, ...
                    'Text',     measurementNodeText(app, measurement), ...
                    'NodeData', measurement);
            end
        end

        %-----------------------------------------------------------------%
        function loadSelectedStation(app, stationIdx)
            % A medição em edição é descartada e os campos do sensor e a data 
            % da medição são mantidos, facilitando o registro em estações 
            % sucessivas com o mesmo equipamento.
            app.EditingNode = [];
            clearMeasurementFields(app)

            loadStationData(app, stationIdx)
            loadStationMeasurements(app)
            plotStation(app)
            refreshMeasurementPlot(app)
            ensureMeasuresVisible(app)
        end

        %-----------------------------------------------------------------%
        function confirmStationEdition(app)
            if isempty(app.Latitude_3.Value) || isempty(app.Longitude_3.Value)
                ui.Dialog(app.UIFigure, 'warning', 'Informe a latitude e a longitude da estação.');
                return
            end

            newCoordinates = struct('Latitude', app.Latitude_3.Value, 'Longitude', app.Longitude_3.Value);
            isEdited       = ~isequal(newCoordinates, app.StationCoordinates);

            app.StationCoordinates = newCoordinates;
            updateStationNumber(app)
            updateLocationPanelLayout(app, 'off')
            plotStation(app, false)

            % A edição é registrada na tabela de estações do projeto, de modo 
            % que persista ao navegar entre estações. Estações importadas de 
            % planilha e ausentes da tabela de referência não possuem registro.
            if isEdited && ~isempty(app.StationIdx)
                ipcMainMatlabCallsHandler(app.mainApp, app, 'onStationCoordinatesEdited', 'MONITORINGPLAN', app.StationIdx, newCoordinates.Latitude, newCoordinates.Longitude)
            end

            updateLocationRefresh(app)
        end

        %-----------------------------------------------------------------%
        function restoreStationCoordinates(app)
            % Retorna aos valores constantes em base ("Lat" e "Long").
            stationTable = app.mainApp.projectData.modules.MONITORINGPLAN.stationTable;

            app.Latitude_3.Value  = stationTable.("Lat")(app.StationIdx);
            app.Longitude_3.Value = stationTable.("Long")(app.StationIdx);
            confirmStationEdition(app)
        end

        %-----------------------------------------------------------------%
        function cancelStationEdition(app)
            app.Latitude_3.Value  = app.StationCoordinates.Latitude;
            app.Longitude_3.Value = app.StationCoordinates.Longitude;

            updateLocationPanelLayout(app, 'off')
            plotStation(app, false)    
        end

        %-----------------------------------------------------------------%
        function loadEquipmentTable(app)
            % A planilha é lida a cada abertura da janela, de forma que 
            % atualizações nela reflitam nas opções dos dropdowns. Uma cópia 
            % em "ProgramData\...\DataBase" tem precedência sobre a que acompanha 
            % o app ("resources").
            fileName = 'equipamentos_medição_rni_eFiscaliza.xlsx';
            rootFolder = app.mainApp.rootFolder;
            [~, programDataFolder] = appEngine.util.Path(class.Constants.appName, rootFolder);

            candidates = {fullfile(programDataFolder, 'DataBase', fileName), ...
                          fullfile(rootFolder, 'resources', fileName)};
            fileIdx = find(cellfun(@isfile, candidates), 1);
            if isempty(fileIdx)
                error('dockManualMeasurement:EquipmentFileNotFound', 'Planilha de equipamentos "%s" não encontrada.', fileName)
            end

            opts = detectImportOptions(candidates{fileIdx}, 'VariableNamingRule', 'preserve');
            opts = setvartype(opts, 'string');
            equipTable = readtable(candidates{fileIdx}, opts);

            % Registros sem identificação ("-") são descartados.
            requiredColumns = {'Marca', 'Modelo', 'Patrimônio SIADS'};
            invalidRows = any(ismissing(equipTable(:, requiredColumns)) | equipTable{:, requiredColumns} == "-", 2);
            equipTable(invalidRows, :) = [];

            if isempty(equipTable)
                error('dockManualMeasurement:EquipmentTableEmpty', 'Planilha de equipamentos "%s" não possui registros válidos.', fileName)
            end

            if ~ismember('UG Atual', equipTable.Properties.VariableNames)
                equipTable.("UG Atual") = repmat("-", height(equipTable), 1);
            end

            equipTable.("Nº de Série")(ismissing(equipTable.("Nº de Série"))) = "-";
            equipTable.("UG Atual")(ismissing(equipTable.("UG Atual"))) = "-";
            equipTable.MarcaModelo      = strtrim(equipTable.Marca) + " / " + strtrim(equipTable.Modelo);
            equipTable.SIADSSerial      = strtrim(equipTable.("Patrimônio SIADS")) + " / " + strtrim(equipTable.("Nº de Série"));
            app.EquipmentTable = equipTable;
        end

        %-----------------------------------------------------------------%
        function filteredTable = filterEquipmentTable(app, filterUntil)
            % Cada seleção restringe apenas os campos seguintes da ordem 
            % "UG atual" > "Marca / Modelo" > "Patrimônio SIADS / Nº de Série".
            arguments
                app
                filterUntil char {mustBeMember(filterUntil, {'none', 'UG', 'MarcaModelo'})}
            end

            filteredTable = app.EquipmentTable;

            if ismember(filterUntil, {'UG', 'MarcaModelo'}) && ~isempty(app.UGatualDropDown.Value)
                filteredTable = filteredTable(filteredTable.("UG Atual") == string(app.UGatualDropDown.Value), :);
            end

            if strcmp(filterUntil, 'MarcaModelo') && ~isempty(app.MarcaModeloDropDown.Value)
                filteredTable = filteredTable(filteredTable.MarcaModelo == string(app.MarcaModeloDropDown.Value), :);
            end
        end

        %-----------------------------------------------------------------%
        function updateEquipmentItems(app, changedField)
            % Os itens dos campos seguintes são restringidos pela seleção, 
            % porém nunca preenchidos: o valor atual é mantido apenas se 
            % ainda for válido; caso contrário, o campo volta a ficar vazio.
            arguments
                app
                changedField char {mustBeMember(changedField, {'all', 'UG', 'MarcaModelo'})}
            end

            emptyItem = {''};

            if ismember(changedField, {'all'})
                app.UGatualDropDown.Items = [emptyItem, cellstr(unique(app.EquipmentTable.("UG Atual")))'];
            end

            if ismember(changedField, {'all', 'UG'})
                equipTable = filterEquipmentTable(app, 'UG');
                setDropDownItems(app, app.MarcaModeloDropDown, [emptyItem, cellstr(unique(equipTable.MarcaModelo))'])
            end

            equipTable = filterEquipmentTable(app, 'MarcaModelo');
            setDropDownItems(app, app.PatrimnioSIADSNdeSrieDropDown, [emptyItem, cellstr(unique(equipTable.SIADSSerial))'])
        end

        %-----------------------------------------------------------------%
        function setDropDownItems(app, hDropDown, items)
            currentValue = hDropDown.Value;
            hDropDown.Items = items;

            if ismember(currentValue, items)
                hDropDown.Value = currentValue;
            else
                hDropDown.Value = '';
            end
        end

        %-----------------------------------------------------------------%
        function equipRow = selectedEquipment(app)
            % Retorna a linha da planilha de equipamentos correspondente ao 
            % "Patrimônio SIADS / Nº de Série" selecionado (vazio se nenhum).
            equipRow = app.EquipmentTable([], :);

            if isempty(app.PatrimnioSIADSNdeSrieDropDown.Value)
                return
            end

            equipTable = filterEquipmentTable(app, 'MarcaModelo');
            equipRow   = equipTable(equipTable.SIADSSerial == string(app.PatrimnioSIADSNdeSrieDropDown.Value), :);
            equipRow   = equipRow(1:min(1, height(equipRow)), :);
        end

        %-----------------------------------------------------------------%
        function clearEquipmentFields(app)
            set([app.UGatualDropDown, app.MarcaModeloDropDown, app.PatrimnioSIADSNdeSrieDropDown], 'Items', {''}, 'Value', '')
            updateEquipmentItems(app, 'all')
        end

        %-----------------------------------------------------------------%
        function clearMeasurementFields(app)
            % Campos obrigatórios ficam vazios (0 é um valor válido); Altitude é 
             % opcional e inicia em 0. A data da medição é mantida.
            set([app.Latitude, app.Longitude, app.Medida], 'Value', [])
            set(app.Altitude, 'Value', 0)
            app.Hora.Value = '';
        end

        %-----------------------------------------------------------------%
        function clearForm(app)
             % Os campos do sensor e da medição iniciam vazios.
            clearEquipmentFields(app)
            app.Datadamedicao.Value = NaT;
            app.EditingNode         = [];
            clearMeasurementFields(app)
        end

        %-----------------------------------------------------------------%
        function measurements = nodeMeasurements(app)
            nodes = app.TreeMedidas.Children;
            if isempty(nodes)
                measurements = struct([]);
            else
                measurements = [nodes.NodeData];
            end
        end

        %-----------------------------------------------------------------%
        function key = measurementKey(app, measurement)
            key = strjoin(string({measurement.Sensor, measurement.SIADS, measurement.SerialNumber}), '|');
        end

        %-----------------------------------------------------------------%
        function syncManualMeasurements(app, referenceMeasurements)
            % Registra em app.mainApp.projectData.modules.MONITORINGPLAN.manualMeasurement 
            % as medidas da árvore pertencentes aos conjuntos (estação + sensor 
            % + nº de série) das medidas de referência. Conjuntos que ficaram 
            % sem medidas são removidos do projeto.
            allMeasurements = nodeMeasurements(app);
            allKeys         = strings(1, numel(allMeasurements));
            for ii = 1:numel(allMeasurements)
                allKeys(ii) = measurementKey(app, allMeasurements(ii));
            end

            refKeys = strings(1, numel(referenceMeasurements));
            for ii = 1:numel(referenceMeasurements)
                refKeys(ii) = measurementKey(app, referenceMeasurements(ii));
            end
            [~, refIdxs] = unique(refKeys, 'stable');

            for ii = refIdxs(:)'
                reference = referenceMeasurements(ii);
                group     = allMeasurements(allKeys == refKeys(ii));

                if isempty(group)
                    ipcMainMatlabCallsHandler(app.mainApp, app, 'onManualMeasurementRemoved', app.StationId, reference.SIADS, reference.SerialNumber)
                else
                    ipcMainMatlabCallsHandler(app.mainApp, app, 'onManualMeasurementChanged', buildManualTable(app, group))
                end
            end
        end

        %-----------------------------------------------------------------%
        function setEquipmentFields(app, siads)
            % Preenche os campos do sensor a partir do patrimônio SIADS (usado 
            % na edição de uma medida e na importação). Retorna sem alterações 
            % caso o patrimônio não conste na planilha de equipamentos.
            equipRow = app.EquipmentTable(app.EquipmentTable.("Patrimônio SIADS") == string(siads), :);
            if isempty(equipRow)
                return
            end

            app.UGatualDropDown.Value = char(equipRow.("UG Atual")(1));
            updateEquipmentItems(app, 'UG')
            app.MarcaModeloDropDown.Value = char(equipRow.MarcaModelo(1));
            updateEquipmentItems(app, 'MarcaModelo')
            app.PatrimnioSIADSNdeSrieDropDown.Value = char(equipRow.SIADSSerial(1));
        end

        %-----------------------------------------------------------------%
        function addMeasurement(app)
            % Latitude, Longitude e Medida são obrigatórios; Altitude é opcional.
            requiredFields = {app.Latitude, app.Longitude, app.Medida};
            requiredLabels = {'Latitude', 'Longitude', 'Medição'};
            missingFields  = cellfun(@(x) isempty(x.Value), requiredFields);

            if any(missingFields)
                ui.Dialog(app.UIFigure, 'warning', sprintf('Preencha o(s) campo(s) obrigatório(s): %s.', strjoin(requiredLabels(missingFields), ', ')));
                focus(requiredFields{find(missingFields, 1)})
                return
            end

            if isnat(app.Datadamedicao.Value)
                ui.Dialog(app.UIFigure, 'warning', 'Preencha o campo obrigatório: Data da medição.');
                focus(app.Datadamedicao)
                return
            end

            timeOfDay = parseTimeOfDay(app, app.Hora.Value);
            if isempty(timeOfDay)
                ui.Dialog(app.UIFigure, 'warning', 'Informe a hora da medição no formato HH:MM (ou HH:MM:SS).');
                focus(app.Hora)
                return
            end

            timestamp = dateshift(app.Datadamedicao.Value, 'start', 'day') + timeOfDay;
            timestamp.Format = 'dd/MM/yyyy HH:mm:ss';

            equipRow = selectedEquipment(app);
            if isempty(app.MarcaModeloDropDown.Value) || isempty(equipRow)
                requiredField = app.MarcaModeloDropDown;
                if ~isempty(app.MarcaModeloDropDown.Value)
                    requiredField = app.PatrimnioSIADSNdeSrieDropDown;
                end
                ui.Dialog(app.UIFigure, 'warning', 'Preencha os campos obrigatórios de identificação do sensor: Marca / Modelo e Patrimônio SIADS / Nº de Série.');
                focus(requiredField)
                return
            end

            measurement = struct( ...
                'Timestamp',    timestamp, ...
                'Latitude',     app.Latitude.Value,  ...
                'Longitude',    app.Longitude.Value, ...
                'Altitude',     app.Altitude.Value,  ...
                'FieldValue',   app.Medida.Value,    ...
                'Sensor',       char(equipRow.MarcaModelo(1)),         ...
                'SIADS',        char(equipRow.("Patrimônio SIADS")(1)), ...
                'SerialNumber', char(equipRow.("Nº de Série")(1)));

            % Caso a medida em edição pertença a outro sensor, o conjunto de
            % origem também precisa ser atualizado no projeto.
            referenceMeasurements = measurement;

            if isscalar(app.EditingNode) && isvalid(app.EditingNode)
                referenceMeasurements(end+1) = app.EditingNode.NodeData;
                app.EditingNode.Text     = measurementNodeText(app, measurement);
                app.EditingNode.NodeData = measurement;
            else
                % Após "Limpar" a árvore fica vazia, mas o projeto mantém as medidas: 
                % elas são recarregadas para não serem sobrescritas na sincronização.
                if isempty(app.TreeMedidas.Children)
                    loadStationMeasurements(app)
                end
                uitreenode(app.TreeMedidas, ...
                    'Text',     measurementNodeText(app, measurement), ...          
                    'NodeData', measurement);
            end
            app.EditingNode = [];

            syncManualMeasurements(app, referenceMeasurements)

            refreshMeasurementPlot(app)
            ensureMeasuresVisible(app)
            clearMeasurementFields(app)
            focus(app.Latitude)
        end

        %-----------------------------------------------------------------%
        function editSelectedMeasurement(app)
            selectedNodes = app.TreeMedidas.SelectedNodes;
            if ~isscalar(selectedNodes)
                ui.Dialog(app.UIFigure, 'warning', 'Selecione um único nó da árvore de medições para editar.');
                return
            end

            measurement = selectedNodes.NodeData;

            app.Latitude.Value      = measurement.Latitude;
            app.Longitude.Value     = measurement.Longitude;
            app.Altitude.Value      = measurement.Altitude;
            app.Medida.Value        = measurement.FieldValue;
            app.Datadamedicao.Value = dateshift(measurement.Timestamp, 'start', 'day');
            app.Hora.Value          = char(string(measurement.Timestamp, 'HH:mm:ss'));
            setEquipmentFields(app, measurement.SIADS)

            % O nó é atualizado (e não duplicado) quando o ícone "Adicionar" for acionado.
            app.EditingNode = selectedNodes;
            focus(app.Latitude)
        end

        %-----------------------------------------------------------------%
        function deleteSelectedMeasurements(app)
            selectedNodes = app.TreeMedidas.SelectedNodes;
            if isempty(selectedNodes)
                return
            end

            if ~isempty(app.EditingNode) && any(selectedNodes == app.EditingNode)
                app.EditingNode = [];
                clearMeasurementFields(app)
            end
            deletedMeasurements = [selectedNodes.NodeData];
            delete(selectedNodes)
            refreshMeasurementPlot(app)
            syncManualMeasurements(app, deletedMeasurements)
        end

        %-----------------------------------------------------------------%
        function timeOfDay = parseTimeOfDay(app, timeText)
            % Retorna duration (hora do dia) ou [] caso o texto seja inválido.
            timeOfDay = [];
            tokens    = regexp(strtrim(timeText), '^(\d{1,2}):(\d{2})(?::(\d{2}))?$', 'tokens', 'once');
            if isempty(tokens)
                return
            end

            % Segundos são opcionais: o regexp omite o token não casado.
            hms = zeros(1, 3);
            hms(1:numel(tokens)) = str2double(tokens);
            hms(isnan(hms)) = 0;
            if hms(1) > 23 || hms(2) > 59 || hms(3) > 59
                return
            end

            timeOfDay = duration(hms(1), hms(2), hms(3));
        end

        %-----------------------------------------------------------------%
        function htmlText = measurementNodeText(app, measurement)
            labelStyle = 'color: #808080; font-size: 10px;';
            indent     = repmat('&nbsp;', 1, 8);
            separator  = '&nbsp;&nbsp;<span style="color: #BEBEBE;">|</span>&nbsp;&nbsp;';

            htmlText   = sprintf([ ...
                '<span style="font-weight: bold; color: #0072BD;">🕒 %s</span><br>' ...
                '%s🌐 %.6f°&nbsp;&nbsp;%.6f°<br>' ...
                '%s<span style="font-weight: bold; color: #D95319;">⚡ %.1f V/m</span>%s' ...
                '<span style="%s">ALT</span> %.1f m'], ...
                char(measurement.Timestamp), ...
                indent, measurement.Latitude, measurement.Longitude, ...
                indent, measurement.FieldValue, separator, ...
                labelStyle, measurement.Altitude);
        end

        %-----------------------------------------------------------------%
        function saveMeasurements(app)
            % As medidas já foram registradas no projeto ao serem adicionadas; 
            % aqui são apenas exportadas para planilha (uma por sensor).
            if isempty(app.TreeMedidas.Children)
                ui.Dialog(app.UIFigure, 'warning', 'Adicione ao menos uma medição à árvore de medições.');
                return
            end

            manualTable = buildManualTable(app, nodeMeasurements(app));
            outputFiles = exportMeasurements(app, manualTable);

            if ~isempty(outputFiles)
                ui.Dialog(app.UIFigure, 'info', sprintf('Planilha(s) salva(s) em:\n%s', strjoin(outputFiles, newline)));
            end
        end

        %-----------------------------------------------------------------%
        function manualTable = buildManualTable(app, measurements)
            % Tabela no formato de app.projectData.modules.MONITORINGPLAN.manualMeasurement:
            % identificação da estação (nº), do sensor e as medidas informadas. 
            numRows    = numel(measurements);
            repeatText = @(x) repmat({char(x)}, numRows, 1);

            manualTable = table( ...
                repmat(app.StationId, numRows, 1), ...
                repeatText(app.StationInfo.Service),       ...
                repeatText(app.StationInfo.Entity),        ...
                repeatText(app.StationInfo.UD),            ...
                {measurements.Sensor}',                    ...
                {measurements.SIADS}',                     ...
                {measurements.SerialNumber}',              ...
                [measurements.Timestamp]',                 ...
                [measurements.Latitude]',                  ...
                [measurements.Longitude]',                 ...
                [measurements.Altitude]',                  ...
                [measurements.FieldValue]',                ...
                'VariableNames', model.ProjectBase.initializeCustomTable('MANUALMEASUREMENT').Properties.VariableNames);
            manualTable.Timestamp.Format = 'dd/MM/yyyy HH:mm:ss';
        end

        %-----------------------------------------------------------------%
        function outputFiles = exportMeasurements(app, manualTable)
            % A planilha comporta um único sensor: havendo mais de um, é 
            % gerado um arquivo por sensor (sufixo numérico). Os dados da 
            % estação não constam em "manualTable", sendo obtidos do formulário.
            stationInfo = struct( ...
                'Latitude',     app.StationCoordinates.Latitude,  ...
                'Longitude',    app.StationCoordinates.Longitude, ...
                'Municipality', app.StationInfo.Municipality,     ...
                'UF',           app.StationInfo.UF);

            outputFiles   = {};
            appName       = class.Constants.appName;
            nameFormatMap = {'*.xlsx', 'Excel (*.xlsx)'};
            defaultName   = appEngine.util.DefaultFileName(app.mainApp.General.fileFolder.userPath, [appName '_ManualMeasurements']);
            outputFile    = ui.Dialog(app.UIFigure, 'uiputfile', '', nameFormatMap, defaultName);
            if isempty(outputFile)
                return
            end

            % O nome sugerido pode conter pontos (data e hora), induzindo a 
            % interpretação de parte dele como extensão do arquivo.
            if ~endsWith(outputFile, '.xlsx', 'IgnoreCase', true)
                outputFile = [outputFile '.xlsx'];
            end

            groupKeys = strcat(string(manualTable.SIADS), '|', string(manualTable.SerialNumber));
            [~, ~, groupIdxs] = unique(groupKeys, 'stable');
            numGroups = max(groupIdxs);

            d = ui.Dialog(app.UIFigure, 'progressdlg', 'Em andamento a criação da planilha de medidas.');

            try
               templateFile = model.ManualMeasurementFile.templateFile(app.mainApp.rootFolder);

               for ii = 1:numGroups
                    groupFile = outputFile;
                    if numGroups > 1
                        [folder, name, ext] = fileparts(outputFile);
                        groupFile = fullfile(folder, sprintf('%s_%d%s', name, ii, ext));
                    end

                    groupTable = manualTable(groupIdxs == ii, :);
                    model.ManualMeasurementFile.write(groupTable, stationInfo, groupFile, templateFile)
                    outputFiles{end+1} = groupFile; %#ok<AGROW>
               end
            catch ME
                ui.Dialog(app.UIFigure, 'error', ME.message);
            end

            delete(d)
        end

        %-----------------------------------------------------------------%
        function openMeasurementFile(app)
            [fileFullPath, fileFolder] = ui.Dialog(app.UIFigure, 'uigetfile', '', {'*.xlsx', 'Excel (*.xlsx)'}, app.mainApp.General.fileFolder.lastVisited, {'MultiSelect', 'off'});
            if isempty(fileFullPath)
                return
            end
            ipcMainMatlabCallsHandler(app.mainApp, app, 'onUpdateLastVisitedFolder', fileFolder)

            if ~isempty(app.TreeMedidas.Children)
                userSelection = ui.Dialog(app.UIFigure, 'uiconfirm', 'A estação da planilha será carregada e as medidas já registradas para o mesmo sensor serão substituídas pelas da planilha. Deseja continuar?', {'Sim', 'Não'}, 2, 2);
                if userSelection == "Não"
                    return
                end
            end

            d = ui.Dialog(app.UIFigure, 'progressdlg', 'Em andamento a leitura da planilha de medidas.');

            try
                data = model.ManualMeasurementFile.read(fileFullPath);
                if isnan(data.Station) || isnan(data.StationLatitude) || isnan(data.StationLongitude)
                    error('Não foi possível identificar o nº e as coordenadas da estação na planilha.')
                end
                applyImportedData(app, data)

            catch ME
                ui.Dialog(app.UIFigure, 'error', ME.message);
            end

            delete(d)
        end

        %-----------------------------------------------------------------%
        function applyImportedData(app, data)
            % A estação é buscada na tabela de referência do PM-RNI. Caso não 
            % seja localizada, são utilizados os dados da própria planilha.
            stationTable = app.mainApp.projectData.modules.MONITORINGPLAN.stationTable;
            stationIdx   = find(double(stationTable.("Estação")) == data.Station & ...
                                string(stationTable.("Município")) == string(data.Municipality) & ...
                                string(stationTable.("UF")) == string(data.UF), 1);
            
            clearForm(app)

            if ~isempty(stationIdx)
                loadStationData(app, stationIdx)
            else
                app.StationIdx              = [];
                app.StationId               = data.Station;
                app.Latitude_3.Value        = data.StationLatitude;
                app.Longitude_3.Value       = data.StationLongitude;
                app.StationInfo             = struct('Service', data.Service, 'Entity', data.Entity, 'UD', data.UD, 'Municipality', data.Municipality, 'UF', data.UF);
                app.StationCoordinates      = struct('Latitude', data.StationLatitude, 'Longitude', data.StationLongitude);
                updateStationNumber(app)
                updateLocationRefresh(app)
                updateLocationPanelLayout(app, 'off')
            end
            loadStationMeasurements(app)
            plotStation(app)

            [sensor, siads, serial, msgWarning] = importedEquipment(app, data.Sensor, data.SIADS);
            importedKey = strjoin(string({sensor, siads, serial}), '|');

            nodes = app.TreeMedidas.Children;
            for ii = numel(nodes):-1:1
                if measurementKey(app, nodes(ii).NodeData) == importedKey
                    delete(nodes(ii))
                end
            end

            for ii = 1:height(data.Measurements)
                measurement = table2struct(data.Measurements(ii, :));
                measurement.Sensor       = sensor;
                measurement.SIADS        = siads;
                measurement.SerialNumber = serial;

                uitreenode(app.TreeMedidas, ...
                    'Text',     measurementNodeText(app, measurement), ...
                    'NodeData', measurement);
            end

            reference = struct('Sensor', sensor, 'SIADS', siads, 'SerialNumber', serial);
            syncManualMeasurements(app, reference)

            % Os campos do sensor e a data da medição são preenchidos para que o 
            % registro de novas medidas prossiga com o mesmo equipamento.
            setEquipmentFields(app, siads)
            app.Datadamedicao.Value = dateshift(data.Measurements.Timestamp(end), 'start', 'day');
            
            refreshMeasurementPlot(app)
            ensureMeasuresVisible(app)

            if ~isempty(msgWarning)
                ui.Dialog(app.UIFigure, 'warning', msgWarning);
            end
        end

        %-----------------------------------------------------------------%
        function [sensor, siads, serial, msgWarning] = importedEquipment(app, sensorText, siads)
            % O equipamento é identificado pelo patrimônio SIADS na planilha de 
            % equipamentos. Caso não conste, são mantidos os dados da planilha importada.
            msgWarning = '';
            sensor     = sensorText;
            serial     = '-';

            equipRow = app.EquipmentTable(app.EquipmentTable.("Patrimônio SIADS") == string(siads), :);
            if isempty(equipRow)
                msgWarning = sprintf('O patrimônio "%s" (medidor "%s") não consta na lista de equipamentos. As medidas foram registradas com os dados da planilha.', siads, sensorText);
                return
            end

            sensor = char(equipRow.MarcaModelo(1));
            serial = char(equipRow.("Nº de Série")(1));
            siads  = char(equipRow.("Patrimônio SIADS")(1));
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp, callingApp, context, stationIdx)
                       
            try
                appEngine.boot(app, app.Role, mainApp, callingApp)
                configureComponents(app)
                createMap(app)
                loadEquipmentTable(app)
                clearForm(app) 
                addStyle(app.TreeMedidas, uistyle('Interpreter', 'html'))
                loadSelectedStation(app, stationIdx)
                
            catch ME
                ui.Dialog(app.UIFigure, 'error', getReport(ME), 'CloseFcn', @(~,~)closeFcn(app));
            end
            
        end

        % Close request function: UIFigure
        function closeFcn(app, event)
            
            delete(app)
            
        end

        % Image clicked function: exportar, importar
        function onImportExportImageClicked(app, event)
            
            switch event.Source
                case app.exportar
                    saveMeasurements(app)

                case app.importar
                    openMeasurementFile(app)
            end

        end

        % Value changed function: Hora
        % Value changing function: Hora
        function onHoraValueChanging(app, event)

            % Também executada ao confirmar o valor (colar texto, Enter, perda 
            % de foco), garantindo que letras e dígitos excedentes sejam 
            % descartados. Mantém apenas dígitos e os agrupa em HH:MM:SS, injetando ":" 
            % entre os grupos. Um dígito que não pode iniciar o grupo (hora > 2, 
            % minuto/segundo > 5) é completado com zero à esquerda, de modo que 
            % "909" resulte em "09:09". O separador só é inserido ao digitar 
            % o dígito seguinte, o que permite apagá-lo com Backspace.
            digits    = regexprep(event.Value, '\D', '');
            maxFirst  = [2 5 5];
            parts     = {};
            pos       = 1;

            for ii = 1:3
                if pos > numel(digits)
                    break
                end

                firstDigit = digits(pos);
                if str2double(firstDigit) > maxFirst(ii)
                    part = ['0' firstDigit];
                    pos  = pos+1;

                elseif pos < numel(digits)
                    part = digits(pos:pos+1);
                    pos  = pos+2;
                    if ii == 1 && str2double(part) > 23
                        part = ['0' firstDigit];
                        pos  = pos-1;
                    end

                else
                    part = firstDigit;
                    pos  = pos+1;
                end

                parts{end+1} = part; %#ok<AGROW>
            end

            formattedText = strjoin(parts, ':');
            if ~strcmp(formattedText, event.Value)
                app.Hora.Value = formattedText;
            end

        end

        % Value changed function: Latitude
        function onRequiredFieldEdited(app, event)
 
            event.Source.UserData = true;
            
        end

        % Selection changed function: TreeMedidas
        function onTreeMenuSelected(app, event)
            
            switch event.Source
                case app.EditNodeMenu
                    editSelectedMeasurement(app)

                case app.DeleteNodeMenu
                    deleteSelectedMeasurements(app)

                case app.TreeMedidas
                    updateMeasurementSelection(app)   
            end
            
        end

        % Key press function: UIFigure
        function onKeyPressed(app, event)

            if isa(app.PreviousKeyPressFcn, 'function_handle')
                app.PreviousKeyPressFcn(app.UIFigure, event)
            end
        
            if ~strcmp(event.Key, 'delete') || isempty(app.TreeMedidas.SelectedNodes)
                return
            end
        
            currentObject = app.UIFigure.CurrentObject;
            isTextInput   = isa(currentObject, 'matlab.ui.control.EditField')        || ...
                            isa(currentObject, 'matlab.ui.control.NumericEditField') || ...
                            isa(currentObject, 'matlab.ui.control.DatePicker')       || ...
                            isa(currentObject, 'matlab.ui.control.TextArea');
        
            if ~isTextInput
                deleteSelectedMeasurements(app)
            end
        end

        % Button down function: UIFigure
        function onTreeDeleted(app, event)
            if isvalid(app.UIFigure) && strcmp(app.UIFigure.BeingDeleted, 'off')
                app.UIFigure.WindowKeyPressFcn = app.PreviousKeyPressFcn;
            end
            delete(app.TreeContextMenu)
        end

        % Value changed function: MarcaModeloDropDown, 
        % ...and 2 other components
        function onEquipamentChanged(app, event)
            
            switch event.Source
                case app.UGatualDropDown
                    updateEquipmentItems(app, 'UG')

                case app.MarcaModeloDropDown
                    updateEquipmentItems(app, 'MarcaModelo')
            end
            
        end

        % Image clicked function: NextSelection, PreviousSelection
        function onStationSelectionChanged(app, event)
           
            if isempty(app.callingApp.UITable.Selection)
                return
            end

            idxStations         = app.callingApp.UITable.UserData;
            idxSelectedRow      = app.callingApp.UITable.Selection;
            idxMaxRow           = height(app.callingApp.UITable.Data);

            switch event.Source
                case app.PreviousSelection
                    idxNewRowSelection = idxSelectedRow - 1;
                case app.NextSelection
                    idxNewRowSelection = idxSelectedRow + 1;
            end

            if idxNewRowSelection < 1
                idxNewRowSelection = idxMaxRow;
            elseif idxNewRowSelection > idxMaxRow
                idxNewRowSelection = 1;
            end

            ipcMainMatlabCallsHandler(app.mainApp, app, 'onStationSelectionChanged', 'MONITORINGPLAN', idxNewRowSelection)
            loadSelectedStation(app, idxStations(idxNewRowSelection))

        end

        % Image clicked function: EstEditionCancel, EstEditionConfirm, 
        % ...and 2 other components
        function onLocationEditionModeChanged(app, event)
            
           switch event.Source
                case app.LocationRefresh
                    restoreStationCoordinates(app)

                case app.ImageEdit
                    if app.IsStationEditing
                        cancelStationEdition(app)
                    else
                        updateLocationPanelLayout(app, 'on')
                        focus(app.Latitude_3)
                    end

                case app.EstEditionConfirm
                    confirmStationEdition(app)

                case app.EstEditionCancel
                    cancelStationEdition(app)
            end 

        end

        % Value changed function: Latitude_3
        function onStationCoordinatesChanged(app, event)
            
           plotStation(app, false)
            updateStationROI(app)

            switch event.Source
                case app.Latitude_3
                    focus(app.Longitude_3)
                case app.Longitude_3
                    focus(app.EstEditionConfirm)
            end
            
        end

        % Image clicked function: Add
        function onAddImageClicked(app, event)

            addMeasurement(app)
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app, Container)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            if isempty(Container)
                app.UIFigure = uifigure('Visible', 'off');
                app.UIFigure.AutoResizeChildren = 'off';
                app.UIFigure.Position = [100 100 968 722];
                app.UIFigure.Name = 'monitorRNI';
                app.UIFigure.Icon = 'icon_48.png';
                app.UIFigure.Resize = 'off';
                app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeFcn, true);
                app.UIFigure.ButtonDownFcn = createCallbackFcn(app, @onTreeDeleted, true);
                app.UIFigure.KeyPressFcn = createCallbackFcn(app, @onKeyPressed, true);

                app.Container = app.UIFigure;

            else
                children = Container.Children;
                if isa(Container, 'matlab.ui.Figure') && isprop(Container, 'RunningAppInstance') && isprop(Container.RunningAppInstance, 'jsBackDoor')
                    children(children == Container.RunningAppInstance.jsBackDoor) = [];
                end
                delete(children)

                app.UIFigure  = ancestor(Container, 'figure');
                app.Container = Container;
                if ~isprop(Container, 'RunningAppInstance')
                    addprop(app.Container, 'RunningAppInstance');
                end
                app.Container.RunningAppInstance = app;
                app.isDocked  = true;
            end

            % Create GridLayout
            app.GridLayout = uigridlayout(app.Container);
            app.GridLayout.ColumnWidth = {22, 22, 180, 22, 1, '1x', 24, 24};
            app.GridLayout.RowHeight = {44, 22, 60, 22, 121, 22, 179, 22, '1x', 1, 22};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;
            app.GridLayout.Padding = [20 15 20 20];
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create PreviousSelection
            app.PreviousSelection = uiimage(app.GridLayout);
            app.PreviousSelection.ImageClickedFcn = createCallbackFcn(app, @onStationSelectionChanged, true);
            app.PreviousSelection.Layout.Row = 1;
            app.PreviousSelection.Layout.Column = 7;
            app.PreviousSelection.ImageSource = 'chevron-left.svg';

            % Create SummaryLabel
            app.SummaryLabel = uilabel(app.GridLayout);
            app.SummaryLabel.VerticalAlignment = 'bottom';
            app.SummaryLabel.FontSize = 10;
            app.SummaryLabel.FontColor = [0 0 0];
            app.SummaryLabel.Layout.Row = 4;
            app.SummaryLabel.Layout.Column = [1 3];
            app.SummaryLabel.Text = 'SENSOR';

            % Create EditableFieldsLabel
            app.EditableFieldsLabel = uilabel(app.GridLayout);
            app.EditableFieldsLabel.VerticalAlignment = 'bottom';
            app.EditableFieldsLabel.FontSize = 10;
            app.EditableFieldsLabel.FontColor = [0 0 0];
            app.EditableFieldsLabel.Layout.Row = 6;
            app.EditableFieldsLabel.Layout.Column = [1 3];
            app.EditableFieldsLabel.Text = 'MEDIDAS';

            % Create TreeMedidas
            app.TreeMedidas = uitree(app.GridLayout);
            app.TreeMedidas.SelectionChangedFcn = createCallbackFcn(app, @onTreeMenuSelected, true);
            app.TreeMedidas.Layout.Row = 9;
            app.TreeMedidas.Layout.Column = [1 4];

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.BackgroundColor = [1 1 1];
            app.Panel.Layout.Row = [3 9];
            app.Panel.Layout.Column = [6 8];

            % Create Panel_2
            app.Panel_2 = uipanel(app.GridLayout);
            app.Panel_2.Layout.Row = 7;
            app.Panel_2.Layout.Column = [1 4];

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.Panel_2);
            app.GridLayout6.RowHeight = {22, 22, 22, 22, 22, 22};
            app.GridLayout6.RowSpacing = 5;
            app.GridLayout6.BackgroundColor = [1 1 1];

            % Create DatadamedioDatePickerLabel
            app.DatadamedioDatePickerLabel = uilabel(app.GridLayout6);
            app.DatadamedioDatePickerLabel.VerticalAlignment = 'bottom';
            app.DatadamedioDatePickerLabel.FontSize = 11;
            app.DatadamedioDatePickerLabel.Layout.Row = 1;
            app.DatadamedioDatePickerLabel.Layout.Column = 1;
            app.DatadamedioDatePickerLabel.Text = 'Data da medição:';

            % Create HoraEditFieldLabel_2
            app.HoraEditFieldLabel_2 = uilabel(app.GridLayout6);
            app.HoraEditFieldLabel_2.VerticalAlignment = 'bottom';
            app.HoraEditFieldLabel_2.FontSize = 11;
            app.HoraEditFieldLabel_2.Layout.Row = 1;
            app.HoraEditFieldLabel_2.Layout.Column = 2;
            app.HoraEditFieldLabel_2.Text = 'Hora';

            % Create Datadamedicao
            app.Datadamedicao = uidatepicker(app.GridLayout6);
            app.Datadamedicao.Layout.Row = 2;
            app.Datadamedicao.Layout.Column = 1;

            % Create Hora
            app.Hora = uieditfield(app.GridLayout6, 'text');
            app.Hora.ValueChangingFcn = createCallbackFcn(app, @onHoraValueChanging, true);
            app.Hora.ValueChangedFcn = createCallbackFcn(app, @onHoraValueChanging, true);
            app.Hora.HorizontalAlignment = 'right';
            app.Hora.FontSize = 11;
            app.Hora.Placeholder = 'HH:MM';
            app.Hora.Layout.Row = 2;
            app.Hora.Layout.Column = 2;

            % Create LatitudeLabel_2
            app.LatitudeLabel_2 = uilabel(app.GridLayout6);
            app.LatitudeLabel_2.VerticalAlignment = 'bottom';
            app.LatitudeLabel_2.FontSize = 11;
            app.LatitudeLabel_2.Layout.Row = 3;
            app.LatitudeLabel_2.Layout.Column = 1;
            app.LatitudeLabel_2.Text = 'Latitude:';

            % Create LongitudeLabel_2
            app.LongitudeLabel_2 = uilabel(app.GridLayout6);
            app.LongitudeLabel_2.VerticalAlignment = 'bottom';
            app.LongitudeLabel_2.FontSize = 11;
            app.LongitudeLabel_2.Layout.Row = 3;
            app.LongitudeLabel_2.Layout.Column = 2;
            app.LongitudeLabel_2.Text = 'Longitude:';

            % Create Latitude
            app.Latitude = uieditfield(app.GridLayout6, 'numeric');
            app.Latitude.Limits = [-90 90];
            app.Latitude.ValueDisplayFormat = '%.6f';
            app.Latitude.ValueChangedFcn = createCallbackFcn(app, @onRequiredFieldEdited, true);
            app.Latitude.FontSize = 11;
            app.Latitude.Layout.Row = 4;
            app.Latitude.Layout.Column = 1;

            % Create Longitude
            app.Longitude = uieditfield(app.GridLayout6, 'numeric');
            app.Longitude.Limits = [-180 180];
            app.Longitude.ValueDisplayFormat = '%.6f';
            app.Longitude.FontSize = 11;
            app.Longitude.FontColor = [0 0 0];
            app.Longitude.Layout.Row = 4;
            app.Longitude.Layout.Column = 2;

            % Create LongitudeLabel_4
            app.LongitudeLabel_4 = uilabel(app.GridLayout6);
            app.LongitudeLabel_4.VerticalAlignment = 'bottom';
            app.LongitudeLabel_4.FontSize = 11;
            app.LongitudeLabel_4.Layout.Row = 5;
            app.LongitudeLabel_4.Layout.Column = 1;
            app.LongitudeLabel_4.Text = 'Medição (V/m)';

            % Create LongitudeLabel_3
            app.LongitudeLabel_3 = uilabel(app.GridLayout6);
            app.LongitudeLabel_3.VerticalAlignment = 'bottom';
            app.LongitudeLabel_3.FontSize = 11;
            app.LongitudeLabel_3.Layout.Row = 5;
            app.LongitudeLabel_3.Layout.Column = 2;
            app.LongitudeLabel_3.Text = 'Altura';

            % Create Medida
            app.Medida = uieditfield(app.GridLayout6, 'numeric');
            app.Medida.Limits = [-180 180];
            app.Medida.ValueDisplayFormat = '%.1f';
            app.Medida.FontSize = 11;
            app.Medida.Layout.Row = 6;
            app.Medida.Layout.Column = 1;

            % Create Altitude
            app.Altitude = uieditfield(app.GridLayout6, 'numeric');
            app.Altitude.Limits = [-180 180];
            app.Altitude.ValueDisplayFormat = '%.1f';
            app.Altitude.FontSize = 11;
            app.Altitude.Layout.Row = 6;
            app.Altitude.Layout.Column = 2;

            % Create Panel_3
            app.Panel_3 = uipanel(app.GridLayout);
            app.Panel_3.Layout.Row = 5;
            app.Panel_3.Layout.Column = [1 4];

            % Create EditableFieldsGrid_2
            app.EditableFieldsGrid_2 = uigridlayout(app.Panel_3);
            app.EditableFieldsGrid_2.ColumnWidth = {'0.5x', '1x'};
            app.EditableFieldsGrid_2.RowHeight = {22, 22, 22, 22};
            app.EditableFieldsGrid_2.RowSpacing = 5;
            app.EditableFieldsGrid_2.Padding = [10 10 10 5];
            app.EditableFieldsGrid_2.BackgroundColor = [1 1 1];

            % Create MarcaModeloDropDownLabel
            app.MarcaModeloDropDownLabel = uilabel(app.EditableFieldsGrid_2);
            app.MarcaModeloDropDownLabel.VerticalAlignment = 'bottom';
            app.MarcaModeloDropDownLabel.FontSize = 11;
            app.MarcaModeloDropDownLabel.Layout.Row = 1;
            app.MarcaModeloDropDownLabel.Layout.Column = 2;
            app.MarcaModeloDropDownLabel.Text = 'Marca/Modelo:';

            % Create MarcaModeloDropDown
            app.MarcaModeloDropDown = uidropdown(app.EditableFieldsGrid_2);
            app.MarcaModeloDropDown.Items = {};
            app.MarcaModeloDropDown.ValueChangedFcn = createCallbackFcn(app, @onEquipamentChanged, true);
            app.MarcaModeloDropDown.FontSize = 11;
            app.MarcaModeloDropDown.BackgroundColor = [1 1 1];
            app.MarcaModeloDropDown.Layout.Row = 2;
            app.MarcaModeloDropDown.Layout.Column = 2;
            app.MarcaModeloDropDown.Value = {};

            % Create PatrimnioSIADSNdeSrieDropDownLabel
            app.PatrimnioSIADSNdeSrieDropDownLabel = uilabel(app.EditableFieldsGrid_2);
            app.PatrimnioSIADSNdeSrieDropDownLabel.VerticalAlignment = 'bottom';
            app.PatrimnioSIADSNdeSrieDropDownLabel.FontSize = 11;
            app.PatrimnioSIADSNdeSrieDropDownLabel.Layout.Row = 3;
            app.PatrimnioSIADSNdeSrieDropDownLabel.Layout.Column = [1 2];
            app.PatrimnioSIADSNdeSrieDropDownLabel.Text = 'Identificação:';

            % Create PatrimnioSIADSNdeSrieDropDown
            app.PatrimnioSIADSNdeSrieDropDown = uidropdown(app.EditableFieldsGrid_2);
            app.PatrimnioSIADSNdeSrieDropDown.Items = {};
            app.PatrimnioSIADSNdeSrieDropDown.ValueChangedFcn = createCallbackFcn(app, @onEquipamentChanged, true);
            app.PatrimnioSIADSNdeSrieDropDown.FontSize = 11;
            app.PatrimnioSIADSNdeSrieDropDown.BackgroundColor = [1 1 1];
            app.PatrimnioSIADSNdeSrieDropDown.Layout.Row = 4;
            app.PatrimnioSIADSNdeSrieDropDown.Layout.Column = [1 2];
            app.PatrimnioSIADSNdeSrieDropDown.Value = {};

            % Create UGatualDropDownLabel
            app.UGatualDropDownLabel = uilabel(app.EditableFieldsGrid_2);
            app.UGatualDropDownLabel.VerticalAlignment = 'bottom';
            app.UGatualDropDownLabel.FontSize = 11;
            app.UGatualDropDownLabel.Layout.Row = 1;
            app.UGatualDropDownLabel.Layout.Column = 1;
            app.UGatualDropDownLabel.Text = 'Unidade:';

            % Create UGatualDropDown
            app.UGatualDropDown = uidropdown(app.EditableFieldsGrid_2);
            app.UGatualDropDown.Items = {};
            app.UGatualDropDown.ValueChangedFcn = createCallbackFcn(app, @onEquipamentChanged, true);
            app.UGatualDropDown.FontSize = 11;
            app.UGatualDropDown.BackgroundColor = [1 1 1];
            app.UGatualDropDown.Layout.Row = 2;
            app.UGatualDropDown.Layout.Column = 1;
            app.UGatualDropDown.Value = {};

            % Create Panel_4
            app.Panel_4 = uipanel(app.GridLayout);
            app.Panel_4.Layout.Row = 3;
            app.Panel_4.Layout.Column = [1 4];

            % Create LocationPanelGrid_3
            app.LocationPanelGrid_3 = uigridlayout(app.Panel_4);
            app.LocationPanelGrid_3.RowHeight = {17, 22};
            app.LocationPanelGrid_3.RowSpacing = 5;
            app.LocationPanelGrid_3.Padding = [10 10 10 5];
            app.LocationPanelGrid_3.BackgroundColor = [1 1 1];

            % Create LatitudeLabel_4
            app.LatitudeLabel_4 = uilabel(app.LocationPanelGrid_3);
            app.LatitudeLabel_4.VerticalAlignment = 'bottom';
            app.LatitudeLabel_4.FontSize = 11;
            app.LatitudeLabel_4.Layout.Row = 1;
            app.LatitudeLabel_4.Layout.Column = 1;
            app.LatitudeLabel_4.Text = 'Latitude:';

            % Create Latitude_3
            app.Latitude_3 = uieditfield(app.LocationPanelGrid_3, 'numeric');
            app.Latitude_3.Limits = [-90 90];
            app.Latitude_3.ValueDisplayFormat = '%.6f';
            app.Latitude_3.ValueChangedFcn = createCallbackFcn(app, @onStationCoordinatesChanged, true);
            app.Latitude_3.Editable = 'off';
            app.Latitude_3.FontSize = 11;
            app.Latitude_3.Layout.Row = 2;
            app.Latitude_3.Layout.Column = 1;

            % Create LongitudeLabel_6
            app.LongitudeLabel_6 = uilabel(app.LocationPanelGrid_3);
            app.LongitudeLabel_6.VerticalAlignment = 'bottom';
            app.LongitudeLabel_6.FontSize = 11;
            app.LongitudeLabel_6.Layout.Row = 1;
            app.LongitudeLabel_6.Layout.Column = 2;
            app.LongitudeLabel_6.Text = 'Longitude:';

            % Create Longitude_3
            app.Longitude_3 = uieditfield(app.LocationPanelGrid_3, 'numeric');
            app.Longitude_3.Limits = [-180 180];
            app.Longitude_3.ValueDisplayFormat = '%.6f';
            app.Longitude_3.Editable = 'off';
            app.Longitude_3.FontSize = 11;
            app.Longitude_3.Layout.Row = 2;
            app.Longitude_3.Layout.Column = 2;

            % Create NextSelection
            app.NextSelection = uiimage(app.GridLayout);
            app.NextSelection.ImageClickedFcn = createCallbackFcn(app, @onStationSelectionChanged, true);
            app.NextSelection.Layout.Row = 1;
            app.NextSelection.Layout.Column = 8;
            app.NextSelection.ImageSource = 'chevron-right.svg';

            % Create Title_2
            app.Title_2 = uilabel(app.GridLayout);
            app.Title_2.VerticalAlignment = 'top';
            app.Title_2.FontSize = 15;
            app.Title_2.FontColor = [0.1294 0.2 0.2392];
            app.Title_2.Layout.Row = 1;
            app.Title_2.Layout.Column = [1 6];
            app.Title_2.Interpreter = 'html';
            app.Title_2.Text = {'<b>Registro manual de medições</b>'; '<font style="font-size: 11px;">Registre, importe e exporte medidas pontuais feitas no entorno da estação para compor a análise do PM-RNI</font>'};

            % Create Add
            app.Add = uiimage(app.GridLayout);
            app.Add.ScaleMethod = 'none';
            app.Add.ImageClickedFcn = createCallbackFcn(app, @onAddImageClicked, true);
            app.Add.Layout.Row = 8;
            app.Add.Layout.Column = 4;
            app.Add.ImageSource = 'Add_16.png';

            % Create importar
            app.importar = uiimage(app.GridLayout);
            app.importar.ScaleMethod = 'none';
            app.importar.ImageClickedFcn = createCallbackFcn(app, @onImportExportImageClicked, true);
            app.importar.Layout.Row = 11;
            app.importar.Layout.Column = 1;
            app.importar.ImageSource = 'Import_16.png';

            % Create exportar
            app.exportar = uiimage(app.GridLayout);
            app.exportar.ScaleMethod = 'none';
            app.exportar.ImageClickedFcn = createCallbackFcn(app, @onImportExportImageClicked, true);
            app.exportar.Layout.Row = 11;
            app.exportar.Layout.Column = 2;
            app.exportar.ImageSource = 'Export_16.png';

            % Create GridLayout7
            app.GridLayout7 = uigridlayout(app.GridLayout);
            app.GridLayout7.ColumnWidth = {'1x', 18, 18, 0, 0};
            app.GridLayout7.RowHeight = {22, '1x'};
            app.GridLayout7.ColumnSpacing = 5;
            app.GridLayout7.Padding = [0 0 0 0];
            app.GridLayout7.Layout.Row = 2;
            app.GridLayout7.Layout.Column = [1 4];
            app.GridLayout7.BackgroundColor = [1 1 1];

            % Create Title_3
            app.Title_3 = uilabel(app.GridLayout7);
            app.Title_3.VerticalAlignment = 'bottom';
            app.Title_3.FontSize = 10;
            app.Title_3.FontColor = [0 0 0];
            app.Title_3.Layout.Row = 1;
            app.Title_3.Layout.Column = 1;
            app.Title_3.Text = 'ESTAÇÃO';

            % Create ImageEdit
            app.ImageEdit = uiimage(app.GridLayout7);
            app.ImageEdit.ImageClickedFcn = createCallbackFcn(app, @onLocationEditionModeChanged, true);
            app.ImageEdit.Layout.Row = 1;
            app.ImageEdit.Layout.Column = 3;
            app.ImageEdit.HorizontalAlignment = 'left';
            app.ImageEdit.ImageSource = 'Edit_32.png';

            % Create LocationRefresh
            app.LocationRefresh = uiimage(app.GridLayout7);
            app.LocationRefresh.ScaleMethod = 'none';
            app.LocationRefresh.ImageClickedFcn = createCallbackFcn(app, @onLocationEditionModeChanged, true);
            app.LocationRefresh.Visible = 'off';
            app.LocationRefresh.Layout.Row = 1;
            app.LocationRefresh.Layout.Column = 2;
            app.LocationRefresh.VerticalAlignment = 'bottom';
            app.LocationRefresh.ImageSource = 'Refresh_18.png';

            % Create EstEditionConfirm
            app.EstEditionConfirm = uiimage(app.GridLayout7);
            app.EstEditionConfirm.ImageClickedFcn = createCallbackFcn(app, @onLocationEditionModeChanged, true);
            app.EstEditionConfirm.Enable = 'off';
            app.EstEditionConfirm.Layout.Row = 1;
            app.EstEditionConfirm.Layout.Column = 4;
            app.EstEditionConfirm.VerticalAlignment = 'bottom';
            app.EstEditionConfirm.ImageSource = 'Ok_32Green.png';

            % Create EstEditionCancel
            app.EstEditionCancel = uiimage(app.GridLayout7);
            app.EstEditionCancel.ImageClickedFcn = createCallbackFcn(app, @onLocationEditionModeChanged, true);
            app.EstEditionCancel.Enable = 'off';
            app.EstEditionCancel.Layout.Row = 1;
            app.EstEditionCancel.Layout.Column = 5;
            app.EstEditionCancel.VerticalAlignment = 'bottom';
            app.EstEditionCancel.ImageSource = 'Delete_32Red.png';

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.GridLayout);
            app.GridLayout8.ColumnWidth = {15, '1x'};
            app.GridLayout8.RowHeight = {22};
            app.GridLayout8.ColumnSpacing = 0;
            app.GridLayout8.Padding = [0 10 10 0];
            app.GridLayout8.Layout.Row = [10 11];
            app.GridLayout8.Layout.Column = 6;

            % Create StationNumber
            app.StationNumber = uilabel(app.GridLayout8);
            app.StationNumber.FontSize = 11;
            app.StationNumber.FontWeight = 'bold';
            app.StationNumber.FontColor = [0 0 0];
            app.StationNumber.Layout.Row = 1;
            app.StationNumber.Layout.Column = 2;
            app.StationNumber.Text = '';

            % Create StationPin
            app.StationPin = uiimage(app.GridLayout8);
            app.StationPin.ScaleMethod = 'none';
            app.StationPin.Layout.Row = 1;
            app.StationPin.Layout.Column = 1;
            app.StationPin.HorizontalAlignment = 'left';
            app.StationPin.ImageSource = 'location-station.svg';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = dockManualMeasurement_exported(Container, varargin)

            % Create UIFigure and components
            createComponents(app, Container)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            if app.isDocked
                children = app.Container.Children;
                if isa(app.Container, 'matlab.ui.Figure') && isprop(app.Container, 'RunningAppInstance') && isprop(app.Container.RunningAppInstance, 'jsBackDoor')
                    children(children == app.Container.RunningAppInstance.jsBackDoor) = [];
                end
                delete(children)
            else
                delete(app.UIFigure)
            end
        end
    end
end
