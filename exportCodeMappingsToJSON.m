function exportCodeMappingsToJSON(modelName, outputFile)
% EXPORTCODEMAPPINGSTOJSON  
% Comprehensive extraction of C++ code mapping information from Simulink model
% Based on official MathWorks documentation for coder.mapping.api.CodeMappingCPP
%
% Usage:
%   exportCodeMappingsToJSON('myModel', 'complete_codeMappings.json')

    if nargin < 2
        outputFile = 'complete_codeMappings.json';
    end

    fprintf('🔍 Extracting C++ Code Mappings from model: %s\n', modelName);
    
    % Ensure model is loaded
    try
        load_system(modelName);
    catch ME
        error('Failed to load model "%s": %s', modelName, ME.message);
    end

    % Get the CodeMappingCPP object
    try
        cm = coder.mapping.api.get(modelName);
    catch ME
        error('Failed to get code mapping for model "%s": %s', modelName, ME.message);
    end

    if ~isa(cm, 'coder.mapping.api.CodeMappingCPP')
        error('❌ Model "%s" uses %s, not CodeMappingCPP', modelName, class(cm));
    end

    fprintf('✅ CodeMappingCPP object obtained successfully\n');

    % Initialize complete mapping information structure
    mappingInfo = struct();
    mappingInfo.ModelName = modelName;
    mappingInfo.MappingType = 'coder.mapping.api.CodeMappingCPP';
    mappingInfo.ExportTimestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

    %% === 1. CLASS AND NAMESPACE INFORMATION ===
    fprintf('📝 Extracting class and namespace information...\n');
    
    try
        mappingInfo.ClassName = getClassName(cm);
        fprintf('   Class Name: %s\n', mappingInfo.ClassName);
    catch ME
        mappingInfo.ClassName = '';
        fprintf('   ❌ Class Name: %s\n', ME.message);
    end
    
    try
        mappingInfo.ClassNamespace = getClassNamespace(cm);
        fprintf('   Class Namespace: %s\n', mappingInfo.ClassNamespace);
    catch ME
        mappingInfo.ClassNamespace = '';
        fprintf('   ❌ Class Namespace: %s\n', ME.message);
    end

    %% === 2. DATA CATEGORIES MAPPING ===
    fprintf('📊 Extracting data categories mapping...\n');
    
    % Official data categories from documentation
    dataCategories = {'Inports', 'Outports', 'ModelParameters', 'ModelParameterArguments', 'InternalData'};
    mappingInfo.DataCategories = struct();
    
    for i = 1:length(dataCategories)
        category = dataCategories{i};
        fprintf('   Processing %s...\n', category);
        
        categoryInfo = struct();
        
        % Find elements in this category using find() method
        try
            elements = find(cm, category);
            categoryInfo.ElementCount = length(elements);
            categoryInfo.Elements = elements;
            fprintf('      Found %d elements\n', length(elements));
        catch ME
            categoryInfo.ElementCount = 0;
            categoryInfo.Elements = {};
            fprintf('      ❌ Error finding elements: %s\n', ME.message);
        end
        
        % Get data properties using getData() method for each documented property
        dataProperties = {'MemberAccessMethod', 'DataVisibility', 'DataAccess'};
        categoryInfo.Properties = struct();
        
        for j = 1:length(dataProperties)
            prop = dataProperties{j};
            try
                value = getData(cm, category, prop);
                categoryInfo.Properties.(prop) = value;
                fprintf('      %s: %s\n', prop, value);
            catch ME
                categoryInfo.Properties.(prop) = sprintf('<<Error: %s>>', ME.message);
                fprintf('      ❌ %s: %s\n', prop, ME.message);
            end
        end
        
        mappingInfo.DataCategories.(category) = categoryInfo;
    end

    %% === 3. FUNCTION MAPPING INFORMATION ===
    fprintf('🔧 Extracting function mapping information...\n');
    
    % Function types from documentation
    functionTypes = {'Initialize', 'Terminate', 'Periodic'};
    mappingInfo.Functions = struct();
    
    for i = 1:length(functionTypes)
        funcType = functionTypes{i};
        fprintf('   Processing %s function...\n', funcType);
        
        functionInfo = struct();
        
        % Get function properties using getFunction() method
        functionProperties = {'MethodName', 'Arguments'};
        
        for j = 1:length(functionProperties)
            prop = functionProperties{j};
            try
                value = getFunction(cm, funcType, prop);
                functionInfo.(prop) = value;
                fprintf('      %s: %s\n', prop, value);
            catch ME
                functionInfo.(prop) = sprintf('<<Error: %s>>', ME.message);
                fprintf('      ❌ %s: %s\n', prop, ME.message);
            end
        end
        
        mappingInfo.Functions.(funcType) = functionInfo;
    end
    
    % Try to find additional function types using find() method
    fprintf('   Searching for additional functions...\n');
    try
        allFunctions = find(cm, 'Functions');
        mappingInfo.AdditionalFunctions = struct();
        mappingInfo.AdditionalFunctions.Count = length(allFunctions);
        mappingInfo.AdditionalFunctions.List = allFunctions;
        fprintf('      Found %d additional functions\n', length(allFunctions));
        
        % Extract properties for each found function
        additionalFunctionDetails = {};
        for k = 1:length(allFunctions)
            funcName = allFunctions{k};
            funcDetail = struct();
            funcDetail.Name = funcName;
            
            for prop = {'MethodName', 'Arguments'}
                try
                    value = getFunction(cm, funcName, prop{1});
                    funcDetail.(prop{1}) = value;
                catch ME
                    funcDetail.(prop{1}) = sprintf('<<Error: %s>>', ME.message);
                end
            end
            additionalFunctionDetails{end+1} = funcDetail;
        end
        mappingInfo.AdditionalFunctions.Details = additionalFunctionDetails;
        
    catch ME
        mappingInfo.AdditionalFunctions = struct('Error', ME.message);
        fprintf('      ❌ Error finding functions: %s\n', ME.message);
    end

    %% === 4. FIND ALL DISCOVERABLE CATEGORIES ===
    fprintf('🔍 Discovering all available categories...\n');
    
    % Try to find other potential categories
    possibleCategories = {'Signals', 'Parameters', 'States', 'SharedLocalDataStores'};
    mappingInfo.DiscoveredCategories = struct();
    
    for i = 1:length(possibleCategories)
        category = possibleCategories{i};
        try
            elements = find(cm, category);
            mappingInfo.DiscoveredCategories.(category) = struct(...
                'ElementCount', length(elements), ...
                'Elements', elements);
            fprintf('   %s: %d elements\n', category, length(elements));
        catch ME
            mappingInfo.DiscoveredCategories.(category) = struct('Error', ME.message);
            fprintf('   ❌ %s: %s\n', category, ME.message);
        end
    end

    %% === 5. COMPREHENSIVE OBJECT INTROSPECTION ===
    fprintf('🔬 Performing object introspection...\n');
    
    try
        % Get all public methods and properties using metaclass
        mc = metaclass(cm);
        
        introspection = struct();
        
        % Document all public methods
        publicMethods = {};
        for m = 1:length(mc.MethodList)
            method = mc.MethodList(m);
            if strcmp(method.Access, 'public') && ~method.Hidden && ~method.Static
                methodInfo = struct();
                methodInfo.Name = method.Name;
                methodInfo.Description = method.Description;
                if ~isempty(method.InputNames)
                    methodInfo.InputNames = method.InputNames;
                end
                try
                    methodInfo.OutputNames = method.OutputNames;
                catch
                    methodInfo.OutputNames = {};
                end
                publicMethods{end+1} = methodInfo;
            end
        end
        introspection.PublicMethods = publicMethods;
        
        % Document all accessible properties
        publicProperties = {};
        for p = 1:length(mc.PropertyList)
            prop = mc.PropertyList(p);
            if strcmp(prop.GetAccess, 'public') && ~prop.Hidden
                propInfo = struct();
                propInfo.Name = prop.Name;
                propInfo.GetAccess = prop.GetAccess;
                propInfo.SetAccess = prop.SetAccess;
                propInfo.Description = prop.Description;
                publicProperties{end+1} = propInfo;
            end
        end
        introspection.PublicProperties = publicProperties;
        
        mappingInfo.ObjectIntrospection = introspection;
        fprintf('   Found %d methods, %d properties\n', length(publicMethods), length(publicProperties));
        
    catch ME
        mappingInfo.ObjectIntrospection = struct('Error', ME.message);
        fprintf('   ❌ Introspection failed: %s\n', ME.message);
    end

    %% === 6. SAVE COMPLETE MAPPING DATA ===
    fprintf('💾 Saving comprehensive mapping data...\n');
    
    try
        jsonStr = jsonencode(mappingInfo, 'PrettyPrint', true);
        fid = fopen(outputFile, 'w', 'n', 'UTF-8');
        if fid == -1
            error('Cannot open file %s for writing', outputFile);
        end
        fwrite(fid, jsonStr, 'char');
        fclose(fid);
        
        % Get file statistics
        fileInfo = dir(outputFile);
        fileSizeKB = fileInfo.bytes / 1024;
        
        fprintf('✅ Complete C++ code mapping exported to: %s\n', outputFile);
        fprintf('📄 File size: %.1f KB\n', fileSizeKB);
        fprintf('📈 Export Summary:\n');
        fprintf('   - Model: %s\n', modelName);
        fprintf('   - Class Name: %s\n', mappingInfo.ClassName);
        fprintf('   - Class Namespace: %s\n', mappingInfo.ClassNamespace);
        fprintf('   - Data Categories: %d\n', length(fieldnames(mappingInfo.DataCategories)));
        fprintf('   - Functions: %d\n', length(fieldnames(mappingInfo.Functions)));
        if isfield(mappingInfo, 'ObjectIntrospection') && ~isfield(mappingInfo.ObjectIntrospection, 'Error')
            fprintf('   - API Methods: %d\n', length(mappingInfo.ObjectIntrospection.PublicMethods));
            fprintf('   - API Properties: %d\n', length(mappingInfo.ObjectIntrospection.PublicProperties));
        end
        
    catch ME
        error('Failed to write JSON file: %s', ME.message);
    end
    
    fprintf('🎉 Export completed successfully!\n');
end
