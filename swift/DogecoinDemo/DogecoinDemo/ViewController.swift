//
//  ViewController.swift
//  DogecoinDemo
//
//  Created by daiwei on 2022/5/9.
//

import UIKit
import Dogecoin

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
 
        // 1. phrase -> private -> pubkey
        let phrase0 = "flame flock chunk trim modify raise rough client coin busy income smile"
        let phrase1 = "shrug argue supply evolve alarm caught swamp tissue hollow apology youth ethics"
        let phrase2 = "awesome beef hill broccoli strike poem rebel unique turn circle cool system"
        let private0 = try! generateMyPrivkey(phrase: phrase0, pd_passphrase: "").get()
        let private1 = try! generateMyPrivkey(phrase: phrase1, pd_passphrase: "").get()
        let private2 = try! generateMyPrivkey(phrase: phrase2, pd_passphrase: "").get()
        let pubkey0 = try! generateMyPubkey(privkey: private0).get()
        let pubkey1 = try! generateMyPubkey(privkey: private1).get()
        let pubkey2 = try! generateMyPubkey(privkey: private2).get()
        
        // 2. Generate p2kh address
        let addr0 = generateAddress(pubkey: pubkey0, network: "testnet")
        assert(addr0=="nb2gZmphdD5fEVLDHdYAKp5Lpb1w4p5R2k", "addr0 not as expected")
        let addr1 = generateAddress(pubkey: pubkey1, network: "testnet")
        assert(addr1=="nbGodDo7pezD2LcKN8AFMc9nMPvT1YhXcc", "addr1 not as expected")
        let addr2 = generateAddress(pubkey: pubkey2, network: "testnet")
        assert(addr2=="ncLLmm2HPn2JJ61W3fvqMqLNRWcpXki6mJ", "addr2 not as expected")
        
        // 3. Generate p2sh address
        // step0: generate redeem script using multiple user public keys and threshold
        let threshold: UInt32 = 2
        let redeem_script = try! generateRedeemScript(pubkeys: [pubkey0, pubkey1, pubkey2], threshold: threshold).get()
        assert(redeem_script=="5221032f7e2f0f3e912bf416234913b388393beb5092418fea986e45c0b9633adefd85210251e0dc3d9709d860c49785fc84b62909d991cffd81592f6994c452438f91b6a22102a09e8182977710bab64472c0ecaf9e52255a890554a00a62facd05c0b13817f853ae", "redeem script not as expected")
        // setp1: Use reddem script to generate addresses
        let multi_addr = generateMultisigAddress(redeem_script: redeem_script, network: "testnet")
        assert(multi_addr=="2MsemWYAyMhd3FzfNn6LNv5EmtG9aN1ZyVk", "multi_addr not as expected")
        
        // 4. spent from p2kh address, e.g: addr1
        // step0: enter txid, index, address, amount array to generate raw tx
        let op_return = "35516a706f3772516e7751657479736167477a6334526a376f737758534c6d4d7141754332416255364c464646476a38"
        var txids = ["55728d2dc062a9dfe21bae44e87665b270382c8357f14b2a1a4b2b9af92a894a"]
        var indexs: [UInt32] = [0]
        var base_tx = try! generateRawTx(txids: txids, indexs: indexs, addresses: [addr0, op_return, addr1], amounts: [100000, 0, 800000]).get()
        // note: Each txid must be signed separately
        for i in 0..<txids.count{
            // step1: generate p2kh sighash
            let sighash = try! generateSighash(base_tx: base_tx, txid: txids[i], index: indexs[i], sig_type: 0, script: pubkey1).get()
            // step2: generate signature
            let signature = try! generateSignature(message: sighash, privkey: private1).get()
            // step3: combine base tx and signature
            base_tx = try! buildTx(base_tx: base_tx, signature: signature, txid: txids[i], index: indexs[i], sig_type: 0, script: pubkey1).get()
        }
        print("final p2kh tx:", base_tx)
        
        // 5. spent from p2sh address, e.g: multi_addr
        // step0: enter txid, index, address, amount array to generate raw tx
        txids = ["55728d2dc062a9dfe21bae44e87665b270382c8357f14b2a1a4b2b9af92a894a"]
        indexs = [1]
        base_tx = try! generateRawTx(txids: txids, indexs: indexs, addresses: [addr1, multi_addr], amounts: [1000000, 6000000]).get()
        // note: Each txid must be signed separately, and each tixd has at least a threshold of user signatures!
        for i in 0..<txids.count{
            // step1: generate p2sh sighash
            let sighash = try! generateSighash(base_tx: base_tx, txid: txids[i], index: indexs[i], sig_type: 1, script: redeem_script).get()
            // step2: user1 generate signature
            let signature1 = try! generateSignature(message: sighash, privkey: private1).get()
            // step3: combine base tx and signature
            base_tx = try! buildTx(base_tx: base_tx, signature: signature1, txid: txids[i], index: indexs[i], sig_type: 1, script: redeem_script).get()
            // step4: user0 generate signature
            let signature0 = try! generateSignature(message: sighash, privkey: private0).get()
            // step5: combine base tx and signature
            base_tx = try! buildTx(base_tx: base_tx, signature: signature0, txid: txids[i], index: indexs[i], sig_type: 1, script: redeem_script).get()
        }
        print("final p2sh tx:", base_tx)
    }


}

