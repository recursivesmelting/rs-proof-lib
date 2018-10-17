# Recursive Smelting Proof Library
A wallet interface allowing for proof generation and verification required for the Recursive Smelting protocol.
## Installation
1. Install xjsnark as outlined [here](https://github.com/akosba/xjsnark).
2. Copy & Paste rsValidate.mps into ./xjsnark/languages/xjsnark/sandbox/models/xjsnark folder.
## Running and Generating circuit
1. Open MPS and the xjsnark project.
2. In the logical view navigate to xjsnark.sandbox -> xjsnark -> Tests.
3. Right click on the one of the various test classes, for example ConvertTest, and then select Run 'Class ConvertTest'.

## Tests
* ConvertTest: Convert from a 32 byte array to a 8 byte array and back.
* HashTest: Hash and double hash a value.
* RawTXTest: Collect states and dummy scripts into a rawtx.
* FullValidateTest: 
  * Verify either genesis, minting or ownership rules. 
  * Generate raw transactions from states and scripts, calculate TXIDs.
  * Concatenate the TXIDs and hash them.
  * Check hash of concatenation of TXIDs equals public input.

### Test data Generation (Javascript)
+ [Bch Lib](https://github.com/owstack/bch-lib)
