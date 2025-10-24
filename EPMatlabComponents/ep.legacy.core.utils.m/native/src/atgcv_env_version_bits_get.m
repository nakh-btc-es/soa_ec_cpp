% Get bitsize (32/64) for Windows OS and Matlab version.
%
% function bits = atgcv_env_version_bits_get(sSystem)
%
% -  bits = atgcv_env_version_bits_get('WIN')
%    Get number of bits for the Windows version of the current system.
%    Result is 32 for 32 bit systems and 64 for 64 bit systems.
%
% -  bits = atgcv_env_version_bits_get('MATLAB')
%    Get number of bits for the Matlab version of the current system.
%    Result is 32 for 32 bit systems and 64 for 64 bit systems.
%
% -  [win_bits, matlab_bits] = atgcv_env_version_bits_get
%    Get the bit numbers of Windows (win_bits) and Matlab (matlab_bits).
%
%   AUTHOR(S):
%       Rainer.Lochmann@btc-es.de
% $$$COPYRIGHT$$$-2012
%
function bits = atgcv_env_version_bits_get(sSystem)

    bits = [];
    
    if nargin == 0
        bits = [i_win_bits_get(), i_matlab_bits_get()];
    else
        switch sSystem
            case 'WIN'
                bits = i_win_bits_get();
            case 'MATLAB'
                bits = i_matlab_bits_get();
        end
    end
    
end

%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                           ***
%                                                                           ***
%******************************************************************************

%******************************************************************************
% Get Windows OS Bit Version
%******************************************************************************
function iBits = i_win_bits_get()
    
    persistent nBits;
    if isempty(nBits)
        sWinDir = getenv('windir');
        if isdir([sWinDir, '\SysWOW64'])
            nBits = 64;
        else 
            nBits = 32;
        end
    end
    
    iBits = nBits;
end

%******************************************************************************
% Get Matlab Bit Version
%******************************************************************************
function iBits = i_matlab_bits_get()
    
    persistent nBits;
    if isempty(nBits)
        sMexExt = mexext;
        if strcmp(sMexExt, 'mexw64')
            nBits = 64;
        else
            nBits = 32;
        end
    end
    
    iBits = nBits;
end

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************
