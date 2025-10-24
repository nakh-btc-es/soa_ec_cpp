function bIsLess = atgcv_verLessThan(sVersion)
persistent p_knownVersionsIsLess;

if isempty(p_knownVersionsIsLess)
    p_knownVersionsIsLess = containers.Map();
end
if isKey(p_knownVersionsIsLess, sVersion)
    bIsLess = p_knownVersionsIsLess(sVersion);
else
    bIsLess = (atgcv_version_p_compare(sVersion) < 0);
    p_knownVersionsIsLess(sVersion) = bIsLess;
end
end
