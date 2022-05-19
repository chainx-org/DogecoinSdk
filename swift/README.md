# **Overview**

This is an api documentation for dogecoin. These help to build dogecoin wallets for iOS. 

# **Dependencies**

Step 1.  Import project

`File>Add Packages>Github` search [https://github.com/chainx-org/dogecoin-ios-api](https://github.com/chainx-org/dogecoin-ios-api) . The current version is **0.1.1**.

Step 2. Import and use

```swift
import Dogecoin
```

# **Api**

## Error

~~~swift
public enum DogecoinError: Error {
    case failPrivkey(message: String)
    case failPubkey(message: String)
    case failRedeemScript(message: String)
    case failRawTx(message: String)
    case failSighash(message: String)
    case failSignature(message: String)
    case failBuildTx(message: String)
}
~~~

## Construct Transaction

### generateRawTx

To generate an unsigned transaction, the transaction needs to contain the complete input and output information.

inputs: 

	- txid : Transaction ID where the unspent output is located
	- index: The index in the transaction where the unspent output is located.

outputs:

- address
- amount

Note: The txid and index need to be put into array one by one correspondence, address and amount as well.

```swift
/**
 * Add the first input to initialize basic transactions
 *
 * - parameter txids: utxo's txid array
 * - parameter indexs: utxo's index array
 * - parameter addresses: utxo's addresse array
 * - parameter amounts: utxo's amount array
 * - returns: the dogecoin raw tx hex string without signature
 */
public func generateRawTx(txids: [String], indexs: [UInt32], addresses: [String],  amounts: [UInt64]) -> Result<String, DogecoinError>
```

### generateSighash

Each input corresponds to a sighash, and signing the input is signing the sighash.

```swift
/**
 * Generate sighash/message to sign. Through sig_type and script input different, support p2kh and p2sh two types of sighash
 *
 * - parameter base_tx: base transaction hex string
 * - parameter txid: utxo's txid
 * - parameter index: utxo's index
 * - parameter sig_type: support  [0, 1]. 0 is p2kh, 1 is p2sh
 * - parameter script: When p2kh, script input user pubkey, when p2sh script input redeem script
 * - returns: the sighash hex string
 */
public func generateSighash(base_tx: String, txid: String, index: UInt32, sig_type: UInt32, script: String) -> Result<String, DogecoinError>
```

### generateSignature

```swift
/**
 * Generate ecdsa signature.
 *
 * - parameter message: Awaiting signed sighash/message
 * - parameter privkey: private key
 * - returns: the signature hex string.
 */
public func generateSignature(message: String, privkey: String) -> Result<String, DogecoinError>
```

### buildTx

The complete transaction is constructed by placing all signatures in each transaction input separately. Since only one signature can be placed at a time, if there are multiple inputs then multiple calls should be made.

```swift
/**
 * Combining signatures into transaction.
 *
 * - parameter base_tx: base transaction hex string.
 * - parameter signature: signature of sighash
 * - parameter txid: utxo's txid
 * - parameter index: utxo's index
 * - parameter sig_type: support  [0, 1]. 0 is p2kh, 1 is p2sh
 * - parameter script: When p2kh, script input user pubkey, when p2sh script input redeem script
 * - returns: base transaction with one more signature.
 */
public func buildTx(base_tx: String, signature: String, txid: String, index: UInt32, sig_type: UInt32, script: String) -> Result<String, DogecoinError>
```

## Tools

phrase -> privkey -> pubkey -> address

​								-> pubkeys -> redeem script -> multisig address

### generateMyPrivkey

```swift
/**
 * Generate private key from mnemonic
 *
 * - parameter phrase: root phrase
 * - parameter pd_passphrase: pass phrase
 * - returns: the private key hex string
 */
public func generateMyPrivkey(phrase: String, pd_passphrase: String) -> Result<String, DogecoinError>
```

### generateMyPubkey

```swift
/**
 * Generate pubkey from privkey
 *
 * - parameter privkey: private key
 * - returns: pubkey string
 */
public func generateMyPubkey(privkey: String) -> Result<String, DogecoinError>
```

### generateAddress

```swift
/**
 * Generate dogecoin p2kh address from pubkey
 *
 * - parameter pubkey: pubkey hex string
 * - parameter network: network string, support  ["mainnet", "testnet"]
 *
 * - returns: the dogecoin address string.
 */
public func generateAddress(pubkey: String, network: String) -> String
```

### generateRedeemScript

Using p2sh for threshold signing requires the use of an redeem script. The redeem script contains the public keys of all signers.

```swift
/**
 * Generate redeem script
 *
 * - parameter pubkeys: Hex string concatenated with multiple pubkeys
 * - parameter threshold: threshold number
 * - returns: the dogecoin redeem script.
 */
public func generateRedeemScript(pubkeys: [String], threshold: UInt32) -> Result<String, DogecoinError>
```

### generateMultisigAddress

Use the redeem script and pick the network to generate the multi-signature address.

```swift
/**
 * Generate dogecoin p2sh address
 *
 * - parameter redeem_script: redeem script
 * - parameter network: network string, support ["mainnet", "testnet"]
 * - returns: the dogecoin address string.
 */
public func generateMultisigAddress(redeem_script: String, network: String) -> String
```

# **Example**

The following example shows the use of the tool and the construction of a p2pkh-based transfer method for normal users and a p2sh-based transfer method for trustees, respectively. The complete code can be viewed in [ViewController.swift](https://github.com/chainx-org/DogecoinSdk/blob/main/swift/DogecoinDemo/DogecoinDemo/ViewController.swift#L17-L79).

## **Details**

### Generate dogecoin address

1. Pass in the mnemonic phrase and password to generate a private key

   ~~~swift
   let private0 = try! generateMyPrivkey(phrase: phrase0, pd_passphrase: "").get()
   ~~~

2. Generate public key

   ~~~swift
   let pubkey0 = try! generateMyPubkey(privkey: private0).get()
   ~~~

3. Generate Address

   ~~~swift
   let addr0 = generateAddress(pubkey: pubkey0, network: "testnet")
   ~~~

## Generate dogecoin multisig address

1. Pass in the public keys and thresholds of all signers

   ```swift
   let redeem_script = try! generateRedeemScript(pubkeys: [pubkey0, pubkey1, pubkey2], threshold: threshold).get()
   ```

2. Generate Multisig Address

   ```swift
   let multi_addr = generateMultisigAddress(redeem_script: redeem_script, network: "testnet")
   ```

## Construct p2pkh transaction (for users)

1. Assembled unsigned transaction

```swift
// inputs
var txids = ["55728d2dc062a9dfe21bae44e87665b270382c8357f14b2a1a4b2b9af92a894a"]
var indexs: [UInt32] = [0]
// outputs
// op_return as output address and it's amount == 0
let op_return = "35516a706f3772516e7751657479736167477a6334526a376f737758534c6d4d7141754332416255364c464646476a38"
var base_tx = try! generateRawTx(txids: txids, indexs: indexs, addresses: [addr0, op_return, addr1], amounts: [100000, 0, 800000]).get()
```

2. Generate sighash for one input

```swift
// pubkey is user's pubkey
let sighash = try! generateSighash(base_tx: base_tx, txid: txids[i], index: indexs[i], sig_type: 0, script: pubkey1).get()
```

3. Sign sighash to get signature 

```swift
let signature = try! generateSignature(message: sighash, privkey: private1).get()
```

4. Put signature into base tx 

```swift
let signature = try! generateSignature(message: sighash, privkey: private1).get()
```

5. Repeat steps 2, 3 and 4 until all signatures are placed in the transaction.

## Construct p2sh transaction (for trustees)

1. Assembled unsigned transaction

``` swift
txids = ["55728d2dc062a9dfe21bae44e87665b270382c8357f14b2a1a4b2b9af92a894a"]
indexs = [1]
base_tx = try! generateRawTx(txids: txids, indexs: indexs, addresses: [addr1, multi_addr], amounts: [1000000, 6000000]).get()
```

2. Generate multisig's sighash for one input

```swift
let sighash = try! generateSighash(base_tx: base_tx, txid: txids[i], index: indexs[i], sig_type: 1, script: redeem_script).get()
```

3. Generate signature for one input

```swift
let signature1 = try! generateSignature(message: sighash, privkey: private1).get()
```

4. Put signature into base tx 

```swift
base_tx = try! buildTx(base_tx: base_tx, signature: signature1, txid: txids[i], index: indexs[i], sig_type: 1, script: redeem_script).get()
```

5. Repeat steps 2, 3 and 4 until all signatures are placed in the transaction.
6. When a trustee completes all signatures, the transaction is passed to the next trustee for signning and the process is repeated until the number of trusts with completed signatures reaches a threshold and the transaction construction is complete.

# Calculation of handling fee and change balance

Background: A wants to transfer money to `B 2BTC`, `C 3BTC`

1. Find all unspent transaction txids and balances through the address of A, and sort them from largest to smallest, assuming it is `[(txid1, 4), (txid2, 2), (tixd3, 1), (tixd4, 1) ]`.

2. Accumulate the txids and balance list and find the txid that is greater than the output amount 2+3=5, that is, txid2. If it is not found, it will return that the transfer is not allowed.

3. Extend one bit from txid2 backward, using `[(txid1, 4), (txid2, 2), (tixd3, 1)]` as input. If txid2 is the last one, use `[(txid1, 4), (txid2, 2)]` as input.

4. Use the number of inputs and outputs and the following formula to estimate the number of transaction bytes:

   **Estimation of the number of bytes spent by p2pkh addresses**

   ```
   70 +180 * input_count(p2pkh) + 34 * output_count
   ```

   `input_count(p2pkh)` represents the number of input txid when the non-threshold address is spent

   **Estimation of the number of bytes of the p2sh address**

   ```
   70 + 900 * input_count(p2sh) + 34 * output_count
   ```

   `input_count(p2sh)` represents the number of input txid when the threshold address is spent

5. Multiply the number of bytes by the current `FEE RATES` to get the transaction fee.

6. Enter `total amount-(total amount of output + handling fee)` to get `change amount`. If it is negative, there is no change (that is, the change address and amount are not filled in the output list), and the transaction fee becomes `Total input amount-Total amount to output`.
