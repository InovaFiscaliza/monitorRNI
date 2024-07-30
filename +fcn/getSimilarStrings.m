
function idxFiltered = getSimilarStrings(methodName, cacheStringList, cacheTokenList, value2Search, idxFiltered, nMaxValues)

    switch methodName
        case 'startsWith'
            idxLogical  = startsWith(cacheStringList, value2Search);
            idxFiltered = unique([idxFiltered; find(idxLogical)], 'stable');
    
        case 'Contains'
            idxLogical  = contains(cacheStringList, value2Search);
            idxFiltered = unique([idxFiltered; find(idxLogical)], 'stable');
    
        case 'Levenshtein'
            nTokens     = numel(cacheTokenList);
            levDistance = zeros(nTokens, 1, 'single');
    
            fcn.parpoolCheck()
            parfor ii = 1:nTokens
                levDistance(ii) = fcn.LevenshteinDistance(cacheTokenList{ii}, value2Search);
            end
            [~, sortedIndex] = sortrows(levDistance);
    
            kk = 0;
            while numel(idxFiltered) < nMaxValues
                kk = kk+1;
                if kk > nTokens
                    break
                end
    
                sortedTokenIndex = find(contains(cacheStringList, cacheTokenList{sortedIndex(kk)}));
                idxFiltered      = unique([idxFiltered; sortedTokenIndex], 'stable');
            end
            idxFiltered = idxFiltered(1:min([numel(idxFiltered), nMaxValues]));
    end
end