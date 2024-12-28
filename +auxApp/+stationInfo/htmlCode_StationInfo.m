function htmlContent = htmlCode_StationInfo(stationTable, idxStation, rfDataHub)

    % PM-RNI
    % (planilha de referência)
    stationTable = stationTable(idxStation, :);
    stationID    = stationTable.("N° estacao");

    stationEntity   = '';
    if ~isempty(stationTable.("Entidade"){1})
        stationEntity = [stationTable.("Entidade"){1} ' '];
    end

    stationAddress  = '';
    if ~isempty(stationTable.("Endereco"){1})
        stationAddress = sprintf(', Endereço="%s"', stationTable.("Endereco"){1});
    end

    stationCritical = '';
    if ~isempty(stationTable.("Áreas Críticas"){1})
        stationCritical = sprintf('\nÁreas críticas: %s', stationTable.("Áreas Críticas"){1});
    end    

    stationMonitoringPlan  = sprintf('%s, %s(Fistel=%.0f, Estação=%.0f), %s/%s @ (Latitude=%.6fº, Longitude=%.6fº%s)%s', ...
        upper(stationTable.("Serviço"){1}), stationEntity, stationTable.("Fistel")(1), stationTable.("N° estacao")(1), stationTable.("Município"){1}, stationTable.UF{1}, ...
        stationTable.("Lat")(1), stationTable.("Long")(1), stationAddress, stationCritical);

    % RFDATAHUB
    rfDataHub    = rfDataHub;
    idxRFDataHub = find(rfDataHub.Station == stationID);

    if ~isempty(idxRFDataHub)
        % Frequência central e descrição:
        stationRFDataHub   = {};
        for ii = idxRFDataHub'
            stationTag     = sprintf('%.3f MHz', rfDataHub.Frequency(ii));
            if rfDataHub.BW(ii) > 0
                stationTag = [stationTag sprintf(' ⌂ %.1f kHz', rfDataHub.BW(ii))];
            end
            stationRFDataHub{end+1} = [stationTag newline class.RFDataHub.Description(rfDataHub, ii)];
        end
        stationRFDataHub   = strjoin(unique(stationRFDataHub), '\n\n');

    else
        stationRFDataHub   = '(registro não encontrado na base do RFDataHub)';
    end

    dataStruct(1)  = struct('group', 'PM-RNI', 'value', stationMonitoringPlan);
    dataStruct(2)  = struct('group', 'RFDATAHUB',   'value', stationRFDataHub);

    htmlContent{1} = sprintf('<p style="font-family: Helvetica, Arial, sans-serif; font-size: 16px; text-align: justify; line-height: 12px; margin: 5px; padding-top: 5px; padding-bottom: 10px;"><b>Estação nº %.0f</b></p>', stationID);
    htmlContent{2} = textFormatGUI.struct2PrettyPrintList(dataStruct, 'delete');
    htmlContent    = strjoin(htmlContent);
end