# Position Decoding
### Author: Christina Hahn

Runs LSTM to decode tongue marker position from spiking activity in the brain. Raw data is not included.

Code in Neural_Decoding folder (for binning, LSTM, and calculating R2) provided by the Kording Lab.

### How to Use:
1. Open position_format.m with MATLAB and modify any user params. Running this file outputs formatted .mat structs stored in the Data_Formatted folder.
2. Open Position_Preprocessing.ipynb and modify any user params. Running this file outputs binned spikes/directions stored in the Data_Binned folder.
3. Open Position_Decoding.ipynb and modify any user params. Running this takes a while (~4 hours for all datasets). The program saves R2 results as .csv files stored in the Results folder.