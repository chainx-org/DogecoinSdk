package com.chainx.dogecoindemo;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;

import com.chainx.dogecoin.Dogecoin;
import com.chainx.dogecoin.DogecoinExcpetion;

public class MainActivity extends AppCompatActivity {

    final static String phrase0 = "flame flock chunk trim modify raise rough client coin busy income smile";
    final static String phrase1 = "shrug argue supply evolve alarm caught swamp tissue hollow apology youth ethics";
    final static String phrase2 = "awesome beef hill broccoli strike poem rebel unique turn circle cool system";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // 1. phrase -> private -> pubkey
        String private0 = null;
        try {
            private0 = Dogecoin.generateMyPrivkey(phrase0, "");
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }
        String private1 = null;
        try {
            private1 = Dogecoin.generateMyPrivkey(phrase1, "");
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }
        String private2 = null;
        try {
            private2 = Dogecoin.generateMyPrivkey(phrase2, "");
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }
        String pubkey0 = null;
        try {
            pubkey0 = Dogecoin.generateMyPubkey(private0);
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }
        String pubkey1 = null;
        try {
            pubkey1 = Dogecoin.generateMyPubkey(private1);
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }
        String pubkey2 = null;
        try {
            pubkey2 = Dogecoin.generateMyPubkey(private2);
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }

        // 2. Generate p2kh address
        String addr0 = Dogecoin.generateAddress(pubkey0, "testnet");
        String addr1 = Dogecoin.generateAddress(pubkey1, "testnet");
        String addr2 = Dogecoin.generateAddress(pubkey2, "testnet");

        // 3. Generate p2sh address
        // step0: generate redeem script using multiple user public keys and threshold
        long threshold = 2;
        String redeem_script = null;
        try {
            redeem_script = Dogecoin.generateRedeemScript(new String[] {pubkey0, pubkey1, pubkey2}, threshold);
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }
        // setp1: Use reddem script to generate addresses
        String multi_addr = null;
        try {
            multi_addr = Dogecoin.generateMultisigAddress(redeem_script, "testnet");
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }

        // 4. spent from p2kh address, e.g: addr1
        // step0: enter txid, index, address, amount array to generate raw tx
        String op_return = "35516a706f3772516e7751657479736167477a6334526a376f737758534c6d4d7141754332416255364c464646476a38";
        String[] txids = {"55728d2dc062a9dfe21bae44e87665b270382c8357f14b2a1a4b2b9af92a894a"};
        long[] indexs = {0};
        String base_tx = null;
        try {
            base_tx = Dogecoin.generateRawTx(txids, indexs, new String[] {addr0, op_return, addr1}, new long[] {100000, 0, 800000});
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }
        // note: Each txid must be signed separately
        for (int i=0; i < txids.length; i++) {
            // step1: generate p2kh sighash
            String sighash = null;
            try {
                sighash = Dogecoin.generateSighash(base_tx, txids[i], indexs[i], 0, pubkey1);
            } catch (DogecoinExcpetion dogecoinExcpetion) {
                dogecoinExcpetion.printStackTrace();
            }
            // step2: generate signature
            String signature = null;
            try {
                signature = Dogecoin.generateSignature(sighash, private1);
            } catch (DogecoinExcpetion dogecoinExcpetion) {
                dogecoinExcpetion.printStackTrace();
            }
            // step3: combine base tx and signature
            try {
                base_tx = Dogecoin.buildTx(base_tx, signature, txids[i], indexs[i], 0, pubkey1);
            } catch (DogecoinExcpetion dogecoinExcpetion) {
                dogecoinExcpetion.printStackTrace();
            }
        }
        System.out.println("final p2kh tx:" + base_tx);

        // 5. spent from p2sh address, e.g: multi_addr
        // step0: enter txid, index, address, amount array to generate raw tx
        txids = new String[] {"55728d2dc062a9dfe21bae44e87665b270382c8357f14b2a1a4b2b9af92a894a"};
        indexs = new long[] {1};
        try {
            base_tx = Dogecoin.generateRawTx(txids, indexs, new String[] {addr1, multi_addr}, new long[] {1000000, 6000000});
        } catch (DogecoinExcpetion dogecoinExcpetion) {
            dogecoinExcpetion.printStackTrace();
        }
        // note: Each txid must be signed separately, and each tixd has at least a threshold of user signatures!
        for (int i=0; i < txids.length; i++) {
            // step1: generate p2sh sighash
            String sighash = null;
            try {
                sighash = Dogecoin.generateSighash(base_tx, txids[i], indexs[i], 1, redeem_script);
            } catch (DogecoinExcpetion dogecoinExcpetion) {
                dogecoinExcpetion.printStackTrace();
            }
            // step2: user1 generate signature
            String signature1 = null;
            try {
                signature1 = Dogecoin.generateSignature(sighash, private1);
            } catch (DogecoinExcpetion dogecoinExcpetion) {
                dogecoinExcpetion.printStackTrace();
            }
            // step3: combine base tx and signature
            try {
                base_tx = Dogecoin.buildTx(base_tx, signature1, txids[i], indexs[i], 1, redeem_script);
            } catch (DogecoinExcpetion dogecoinExcpetion) {
                dogecoinExcpetion.printStackTrace();
            }
            // step4: user0 generate signature
            String signature0 = null;
            try {
                signature0 = Dogecoin.generateSignature(sighash, private0);
            } catch (DogecoinExcpetion dogecoinExcpetion) {
                dogecoinExcpetion.printStackTrace();
            }
            // step5: combine base tx and signature
            try {
                base_tx = Dogecoin.buildTx(base_tx, signature0, txids[i], indexs[i], 1, redeem_script);
            } catch (DogecoinExcpetion dogecoinExcpetion) {
                dogecoinExcpetion.printStackTrace();
            }
        }
        System.out.println("final p2sh tx:" + base_tx);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }
}