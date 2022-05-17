# **Overview**

This is an api documentation for dogecoin. These help to build dogecoin wallets for android. 

# **Dependencies**

Step 1. Add the JitPack repository to your build file

```
allprojects {
repositories {
...
maven {url'https://jitpack.io'}
}
}
```

Step 2. Add dependencies

```
dependencies {
implementation'com.github.chainx-org:dogecoin-android-api:v0.1.0'
}
```

Step 3. Import the Dogecoin package

```
import com.chainx.dogecoin.Dogecoin;
import com.chainx.dogecoin.DogecoinExcpetion;
```

# **Api**

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

```java
/*
     * Add the first input to initialize basic transactions
     *
     * - parameter txids: utxo's txid array
     * - parameter indexs: utxo's index array
     * - parameter addresses: utxo's addresse array
     * - parameter amounts: utxo's amount array
     * - returns: the dogecoin raw tx hex string without signature
*/
public static String generateRawTx(String[] txids, long[] indexs, String[] addresses, long[] amounts) throws DogecoinExcpetion
```

### generateSighash

Each input corresponds to a sighash, and signing the input is signing the sighash.

```java
/*
     * Generate sighash/message to sign. Through sig_type and script input different, support p2kh and p2sh two types of sighash
     *
     * - parameter base_tx: base transaction hex string
     * - parameter txid: utxo's txid
     * - parameter index: utxo's index
     * - parameter sig_type: support  [0, 1]. 0 is p2kh, 1 is p2sh
     * - parameter script: When p2kh, script input user pubkey, when p2sh script input redeem script
     * - returns: the sighash hex string
*/
public static String generateSighash(String base_tx, String txid, long index, long sig_type, String script) throws DogecoinExcpetion
```

### generateSignature

```java
/**
     * Generate ecdsa signature.
     *
     * - parameter message: Awaiting signed sighash/message
     * - parameter privkey: private key
     * - returns: the signature hex string.
*/
public static String generateSignature(String message, String privkey) throws DogecoinExcpetion
```

### buildTx

The complete transaction is constructed by placing all signatures in each transaction input separately. Since only one signature can be placed at a time, if there are multiple inputs then multiple calls should be made.

```java
/*
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
public static String buildTx(String base_tx, String signature, String txid, long index, long sig_type, String script) throws DogecoinExcpetion
```

## Tools

phrase -> privkey -> pubkey -> address

​								    pubkeys -> redeem script -> multisig address

### generateMyPrivkey

```java
/*
     * Generate private key from mnemonic
     *
     * - parameter phrase: root phrase
     * - parameter pd_passphrase: pass phrase
     * - returns: the private key hex string
*/
public static String generateMyPrivkey(String phrase, String pd_passphrase) throws DogecoinExcpetion
```

### generateMyPubkey

```java
/**
     * Generate pubkey from privkey
     *
     * - parameter privkey: private key
     * - returns: pubkey string
*/
public static String generateMyPubkey(String privkey) throws DogecoinExcpetion
```

### generateAddress

```java
/**
     * Generate dogecoin p2kh address from pubkey
     *
     * - parameter pubkey: pubkey hex string
     * - parameter network: network string, support  ["mainnet", "testnet"]
     *
     * - returns: the dogecoin address string.
*/
public static String generateAddress(String pubkey, String network)
```

### generateRedeemScript

Using p2sh for threshold signing requires the use of an redeem script. The redeem script contains the public keys of all signers.

```java
/*
     * Generate redeem script
     *
     * - parameter pubkeys: Hex string concatenated with multiple pubkeys
     * - parameter threshold: threshold number
     * - returns: the dogecoin redeem script.
*/
public static String generateRedeemScript(String[] pubkeys, long threshold) throws DogecoinExcpetion
```

### generateMultisigAddress

Use the redeem script and pick the network to generate the multi-signature address.

```java
/*
     * Generate dogecoin p2sh address
     *
     * - parameter redeem_script: redeem script
     * - parameter network: network string, support ["mainnet", "testnet"]
     * - returns: the dogecoin address string.
*/
public static String generateMultisigAddress(String redeem_script, String network) throws DogecoinExcpetion
```

# **Example**

The following example shows the use of the tool and the construction of a p2pkh-based transfer method for normal users and a p2sh-based transfer method for trustees, respectively. The complete code can be viewed in [MainActivity.java](DogecoinDemo/app/src/main/java/com/chainx/dogecoindemo/MainActivity.java).

## **Details**

### Generate dogecoin address

1. Pass in the mnemonic phrase and password to generate a private key

   ~~~java
   String private0 = Dogecoin.generateMyPrivkey(phrase0, "");
   ~~~

2. Generate public key

   ~~~java
   String pubkey0 = Dogecoin.generateMyPubkey(private0);
   ~~~

3. Generate Address

   ~~~java
   String addr0 = Dogecoin.generateAddress(pubkey0, "testnet");
   ~~~

## Generate dogecoin multisig address

1. Pass in the public keys and thresholds of all signers

   ```java
   String redeem_script = Dogecoin.generateRedeemScript(new String[] {pubkey0, pubkey1, pubkey2}, threshold);
   ```

2. Generate Multisig Address

   ```java
   String multi_addr = Dogecoin.generateMultisigAddress(redeem_script, "testnet");
   ```

## Construct p2pkh transaction (for users)

1. Assembled unsigned transaction

```java
// inputs
String[] txids = new String[] {"55728d2dc062a9dfe21bae44e87665b270382c8357f14b2a1a4b2b9af92a894a"};
long[] indexs = new long[] {1};
// outputs
// op_return as output address and it's amount == 0
String op_return = "35516a706f3772516e7751657479736167477a6334526a376f737758534c6d4d7141754332416255364c464646476a38";
String[] addresses = new String[] {addr0, op_return, addr1}
long[] amounts = new long[] {100000, 0, 800000}

String base_tx = Dogecoin.generateRawTx(txids, indexs, addresses, amounts);
```

2. Generate sighash for one input

```java
// pubkey is user's pubkey
String sighash = Dogecoin.generateSighash(base_tx, txids[i], indexs[i], 0, pubkey1);
```

3. Sign sighash to get signature 

```java
String signature = Dogecoin.generateSignature(sighash, private1);
```

4. Put signature into base tx 

```java
base_tx = Dogecoin.buildTx(base_tx, signature, txids[i], indexs[i], 0, pubkey1);
```

5. Repeat steps 2, 3 and 4 until all signatures are placed in the transaction.

## Construct p2sh transaction (for trustees)

1. Assembled unsigned transaction

``` java
// inputs
String[] txids = new String[] {"55728d2dc062a9dfe21bae44e87665b270382c8357f14b2a1a4b2b9af92a894a"};
long[] indexs = new long[] {1};
// outputs
String[] addresses = new String[] {addr1, multi_addr}
long[] amounts = new long[] {1000000, 6000000}

String base_tx = Dogecoin.generateRawTx(txids, indexs, addresses, amounts);
```

2. Generate multisig's sighash for one input

```java
String sighash = Dogecoin.generateSighash(base_tx, txids[i], indexs[i], 1, redeem_script);
```

3. Generate signature for one input

```java
String signature1 = Dogecoin.generateSignature(sighash, private1);
```

4. Put signature into base tx 

```java
base_tx = Dogecoin.buildTx(base_tx, signature1, txids[i], indexs[i], 1, redeem_script);
```

5. Repeat steps 2, 3 and 4 until all signatures are placed in the transaction.
6. When a trustee completes all signatures, the transaction is passed to the next trustee for signning and the process is repeated until the number of trusts with completed signatures reaches a threshold and the transaction construction is complete.

# Calculation of handling fee and change balance

Background: A wants to transfer money to `B 2BTC`, `C 3BTC`

1. Find all unspent transaction txids and balances through the address of A, and sort them from largest to smallest, assuming it is `[(txid1, 4), (txid2, 2), (tixd3, 1), (tixd4, 1) ]`.

2. Accumulate the txids and balance list and find the txid that is greater than the output amount 2+3=5, that is, txid2. If it is not found, it will return that the transfer is not allowed.

3. Extend one bit from txid2 backward, using `[(txid1, 4), (txid2, 2), (tixd3, 1)]` as input. If txid2 is the last one, use `[(txid1, 4), (txid2, 2)]` as input.

4. Use the number of inputs and outputs and the following formula to estimate the number of transaction bytes:

   **Estimation of the number of bytes spent by non-threshold addresses**

   ```
   70 +180 * input_count(p2pkh) + 34 * output_count
   ```

   `input_count(taproot_address)` represents the number of input txid when the non-threshold address is spent

   **Estimation of the number of bytes of the threshold address**

   ```
   105 + 141 * input_count(threshold_address) + 43 * output_count
   ```

   `input_count(threshold_address)` represents the number of input txid when the threshold address is spent

5. Multiply the number of bytes by the current `FEE RATES` to get the transaction fee.

6. Enter `total amount-(total amount of output + handling fee)` to get `change amount`. If it is negative, there is no change (that is, the change address and amount are not filled in the output list), and the transaction fee becomes `Total input amount-Total amount to output`.