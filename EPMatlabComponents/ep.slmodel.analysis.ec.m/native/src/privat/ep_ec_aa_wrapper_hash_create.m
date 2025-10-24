function [sUniqueHash, bIsDuplicate] = ep_ec_aa_wrapper_hash_create(sString, jHashSetOfHashes)
% Creates a truncated MD5 hash that is unique in the provided Java HashSet

bIsDuplicate = false;

sUniqueHash = i_createHash(sString);

% truncate hash for readability in EP
sUniqueHash = sUniqueHash(1:5);
if jHashSetOfHashes.contains(sUniqueHash)
    bIsDuplicate = true;
    sUniqueHash = ep_ec_aa_wrapper_hash_create([sString, 'X'], jHashSetOfHashes);
else
    jHashSetOfHashes.add(sUniqueHash);
end
end


%%
function sHash = i_createHash(sString)
jHasher = java.security.MessageDigest.getInstance('MD5');
sHash = reshape(dec2hex(jHasher.digest(uint8(sString))), 1, []);
end

