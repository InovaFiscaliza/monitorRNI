function MetadataOutput = Metadata(app, Type_Meas_Probes, File_Sondas, Num_Lines_File)

    % Extract metadata
    fileName = File_Sondas;
    fileSize = Num_Lines_File; % Número linhas com dados úteis do arquivo
    TypeSonda = Type_Meas_Probes; % Tipo de sonda

    % fileInfo = 'C:\P&D\AppRNI\Metadata';
    
    % Specify the path to the output metadata file
    outputFilePath = 'C:\P&D\AppRNI\Metadata\Metadata_output.txt';
    
    % Open the output file for writing
    fileID = fopen(outputFilePath, 'w');
    
    % Write the metadata to the file
    fprintf(fileID, 'Nome do arquivo: %s\n', fileName);
    fprintf(fileID, 'Número de linhas do arquivo: %d\n', fileSize);
    fprintf(fileID, 'Tipo de sonda: %s\n', TypeSonda);
    
    % Close the file
    fclose(fileID);
    
    % Display a message indicating success
    fprintf('Metadata has been saved to %s\n', outputFilePath);
end