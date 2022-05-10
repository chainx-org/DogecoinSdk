//
//  Dogecoin.swift
//
//  Created by daiwei on 2021/10/16.
//

import Foundation

public enum DogecoinError: Error {
    case failPrivkey(message: String)
    case failPubkey(message: String)
    case failRedeemScript(message: String)
    case failRawTx(message: String)
    case failSighash(message: String)
    case failSignature(message: String)
    case failBuildTx(message: String)
}

public func judgeHex(s: String) -> Bool{
    let s = s.lowercased()
    if s.count % 2 != 0{
        return false
    }
    for i in s{
        if (i<"0" || i>"9") && (i<"a" || i>"f"){
            return false
        }
    }
    return true
}

/**
 * Generate private key from mnemonic
 *
 * - parameter phrase: root phrase
 * - parameter pd_passphrase: pass phrase
 * - returns: the private key hex string
 */
public func generateMyPrivkey(phrase: String, pd_passphrase: String) -> Result<String, DogecoinError>{
    let result = String.init(cString:generate_my_privkey_dogecoin(phrase, pd_passphrase))
    if judgeHex(s: result) {
        return .success(result)
    }else{
        return .failure(.failPrivkey(message: result))
    }
}

/**
 * Generate pubkey from privkey
 *
 * - parameter privkey: private key
 * - returns: pubkey string
 */
public func generateMyPubkey(privkey: String) -> Result<String, DogecoinError>{
    let result = String.init(cString:generate_my_pubkey_dogecoin(privkey))
    if judgeHex(s: result) {
        return .success(result)
    }else{
        return .failure(.failPubkey(message: result))
    }
}

/**
 * Generate dogecoin p2kh address from pubkey
 *
 * - parameter pubkey: pubkey hex string
 * - parameter network: network string, support  ["mainnet", "testnet"]
 *
 * - returns: the dogecoin address string.
 */
public func generateAddress(pubkey: String, network: String) -> String{
    return String.init(cString:generate_address_dogecoin(pubkey, network))
}

/**
 * Generate redeem script
 *
 * - parameter pubkeys: Hex string concatenated with multiple pubkeys
 * - parameter threshold: threshold number
 * - returns: the dogecoin redeem script.
 */
public func generateRedeemScript(pubkeys: [String], threshold: UInt32) -> Result<String, DogecoinError>{
    let result = String.init(cString:generate_redeem_script_dogecoin(pubkeys.joined(separator: ""), threshold))
    if judgeHex(s: result) {
        return .success(result)
    }else{
        return .failure(.failRedeemScript(message: result))
    }
}

/**
 * Generate dogecoin p2sh address
 *
 * - parameter redeem_script: redeem script
 * - parameter network: network string, support ["mainnet", "testnet"]
 * - returns: the dogecoin address string.
 */
public func generateMultisigAddress(redeem_script: String, network: String) -> String{
    return String.init(cString:generate_multisig_address_dogecoin(redeem_script, network))
}

/**
 * Add the first input to initialize basic transactions
 *
 * - parameter txids: utxo's txid array
 * - parameter indexs: utxo's index array
 * - parameter addresses: utxo's addresse array
 * - parameter amounts: utxo's amount array
 * - returns: the dogecoin raw tx hex string without signature
 */
public func generateRawTx(txids: [String], indexs: [UInt32], addresses: [String],  amounts: [UInt64]) -> Result<String, DogecoinError>{
    if txids.count != indexs.count || addresses.count != amounts.count{
        return .failure(.failRawTx(message: "input or output must be equal"))
    }
    var base_tx = String.init(cString:generate_base_tx_dogecoin(txids[0], indexs[0]));

    for i in 1..<txids.count {
        base_tx = String.init(cString:add_input_dogecoin(base_tx,  txids[i], indexs[i]));
    }
    for i in 0..<addresses.count{
        base_tx = String.init(cString:add_output_dogecoin(base_tx, addresses[i], amounts[i]));
    }
    if judgeHex(s: base_tx) {
        return .success(base_tx)
    }else{
        return .failure(.failRawTx(message: base_tx))
    }
}

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
public func generateSighash(base_tx: String, txid: String, index: UInt32, sig_type: UInt32, script: String) -> Result<String, DogecoinError>{
    let result = String.init(cString:generate_sighash_dogecoin(base_tx, txid, index, sig_type, script))
    if judgeHex(s: result) {
        return .success(result)
    }else{
        return .failure(.failSighash(message: result))
    }
}

/**
 * Generate ecdsa signature.
 *
 * - parameter message: Awaiting signed sighash/message
 * - parameter privkey: private key
 * - returns: the signature hex string.
 */
public func generateSignature(message: String, privkey: String) -> Result<String, DogecoinError>{
    let result = String.init(cString:generate_signature_dogecoin(message, privkey))
    if judgeHex(s: result) {
        return .success(result)
    }else{
        return .failure(.failSignature(message: result))
    }
}

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
public func buildTx(base_tx: String, signature: String, txid: String, index: UInt32, sig_type: UInt32, script: String) -> Result<String, DogecoinError>{
    let result = String.init(cString:build_tx_dogecoin(base_tx, signature, txid, index, sig_type, script))
    if judgeHex(s: result) {
        return .success(result)
    }else{
        return .failure(.failBuildTx(message: result))
    }
}

